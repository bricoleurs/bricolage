package Bric::Util::Coll::OCInclude;

###############################################################################

=head1 Name

Bric::Util::Coll::OCInclude - Interface for managing Output Channels includes.

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
#use Bric::Biz::OutputChannel;
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

sub class_name { 'Bric::Biz::OutputChannel' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save

=item $self = $coll->save($oc_id)

Saves the list of included Output Channels, associated them with their parent.
Pass in the parent ID to make sure all the Bric::Biz::OutputChannel objects are
properly associated with the parent.

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
    my ($self, $oc_id) = @_;
    my ($new_objs, $del_objs) = $self->_get(qw(new_obj del_obj));

    if (%$del_objs) {
    my $del = prepare_c(qq{
            DELETE FROM output_channel_include
            WHERE  output_channel__id = ?
                   AND include_oc_id = ?
        }, undef);
    execute($del, $oc_id, $_->get_id) for values %$del_objs;
    %$del_objs = ();
    }

    if (@$new_objs) {
    my $next = next_key('output_channel_include');
        my $ins = prepare_c(qq{
            INSERT INTO output_channel_include (id, output_channel__id,
                                                include_oc_id)
            VALUES($next, ?, ?)
        }, undef);

    foreach my $new (@$new_objs) {
        execute($ins, $oc_id, $new->get_id);
        $new->_set(['_include_id'], [last_key('output_channel_include')]);
    }
    $self->add_objs(@$new_objs);
    @$new_objs = ();
    }
    return $self;
}

=back

=head1 Private

=head2 Private Class Methods

=over 4

=item Bric::Util::Coll->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. This implementation
overrides the default, sorting the action objects by their '_include_id'
property, which is a private property of Output Channels.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sort_objs {
    my ($pkg, $objs) = @_;
    return ( map { $objs->{$_} }
           sort { $objs->{$a}{_include_id} <=> $objs->{$b}{_include_id} }
         keys %$objs);
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
L<Bric::Biz::OutputChannel|Bric::Biz::OutputChannel>

=cut
