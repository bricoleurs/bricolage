package Bric::Util::Grp::Media;

=head1 NAME

Bric::Util::Grp::Media - Interface to Bric::Biz::Asset::Business::Media Groups.

=head1 VERSION

$Revision: 1.3 $

=cut

# Grab the Version Number.
our $VERSION = substr(q$Revision: 1.3 $, 10, -1);

=head1 DATE

$Date: 2001-10-11 00:34:55 $

=head1 SYNOPSIS

See Bric::Util::Grp

=head1 DESCRIPTION

See Bric::Util::Grp.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences

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
use constant CLASS_ID => 66;

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

=head1 INTERFACE

=head2 Constructors

Inherited from Bric::Util::Grp.

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

=item $supported_classes = Bric::Util::Grp::Media->get_supported_classes()

This will return an anonymous hash of the supported classes in the group as keys
with the short name as a value. The short name is used to construct the member
table names and the foreign key in the table.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_supported_classes {
    { 'Bric::Biz::Asset::Business::Media' => 'media',
      'Bric::Biz::Asset::Business::Media::Video' => 'media',
      'Bric::Biz::Asset::Business::Media::Audio' => 'media',
      'Bric::Biz::Asset::Business::Media::Image' => 'media',
    }
}

################################################################################

=item $class_id = Bric::Util::Grp::Media->get_class_id()

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

sub get_object_class_id { 46 }

################################################################################

=item my $secret = Bric::Util::Grp::Media->get_secret()

Returns false, because this is not a secret type of group, but one that can be
used by users.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_secret { 0 }

################################################################################

=item my $class = Bric::Util::Grp::Media->my_class()

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

=item my $class = Bric::Util::Grp::Media->member_class()

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => 46 });
    return $mem_class;
}

################################################################################

=back

=head2 Public Instance Methods

Inherited from Bric::Util::Grp.

=head1 PRIVATE

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

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Bric::Biz::Asset::Business::Media(3)
Bric::Util::Grp(4)

=cut

