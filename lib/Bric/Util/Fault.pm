package Bric::Util::Fault;
###############################################################################

=head1 NAME

Bric::Util::Fault - Bricolage Exceptions

=head1 VERSION

$Revision: 1.13 $

=cut

our $VERSION = (qw$Revision: 1.13 $ )[-1];

=head1 DATE

$Date: 2003-03-07 16:34:33 $

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
  }

=head1 DESCRIPTION

This class does Exceptions for Bricolage. It replaces a
home-grown implementation with one based on Exception::Class
(which is what HTML::Mason uses). For now, we are merely
emulating the previous functionality, so the above synopsis
should still be valid, but this will change as we use more
features of Exception::Class and try to clean exception usage
throughout the Bricolage API code.

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
use Exception::Class (
    'Bric::Util::Fault' => {
        description => 'Bricolage Exception',
        fields => [qw(payload)],
    },
    'Bric::Util::Fault::Exception' => {
        description => 'Remove Me Exception',
        isa => 'Bric::Util::Fault',
    },
    'Bric::Util::Fault::Exception::AP' => {
        description => 'Application Exception',
        isa => 'Bric::Util::Fault::Exception',
        alias => 'throw_ap',
    },
    'Bric::Util::Fault::Exception::DA' => {
        description => 'Data Access Exception',
        isa => 'Bric::Util::Fault::Exception',
        alias => 'throw_da',
    },
    'Bric::Util::Fault::Exception::DP' => {
        description => 'Data Processing Exception',
        isa => 'Bric::Util::Fault::Exception',
        alias => 'throw_dp',
    },
    'Bric::Util::Fault::Exception::GEN' => {
        description => 'General Exception',
        isa => 'Bric::Util::Fault::Exception',
        alias => 'throw_gen',
    },
    'Bric::Util::Fault::Exception::MNI' => {
        description => 'Method Not Implemented Exception',
        isa => 'Bric::Util::Fault::Exception',
        alias => 'throw_mni',
    },
);

require Exporter;
*import = \&Exporter::import;
our @EXPORT_OK = qw(isa_bric_exception rethrow_exception throw_ap throw_da
                    throw_dp throw_gen throw_mni);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

#--------------------------------------#
# Programatic Dependencies
use overload q{""} => \&error_info;
use HTML::Mason::Exceptions ();

#=============================================================================#
# Function Prototypes and Closures     #
#======================================#


#==============================================================================#
# Constants                            #
#======================================#
__PACKAGE__->Trace(1);

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

=item $obj = Bric::Util::Fault->new($init);

Creates a new Fault object for processing up the caller stack

Keys of $init are:

=over 4

=item msg

The exception message.

=item payload

Extra error information, e.g., from C<$!> or C<$@>.

=back

B<Throws:> NONE

B<Side Effects:> NONE.

B<Notes:>

This method should only be used within a C<die> context, and one of its
subclasses (GEN, MNI, etc..) should be thrown instead.
We want to change this so that you generally use the C<throw> method
instead.

=cut

