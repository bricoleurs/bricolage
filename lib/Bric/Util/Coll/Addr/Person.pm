package Bric::Util::Coll::Addr::Person;
###############################################################################

=head1 NAME

Bric::Util::Coll::Addr - Interface for managing collections of contacts.

=head1 VERSION

$Revision: 1.1.1.1.2.1 $

=cut

our $VERSION = substr(q$Revision: 1.1.1.1.2.1 $, 10, -1);

=head1 DATE

$Date: 2001-10-09 21:51:08 $

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
use Bric::Biz::Org::Parts::Addr;
use Bric::Util::DBI qw(:standard);

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Util::Coll::Addr);

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

sub class_name { 'Bric::Biz::Org::Parts::Addr' }

################################################################################

=back

=head2 Public Instance Methods

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
    my ($self, $oid) = @_;
    my ($objs, $new_objs, $del_objs) = $self->_get(qw(objs new_obj del_obj));
    my $del = prepare_c(qq{
        DELETE FROM person_org__addr
        WHERE  person_org__id = ?
               AND addr__id = ?
    });

    my $ins = prepare_c(qq{
        INSERT INTO person_org__addr (person_org__id, addr__id)
        VALUES (?, ?)
    });

    foreach my $a (@$del_objs) { execute($del, $oid, $a->get_id) }
    @$del_objs = ();

    foreach my $a (values %$objs) { $a->save }
    foreach my $a (@$new_objs) {
	$a->save;
	my $id = $a->get_id;
	execute($ins, $oid, $id);
    }
    $self->add_objs(@$new_objs);
    @$new_objs = ();
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

=cut
