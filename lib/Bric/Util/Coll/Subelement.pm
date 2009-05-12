package Bric::Util::Coll::Subelement;

###############################################################################

=head1 Name

Bric::Util::Coll::Subelement - Interface for managing collections of
Bric::Biz::ElementType::Subelement objects.

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
#require Bric::Biz::ElementType::Subelement;

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
BEGIN { }

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

sub class_name { 'Bric::Biz::ElementType::Subelement' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save($parent_id)

Saves the changes made to all the objects in the collection

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my ($self, $id) = @_;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    # Save the deleted objects.
    foreach my $sube (values %$del_objs) {
        if ($sube->get_id) {
            $sube->remove;
            $sube->save;
        }
    }
    %$del_objs = ();

    # Save the existing objects.
    foreach my $sube (values %$objs) {
    $sube->save;
    }

    # Save the new objects.
    foreach my $sube (@$new_objs) {
        $sube->set_parent_id($id);
        $sube->save;
    }

    # Add the new objects to the main list of objects.
    $self->add_objs(@$new_objs);

    # Reset the new_objs array and return.
    @$new_objs = ();
    return $self;
}

=back

=head1 Private

=head2 Private Class Methods

=over 4

=item Bric::Util::Coll::Subelement->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. This class sorts
subelement objects by their child's name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sort_objs {
    my ($pkg, $objs) = @_;
    return map  {          $_->[1]          }
           sort {    $a->[0] <=> $b->[0]    }
           map  {  [ $_->get_place => $_ ]  }
           values %$objs;
}

=back

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

Christian Muise <christian.muise@gmail.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Biz::ElementType::Subelement|Bric::Biz::ElementType::Subelement>

=cut
