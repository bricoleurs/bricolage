package Bric::Util::Fault;
###############################################################################

=head1 NAME

Bric::Util::Fault - base class for all Exceptions and Errors

=head1 VERSION

$Revision: 1.1.1.1.2.1 $

=cut

our $VERSION = substr(q$Revision: 1.1.1.1.2.1 $, 10, -1);

=head1 DATE

$Date: 2001-10-09 21:51:08 $

=head1 SYNOPSIS

 eval {
	# do something that causes general mayhem.
 	die Bric::Util::Fault->new ({msg => 'fuck!'});
 };

 if ($@) {

	# do copy because $@ get over-written for every eval
	my $s = $@; 

	print "uhho.  something faulted.  lets look at it...";
	print "the fault was of type " . ref ($@) . "\n";

	print "timestamp -- " . $s->get_timestamp . "\n";
	print "pkg -- " . $s->get_pkg . "\n";
	print "filename-- " . $s->get_filename. "\n";
	print "line -- " . $s->get_line . "\n";
	print "stack -- " . join("\n", $s->get_stack) . "\n";
	print "env -- " . $s->get_env . "\n";
	print "msg -- " . $s->get_msg . "\n";
	print "payload -- " . $s->get_payload . "\n";
 }


=head1 DESCRIPTION

Bric::Util::Fault.pm is the base class for all Bricolage Exceptions and Errors.  Do not
use this class directly if you are looking for an error or exception to throw.
Rather, look at Bric::Util::Fault::Exception or Bric::Util::Fault::Error.

You should only directly interact with this class if you are subclassing it to
create another type of Fault that is parallel to Fault::Exception and
Fault::Error.

Whereas earlier perl versions could only die ('string'), perl 5.005 and beyond
can die ($obj).  This object can contain rich state information which enables
the calling eval {} to perform more varied object introspection.  This also
avoids the proliferation of error strings, and makes catching errors very
simple.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#==============================================================================#
# Inheritance                          #
#======================================#


#--------------------------------------#
# Programatic Dependencies              
use overload q{""} => \&error_info;
 
# THIS MODULE SHOULD HAVE NO PROGRAMATIC DEPENDENCIES!!!
# NO, DAVID, NOT EVEN FOR TIME! :-)


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

#------------------------------------------------------------------------------#

=item $obj = new Bric::Util::Fault($init);

Creates a new Fault object for processing up the caller stack

Keys of $init are:

=over 4

=item *

msg

programmer message

=item *

payload

programmer payload

=back

B<Throws:>

Um, this can't really throw itself.  or can it?  i dunno.

B<Side Effects:>

sets some values.  not much more.

B<Notes:>

This method should only be used within a 'die' context, and one of its subclasses should be thrown instead.'

=cut

sub new {
	my $class = shift;
	my ($init) = @_;

	# calculate state information needed for object

	## timestamp
	my ($timestamp) = time;

	## caller
	my (@stack, $i);
	$i = 0;
	while (my @s = caller($i++)) {push @stack, \@s}

	my ($pkg, $filename, $line) = @{$stack[0]};

	## env
	my ($env) = (\%ENV);

	## construct parameters
	my $p = {
		 timestamp => $timestamp,
		 pkg => $pkg,
		 filename => $filename,
		 line => $line,
		 env => $env,
		 msg => $init->{'msg'},
		 payload => $init->{'payload'},
		 stack => \@stack,
		};

	# Create the object via fields which returns a blessed object.
	bless $p, ref $class || $class;

}

#------------------------------------------------------------------------------#


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

=item $string = $obj->error_info();

returns error string of type 'pkg -- filename -- line -- msg'

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub error_info {
	my ($self) = shift;
	return join(' -- ', $self->get_pkg, $self->get_filename,
	  $self->get_line) . "\n" . ($self->get_msg || '') . "\n\n"
	  . ($self->get_payload || '') . "\n";
}

#------------------------------------------------------------------------------#

=item $id = $obj->get_msg();

Returns the message set by the programmer at error time.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_msg { shift->{msg} };


#------------------------------------------------------------------------------#

=item $id = $obj->get_timestamp();

Returns the timestamp of the error

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_timestamp { shift->{timestamp} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_env();

Returns the contents of %ENV at time of error

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_env { shift->{env} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_filename();

Returns the filename that died

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_filename { shift->{filename} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_line();

Return the line of the file that died

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_line { shift->{line} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_pkg();

Returns the package that died

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_pkg { shift->{pkg} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_payload();

Returns the programmer-specificed payload

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_payload { shift->{payload} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_stack();

Returns the stack trace

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_stack { shift->{stack} };


=cut



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

This is the *only* class file that should use the command 'die'.  everyone else should use the interface specified above.

=head1 AUTHOR

matthew d. p. k. strelchun-lanier - matt@lanier.org

=head1 SEE ALSO

uh, nothing.

=cut
