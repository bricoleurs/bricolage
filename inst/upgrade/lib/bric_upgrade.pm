package bric_upgrade;

=pod

=head1 Name

bric_upgrade - Library with functions to assist upgrading a Bricolage installation.

=cut

# Grab the Version Number.
use Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

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

=head1 Description

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
database administrative user. This is to allow trusted authentication to work
properly. All upgrades must therefore be run the super user, so that the
switch works.

For those scripts that do not wish to run as the database user, such as to
delete files from the existing Bricolage installation, just don't load this
module and you'll be good to go.

=head1 Options

=over

=item * -u username

The database super user's username.

=item * -p password

The database super user's password.

=item * -s username

The username of the database system user.

=item * -i uid

The UID of the database system user, used to switch to that user's context
while scripts are running.

=back

=cut

##############################################################################

use strict;
require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(prompt y_n do_sql test_column test_table test_constraint
                    test_foreign_key test_index test_function test_aggregate
                    fetch_sql db_version test_primary_key DBD_TYPE);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use File::Spec::Functions qw(catdir updir);
use FindBin;

# Prevent stupid "Can't locate Log/Agent.pm errors by always loading
# Cache::FileCache here.
use Cache::FileCache;

# Load the options.
use Getopt::Std;
our ($opt_u, $opt_p, $opt_i, $opt_s);

BEGIN {
    local @ARGV = @ARGV;
    getopts('u:p:i:s');
}

# Make sure we can load the Bricolage libraries.
BEGIN {
    # $BRICOLAGE_ROOT defaults to /usr/local/bricolage
    $ENV{BRICOLAGE_ROOT} ||= "/usr/local/bricolage";

    # Always use the Bric::Config and Bric::Util::DBI from the sources.
    unshift @INC, catdir $FindBin::Bin, updir, updir, updir, 'lib';
    require Bric::Config;
    Bric::Config->import(qw(DBI_USER DBD_TYPE));
}

BEGIN {
    my $mod = 'bric_upgrade_' . DBD_TYPE;
    eval "require $mod";
    die $@ if $@;
    shift @INC;

    # Set the db admin user and password to some reasonable defaults.
    $ENV{BRIC_DBI_USER} ||= $opt_u ||= __PACKAGE__->super_user;
    $ENV{BRIC_DBI_PASS} ||= $opt_p ||= __PACKAGE__->super_pass;

    # Load the DBI.
    require Bric::Util::DBI;
    Bric::Util::DBI->import(qw(:all));

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
# Switch to the database systsem user.
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

=head1 Exported Functions

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

##############################################################################

=head2 fetch_sql()

  exit if fetch_sql($sql);

Evaluates the C<SELECT> SQL expression C<$sql> against the Bricolage database
and attempts to fetch a value from the query. If a value is successfully
returned, C<fetch_sql()> returns true. Otherwise, it returns false. An
exception will also cause C<fetch_sql()> to return false. Use this function to
determine whether the upgrades your script is about to perform have already
been performed.

This function is useful for testing for database changes that may not trigger
an exception even if they haven't been run. For example, say you need to add a
new value to the "event_type" table with the "key_name" column value
'foo_grepped'. To determine whether this value has already been entered into
the database, you simply try to select it. Use C<fetch_sql()> to do this, as
it will return true if it manages to fetch a value, and false otherwise.

  exit if fetch_sql('SELECT name FROM event_type WHERE key_name = 'foo_grepped');

=cut

sub fetch_sql($) {
    my $val;
    eval {
        my $sth = prepare(shift);
        execute($sth);
        $val = fetch($sth);
        finish($sth);
    };
    return $val && !$@ ? 1 : 0;
}

##############################################################################

=head2 do_sql()

  do_sql(@sql_statements);

This function takes a list of SQL statements and executes each in turn. It
also sets the proper permissions for the Bricolage database user to be able to
access the tables and sequences it creates. Use this function to actually make
changes to the Bricolage database.

For example, say you need to add the table "soap_scum". Simply pass the proper
SQL to create the table to this function, and the SQL will be executed, and
the Bricolage database user provided the proper permissions to access it.

  my $sql = qq{
      CREATE TABLE soap_scum (
          lname VARCHAR(64),
          fname VARCHAR(64),
          mname VARCHAR(64)
     )
  };

  do_sql($sql);

=cut

sub do_sql {
    # Execute each SQL statement.
    foreach my $sql (@_) {
        my $sth = prepare($sql);
        execute($sth);
    }
}

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric:Util::DBI|Bric::Util::DBI>

=cut
