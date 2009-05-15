package Bric::Util::Alerted::Parts::Sent;

=head1 Name

Bric::Util::Alerted::Parts::Sent - Interface to objects describing how and when
alerts were sent.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Alerted::Parts::Sent;
  my $sent = Bric::Util::Alerted::Parts::Sent->new($init);

  print "Method:  ", $meth->get_type, "\n";
  print "Contact: ", $meth->get_value, "\n";
  print "Time:    ", $meth->get_sent_time("%D %T"), "\n\n";

=head1 Description

Used internally by Bric::Util::Alerted. Do not use.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::Time qw(:all);

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
             type =>  Bric::FIELD_READ,
             value => Bric::FIELD_READ,
             sent_time => Bric::FIELD_READ

             # Private Fields
            });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $sent = Bric::Util::Alerted::Parts::Sent->new($init)

Creates a new Bric::Util::Alerted::Parts::Sent object. Pass in the following
keys as arguments:

=over 4

=item *

type

=item *

value

=item *

sent_time

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

=head2 Public Instance Methods

=over 4

=item my $id = $sent->get_type

Returns the Contact type string identifying how the alert was sent.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'type' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $value = $sent->get_value

Returns the value of the contact (the address, number, or ID) to which the alert
was sent.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'value' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $uid = $alerted->get_sent_time($format)

Returns the time at which the alert was sent to this contact value. Pass in a
strftime format string to get the time back in that format. If no format is
passed, it will default to ISO 8601 format.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_sent_time { local_date($_[0]->_get('sent_time'), $_[1]) }

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
L<Bric::Util::Alert|Bric::Util::Alert>, 
L<Bric::Util::Alerted|Bric::Util::Alerted>

=cut

