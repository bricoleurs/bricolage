package Bric::Util::Coll::Instance;
###############################################################################

=head1 NAME

Bric::Util::Coll::Instance - Interface for managing collections of
Bric::Biz::Asset::Business::Parts::Instance objects.

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
use Bric::Util::DBI qw(:standard);
use Bric::Util::Fault qw(throw_dp throw_gen);

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

sub class_name { 'Bric::Biz::Asset::Business::Parts::Instance' }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $self = $coll->save

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
    my ($self, $type, $id) = @_;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));

    if (%$del_objs) {
        my $del;
        if ($type eq 'story') {
            $del = prepare_c(qq{
                DELETE FROM story_instance__story_version
                WHERE  story_version__id = ?
                       AND story_instance__Id = ?
            }, undef);
        } elsif ($type eq 'media') {
            $del = prepare_c(qq{
                DELETE FROM media_instance__media_version
                WHERE  media_version__id = ?
                       AND media_instance__id = ?
            }, undef);
        }
        execute($del, $id, $_->get_id) for values %$del_objs;
        %$del_objs = ();
    }
    
    # Save the existing objects.
    foreach my $inst (values %$objs) {
        $inst->save;
    }

    if (@$new_objs) {
        my $ins;
        if ($type eq 'story') {
            $ins = prepare_c(qq{
                INSERT INTO story_instance__story_version
                            (story_version__id, story_instance__id)
                VALUES (?, ?)
            }, undef);
        } elsif ($type eq 'media') {
            $ins = prepare_c(qq{
                INSERT INTO media_instance__media_version
                            (media_version__id, media_instance__id)
                VALUES (?, ?)
            }, undef);
        } else {
            throw_dp(error => "Invalid key '$type'");
        }

        foreach my $inst (@$new_objs) {
            $inst->save;
            execute($ins, $id, $inst->get_id);
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
objects by name.

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

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric::Util::Coll|Bric::Util::Coll>

=cut
