package Bric::Util::Trans::Mail;

###############################################################################

=head1 NAME

Bric::Util::Trans::Mail - Utility class for sending email.

=head1 VERSION

$Revision: 1.4 $

=cut

our $VERSION = (qw$Revision: 1.4 $ )[-1];

=head1 DATE

$Date: 2001-11-20 00:02:46 $

=head1 SYNOPSIS

  use Bric::Util::Trans::Mail;
  my $m = Bric::Util::Trans::Mail->new(
    { smtp    => 'mail.sourceforge.net',
      from    => 'bricolage-devel@lists.sourceforge.net',
      to      => ['joe@bricolage_customer.com'],
      subject => 'Greetings',
      message => 'This is a message sent via Bric::Util::Trans::Mail'
     });
  $m->send;

=head1 DESCRIPTION

This class provides a thin abstraction to the Net::SMTP module. Use it to send
email from within Bricolage applications.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Net::SMTP;
use Bric::Util::Fault::Exception::DP;
use Bric::Config qw(:email);

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
			 smtp => Bric::FIELD_RDWR,
			 from => Bric::FIELD_RDWR,
			 subject => Bric::FIELD_RDWR,
			 message => Bric::FIELD_RDWR,
			 to => Bric::FIELD_RDWR,
			 cc => Bric::FIELD_RDWR,
			 bcc => Bric::FIELD_RDWR

			 # Private Fields
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $mail = Bric::Util::Trans::Mail->new($init)

Instantiates a Bric::Util::Trans::Mail object. An anonymous of initial values may be
passed. The supported intial value keys are:

=over 4

=item *

smtp - String with the DNS name of the SMTP server. Defaults to value of the
SMTP_SERVER constant in Bric::Config.

=item *

from - String with sender's email address.

=item *

to - Anonymous array of email addresses to send mail to.

=item *

cc - Anonymous array of email address to Cc email to.

=item *

bcc - Anonymous array of email addresses to Bcc email to.

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
    $init->{smtp} ||= SMTP_SERVER;
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

=item my $smtp = $mail->get_smtp

Returns the DNS name of the SMTP server to which to send email.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'smtp' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $mail->set_smtp($smtp)

Sets the DNS name of the SMTP server to which to send email.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'smtp' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $from = $mail->get_from

Returns the email address the message is to be sent from.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'from' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $mail->set_from($from)

Sets the email address from which to send the email.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'from' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $to_aref = $mail->get_to

Returns an anonymous array of email address to which to send the mail.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'to' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $mail->set_to($to_aref)

Sets the list of email addresses to which to send the mail. Pass in the list as
an anonymous array.

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

=item my $cc_aref = $mail->get_cc

Returns an anonymous array of address to which to Cc the mail.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'cc' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $mail->set_cc($cc_aref)

Sets the list of email addresses to which to Cc the mail. Pass in the list as an
anonymous array.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'cc' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $bcc_aref = $mail->get_bcc

Returns an anonymous array of address to which to Bcc the mail.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'bcc' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $mail->set_bcc($bcc_aref)

Sets the list of email addresses to which to Bcc the mail. Pass in the list as
an anonymous array.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'bcc' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $sub = $mail->get_subject

Returns the subject of the mail.

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

=item $self = $mail->set_subject($sub)

Sets subject of the email.

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

=item my $msg = $mail->get_message

Returns the message (body) of the email.

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

=item $self = $mail->set_message($msg)

Sets message (body) of the email.

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

=item $self = $mail->send

=item $self = $mail->send($debug)

Sends the email to the addresses stored in to, cc, and bcc. Pass in a true value
in order to get debugging statements from Net::SMTP. This is useful to see
excactly what's happening when you send email.

B<Throws:>

=over 4

=item *

Unable to send mail.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub send {
    my ($self, $debug) = @_;
    my ($smtp, $to, $from, $cc, $bcc, $sub, $msg) =
      $self->_get(qw(smtp to from cc bcc subject message));
    eval {
	my $smtp = Net::SMTP->new($smtp, Debug => $debug || DEBUG) ||
	  die "Unable to create Net::SMTP object for '$smtp'";;
	$smtp->mail($from);
	$smtp->to(@$to, @$cc, @$bcc);
	$smtp->data;
	$smtp->datasend("From: $from\n");
	local $" = ', ';
	$smtp->datasend("To: @$to\n");
	$smtp->datasend("Cc: @$cc\n");
	$smtp->datasend("Subject: $sub\n\n");
	$smtp->datasend($msg);
	$smtp->quit;
    };
    return $self unless $@;
    die Bric::Util::Fault::Exception::DP->new({msg => "Unable to send mail: $@"});
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

=cut

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Net::SMTP(3)

=cut
