package Bric::Util::Fault::Exception;
###############################################################################

=head1 NAME

Bric::Util::Fault::Exception - base class for all Exceptions

=head1 VERSION

$Revision: 1.7 $

=cut

our $VERSION = (qw$Revision: 1.7 $ )[-1];

=head1 DATE

$Date: 2003-02-18 05:55:09 $

=head1 SYNOPSIS

Don't use this module.  Use one of it's subclasses for specific exceptions.

=head1 DESCRIPTION

[need better description]

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              

# A sample use module.

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric::Util::Fault );

#=============================================================================#
# Function Prototypes and Closures     #
#======================================#

# Put any function prototypes and lexicals to be defined as closures here.

#==============================================================================#
# Constants                            #
#======================================#


#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

# Public fields should use 'vars'

#--------------------------------------#
# Private Class Fields                  

# Private fields use 'my'

#--------------------------------------#
# Instance Fields                       

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

NONE.

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=back

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

Don't use this module.  Use one of it's subclasses for specific exceptions.

=head1 AUTHOR

matthew d. p. k. strelchun-lanier - matt@lanier.org

=head1 SEE ALSO

NONE

=cut
