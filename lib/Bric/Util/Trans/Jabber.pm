package Bric::Util::Trans::Jabber;

###############################################################################

=head1 Name

Bric::Util::Trans::Jabber - Utility class for sending instant messages.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Trans::Jabber;
  my $j = Bric::Util::Trans::Jabber->new(
    { to      => ['jchaddickerson@aol.jabber.org'],
      subject => 'Greetings',
      message => 'This is an instant message sent via Bric::Util::Trans::Jabber'
     });
  $j->send;

=head1 Description

This class provides a thin abstraction to the Net::Jabber module. Use it to send
instant messages from within Bricolage applications.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
#use Net::Jabber;
use Bric::Util::Fault qw(throw_dp);

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

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
             # Public Fields
             to =>  Bric::FIELD_RDWR,
             subject =>  Bric::FIELD_RDWR,
             message =>  Bric::FIELD_RDWR,

             # Private Fields
            });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $j = Bric::Util::Trans::Jabber->new($init)

Instantiates a Bric::Util::Trans::Jabber object. An anonymous of initial values
may be passed. The supported intial value keys are:

=over 4

=item *

to - Anonymous array of instant message addresses to send mail to. Be sure to
include a full address and server name in email address style, as this is what
jabber uses to send the message to the proper network. For example,
'jchaddickerson@aol.jabber.org'.

=item *

subject - The subject of the message.

=item *

message - The message to be sent.

=back

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $self->SUPER::new($init);
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

NONE.

=head2 Public Instance Methods

=over 4

=item my $to_aref = $j->get_to

Returns an anonymous array of addresses to which to send the instant message.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field '' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $j->set_to($to_aref)

Sets the list of addresses to which to send the instant message. Pass in the
list as an anonymous array.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'to' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $sub = $j->get_subject

Returns the subject of the instant message.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'subject' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $j->set_subject($sub)

Sets subject of the instant message.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'subject' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $msg = $j->get_message

Returns the message (body) of the instant message.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'message' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $j->set_message($msg)

Sets message (body) of the instant message.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'message' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $j->send

Sends the instant message to the addresses stored in to.

B<Throws:>

=over 4

=item *

Unable to send instant message.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub send {
    my $self = shift;
    my ($to, $sub, $msg) = $self->_get(qw(to subject message));
    eval {
    # Do Jabber stuff in here.
    };
    return $self unless $@;
    throw_dp(error => "Unable to send instant message: $@");
}

################################################################################

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
L<Net::Jabber|Net::Jabber>

=cut
