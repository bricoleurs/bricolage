npackage Bric::Dist::Client;

=head1 NAME

Bric::Dist::Client - LWP Client for telling Bric::Dist::Handler to execute
distribution jobs.

=head1 VERSION

$Revision: 1.6 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.6 $ )[-1];

=head1 DATE

$Date: 2002-01-06 04:40:36 $

=head1 SYNOPSIS

  use Bric::Dist::Client;

  my $dist = Bric::Dist::Client->new;
  $dist->load_ids;

  my @exec_ids = $dist->get_exec_ids;
  $dist->add_exec_ids(@exec_ids);
  $dist->del_exec_ids(@exec_ids);

  my $url = $dist->get_url;
  $dist = $dist->set_url($url);
  my $cookie = $dist->get_cookie;
  $dist = $dist->set_cookie($cookie);

  $dist->send;

=head1 DESCRIPTION

This class functions as a client to the distribution server. It will load the
lists of job IDs to be executed and send them via lwp to the distribution
server, which is running Bric::Dist::Handler. It is principally used to distribute
files for preview, and by dist_mon to distribute files for publication.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Dist::Job;
use Bric::Util::DBI qw(:standard);
use Bric::Util::Time qw(:all);
use Bric::Util::Fault::Exception::GEN;
use LWP::UserAgent;
use HTTP::Request;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################


################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant TIMEOUT => 30;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $ua = LWP::UserAgent->new;
$ua->timeout(TIMEOUT);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 exec_ids => Bric::FIELD_READ,
			 url => Bric::FIELD_RDWR,
			 cookie => Bric::FIELD_RDWR

			 # Private Fields
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $dist = Bric::Dist::Client->new($init)

Instantiates a Bric::Dist::Client object. An anonymous hash of initial values may
be passed. The supported initial value keys are:

=over 4

=item *

exec_ids - An anonymous array of Bric::Dist::Job IDs to be executed.

=item *

exp_ids - An anonymous array of Bric::Dist::Job IDs to be expired.

=back

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bric::_get() - Problems retrieving fields.

=item *

Cannot add resources to a completed job.

=item *

Cannot add resources to a pending job.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    @{$init->{exec_ids}}{ @{ delete $init->{exec_ids} || [] } } = ();
    $self->SUPER::new($init);
}

################################################################################

=back 4

=head2 Destructors

=over 4

=item $dist->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

=over 4

=item $dist = $dist->load_ids

Looks up the IDs of all Bric::Dist::Job objects in the database that are ready
to be executed or expired and populates the properties of this object with those
IDs.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub load_ids {
    my $self = shift;
    my $jids = $self->_get('exec_ids');
    my $new_jids = Bric::Dist::Job->list_ids(
      { sched_time => [undef, strfdate()],
	comp_time => undef });
    grep { $jids->{$_} = undef } @$new_jids;
    return $self;
}

################################################################################

=item my $url = $dist->get_url

Returns the Distribution server URL.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'url' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $dist->set_url($url)

Sets the distribution server URL.

  $dist->set_url('http://cf.about.com/dist/');

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'url' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $cookie = $dist->get_cookie

Returns the Distribution server cookie.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'cookie' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $dist->set_cookie($cookie)

Sets the distribution server cookie. If no cookie is set, then none will be
sent.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'cookie' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my (@exec_jids, $exec_jids_aref) = $dist->get_exec_ids

Returns a list anonymous array of Bric::Dist::Job IDs to be executed.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_exec_ids {
    wantarray ? sort { $a <=> $b } keys %{ $_[0]->_get('exec_ids') }
      : [ sort { $a <=> $b } keys %{ $_[0]->_get('exec_ids') } ];
}

################################################################################

=item $self = $dist->add_exec_ids(@exec_ids)

Adds to the list of Bric::Dist::Job IDs to be executed.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_exec_ids {
    my $self = shift;
    my $ids = $self->_get('exec_ids');
    @{$ids}{@_} = ();
    return $self;
}

################################################################################

=item $self = $dist->del_exec_ids(@exec_ids)

Deletes from the list of Bric::Dist::Job IDs to be executed. If no exec IDs are
passed, they will all be deleted.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_exec_ids {
    my $self = shift;
    my $ids = $self->_get('exec_ids');
    @_ ? delete @{$ids}{@_} : (%$ids = ());
    return $self;
}

################################################################################

=item $self = $dist->send

Sends the lists of Bric::Dist::Job IDs to be expired to the distribution server.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Error sending jobs to distributor.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub send {
    my $self = shift;
    my $exec = $self->get_exec_ids;
    my $cookie = $self->get_cookie;

    eval {
	my $req = HTTP::Request->new(HEAD => $self->_get('url'));
	$req->header(Execute => $exec);
	$req->header(Cookie => $cookie) if $cookie;
	my $res = $ua->request($req);
	return $self if $res->is_success;
	die $res->status_line;
    };
    die $gen->new({ msg => "Error sending jobs to distributor.",
		    payload => $@ }) if $@;
}

################################################################################

=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>

=cut
