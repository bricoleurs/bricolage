package Bric::Util::Coll::OutputChannel;
###############################################################################

=head1 NAME

Bric::Util::Coll::OutputChannel - Interface for managing collections of Output
Channels.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = substr(q$Revision: 1.1 $, 10, -1);

=head1 DATE

$Date: 2001-09-06 21:55:43 $

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
use Bric::Biz::OutputChannel;
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

sub class_name { 'Bric::Biz::OutputChannel' }

################################################################################

=back

=head2 Public Instance Methods

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
    my ($self, $st_id) = @_;
    my ($new_objs, $del_objs) = $self->_get(qw(new_obj del_obj));

    if (@$new_objs) {
	my $ins = prepare_c(qq{
            INSERT INTO server_type__output_channel (server_type__id, output_channel__id)
            VALUES (?, ?)
        });

	foreach my $oc (@$new_objs) {
	    $oc->save;
	    execute($ins, $st_id, $oc->get_id);
	}
	$self->add_objs(@$new_objs);
	@$new_objs = ();
    }

    if (@$del_objs) {
	my $del = prepare_c(qq{
            DELETE FROM server_type__output_channel
            WHERE  server_type__id = ?
                   AND output_channel__id = ?
        });
	execute($del, $st_id, $_->get_id) for @$del_objs;
	@$del_objs = ();
    }
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

perl(1),
Bric (2),
Bric::Util::Coll(3),
Bric::Biz::OutputChannel(4),

=head1 REVISION HISTORY

$Log: OutputChannel.pm,v $
Revision 1.1  2001-09-06 21:55:43  wheeler
Initial revision

=cut
