package Bric::Inst;

=head1 NAME

Bric::Inst - support library for installation system scripts

=head1 VERSION

$LastChangedRevision$

=cut

# XXX: using Bric doesn't work before Bric is installed
# use Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use strict;
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use Bric::Inst qw(:all);

=head1 DESCRIPTION

This module exports function used by the installation system scripts.

=head1 EXPORTED FUNCTIONS

=over 4

=cut

use strict;

require Exporter;
use base 'Exporter';
our @EXPORT_OK   = qw(soft_fail hard_fail ask_yesno ask_confirm ask_choice);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

=item soft_fail($msg)

Prints out an error message and returns 0.  Usually used to soft-fail
a test like:

  return soft_fail("Couldn't find Postgres...") unless ...;

This is saves a few lines since the alternative would be:

  unless(...) {
    print "Couldn't find Postgres...\n";
    return 0;
  }

=cut

sub soft_fail {
    print join('', @_), "\n";
    return 0;
}

=item hard_fail($msg)

Prints out an error message surrounded by lines of hash marks and
exits with code 1.

=cut

sub hard_fail {
    print "#" x 79, "\n\n", join('', @_), "\n", "#" x 79, "\n";
    exit 1;
}

=item ask_yesno($question, $default, $quiet_mode)

Asks the user a yes/no question.  Default to $default if they just
press [return].  Returns 1 for a yes answer and 0 for no.

If $quiet_mode is true the default answer is returned without
asking for user input (useful for unattended execution where
appropriate default values can be passed to this sub).

Be careful when using ask_yesno in quiet mode: if you're asking
confirmation for a potentially dangerous task either be sure
to set the "forget it" answer as default or don't allow
quiet mode at all.

=cut

sub ask_yesno {
    my ($question, $default, $quiet_mode) = @_;
    my $tries = 1;
    local $| = 1;
    while (1) {
        print $question;
        # just print a newline after the question to keep
        # output tidy, if we are in quiet mode
        print "\n" if $quiet_mode;
        
        my $answer= '';
        # do not wait for user input if we are in quiet mode
        $answer = <STDIN> unless $quiet_mode;
        chomp($answer);
        return $default if not length $answer;
        return 0 if $answer and $answer =~ /^no?$/i;
        return 1 if $answer =~ /^y(?:es)?$/i;
        print "Please answer \"yes\" or \"no\".\n";
        print "And quit screwing around.\n" if ++$tries > 3;
    }
}


=item ask_confirm($description, $ref_to_setting, $quiet_mode)

Asks the user to confirm a setting.  If they enter a new value asks
"are you sure."  Directly updates the setting and returns when done.

A default setting of "NONE" will force the user to enter a value.

If $quiet_mode is true the default answer is returned without
asking for user input (useful for unattended execution where
appropriate default values can be passed to this sub).

The question is printed anyway, so that the default value appears
in the output.

=cut

sub ask_confirm {
    my ($desc, $ref, $quiet_mode) = @_;
    my $tries = 1;
    local $| = 1;
    while (1) {
        print $desc, " [", $$ref, "] ";
        # just print a newline after the question to keep
        # output tidy, if we are in quiet mode
        print "\n" if $quiet_mode;
        
        my $answer= '';
        # do not wait for user input if we are in quiet mode
        $answer = <STDIN> unless $quiet_mode;
        chomp($answer);
        if (not length $answer or $answer eq $$ref) {
            if($quiet_mode and $$ref eq 'NONE') {
                print "No default is available for this question: ",
                    "cannot continue quiet mode execution";
                return;
            }
            return unless $$ref eq 'NONE';
            print "No default is available for this question, ",
                "please enter a value.\n";
            next;
        }
        if (ask_yesno("Are you sure you want to use '$answer'? [yes] ", 1, $quiet_mode)) {
            $$ref = $answer;
            return;
        }
    }
}

=item ask_choice($question, [ "opt1", "opt2" ], "default", $quiet_mode)

Asks the user to choose from a list of options.  Returns the option
selected.

If $quiet_mode is true the default answer is returned without
asking for user input (useful for unattended execution where
appropriate default values can be passed to this sub).

The question is printed anyway, so that the default value appears
in the output.

=cut

sub ask_choice {
    my ($desc, $choices, $default, $quiet_mode) = @_;
    my $tries = 1;
    local $| = 1;
    while (1) {
        print $desc, " [", $default, "] ";
        # just print a newline after the question to keep
        # output tidy, if we are in quiet mode
        print "\n" if $quiet_mode;
        
        my $answer= '';
        # do not wait for user input if we are in quiet mode
        $answer = <STDIN> unless $quiet_mode;
        chomp($answer);
        $answer = lc $answer;
        return $default if not length $answer;
        return $answer if grep { $_ eq $answer } @$choices;
        print "Please choose from: ", join(', ', @$choices), "\n";
        print "And quit screwing around.\n" if ++$tries > 3;
    }
}

=back

=head1 NOTES

NONE.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut
