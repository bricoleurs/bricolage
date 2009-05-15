package Bric::Util::Grp::Person;

=head1 Name

Bric::Util::Grp::Person - Interface to Bric::Biz::Person Groups

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

See Bric::Util::Grp

=head1 Description

See Bric::Util::Grp.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::Grp::ContribType;

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Util::Grp);

################################################################################
# Function Prototypes
################################################################################


################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant INSTANCE_GROUP_ID => 24;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::ContribType';
use constant CLASS_ID => 9;
use constant OBJECT_CLASS_ID => 1;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my ($class, $mem_class);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields();
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

Inherited from Bric::Util::Grp.

=cut

sub new {
    my ($class, $init) = @_;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    $class->SUPER::new($init);
}

=head2 Destructors

=over 4

=item $attr->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over

=item $supported_classes = Bric::Util::Grp->get_supported_classes()

This will return an anonymous hash of the supported classes in the group as keys
with the short name as a value. The short name is used to construct the member
table names and the foreign key in the table.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_supported_classes { { 'Bric::Biz::Person' => 'person',
                  'Bric::Biz::Person::User' => 'person' } }

##############################################################################

=item my @list_classes = Bric::Util::Grp::Person->get_list_classes

Returns a list or anonymous array of the supported classes in the group that
can have their C<list()> methods called in succession to assemble a list of
member objects. This data varies from that stored in the keys in the hash
reference returned by C<get_supported_classes> in that some classes' C<list()>
methods may inherit from others, and we don't want the same C<list()> method
executed more than once.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_list_classes { ('Bric::Biz::Person') }

################################################################################

=item $class_id = Bric::Util::Grp::Person->get_class_id()

This will return the class ID that this group is associated with.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_class_id { CLASS_ID }

################################################################################

=item $class_id = Bric::Util::Grp::Person->get_object_class_id()

Forces all Objects to be considered as this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_object_class_id { OBJECT_CLASS_ID }

################################################################################

=item my $secret = Bric::Util::Grp::Person->get_secret()

Returns true, because this is a secret type of group, cannot be directly used by
users.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_secret { Bric::Util::Grp::SECRET_GRP }

################################################################################

=item my $class = Bric::Util::Grp::Person->my_class()

Returns a Bric::Util::Class object describing this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub my_class {
    $class ||= Bric::Util::Class->lookup({ id => CLASS_ID });
    return $class;
}

################################################################################

=item my $class = Bric::Util::Grp::Person->member_class()

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => OBJECT_CLASS_ID });
    return $mem_class;
}

################################################################################

=back

=head2 Public Instance Methods

Inherited from Bric::Util::Grp.

=cut

sub save {
    my $self = shift;
    my $id = $self->get_id;
    $self->SUPER::save(@_);
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE)
      unless defined $id;
    return $self;
}

=head1 Private

=head2 Private Constructors

NONE.

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
L<Bric::Biz::Person|Bric::Biz::Person>, 
L<Bric::Util::Grp|Bric::Util::Grp>

=cut

