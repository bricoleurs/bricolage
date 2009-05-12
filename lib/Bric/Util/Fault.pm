package Bric::Util::Fault;

###############################################################################

=head1 Name

Bric::Util::Fault - Bricolage Exceptions

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Fault qw(throw_gen);

  eval {
      # Do something that causes general mayhem.
      throw_gen(error => 'Ro-ro!');
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

=head1 Description

This class does Exceptions for Bricolage. It replaces a home-grown
implementation with one based on Exception::Class (which is what HTML::Mason
uses). For now, we are merely emulating the previous functionality, so the
above synopsis should still be valid, but this will change as we use more
features of Exception::Class and try to clean exception usage throughout the
Bricolage API code.

There are currently two major classes of exceptions:
Bric::Util::Fault::Exception and its subclasses represent fatal,
non-recoverable errors. Exceptions of this sort are unexpected, and should be
reported to an administrator or to the Bricolage developers.

Bric::Util::Fault::Error and its subclasses represent non-fatal errors
triggered by invalid data. These can be used to let users know that the data
they've entered is invalid. To support this usage, Bric::Util::Fault::Error
and its subclasses offer the C<maketext> field, which can be passed an array
reference of values suitable for passing to Bric::Util::Language's
C<maketext()> method.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#
use Bric::Config qw(:qa);

#--------------------------------------#
# Standard Dependencies
use strict;

#==============================================================================#
# Inheritance                          #
#======================================#
use Exception::Class
  (
   'Bric::Util::Fault' =>
     { description => 'Bricolage Exception',
       fields => [qw(payload)],
     },
   'Bric::Util::Fault::Exception' =>
     { description => 'Remove Me Exception',
       isa => 'Bric::Util::Fault',
     },
    'Bric::Util::Fault::Exception::AP' =>
      { description => 'Application Exception',
        isa => 'Bric::Util::Fault::Exception',
        alias => 'throw_ap',
      },
   'Bric::Util::Fault::Exception::DA' =>
     { description => 'Data Access Exception',
       isa => 'Bric::Util::Fault::Exception',
       alias => 'throw_da',
     },
   'Bric::Util::Fault::Exception::DP' =>
     { description => 'Data Processing Exception',
       isa => 'Bric::Util::Fault::Exception',
       alias => 'throw_dp',
     },
   'Bric::Util::Fault::Exception::GEN' =>
     { description => 'General Exception',
       isa => 'Bric::Util::Fault::Exception',
       alias => 'throw_gen',
     },
   'Bric::Util::Fault::Exception::MNI' =>
     { description => 'Method Not Implemented Exception',
       isa => 'Bric::Util::Fault::Exception',
       alias => 'throw_mni',
     },
   'Bric::Util::Fault::Exception::Burner' =>
     { description => 'Burner exception',
       isa => 'Bric::Util::Fault::Exception',
       fields => [qw(oc cat elem mode element)],
       alias => 'throw_burn_error',
     },
   'Bric::Util::Fault::Exception::Auth' =>
     { description => 'Authentication exception',
       isa => 'Bric::Util::Fault::Exception',
       alias => 'throw_auth',
     },
   'Bric::Util::Fault::Exception::Burner::User' =>
     { description => 'Burner user exception',
       isa => 'Bric::Util::Fault::Exception::Burner',
       alias => 'throw_burn_user',
     },
   'Bric::Util::Fault::Error' =>
     { description => 'Invalid data error',
       isa => 'Bric::Util::Fault::Exception',
       fields => [qw(maketext)],
       alias => 'throw_error',
     },
   'Bric::Util::Fault::Error::NotUnique' =>
     { description => 'Not a unique value error',
       isa => 'Bric::Util::Fault::Error',
       alias => 'throw_not_unique',
     },
   'Bric::Util::Fault::Error::Undef' =>
     { description => 'Undefined value error',
       isa => 'Bric::Util::Fault::Error',
       alias => 'throw_undef',
     },
   'Bric::Util::Fault::Error::Invalid' =>
     { description => 'Invalid value error',
       isa => 'Bric::Util::Fault::Error',
       alias => 'throw_invalid',
     },
   'Bric::Util::Fault::Error::Forbidden' =>
     { description => 'Authorization denied error',
       isa => 'Bric::Util::Fault::Error',
       alias => 'throw_forbidden',
       fields => [qw(perm obj)],
     },
  );

# $err->as_string() will include the stack trace
Bric::Util::Fault->Trace(1);

require Exporter;
*import = \&Exporter::import;
our @EXPORT_OK = qw(isa_bric_exception isa_exception rethrow_exception throw_ap
                    throw_da throw_dp throw_gen throw_mni throw_burn_error
                    throw_burn_user throw_error throw_not_unique throw_undef
                    throw_invalid throw_auth throw_forbidden);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

#--------------------------------------#
# Programatic Dependencies
use overload q{""} => \&error_info, fallback => 1;
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

=head1 Interface

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

=item maketext

Supported by Bric::Util::Fault::Error and its subclasses. An array reference
suitable for passing to Bric::Util::Language's C<maketext()> method.

=back

B<Throws:> NONE

B<Side Effects:> NONE.

B<Notes:>

This method should only be used within a C<die> context, and one of its
subclasses (GEN, MNI, etc..) should be thrown instead. We want to change this
so that you generally use the C<throw> method instead.

=cut

sub new {
    my $class = shift;
    my %params =  @_ == 1 ? ( error => $_[0] ) : @_;

    # Just rethrow it if it appears to be an exception already.
    return $params{error} if isa_exception($params{error});

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

Returns $obj->as_string.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Overloads the double-quoted string operator.

=cut

sub error_info { $_[0]->as_string() }

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

This overrides the C<throw> method in Exception::Class so that if we create a
new exception from a Bric or HTML::Mason exception, we will just use the short
error message. Otherwise, exceptions can get stringified more than once.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub throw {
    my $class = shift;
    my %params =  @_ == 1 ? ( error => $_[0] ) : @_;
    # Just rethrow it if it appears to be an exception already.
    rethrow_exception($params{error}) if isa_exception($params{error});
    $class->SUPER::throw(%params);
}


#------------------------------------------------------------------------------#

=item $str = $obj->full_message;

Overrides $obj->as_string to include the payload.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub full_message {
    my $self = shift;
    my $msg = $self->error;
    $msg .= ': ' . $self->payload if $self->payload;
    return $msg;
}

#------------------------------------------------------------------------------#

=item $str = $obj->as_string;

Displays the exception object as a text string. Includes the output of
C<trace_as_text()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub as_string {
    my $self = shift;
    return sprintf("%s\n%s\n", $self->full_message, $self->trace_as_text);
}

#------------------------------------------------------------------------------#

=item $str = $obj->trace_as_text;

Displays the exception object's stack trace as text.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub trace_as_text {
    my $self = shift;
    return join "\n", map {
        my $str = sprintf("[%s:%d]", $_->filename, $_->line);
        if (QA_MODE) {
            my $sub = $_->subroutine;
            $sub =~ s/.*:://;
            $str .= sprintf("\n  %s(%s)", $sub, join(', ', $_->args));
        }
        $str;
    } $self->_filtered_frames;
}

sub _filtered_frames {
    my $self = shift;

    my (@frames, $trace, %ignore_subs, $faultregex);

    $trace = $self->trace;
    %ignore_subs = map { $_ => 1 }
      qw{
         (eval)
         Exception::Class::Base::throw
         Bric::Util::Fault::__ANON__
      };
    $faultregex = qr{/Bric/Util/Fault\.pm|/dev/null};

    while (my $frame = $trace->next_frame) {
        unless ($frame->filename =~ $faultregex
                  || $ignore_subs{$frame->subroutine}) {
            push @frames, $frame;
        }
    }
    unless (@frames) {
        @frames = grep { $_->filename !~ $faultregex } $trace->frames;
    }
    return @frames;
}

#------------------------------------------------------------------------------#

=back

=head2 Public Functions

=over 4

=item isa_bric_exception($err, 'MNI');

This function tests whether the $err argument is a Bricolage exception. The
optional second argument can be used to test for a specific Bricolage
exception.

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
        my $class = "Bric::Util::Fault::$name";
        no strict 'refs';

        # XXX: shouldn't an exception be thrown here instead?
        # I've copied it from HTML::Mason::Exception.
        die "no such exception class $class"
            unless defined(${"${class}::VERSION"});
        return UNIVERSAL::isa($err, $class);
    } else {
        return UNIVERSAL::isa($err, "Bric::Util::Fault");
    }
}

#------------------------------------------------------------------------------#

=item isa_exception($err);

This function tests whether the $err argument is an Exception::Class
exception.

B<Throws:>

=over 4

=item *

"no such exception class $class"

=back

B<Side Effects:> NONE.

B<Notes:>

This function is imported into the calling class.

=cut

sub isa_exception {
    my $err = shift;
    return defined $err && UNIVERSAL::isa($err, 'Exception::Class::Base');
}

#------------------------------------------------------------------------------#

=item rethrow_exception($err);

This function rethrows the $err argument if it C<can> rethrow (i.e. it is a
Bricolage or HTML::Mason exception).

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

=head1 Private

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

This was muchly copied from HTML::Mason::Exceptions. This replaces the
home-grown exception handling written by matthew d. p. k. strelchun-lanier
<matt@lanier.org>.

=head1 Author

Scott Lanning <lannings@who.int>

=head1 See Also

L<Exception::Class|Exception::Class>,
L<Devel::StackTrace|Devel::StackTrace>,
L<HTML::Mason::Exceptions|HTML::Mason::Exceptions>

=cut
