package Bric::Util::Coll::Contact;

###############################################################################

=head1 Name

Bric::Util::Coll::Contact - Interface for managing collections of contacts.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

See Bric::Util::Coll.

=head1 Description

See Bric::Util::Coll.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Biz::Contact;
use Bric::Util::DBI qw(:standard);

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Util::Coll);

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
BEGIN {}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

Inherited from Bric::Util::Coll.

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

=item Bric::Util::Coll->class_name()

Returns the name of the class of objects this collection manages.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub class_name { 'Bric::Biz::Contact' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save($obj, $map_class)

Saves the changes made to all the objects in the collection. $obj contains the
objec to which new contacts should be mapped, and $map_class holds the name of
the Bric::Util::Map subclass that does the mapping.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=back

B<Side Effects:> Uses a subclass of Bric::Util::Map internally.

B<Notes:> NONE.

=cut

sub save {
    my ($self, $obj, $pid) = @_;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));


    if (%$del_objs) {
    my $del = prepare_c(qq{
            DELETE FROM person__contact_value
            WHERE person__id = ?
                  AND contact_value__id = ?
        }, undef);
    foreach my $con (values %$del_objs) {
        $con->deactivate;
        $con->save;
        execute($del, $pid, $con->get_id);
    }
    %$del_objs = ();
    }

    foreach my $con (values %$objs) { $con->save }
    if (@$new_objs) {
    my $ins = prepare_c(qq{
            INSERT INTO person__contact_value (person__id, contact_value__id)
            VALUES (?, ?)
        }, undef);
    foreach my $con (@$new_objs) {
        $con->save;
        execute($ins, $pid, $con->get_id);
    }
    $self->add_objs(@$new_objs);
    @$new_objs = ();
    }
    return $self;
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
L<Bric::Util::Coll|Bric::Util::Coll>

=cut
