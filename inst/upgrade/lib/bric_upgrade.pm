package bric_upgrade;

=pod

=head1 NAME

bric_upgrade - Library with functions to assist upgrading a Bricolage installation.

=cut

# Grab the Version Number.
use Bric; our $VERSION = Bric->VERSION;

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use strict;
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use bric_upgrade qw(:all);

  # Check to see if we've run this before.
  exit if test_table('table_to_add');

  # Now update the database.
  my @sql = (
      'CREATE TABLE table_to_add (
            lname VARCHAR(64),
            fname VARCHAR(64),
            mname VARCHAR(64)
       )'
  );
  do_sql(@sql);

=head1 DESCRIPTION

This module exports functions that are useful for upgrading a Bricolage
database. The idea is that all changes to the Bricolage database that are
required by and upgrade will be performed in a single transaction via this
module. It provides functions to test to see if an upgrade has previously been
performed, as well as functions to update the database. Furthermore, it will
automatically process arguments to your upgrade script so that the change can
be done by a database user with administrative permissions.

This module assumes that the upgrades performed by a single upgrade script
must be carried out atomically; either all of the changes are committed, or
none are. Thus, this module starts a database transaction as soon as it loads,
and rolls back any changes if any exceptions are thrown. If all changes
succeed, then the transaction will be commited when the script exits.

If the C<-i> argument is specified on the command-line (as it is by
F<inst/db_upgrade.pl>, this module will also switch the user context to the
PostgreSQL administrative user. This is to allow trusted authentication to
work properly. All upgrades must therefore be run the super user, so that the
switch works.

For those scripts that do not wish to run as the PostgreSQL user, such as to
delete files from the existing Bricolage installation, just don't load this
module and you'll be good to go.

=head1 OPTIONS

=over

=item * -u username

The PostgreSQL super user's username.

=item * -p password

The PostgreSQL super user's password.

=item * -s username

The username of the PostgreSQL system user, usually "postgres".

=item * -i uid

The UID of the PostgreSQL system user, used to switch to that user's context
while scripts are running.

=back

=cut

##############################################################################

use strict;
require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(prompt y_n do_sql test_column test_table test_constraint
                    test_foreign_key test_index test_function test_aggregate
                    fetch_sql db_version test_primary_key);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use File::Spec::Functions qw(catdir updir);
use FindBin;

# Prevent stupid "Can't locate Log/Agent.pm errors by always loading
# Cache::FileCache here.
use Cache::FileCache;

# Load the options.
use Getopt::Std;
our ($opt_u, $opt_p, $opt_i, $opt_s);

BEGIN{
    getopts('u:p:i:s');
    # Set the db admin user and password to some reasonable defaults.
    $ENV{BRIC_DBI_PASS} ||= $opt_p ||= 'postgres';
    $ENV{BRIC_DBI_USER} ||= $opt_u ||= 'postgres';
}

# Make sure we can load the Bricolage libraries.
BEGIN {
    # $BRICOLAGE_ROOT defaults to /usr/local/bricolage
    $ENV{BRICOLAGE_ROOT} ||= "/usr/local/bricolage";

    # Always use the Bric::Config and Bric::Util::DBI from the sources.
    unshift @INC, catdir $FindBin::Bin, updir, updir, updir, 'lib';
    require Bric::Config;
    Bric::Config->import(qw(DBI_USER));
    require Bric::Util::DBI;
    Bric::Util::DBI->import(qw(:all));
    eval "require bric_upgrade_".DBD_TYPE;
    die $@ if $@;
    ('bric_upgrade_'.DBD_TYPE)->import(qw(:all));
    shift @INC;

    # use $BRICOLAGE_ROOT/lib if exists
    $_ = catdir($ENV{BRICOLAGE_ROOT}, "lib");
    unshift(@INC, $_) if -e $_;

    # make sure Bric is found
    eval "use Bric";
    die <<"END" if $@;
######################################################################

Cannot locate Bricolage libraries. Please set the environment
variable BRICOLAGE_ROOT to the location of your Bricolage
installation or set the environment variable PERL5LIB to the
directory where Bricolage's libraries are installed. The error
encountered was:

$@

######################################################################
END
}

##############################################################################
# Switch to the PostgreSQL systsem user.
if ($opt_i) {
    $> = $opt_i;
    die "Failed to switch EUID to $opt_i ($opt_s).\n" unless $> == $opt_i;
}

##############################################################################
# Start a transaction. Everyting the script that loads this module
# does should be in a single transaction.
begin();

my $rolled_back;

# Catch all exceptions. We want to rollback any transactions before
# exiting.
$SIG{__DIE__} = sub {
    # For some reason, this seems to get called twice.
    unless ($rolled_back) {
        rollback();
        print STDERR "\n\n", ('#') x 70, "\n",
          "ERROR: DATABASE UPDATE FAILED!\n\n",
          "The database was not affected. Please address this ",
          "issue before continuing.\n\nThe error encountered was:\n\n@_";
        $rolled_back = 1;
    }
    die @_;
};

END {
    # Commit all transactions unless there was an error and a rollback.
    commit() unless $rolled_back;
}

##############################################################################
# What Perl are we using?
my $perl = $ENV{PERL} || $^X;

# Tell STDERR to ignore PostgreSQL NOTICE messages by forking another Perl to
# filter them out.
open STDERR, "| $perl -ne 'print unless /^NOTICE:  /'"
  or die "Cannot pipe STDERR: $!\n";

##############################################################################

=head1 EXPORTED FUNCTIONS

=head2 prompt

  my $answer = prompt($question, $default);

Prompts the user for some information and then returns the value entered.
If the user provides no answer, or if there is no TTY, C<prompt()> simply
returns the default value.

=cut

sub prompt {
    die "prompt() called without a prompt message" unless @_;
    my ($msg, $def) = @_;

    ($def, my $dispdef) = defined $def ? ($def, "[$def] ") : ('', ' ');

    do {
        local $|=1;
        print "$msg $dispdef";
    };

    my $ans;
    if (-t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT))) {
        $ans = <STDIN>;
        if (defined $ans) {
            chomp $ans;
        } else { # user hit ctrl-D
            print $/;
        }
    }

    return defined $ans && length $ans ? $ans : $def;
}

##############################################################################

=head2 y_n

  my $answer = y_n($prompt, $default);

Prompts the user with the prompt message and returns true if the answer was
"yes" or "y" and false if it was "no" or "n". The check for the answer is
case-insensitive.

=cut

sub y_n {
    die "y_n() called without a prompt message" unless @_;

    while (1) {
        my $ans = prompt(@_);
        return 1 if $ans =~ /^y/i;
        return 0 if $ans =~ /^n/i;
        print "Please answer 'y' or 'n'.\n";
    }
}

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@justatheory.com>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric:Util::DBI|Bric::Util::DBI>

=cut
