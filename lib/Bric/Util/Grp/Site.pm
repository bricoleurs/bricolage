package Bric::Util::Grp::Site;

=head1 Name

Bric::Util::Grp::Site - Interface to Bric::Biz::Site Groups

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

See Bric::Util::Grp

=head1 Description

See Bric::Util::Grp.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
# None.

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric::Util::Grp);

##############################################################################
# Function Prototypes
##############################################################################
# None.

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;
use constant OBJ_CLASS_ID => 75;
use constant CLASS_ID => 76;

##############################################################################
# Fields
##############################################################################
# Public Class Fields

##############################################################################
# Private Class Fields
my ($CLASS, $MEM_CLASS);

##############################################################################

##############################################################################
# Instance Fields
BEGIN { Bric::register_fields() }

##############################################################################
# Class Methods
##############################################################################

=head1 Interface

=head2 Constructors

Inherited from Bric::Util::Grp.

=head2 Class Methods

=head3 get_supported_classes

  my $supported_classes = Bric::Util::Grp::Site->get_supported_classes;

This will return an anonymous hash of the supported classes in the group as
keys with the short name as a value. The short name is used to construct the
member table names and the foreign key in the table.

=cut

sub get_supported_classes { { 'Bric::Biz::Site' => 'site' } }

##############################################################################

=head3 get_list_classes

  my @list_classes = Bric::Util::Grp::Site->get_list_classes

Returns a list or anonymous array of the supported classes in the group that
can have their C<list()> methods called in succession to assemble a list of
member objects. This data varies from that stored in the keys in the hash
reference returned by C<get_supported_classes> in that some classes' C<list()>
methods may inherit from others, and we don't want the same C<list()> method
executed more than once.

=cut

sub get_list_classes { ('Bric::Biz::Site') }

##############################################################################

=head3 get_object_class_id

 my $class_id = Bric::Util::Grp::Site->get_object_class_id;

If this method returns an ID, then all objects returne as members of this
class of group will be instances of the class represented by that ID. If no ID
is returned, then member objects will not be forced into the single class.

=cut

sub get_object_class_id { OBJ_CLASS_ID }

##############################################################################

=head3 get_class_id

  my $class_id = Bric::Util::Grp::Site->get_class_id;

Returns the Bric::Util::Class object ID representing this class.

=cut

sub get_class_id { CLASS_ID }

##############################################################################

=head3 get_secret

  my $secret = Bric::Util::Grp::Site->get_secret;

Returns false, because groups of this class are not secret groups, but groups
that can be used by users.

=cut

sub get_secret { 0 }

##############################################################################

=head3 my_class

  my $class = Bric::Util::Grp::Site->my_class;

Returns the Bric::Util::Class object representing this class.

=cut

sub my_class {
    $CLASS ||= Bric::Util::Class->lookup({ id => CLASS_ID });
    return $CLASS;
}

##############################################################################

=head3 member_class

  my $class = Bric::Util::Grp::Site->member_class;

Returns the Bric::Util::Class object representing the members of this group.

=cut

sub member_class {
    $MEM_CLASS ||= Bric::Util::Class->lookup({ id => OBJ_CLASS_ID });
    return $MEM_CLASS;
}

##############################################################################

=head2 Instance Methods

Inherited from Bric::Util::Grp.

=cut

1;
__END__

=head1 Author

David Wheeler <david@kineticode.com>

=head1 See Also

=over 4

=item L<Bric::Util::Grp|Bric::Util::Grp>

=item L<Bric::Biz::Site|Bric::Biz::Site>

=back

=cut
