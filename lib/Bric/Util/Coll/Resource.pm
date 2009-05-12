package Bric::Util::Coll::Resource;

###############################################################################

=head1 Name

Bric::Util::Coll::Resource - Interface for managing collections of resources.

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
use Bric::Dist::Resource;
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

sub class_name { 'Bric::Dist::Resource' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save

=item $self = $coll->save($server_type_id)

Saves the changes made to all the objects in the collection. Pass in a
Bric::Util::Job object ID to make sure all the Bric::Dist::Resource objects are
associated with that job.

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
    my ($self, $job_id) = @_;
    my ($new_objs, $del_objs) = $self->_get(qw(new_obj del_obj));

    if (@$new_objs) {
        my $ins = prepare_c(qq{
            INSERT INTO job__resource (job__id, resource__id)
            VALUES (?, ?)
        }, undef);

        foreach my $res (@$new_objs) {
            $res->save;
            execute($ins, $job_id, $res->get_id);
        }
        $self->add_objs(@$new_objs);
        @$new_objs = ();
    }

    if (%$del_objs) {
        my $del = prepare_c(qq{
            DELETE FROM job__resource
            WHERE  job__id = ?
                   AND resource__id = ?
        }, undef);
        execute($del, $job_id, $_->get_id) for values %$del_objs;
        %$del_objs = ();
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
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Dist::Resource|Bric::Dist::Resource>

=cut
