package Bric::Util::Trans::Mail;

###############################################################################

=head1 Name

Bric::Util::Trans::Mail - Utility class for sending email.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Trans::Mail;
  my $m = Bric::Util::Trans::Mail->new(
    { smtp    => 'mail.sourceforge.net',
      from    => 'bricolage-devel@lists.sourceforge.net',
      to      => ['joe@example.com'],
      subject => 'Greetings',
      message => 'This is a message sent via Bric::Util::Trans::Mail'
     });
  $m->send;

=head1 Description

This class provides a thin abstraction to the MIME::Entity and Net::SMTP
modules. Use it to send email from within Bricolage applications. Or from
within other applications. We don't care.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Net::SMTP;
use MIME::Entity;
use Bric::Util::Fault qw(throw_dp throw_gen);
use Bric::Config qw(:email);
use Bric::Util::Time qw(strfdate);

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
my $mailer = "Bricolage " . Bric->VERSION;

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields
        ({
          # Public Fields
          smtp         => Bric::FIELD_RDWR,
          from         => Bric::FIELD_RDWR,
          subject      => Bric::FIELD_RDWR,
          message      => Bric::FIELD_RDWR,
          to           => Bric::FIELD_RDWR,
          cc           => Bric::FIELD_RDWR,
          bcc          => Bric::FIELD_RDWR,
          content_type => Bric::FIELD_RDWR,
          resources    => Bric::FIELD_RDWR,

          # Private Fields
          _to_recip    => Bric::FIELD_NONE,
          _cc_recip    => Bric::FIELD_NONE,
          _bcc_recip   => Bric::FIELD_NONE,
          _from_recip  => Bric::FIELD_NONE,
         });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

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

content_type - The content type of the email. Defaults to "text/plain" if
unspecified.

=item *

subject - The subject of the message.

=item *

message - The message to be sent.

=item *

resources - Anonymous array of Bric::Dist::Resource objects representing files
to send as attachments.

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
    $self->set_to(delete $init->{to}) if $init->{to};
    $self->set_cc(delete $init->{cc}) if $init->{cc};
    $self->set_bcc(delete $init->{bcc}) if $init->{bcc};
    $init->{smtp} ||= SMTP_SERVER;
    $init->{content_type} ||= 'text/plain';
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

B<Side Effects:> Parses out the one or more email addresses in each item in
the array reference to use as the recipients. The string in each item will be
used literally in the "From" header of the outgoing email. To change the
recipients, pass in a new array reference rather than edit the existing array
reference.

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

B<Side Effects:> Parses out the one or more email addresses in each item in
the array reference to use as the recipients. The string in each item will be
used literally in the "Cc" header of the outgoing email. To change the
recipients, pass in a new array reference rather than edit the existing array
reference.

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

B<Side Effects:> Parses out the one or more email addresses in each item in
the array reference to use as the recipients. To change the recipients, pass
in a new array reference rather than edit the existing array reference.

B<Notes:> NONE.

=item my $sub = $mail->get_content_type

Returns the content type of the mail. Defaults to "text/plain" if unspecified.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'content_type' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $mail->set_content_type($sub)

Sets content type of the email.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'content_type' required.

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

=item my $resources_aref = $mail->get_resources

Returns an anonymous array of Bric::Dist::Resource objects representing files
to send as attachments. Returns C<undef> if no resources are to be attached.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'resources' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $mail->set_resources($resources_aref)

Sets the anonymous array of Bric::Dist::Resource objects representing files to
send as attachments.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'resources' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

foreach my $attr (qw(to cc bcc)) {
    no strict 'refs';
    *{"get_$attr"} = sub { shift->_get($attr) };
    *{"set_$attr"} = sub {
        my ($self, $addrs) = @_;
        $self->_set( [$attr, "_$attr\_recip"],
                     [ $addrs,
                       [map { $_->address }
                        map { Mail::Address->parse($_) } @$addrs ] ] );
    };
}

sub get_from { shift->_get('from') }
sub set_from {
    my ($self, $from) = @_;
    my ($fromre) = Mail::Address->parse($from);
    $fromre = $fromre->address if $fromre;
    $self->_set([ qw(from _from_recip) ], [ $from, $fromre ]);
}

##############################################################################

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
    my ($smtp, $to, $from, $fromre, $cc, $bcc, $ct, $sub, $msg, $resources) =
      $self->_get(qw(smtp to from _from_recip cc bcc content_type subject
                     message resources));

    # Clean up message for CRLF of quoted-printable
    $msg =~ s/\r\n|\r/\n/gs;

    # Assemble the arguments we'll need for MIME::Entity.
    my @args = ( 'X-Mailer' => $mailer,
                 ($from ? (From => $from) : ()),
                 ($to ? (To => join(', ', @$to)) : ()),
                 ($cc ? (Cc => join(', ', @$cc)) : ()),
                 Date => strfdate(time, "%a, %e %b %Y %H:%M:%S %z", 1),
                 Subject    => $sub );
    eval {
        my $top;
        if ($resources && @$resources) {
            # There are files to attach. Use multipart/mixed.
            $top = MIME::Entity->build( @args,
                                        Type => "multipart/mixed" );
            # Add the message.
            $top->attach( Data     => $msg,
                          Type     => $ct,
                          Encoding => "quoted-printable");
            # Attach each file.
            foreach my $res (@$resources) {
                $top->attach( Path => $res->get_tmp_path || $res->get_path,
                              Type => $res->get_media_type);
            }
        } else {
            # Just make it a simple message using quoted-printable.
            $top = MIME::Entity->build( @args,
                                        Type     => $ct,
                                        Encoding => "quoted-printable",
                                        Data     => $msg );
        }

        # Package it up and send it out!
    my $smtp = Net::SMTP->new($smtp, Debug => $debug || DEBUG)
      or throw_gen(error => "Unable to create Net::SMTP object for '$smtp'");
    $smtp->mail($fromre);
        # Send it to everyone.
    $smtp->to( map { $_ ? @$_ : () }
                   $self->_get(qw(_to_recip _cc_recip _bcc_recip)) );
    $smtp->data;
        # Let MIME::Entity do the fun stuff.
        $smtp->datasend($top->as_string);
    $smtp->quit;
    };

    # Return or die.
    return $self unless $@;
    throw_dp "Unable to send mail: $@";
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
L<Bric::Dist::Resource|Bric::Dist::Resource>,
L<Bric::Dist::Action::Email|Bric::Dist::Action::Email>,
L<Net::SMTP|Net::SMTP>,
L<MIME::Entity|MIME::Entity>

=cut
