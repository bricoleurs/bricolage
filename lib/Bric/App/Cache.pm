package Bric::App::Cache;

=head1 NAME

Bric::App::Cache - Object for managing Application-wide global data.

=head1 VERSION

$Revision: 1.16.4.1 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.16.4.1 $ )[-1];

=head1 DATE

$Date: 2003-04-10 19:24:21 $

=head1 SYNOPSIS

  use Bric::App::Cache;
  my $c = Bric::App::Cache->new;
  $c = $c->set($key, $val);
  my $val = $c->get($key);

  my $time = $c->get_lmu_time;
  $c = $c->set_lmu_time;

=head1 DESCRIPTION

This module provides a cache object to cache data that needs to
persist across all processes and across all requests, through time and
space.  The cache is cleared on server restart - for more permenant
storage see L<Bric::Util::DBI|Bric::Util::DBI>.

A Bric::App::Cache object is available from Mason components in the
global variable $c.

=head1 IMPLEMENTATION

This module is implemented as a two-level cache in order to provide
the best possible performance.

The first level is provided by Cache::Mmap.  Cache::Mmap is a very
fast, shared, file-based cache.  However, it is also a fixed-size
cache that will drop items from the cache when the cache becomes full
or the item to be stored is too large.

When an object cannot be stored in the first-level cache it is passed
to the second-level.  The second-level cache (also known as a backing
store) is provided by Cache::Cache.  Cache::Cache is quite a bit
slower than Cache::Mmap but has the advantage of being variable-sized.
As such it grows dynamically and won't refuse to store an object
unless it runs out of disk space.

The get() procedure is:

=over 4

=item *

Look in first-level cache for item.  If found, return it and finish.

=item *

Look in second-level cache for item.  If found, return it and finish.

=item *

Note in first-level cache that item is not in second-level cache.
This will prevent a look in the second-level cache on the next request
for this item.

=back

And the set() prodedure is:

=over 4

=item *

Try to set the item in the first-level cache.  If success, finish.  If
fail, delete old item if it exists.

=item *

Set the item in the second-level cache.  This must succeed or a fatal
error will result.

=back

NOTE: Under QA_MODE all set()s are sent to the secondary-cache to
allow the cache to be debugged.  Cache::Mmap lacks the ability to list
all keys in the cache which is used by the QA_MODE code.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::Fault::Exception::DP;
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Trans::FS;
use Cache::Mmap;
use Cache::FileCache;
use Bric::Config qw(TEMP_DIR SYS_USER SYS_GROUP QA_MODE);
use File::Path qw(mkpath rmtree);

################################################################################
# Inheritance
################################################################################

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant CACHE_ROOT =>
  Bric::Util::Trans::FS->cat_dir(TEMP_DIR, 'bricolage', 'cache');
use constant CACHE_MMAP =>
  Bric::Util::Trans::FS->cat_file(CACHE_ROOT, 'mmap');

unless (-d CACHE_ROOT) {
    mkpath(CACHE_ROOT, 0, 0777);
    # Let the Apache user own it unless $ENV{BRIC_TEMP_DIR} is set, in which
    # case we're running tests and want to keep the current user as owner.
    chown SYS_USER, SYS_GROUP, CACHE_ROOT
      unless $ENV{BRIC_TEMP_DIR};
}

# these could be made into bricolage.conf directives if we decide
# people will want to change them.  These values yeild a maximum cache
# size of 40MB.  See the Cache::Mmap docs for details.
use constant CACHE_MMAP_BUCKETS      => 10 * 1024;
use constant CACHE_MMAP_BUCKET_SIZE  => 4  * 1024;
use constant CACHE_MMAP_PAGE_SIZE    => 4  * 1024;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $dp = 'Bric::Util::Fault::Exception::DP';
my $gen = 'Bric::Util::Fault::Exception::GEN';

# We store the cache object in a package-wide lexical so that this
# class can function as a singleton. new() will always return the same
# object.
my $cache;

# The Cache::FileCache object is a package global so that the QA_MODE
# code in debug.mc can get at it
our $STORE;

################################################################################

################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $c = Bric::App::Cache->new()

Instantiates a Bric::App::Cache object. No initial values may be passed.

B<Throws:>

=over 4

=item *

