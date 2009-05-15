package Bric::Util::Coll::OCElement;

###############################################################################

=head1 Name

Bric::Util::Coll::OCElement - Interface for managing collections of
Bric::Biz::OutputChannel::Element objects.

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

sub class_name { 'Bric::Biz::OutputChannel::Element' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save

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
    foreach my $oce (values %$del_objs) {
        if ($oce->get_id) {
            $oce->remove;
            $oce->save;
        }
    }
    %$del_objs = ();

    # Save the existing objects.
    foreach my $oce (values %$objs) {
        $oce->save;
    }

    # Save the new objects.
    foreach my $oce (@$new_objs) {
        $oce->set_element_id($id);
        $oce->save;
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

=item Bric::Util::Coll::OutputChannel->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. This class sorts
output channel objects by name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sort_objs {
    my ($pkg, $objs) = @_;
    return map  {          $_->[1]          }
           sort {    $a->[0] cmp $b->[0]    }
           map  { [ lc $_->get_name => $_ ] }
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

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Biz::OutputChannel::Element|Bric::Biz::OutputChannel::Element>

=cut
