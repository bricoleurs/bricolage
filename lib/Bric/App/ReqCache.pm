package Bric::App::ReqCache;

=head1 NAME

Bric::App::ReqCache - Object for managing Application-wide global data.

=head1 VERSION

$Revision: 1.4 $

=cut

# Grab the Version Number.
our $VERSION = substr(q$Revision: 1.4 $, 10, -1);

=head1 DATE

$Date: 2001-10-11 00:34:53 $

=head1 SYNOPSIS

  use Bric::App::ReqCache;
  my $rc = Bric::App::ReqCache->new;
  $rc = $rc->set($key, $val);
  my $val = $rc->get($key);

=head1 DESCRIPTION

This class offers simple caching of data for the length of an Apache request.
It is cleaned out during the Apache Cleanup phase. If you need to cache data
beyond the current request, use Bric::App::Cache or Bric::App::Session.

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

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $dp = 'Bric::Util::Fault::Exception::DP';
my $gen = 'Bric::Util::Fault::Exception::GEN';

our %req_cache;

################################################################################

################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $rc = Bric::App::ReqCache->new()

Instantiates a Bric::App::ReqCache object. No initial values may be passed.

B<Throws:>

=over 4

=item *

Unable to instantiate cache.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    bless {}, ref $_[0] || $_[0];
}

################################################################################

=item my $org = Bric::App::ReqCache->lookup()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::App::ReqCache::lookup() method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    die Bric::Util::Fault::Exception::MNI->new(
      {msg => __PACKAGE__."::lookup() method not implemented."});
}

################################################################################

=item Bric::App::ReqCache->list()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::App::ReqCache::list() method not implemented.

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

=item Bric::App::ReqCache->list_ids()

Not implemented - not needed.

B<Throws:>

=over

=item *

Bric::App::ReqCache::list_ids() method not implemented.

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

=item my $val = $rc->get($key)

Returns a value for the specified key. Call $rc->set($key, $value) to store a
value.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get { $req_cache{$_[1]} }

################################################################################

=item $self = $rc->set($key, $value);

Stores $value as referenced by $key. Call $rc->get($key) to retrieve $value.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set {  $req_cache{$_[1]} = $_[2]; $_[0] }

################################################################################

=item $self = $rc->clear()

=item Bric::App::ReqCache->clear()

Clears the cache of all its values. Called during the Apache cleanup phase.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub clear { %req_cache = () }

################################################################################

=item my %req_cache = $rc->get_all()

Returns a hash list of all the values currently in the cache.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_all { %req_cache }

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
Bric::App::Cache(3),
Bric::App::Session(4),
Apache::Session(5)

=cut
