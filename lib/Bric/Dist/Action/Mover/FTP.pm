package Bric::Dist::Action::Mover::FTP;

=head1 NAME

Bric::Dist::Action::Mover::FTP - Distributes resources via FTP.

=head1 VERSION

$Revision: 1.1.1.1.2.2 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.1.1.1.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:34 $

=head1 SYNOPSIS

  use Bric::Dist::Action::Mover::FTP;

=head1 DESCRIPTION



=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Dist::Action::Mover qw(register);

register(FTP => { Put => \&Bric::Dist::Action::Mover::FTP::put,
		  Delete => \&Bric::Dist::Action::Mover::FTP::del });

################################################################################
# Inheritance
################################################################################
#use base qw(Bric);

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
    Bric::register_fields({
			 # Public Fields

			 # Private Fields
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

NONE.

=back 4

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

NONE.

=head2 Public Functions

=over

=item * put($job, $st)

Puts the files specified by the $job object on the servers specified by $st.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub put {

}

################################################################################

=item * del($job, $st)

Deletes the files specified by the $job object from the servers specified by
$st.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del {

}

=back

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
Bric::Dist::Action(3),
Bric::Dist::Action::Mover(4)

=cut
