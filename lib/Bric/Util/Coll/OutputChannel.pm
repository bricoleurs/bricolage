package Bric::Util::Coll::OutputChannel;

###############################################################################

=head1 Name

Bric::Util::Coll::OutputChannel - Interface for managing collections of Output
Channels.

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
use Bric::Biz::OutputChannel;
use Bric::Util::DBI qw(:standard);
use Bric::Util::Fault qw(throw_dp);

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

=item $self = $coll->save($key => $id)

Saves the changes made to all the objects in the collection. The C<$key>
argument indicates the type of object with which each output channel should be
associated. The available keys are:

=over 4

=item server_type

Indicates a L<Bric::Dist::ServerType|Bric::Dist::ServerType> association.

=item story

Indicates a
L<Bric::Biz::Asset::Business::Story|Bric::Biz::Asset::Business::Story>
association.

=item media

Indicates a
L<Bric::Biz::Asset::Business::Media|Bric::Biz::Asset::Business::Media>
association.

=back

The C<$id> argument is the ID of the object with which each output channel
should be associated.

B<Throws:>

=over 4

=item *

Invalid key.

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
    my ($self, $type, $id) = @_;
    my ($new_objs, $del_objs) = $self->_get(qw(new_obj del_obj));

    if (%$del_objs) {
        my $del;
        if ($type eq 'story') {
            $del = prepare_c(qq{
                DELETE FROM story__output_channel
                WHERE  story_instance__id = ?
                       AND output_channel__id = ?
            }, undef);
        } elsif ($type eq 'media') {
            $del = prepare_c(qq{
                DELETE FROM media__output_channel
                WHERE  media_instance__id = ?
                       AND output_channel__id = ?
            }, undef);
        } elsif ($type eq 'server_type') {
            $del = prepare_c(qq{
                DELETE FROM server_type__output_channel
                WHERE  server_type__id = ?
                       AND output_channel__id = ?
            }, undef);
        }
        execute($del, $id, $_->get_id) for values %$del_objs;
        %$del_objs = ();
    }

    if (@$new_objs) {
        my $ins;
        if ($type eq 'story') {
            $ins = prepare_c(qq{
                INSERT INTO story__output_channel
                            (story_instance__id, output_channel__id)
                VALUES (?, ?)
            }, undef);
        } elsif ($type eq 'media') {
            $ins = prepare_c(qq{
                INSERT INTO media__output_channel
                            (media_instance__id, output_channel__id)
                VALUES (?, ?)
            }, undef);
        } elsif ($type eq 'server_type') {
            $ins = prepare_c(qq{
                INSERT INTO server_type__output_channel
                            (server_type__id, output_channel__id)
                VALUES (?, ?)
            }, undef);
        } else {
            throw_dp(error => "Invalid key '$type'");
        }

        foreach my $oc (@$new_objs) {
            $oc->save;
            execute($ins, $id, $oc->get_id);
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

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Biz::OutputChannel|Bric::Biz::OutputChannel>

=cut
