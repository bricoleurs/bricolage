package Bric::Util::Coll::InputChannel;
###############################################################################

=head1 NAME

Bric::Util::Coll::InputChannel - Interface for managing collections of Input
Channels.

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2004-09-13 20:48:55 -0400 (Mon, 13 Sep 2004) $

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
use Bric::Biz::InputChannel;
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

sub class_name { 'Bric::Biz::InputChannel' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save($key => $id)

Saves the changes made to all the objects in the collection. The C<$key>
argument indicates the type of object with which each input channel should be
associated. The available keys are:

=over 4

=item output_channel

Indicates a L<Bric::Biz::OutputChannel|Bric::Biz::OutputChannel> association.

=item story

Indicates a
L<Bric::Biz::Asset::Business::Story|Bric::Biz::Asset::Business::Story>
association.

=item media

Indicates a
L<Bric::Biz::Asset::Business::Media|Bric::Biz::Asset::Business::Media>
association.

=back

The C<$id> argument is the ID of the object with which each input channel
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
                DELETE FROM story__input_channel
                WHERE  story_instance__id = ?
                       AND input_channel__id = ?
            }, undef);
        } elsif ($type eq 'media') {
            $del = prepare_c(qq{
                DELETE FROM media__input_channel
                WHERE  media_instance__id = ?
                       AND input_channel__id = ?
            }, undef);
        } elsif ($type eq 'output_channel') {
            $del = prepare_c(qq{
                DELETE FROM output_channel__input_channel
                WHERE  output_channel__id = ?
                       AND input_channel__id = ?
            }, undef);
        }
        execute($del, $id, $_->get_id) for values %$del_objs;
        %$del_objs = ();
    }

    if (@$new_objs) {
#        my $ins;
#        if ($type eq 'story') {
#            $ins = prepare_c(qq{
#                INSERT INTO story__input_channel
#                            (story_instance__id, input_channel__id)
#                VALUES (?, ?)
#            }, undef);
#        } elsif ($type eq 'media') {
#            $ins = prepare_c(qq{
#                INSERT INTO media__input_channel
#                            (media_instance__id, input_channel__id)
#                VALUES (?, ?)
#            }, undef);
#        } elsif ($type eq 'output_channel') {
#            $ins = prepare_c(qq{
#                INSERT INTO output_channel__input_channel
#                            (output_channel__id, input_channel__id)
#                VALUES (?, ?)
#            }, undef);
#        } else {
#            throw_dp(error => "Invalid key '$type'");
#        }
#
        foreach my $ic (@$new_objs) {
            $ic->save;
#            execute($ins, $id, $ic->get_id);
        }
        $self->add_objs(@$new_objs);
        @$new_objs = ();
    }

    return $self;
}

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=item Bric::Util::Coll::InputChannel->_sort_objs($objs_href)

Sorts a list of objects into an internally-specified order. This class sorts
input channel objects by name.

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

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

Marshall Roch <marshall@exclupen.com>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric::Util::Coll|Bric::Util::Coll>,
L<Bric::Biz::InputChannel|Bric::Biz::InputChannel>

=cut
