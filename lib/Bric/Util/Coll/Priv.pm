package Bric::Util::Coll::Priv;

###############################################################################

=head1 Name

Bric::Util::Coll::Priv - Interface for managing collections of privileges.

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
use Bric::Util::Priv;

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

sub class_name { 'Bric::Util::Priv' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save

Saves the changes made to all the objects in the collection.

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

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my ($self, $usr_grp_id) = @_;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    foreach my $p (values %$del_objs) {
    $p->del;
    $p->save;
    }
    %$del_objs = ();
    foreach my $p (values %$objs, @$new_objs) {
    $p->set_usr_grp_id($usr_grp_id) if defined $usr_grp_id;
    $p->save;
    }
    $self->add_objs(@$new_objs);
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
L<Bric::Util::Priv|Bric::Util::Priv>,
L<Bric::Biz::Person::User|Bric::Biz::Person::User>,
L<Bric::Util::Grp::User|Bric::Util::Grp::User>

=cut
