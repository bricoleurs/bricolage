package Bric::Util::Coll::ServerType;
###############################################################################

=head1 NAME

Bric::Util::Coll::ServerType - Interface for managing collections of servers
types.

=head1 VERSION

$Revision: 1.2 $

=cut

our $VERSION = substr(q$Revision: 1.2 $, 10, -1);

=head1 DATE

$Date: 2001-10-09 20:48:55 $

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
use Bric::Dist::ServerType;
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

sub class_name { 'Bric::Dist::ServerType' }

################################################################################

=back

=head2 Public Instance Methods

=item $self = $coll->save

=item $self = $coll->save($server_type_id)

Saves the changes made to all the objects in the collection. Pass in a
Bric::Dist::Job object ID to make sure all the Bric::Dist::ServerType objects are
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
            INSERT INTO job__server_type (job__id, server_type__id)
            VALUES (?, ?)
        });

	foreach my $r (@$new_objs) {
	    $r->save;
	    execute($ins, $job_id, $r->get_id);
	}
	$self->add_objs(@$new_objs);
	@$new_objs = ();
    }

    if (@$del_objs) {
	my $del = prepare_c(qq{
            DELETE FROM job__server_type
            WHERE  job__id = ?
                   AND server_type__id = ?
        });
	execute($del, $job_id, $_->get_id) for @$del_objs;
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
Bric::Dist::ServerType(4),

=cut
