package Bric::Util::Fault;
###############################################################################

=head1 NAME

Bric::Util::Fault - base class for all Exceptions

=head1 VERSION

$Revision: 1.9 $

=cut

our $VERSION = (qw$Revision: 1.9 $ )[-1];

=head1 DATE

$Date: 2003-02-18 03:38:21 $

=head1 SYNOPSIS

  eval {
      # Do something that causes general mayhem.
      die Bric::Util::Fault::Subclass->new({ msg => 'Ro-ro!' });
  };

  if (my $err = $@) {
      print "Oh-oh, something faulted. Let's look at it...";
      print "Type:      ", ref $err, "\n";
      print "Message:   ", $err->get_msg, "\n";
      print "Payload:   ", $err->get_payload, "\n";
      print "Timestamp: ", $err->get_timestamp, "\n";
      print "Package:   ", $err->get_pkg, "\n";
      print "Filename:  ", $err->get_filename. "\n";
      print "Line"      ", $err->get_line, "\n";

      print "Stack:\n";
      foreach my $c (@{ $err->get_stack }) {
          print "\t", (ref $c ? join(' - ', @{$c}[1,3,2]) : $c), "\n";
      }

      print "Environment:\n";
      while (my ($k, $v) = each %{ $err->get_env }) {
          print "\t$k => $v\n";
      }
  }

=head1 DESCRIPTION

Bric::Util::Fault is the base class for all Bricolage Exceptions. Do not use
this class directly if you are looking for an exception to throw. Rather, look
at L<Bric::Util::Fault::Exception|Bric::Util::Fault::Exception>.

Whereas earlier perl versions could only die ('string'), perl 5.005 and beyond
can die ($obj). This object can contain rich state information which enables
the calling eval {} to perform more varied object introspection. This also
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

=item msg

The exception message.

=item payload

Extra error information, e.g., from C<$!> or C<$@>.

=back

B<Throws:>

Um, this can't really throw itself.  or can it?  i dunno.

B<Side Effects:> NONE.

B<Notes:>

This method should only be used within a 'die' context, and one of its
subclasses should be thrown instead.

=cut

sub new {
    my ($class, $init) = @_;

    ## caller
    my (@stack, $i);
    $i = 0;
    while (my @s = caller($i++)) {push @stack, \@s}

    my ($pkg, $filename, $line) = @{$stack[0]};

    ## construct parameters
    my $p = {
             timestamp => time,
             pkg => $pkg,
             filename => $filename,
             line => $line,
             env =>  { %ENV },
             msg => $init->{'msg'},
             payload => $init->{'payload'},
             stack => \@stack,
            };

    # Create the object via fields which returns a blessed object.
    bless $p, ref $class || $class;
}

#------------------------------------------------------------------------------#

=back

=head2 Destructors

=over

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

None.

=head2 Public Instance Methods

=over 4

=item $string = $obj->error_info;

Returns error string of type "pkg -- filename -- line -- msg". Also called
when the exception object is used in a string context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Overloads the double-quoted string operator.

=cut

sub error_info {
    my ($self) = shift;
    return join(' -- ', $self->get_pkg, $self->get_filename,
                $self->get_line) . "\n" . ($self->get_msg || '') . "\n\n"
                . ($self->get_payload || '') . "\n";
}

#------------------------------------------------------------------------------#

=item $id = $obj->get_msg;

Returns the message set by the programmer at error time.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_msg { shift->{msg} };


#------------------------------------------------------------------------------#

=item $id = $obj->get_timestamp;

Returns the timestamp of the error. The timestamp is the epoch time of the
error - the number of seconds since January 1, 1970.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_timestamp { shift->{timestamp} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_env;

Returns a hash reference of the contents of %ENV at time of error.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_env { shift->{env} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_filename;

Returns the name of the file in which the error ocurred.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_filename { shift->{filename} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_line;

Return the line number at which the error ocurred in the file returned by
C<get_filename()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_line { shift->{line} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_pkg;

Returns the name of the package in which the error ocurred.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_pkg { shift->{pkg} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_payload;

Returns the programmer-specified payload.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_payload { shift->{payload} };

#------------------------------------------------------------------------------#

=item $id = $obj->get_stack;

Returns the stack trace.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_stack { shift->{stack} };

#------------------------------------------------------------------------------#

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

This is the I<only> class file that should use the C<die> operator. Everyone
else should use the interface specified above.

=head1 AUTHOR

matthew d. p. k. strelchun-lanier - matt@lanier.org

=head1 SEE ALSO

L<Bric|Bric>, L<Bric::Util::Fault::Exception|Bric::Util::Fault::Exception>

=cut
