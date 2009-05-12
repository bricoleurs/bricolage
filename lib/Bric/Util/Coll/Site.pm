package Bric::Util::Coll::Site;

###############################################################################

=head1 Name

Bric::Util::Coll::Site - Interface for managing collections of
Bric::Biz::Site objects.

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

use Bric::Util::DBI qw(:standard col_aref);

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

sub class_name { 'Bric::Biz::Site' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save($element_type_id);

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
    my ($self, $element_type_id, $oc_map) = @_;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    # Save the deleted objects.
    foreach my $site (values %$del_objs) {
        if ($site->get_id) {
            my $upd = prepare_c( qq {
                UPDATE element_type__site
                SET    active = '0'
                WHERE  element_type__id = ? AND
                       site__id    = ?
            }, undef, DEBUG);
            execute($upd, $element_type_id, $site->get_id)
        }
    }
    %$del_objs = ();

    foreach my $site (@$new_objs) {
        my $site_id = $site->get_id;
        #insert into element_type__site mapping
        my $sel = prepare_c( qq {
            SELECT 1
            FROM   element_type__site
            WHERE  element_type__id = ? AND
                   site__id    = ?
        }, undef, DEBUG);
        my $state = col_aref($sel, $element_type_id, $site_id);
        if (@$state) {
            my $upd = prepare_c( qq {
                UPDATE element_type__site
                SET    active = '1',
                       primary_oc__id = ?
                WHERE  element_type__id = ? AND
                       site__id    = ?
            }, undef, DEBUG);
            execute($upd, delete $oc_map->{$site_id}, $element_type_id, $site_id);
        } else {
            my $ins = prepare_c(qq {
                INSERT INTO element_type__site (element_type__id, site__id, primary_oc__id)
                VALUES (?, ?, ?)
            }, undef, DEBUG);
            execute($ins, $element_type_id, $site_id, delete $oc_map->{$site_id});
        }
    }

    # Save the existing and new objects.
    foreach my $site (values %$objs, @$new_objs) {
#    $site->save;
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
    return sort { lc $a->get_name cmp lc $b->get_name }
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

Arthur Bergman <sky@nanisky.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Biz::ElementType|Bric::Biz::ElementType>
L<Bric::Biz::Site|Bric::Biz::Site>

=cut
