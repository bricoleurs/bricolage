package Bric::Util::Coll::Keyword;

###############################################################################

=head1 Name

Bric::Util::Coll::Keyword - Interface for managing collections of
Bric::Biz::Keyword objects.

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

sub class_name { 'Bric::Biz::Keyword' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save($object);

Saves the changes made to all the keywors in the collection.

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
    my ($self, $obj) = @_;
    my $key = $obj->key_name;
    my $oid = $obj->get_id;

    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    # Save the deleted objects.
    foreach my $keyword (values %$del_objs) {
        if ($keyword->get_id) {
            my $upd = prepare_c(qq{
                DELETE FROM $key\_keyword
                WHERE  $key\_id = ?
                       AND keyword_id = ?
            }, undef, DEBUG);
            execute($upd, $oid, $keyword->get_id)
        }
    }
    %$del_objs = ();

    if (@$new_objs) {
        # Prepare a SELECT statement to see if the relationship already
        # exists.
        my $sel = prepare_c(qq{
            SELECT 1
            FROM   $key\_keyword
            WHERE  $key\_id = ?
                   AND keyword_id = ?
        }, undef, DEBUG);

        # Prepare an INSERT statement to create the relationship.
        my $ins = prepare_c(qq{
            INSERT INTO $key\_keyword ($key\_id, keyword_id)
            VALUES (?, ?)
        }, undef, DEBUG);

        foreach my $keyword (@$new_objs) {
            $keyword->save;
            my $kid = $keyword->get_id;

            # Skip to the next keyword if this keyword is already
            # associated with the object.
            my $state = col_aref($sel, $oid, $kid);
            next if @$state;

            # Otherwise, create teh relationship.
            execute($ins, $oid, $kid);
        }
    }

    # Save the existing and new objects.
    foreach my $keyword (values %$objs) {
    $keyword->save;
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

=item Bric::Util::Coll::Keyword->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. This class sorts
keywrd objects by sort name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sort_objs {
    my ($pkg, $objs) = @_;
    return sort { lc $a->get_sort_name cmp lc $b->get_sort_name }
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
L<Bric::Biz::Keyword|Bric::Biz::Keyword>

=cut
