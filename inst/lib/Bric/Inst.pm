package Bric::Inst;

=head1 Name

Bric::Inst - support library for installation system scripts

=cut

# XXX: using Bric doesn't work before Bric is installed
# use Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  #!/usr/bin/perl -w

  use strict;
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use Bric::Inst qw(:all);

=head1 Description

This module exports function used by the installation system scripts.

=head1 Exported Functions

=over 4

=cut

use strict;

use File::Spec::Functions qw(catdir tmpdir catfile);
eval { require Term::ReadPassword; import Term::ReadPassword 'read_password' };
if ($@) {
    print "#" x 79, "\n\n", <<END, "\n", "#" x 79, "\n";
Bricolage installation requires Term::ReadPassword. Please install
this Perl module from CPAN.
END

    exit 1;
}
require Exporter;
use base 'Exporter';
our @EXPORT_OK = qw(soft_fail hard_fail ask_yesno ask_confirm ask_choice
                    get_default ask_password);

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
    $default = $default ? 1 : 0;
    local $| = 1;
    while (1) {
        print $question;
        print ' [', ( $default ? 'yes' : 'no' ), '] '; # Append the default
        # just print a newline after the question to keep
        # output tidy, if we are in quiet mode
        print $default ? "yes\n" : "no\n" if $quiet_mode;
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
        # just print the dfault and a newline after the question to keep
        # output tidy, if we are in quiet mode
        print "$$ref\n" if $quiet_mode;
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
        if (ask_yesno("Are you sure you want to use '$answer'?", 1, $quiet_mode)) {
            $$ref = $answer;
            return;
        }
    }
}

=item ask_password($description, $ref_to_setting, $quiet_mode)

Asks the user to enter a password. If they enter a new value, they will be
prompted to enter it a second time. The password will not be echoed to the
shell.

If $quiet_mode is true and the default setting is not "NONE", then the default
answer is returned without asking for user input (useful for unattended
execution where appropriate default values can be passed to this sub).

A default setting of "NONE" will force the user to enter a value.

=cut

sub ask_password {
    my ($desc, $ref, $quiet) = @_;
    return $$ref if $quiet && $$ref ne 'NONE';
    my $tries = 1;
    local $| = 1;
    while (1) {
        my $answer = read_password("$desc: ");
        if (not length $answer or $answer eq $$ref) {
            return unless $$ref eq 'NONE';
            print "No default is available for this question, ",
                "please enter a value.\n";
            next;
        }
        my $second = read_password("Confirm password: ");
        if ($second ne $answer) {
            print "Passwords do not match.\n";
            next
        }
        if (ask_yesno("Are you sure you want to use this password?", 1)) {
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
        print "$default\n" if $quiet_mode;
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


=item get_default($key)

Returns the value for $key from the defaults file (inst/defaults/<distro>)

For example, get_default("APACHE_USER") might return "nobody".

=cut

# We'll store the settings loaded from the defaults file here.
our $defaults;

# Pretty much a copy/paste from Bric::Config
BEGIN {
    # Load the defaults file, if it exists.
    my $distro = lc($ENV{USE_DEFAULTS} ? $ENV{USE_DEFAULTS} : "standard");
    my $def_file = catdir('inst', 'defaults', $distro);

    if (-e $def_file) {
        unless (open DEFS, $def_file) {
            require Carp;
            Carp::croak "Cannot open $def_file: $!\n";
        }

        while (<DEFS>) {
            # Get each configuration line into $defaults.
            chomp;                  # no newline
            s/#.*//;                # no comments
            s/^\s+//;               # no leading white
            s/\s+$//;               # no trailing white
            next unless length;     # anything left?

            # Get the variable and its value.
            my ($var, $val) = split(/\s*=\s*/, $_, 2);

            # Check that the line is a valid config line and exit
            # immediately if not.
            unless (defined $var and length $var and 
                    defined $val and length $val) {
                print STDERR "Syntax error in $def_file at line $.: '$_'\n";
                exit 1;
            }

            # Save the configuration directive.
            $defaults->{uc $var} = $val;
        }
        close DEFS;
    }
}

sub get_default {
    my $key = uc shift;
    (my $env_key = $key) =~ s/^BRICOLAGE_//;
    my $ret = exists $ENV{"BRICOLAGE_$env_key"}
        ? $ENV{"BRICOLAGE_$env_key"}
        : $defaults->{$key};
    print "BRICOLAGE_$env_key => ", (defined $ret ? $ret : ''), "\n"
        if $ENV{DEVELOPER};
    return $ret;
}

=back

=head1 Notes

NONE.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

1;
