package Bric::Util::Coll::Member;
###############################################################################

=head1 NAME

Bric::Util::Coll::Member - Interface for managing collections of group members

=head1 VERSION

$Revision: 1.5 $

=cut

our $VERSION = (qw$Revision: 1.5 $ )[-1];

=head1 DATE

$Date: 2003-01-08 23:55:39 $

=head1 SYNOPSIS

See Bric::Util::Coll.

=head1 DESCRIPTION

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

=head1 INTERFACE

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

sub class_name { 'Bric::Util::Grp::Parts::Member' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

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
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    # Save the deleted objects.
    foreach my $mem (values %$del_objs) {
        if ($mem->get_id) {
            $mem->remove;
            $mem->save;
        }
    }
    %$del_objs = ();

    # Save the existing and new objects.
    foreach my $mem (values %$objs, @$new_objs) {
	$mem->save;
    }

    # Add the new objects to the main list of objects.
    if ($grp->get_object_class_id) {
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

L<Bric|Bric>,
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Util::Grp|Bric::Util::Grp>,
L<Bric::Util::Grp::Parts::Member|Bric::Util::Grp::Parts::Member>


=cut
