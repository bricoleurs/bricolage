package Bric::Util::Priv::Parts::Const;

=head1 NAME

Bric::Util::Priv::Parts::Const - Exports Bricolage Privilege Constants

=head1 VERSION

$Revision: 1.6 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.6 $ )[-1];

=head1 DATE

$Date: 2002-01-06 04:40:37 $

=head1 SYNOPSIS

  use Bric::Util::Priv::Parts::Const qw(:all);

=head1 DESCRIPTION

Exports Privilege constants. Those constants are:

=over 4

=item *

READ

=item *

EDIT

=item *

CREATE

=item *

DENY

=back

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
use base qw(Exporter);

# You can explicitly import any of the functions in this class. The last two
# should only ever be imported by Bric::Util::Time, however.
our @EXPORT_OK = qw(READ EDIT CREATE DENY);

# But you'll generally just want to import a few standard ones or all of them
# at once.
our %EXPORT_TAGS = (all => \@EXPORT_OK);

################################################################################
# Function Prototypes
################################################################################


################################################################################
# Constants
################################################################################
use constant READ => 1;
use constant EDIT => 2;
use constant CREATE => 3;
use constant DENY => 255;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################

################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

NONE.

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

NONE.

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

L<Bric|Bric>, 
L<Bric::Util::Priv|Bric::Util::Priv>, 
L<Bric::Biz::Person::User::Parts::ACL|Bric::Biz::Person::User::Parts::ACL>

=cut
