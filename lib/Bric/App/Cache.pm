package Bric::App::Cache;

=head1 NAME

Bric::App::Cache - Object for managing Application-wide global data.

=head1 VERSION

$Revision: 1.8 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Date: 2001-11-20 00:02:44 $

=head1 SYNOPSIS

  use Bric::App::Cache;
  my $c = Bric::App::Cache->new;
  $c = $c->set($key, $val);
  my $val = $c->get($key);

  my $time = $c->get_lmu_time;
  $c = $c->set_lmu_time;

=head1 DESCRIPTION

This module uses a Cache::FileCache object to cache data that needs to persist
across all processes and across all requests, through time and space.

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
use File::Spec::Functions qw(tmpdir);
use Bric::Util::Trans::FS;
use Cache::FileCache;

################################################################################
# Inheritance
################################################################################

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant CACHE_ROOT =>
  Bric::Util::Trans::FS->cat_dir(tmpdir, 'bricolage', 'cache');

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $dp = 'Bric::Util::Fault::Exception::DP';
my $gen = 'Bric::Util::Fault::Exception::GEN';

# We store the Cache::FileCache object in a package-wide lexical so that this
# class can function as a singleton. new() will always return the same object.
my $cache;

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
    my ($pkg, $init) = @_;
    eval { $cache ||= Cache::FileCache->new({ namespace => 'Bricolage_Cache',
					      cache_root => CACHE_ROOT }) };
    die $gen->new({ msg => 'Unable to instantiate cache.', payload => $@ })
      if $@;
    return bless \$cache, ref $pkg || $pkg;
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

=back 4

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
    eval { $ret = $$self->get($key) };
    return $ret unless $@;
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
    eval { $$self->set($key, $val) };
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

=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Bric::App::Session(3),
Apache::Session(4)

=cut
