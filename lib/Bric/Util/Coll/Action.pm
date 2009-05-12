package Bric::Util::Coll::Action;

###############################################################################

=head1 Name

Bric::Util::Coll::Action - Interface for managing collections of distribution actions.

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
use Bric::Dist::Action;

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
BEGIN {
}

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

sub class_name { 'Bric::Dist::Action' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save

=item $self = $coll->save($server_type_id)

Saves the changes made to all the objects in the collection. Pass in a
Bric::Dist::ServerType object ID to make sure all the Bric::Dist::Action objects are
associated with that server type.

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
    my ($self, $st_id) = @_;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    foreach my $a (values %$del_objs) {
        $a->del;
        $a->save;
    }
    %$del_objs = ();
    foreach my $a (values %$objs, @$new_objs) {
        $a->set_server_type_id($st_id) if defined $st_id;
        $a->save;
    }
    $self->add_objs(@$new_objs);
    @$new_objs = ();
    return $self;
}

################################################################################

=back

=head1 Private

=head2 Private Class Methods

=over 4

=item Bric::Util::Coll->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. This implementation
overrides the default, sorting the action objects by their 'ord' property.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sort_objs {
    my ($pkg, $objs) = @_;
    return ( map { $objs->{$_} }
           sort { $objs->{$a}{ord} <=> $objs->{$b}{ord} } keys %$objs);
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
L<Bric::Dist::Action|Bric::Dist::Action>

=cut
