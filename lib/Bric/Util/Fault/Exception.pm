package Bric::Util::Fault::Exception;
###############################################################################

=head1 NAME

Bric::Util::Fault::Exception - base class for all Exceptions

=head1 VERSION

$Revision: 1.1.1.1.2.2 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:35 $

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

=over 4

=cut

=head2 Destructors

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=cut

# Add methods here that do not require an object be instantiated to call them.
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Public Instance Methods

=cut

# Add methods here that only apply to an instantiated object of this class.
# Use same POD comment style as above for 'new'.

#------------------------------------------------------------------------------#

=head1 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods

=cut


# Add methods here that do not require an object be instantiated, and should not
# be called outside this module (e.g. utility functions for class methods).
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Private Instance Methods

=cut

# Add methods here that apply to an instantiated object, but should not be
# called directly. Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Private Functions

=cut

# Add functions here that can be used only internally to the class. They should
# not be publicly available (hence the prefernce for closures). Use the same POD
# comment style as above for 'new'.

1;
__END__

=back

=head1 NOTES

Don't use this module.  Use one of it's subclasses for specific exceptions.

=head1 AUTHOR

matthew d. p. k. strelchun-lanier - matt@lanier.org

=head1 SEE ALSO


=cut
