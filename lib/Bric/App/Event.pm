package Bric::App::Event;

=head1 Name

Bric::App::Event - Exports simple functions for managing events.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::App::Event qw(:all);
  log_event($name, $obj, $init);
  commit_events();

=head1 Description



=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::App::Session qw(get_user_object);
use Bric::Util::Event;
use Bric::Util::Time qw(:all);

################################################################################
# Inheritance
################################################################################
use base qw(Exporter);
our @EXPORT_OK = qw(log_event commit_events clear_events);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

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
our $events = [];

################################################################################
# Private Class Fields
#my $events = [];

################################################################################

################################################################################
# Instance Fields


################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

NONE.

=head2 Destructors

=over 4

=item $p->DESTROY

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

=head2 Public Functions

=over 4

=item my $bool = log_event($key_name, $obj, $init)

Queues an event for logging. Pass in the following arguments:

=over 4

=item $key_name

The key name of the event to log. Required.

=item $obj

The object for which the event is being logged. Required.

=item $init

The attribute values for this event. Required for those event types that require
them. See Bric::Util::EventType and Bric::Util::Event for more information.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub log_event {
    my ($key_name, $obj, $attr) = @_;
    push @$events, {
        key_name  => $key_name,
        obj       => $obj,
        attr      => $attr,
        user      => get_user_object,
        timestamp => strfdate(),
    };
    commit_events() unless Bric::Config::MOD_PERL || $ENV{BRIC_QUEUED};
}

=item my $bool = commit_events()

Goes through the queue of events created by calls to log_event() and actually
logs them to the database.

B<Throws:> See Bric::Util::Event::new().

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub commit_events {
    # Commit in alphabetical order to prevent deadlocks.
    Bric::Util::Event->new($_)
        for sort { $a->{key_name} cmp $b->{key_name} } @$events;
    @$events = ();
    return 1;
}

=item my $bool = clear_events()

Deletes queue of events so that they won't be logged. Used to prevent event
logging when an error has occurred and all changes have been rolled back.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub clear_events {
    @$events = ();
    return 1;
}

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>, 
L<Bric::Util::Event|Bric::Util::Event>

=cut