Unable to instantiate cache.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    return $cache if $cache; # return singleton object if available
    my $pkg = shift;

    # create a new cache object
    my $mmap;

    # creating a new cache?
    my $exists = -e CACHE_MMAP;

    eval {
        # initialize Cache::Cache backing store
        $STORE = Cache::FileCache->new({ namespace => 'Bricolage_Cache',
                                         cache_root => CACHE_ROOT });
        # initialze mmap cache
        $mmap = Cache::Mmap->new(CACHE_MMAP,
                                  { buckets       => 1024,
                                    bucket_size   => 1024 * 4,
                                    page_size     => 1024 * 4,
                                    permissions   => 0777,
                                    read          => \&_read_backing_store,
                                    write         => \&_write_backing_store,
                                    context       => $STORE,
                                    writethrough  => (QA_MODE ? 1 : 0),
                                    cachenegative => 1,
                                  });
    };
    die $gen->new({ msg => 'Unable to instantiate cache.', payload => $@ })
      if $@;

    # chown if creating cache file
    chown(SYS_USER, SYS_GROUP, CACHE_MMAP)
      unless $exists or $ENV{BRIC_TEMP_DIR};

    # bless ref to cache object into this class and return
    return $cache = bless \$mmap, $pkg;
}

################################################################################

=item my $org = Bric::App::Cache->lookup()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::App::Cache::lookup() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::lookup() method not implemented."});
}

################################################################################

=item Bric::App::Cache->list()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::App::Cache::list() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::list() method not implemented."});
}

################################################################################

=back

=head2 Destructors

=over 4

=item $org->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over 4

=item Bric::App::Cache->list_ids()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::App::Cache::list_ids() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::list_ids() method not implemented."});
}

################################################################################

=item Bric::App::Cache->clear()

Clears the cache of all stored data.

Throws: NONE.

Side Effects: NONE.

Notes: NONE.

=cut

sub clear {
    rmtree(CACHE_ROOT);
    mkpath(CACHE_ROOT, 0, 0777);
    chown(SYS_USER, SYS_GROUP, CACHE_ROOT)
      unless $ENV{BRIC_TEMP_DIR};
}

=back

=head2 Public Instance Methods

=over 4

=item my $val = $c->get($key)

Returns a value for the specified key. Call $c->set($key, $value) to store a
value.

B<Throws:>

=over 4

=item *

Unable to fetch value from the cache.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get {
    my ($self, $key) = @_;
    my $ret;
    eval { $ret = $$self->read($key) };
    return if not defined $ret;
    return $$ret unless $@;
    die $dp->new( { msg => "Unable to fetch value from the cache.",
                    payload => $@ });
}

################################################################################

=item $self = $c->set($key, $value);

Stores $value as referenced by $key. Call $c->get($key) to retrieve $value.

B<Throws:>

=over 4

=item *

Unable to cache value.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set {
    my ($self, $key, $val) = @_;
    eval { $$self->write($key, \$val) };
    return $self unless $@;
    die $dp->new({ msg => "Unable to cache value.", payload => $@ });
}

################################################################################

=item my $lmu_time = $c->get_lmu_time

Returns the epoch time when a user object was last modified.

B<Throws:>

=over 4

=item *

Unable to fetch value from the cache.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_lmu_time { get($_[0], 'lmu_time') }

################################################################################

=item $self = $c->set_lmu_time($lmu_time)

Sets the epoch time when a user object was last modified.

B<Throws:>

=over 4

=item *

Unable to cache value.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_lmu_time { set($_[0], 'lmu_time', time) }

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item $val = _read_backing_store($key)

Reads a value from the backing store.  See the IMPLEMENTATION section
avove for details.

B<Throws:>

=over 4

=item *

Unable to fetch value from the backing cache.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _read_backing_store {
    my $ret;
    eval { $ret = $STORE->get($_[0]) };
    return $ret unless $@;
    die $dp->new( { msg => "Unable to fetch value from the backing cache.",
                    payload => $@ });
}

=item _write_backing_store($key, $val)

Writes a value to the backing store.  See the IMPLEMENTATION section
avove for details.

B<Throws:>

=over 4

=item *

Unable to cache value in the backing cache.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _write_backing_store {
    eval { $STORE->set($_[0], $_[1]) };
    return unless $@;
    die $dp->new({ msg => "Unable to cache value in the backing cache.", 
                   payload => $@ });
}

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric::App::Session|Bric::App::Session>,
L<Apache::Session|Apache::Session>

=cut
