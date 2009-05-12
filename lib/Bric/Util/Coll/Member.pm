package Bric::Util::Coll::Member;

###############################################################################

=head1 Name

Bric::Util::Coll::Member - Interface for managing collections of group members

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
use Bric::Util::Grp::Parts::Member;
use Bric::Config qw(:qa);

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
BEGIN { Bric::register_fields({ _del_mem => Bric::FIELD_NONE }) }

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $coll = Bric::Util::Coll::Member->new($params)

Instanticates a new collection. See L<Bric::Util::Coll|Bric::Util::Coll> for a
complete description.

=cut

sub new {
    my $self = shift->SUPER::new(@_);
    $self->_set(['_del_mem'], [[]]);
}

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

=over 4

=item Bric::Util::Coll->class_name()

Returns the name of the class of objects this collection manages.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub class_name { 'Bric::Util::Grp::Parts::Member' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->del_mem_obj($obj, $mem)

Deletes a member from the collection. This method should only be called
internally by Bric::Util::Grp when it detects that the group object contains
members that are only one particular class of object. That is, for groups that
cannot contain different classes of objects. The collections are build by the
Bric::Util::Grp::Parts::Member class' C<href()> method, which uses the object
IDs for the keys when only one type of object is managed, and the member ID
otherwise. We have to add this special method in order to manage those
situations in which only one type of object is managed, so that the member to
be deleted from the collection is stored under the ID of its associated
object, rather than its own ID. This allows C<get_objs()> to do the right
thing and exclude deleted objects, while at the same time allowing C<save()>
to get access to the actual member objects that need deleting.

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

sub del_mem_obj {
    my ($self, $obj, $mem) = @_;
    # Just let the parent class handle it if it can.
    return $self->del_objs($obj) if QA_MODE or $self->is_populated;

    # Otherwise, handle it ourselves.
    my ($del, $del_mem) = $self->_get(qw(del_obj _del_mem));
    my $oid = $obj->get_id;

    # Store it under the object ID so that get_objs() can avoid it. This is
    # because Bric::Util::Grp::Parts::Member's href() method uses the object
    # IDs for keys when there is only one class of object being managed --
    # that is, when this method is called by Bric::Util::Grp. But either way,
    # the object that is stored in the member hash always needs to be the
    # member object itself.
    $del->{$oid} = $obj;
    push @$del_mem, $mem;
}

=item $self = $coll->save

=item $self = $coll->save($server_type_id)

Saves the changes made to all the objects in the collection. Pass in a
Bric::Dist::ServerType object ID to make sure all the Bric::Biz::OutputChannel
objects are properly associated with that server type.

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
    my ($self, $grp) = @_;
    my ($objs, $new_objs, $del_objs, $del_mem) =
      $self->_get(qw(objs new_obj del_obj _del_mem));
    my $obj_class_id = $grp->get_object_class_id;

    # Save the deleted objects.
    foreach my $mem (! QA_MODE && $obj_class_id ?
                     @$del_mem : values %$del_objs) {
        if ($mem->get_id) {
            $mem->remove;
            $mem->save;
        }
    }
    %$del_objs = ();
    @$del_mem = ();

    # Save the existing and new objects.
    foreach my $mem (values %$objs, @$new_objs) {
    $mem->save;
    }

    # Add the new objects to the main list of objects.
    if ($obj_class_id) {
        # Reference off the underlying object IDs.
        $objs->{$_->get_obj_id} = $_ for @$new_objs;
    } else {
        # Use the default behavior of using the member object IDs.
        $self->add_objs(@$new_objs);
    }

    # Reset the new_objs array and return.
    @$new_objs = ();
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
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Util::Grp|Bric::Util::Grp>,
L<Bric::Util::Grp::Parts::Member|Bric::Util::Grp::Parts::Member>


=cut