sub new {
    my $class = shift;

    # handle old style which used a hashref
    my %params = ref $_[0] ? %{$_[0]} : @_ == 1 ? ( error => $_[0] ) : @_;
    # make any old 'msg' params into 'error'
    $params{'error'} = delete $params{'msg'} if exists $params{'msg'};

    return $class->SUPER::new(%params);
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

=item $str = $obj->error_info;

Returns error string of type "pkg -- filename -- line -- msg". Also called
when the exception object is used in a string context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Overloads the double-quoted string operator. Should probably
be deprecated in favor of C<< Exception::Class->as_string >>.

=cut

sub error_info {
    my $self = shift;
    return join(' -- ', $self->package, $self->file,
                $self->line) . "\n" . ($self->error || '') . "\n\n"
                . ($self->payload || '') . "\n";
}

#------------------------------------------------------------------------------#

=item $str = $obj->get_msg;

Returns the message set by the programmer at error time.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_msg { shift->error }


#------------------------------------------------------------------------------#

=item $id = $obj->get_timestamp;

Returns the timestamp of the error. The timestamp is the epoch time of the
error - the number of seconds since January 1, 1970.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_timestamp { shift->time }

#------------------------------------------------------------------------------#

=item $id = $obj->get_filename;

Returns the name of the file in which the error ocurred.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_filename { shift->file }

#------------------------------------------------------------------------------#

=item $id = $obj->get_line;

Return the line number at which the error ocurred in the file returned by
C<get_filename()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_line { shift->line }

#------------------------------------------------------------------------------#

=item $id = $obj->get_pkg;

Returns the name of the package in which the error ocurred.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_pkg { shift->package }

#------------------------------------------------------------------------------#

=item $id = $obj->get_payload;

Returns the programmer-specified payload.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_payload { shift->payload }

#------------------------------------------------------------------------------#

=item $id = $obj->get_stack;

Returns the stack trace.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_stack {
    my $self = shift;
    my (@stack, $trace, $frame_num);

    # see `perldoc Devel::StackTrace`
    $trace = $self->trace;

    $frame_num = $trace->frame_count - 1;
    while (my $f = $trace->prev_frame) {
        my $str = "$frame_num: " . $f->package . ':' . $f->line
            . ' -> ' . $f->subroutine . '('
            . join(', ', map {length>32 ? substr($_,0,30).'...' : $_} $f->args)
            . ')';
        $str .= ', evaltext=' . $f->evaltext if defined $f->evaltext;

        push @stack, $str;
        $frame_num--;
    }

    return \@stack;
}

#------------------------------------------------------------------------------#

=item $err->throw(error => 'This is some error we are throwing');

This overrides the C<throw> method in Exception::Class so that
if we create a new exception from a Bric or HTML::Mason exception,
we will just use the short error message. Otherwise, exceptions
can get stringified more than once.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub throw {
    my $class = shift;
    my %params = ref $_[0] ? %{$_[0]} : @_ == 1 ? ( error => $_[0] ) : @_;

    # please only use 'error', not 'message', with Bric exceptions :)
    if (isa_bric_exception($params{error})) {
        $params{error} = $params{error}->error;
    }
    if (HTML::Mason::Exceptions::isa_mason_exception($params{error})) {
        $params{error} = $params{error}->error;
    }
    if (HTML::Mason::Exceptions::isa_mason_exception($params{message})) {
        $params{message} = $params{message}->error;
    }
    $class->SUPER::throw(%params);
}

#------------------------------------------------------------------------------#

=back

=head2 Public Functions

=over 4

=item isa_bric_exception($err, 'MNI');

This function tests whether the $err argument is a Bricolage
exception. The optional second argument can be used to test
for a specific Bricolage exception.

B<Throws:>

=over 4

=item *

"no such exception class $class"

=back

B<Side Effects:> NONE.

B<Notes:>

This function is imported into the calling class.

=cut

sub isa_bric_exception {
    my ($err, $name) = @_;
    return unless defined $err;

    if ($name) {
        my $class = "Bric::Util::Fault::Exception::$name";
        no strict 'refs';

        # XXX: shouldn't an exception be thrown here instead?
        # I've copied it from HTML::Mason::Exception.
        die "no such exception class $class"
            unless defined(${"${class}::VERSION"});
        return UNIVERSAL::isa($err, "Bric::Util::Fault::Exception::$name");
    } else {
        return UNIVERSAL::isa($err, "Bric::Util::Fault");
    }
}

#------------------------------------------------------------------------------#

=item rethrow_exception($err);

This function rethrows the $err argument if it
C<can> rethrow (i.e. it is a Bricolage or HTML::Mason exception).

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

This function is imported into the calling class.

=cut

sub rethrow_exception {
    my ($err) = @_;
    return unless $err;

    if (UNIVERSAL::can($err, 'rethrow')) {
        $err->rethrow();
    }
    Bric::Util::Fault->throw(error => $err);
}

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

This was muchly copied from HTML::Mason::Exceptions.
This replaces the home-grown exception handling
written by matthew d. p. k. strelchun-lanier <matt@lanier.org>.

=head1 AUTHOR

Scott Lanning <lannings@who.int>

=head1 SEE ALSO

L<Exception::Class|Exception::Class>,
L<Devel::StackTrace|Devel::StackTrace>,
L<HTML::Mason::Exceptions|HTML::Mason::Exceptions>

=cut
