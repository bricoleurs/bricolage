package bric_upgrade;

=pod

=head1 NAME

bric_upgrade - Library with functions to assist upgrading a Bricolage installation.

=head1 VERSION

$Revision: 1.21 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.21 $ )[-1];

=head1 DATE

$Date: 2003-10-15 23:19:06 $

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use strict;
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use bric_upgrade qw(:all);

  # Check to see if we've run this before.
  exit if test_sql('SELECT * FROM table_to_add');

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
automatically process -p and -u arguments to your upgrade script so that the
change can be done by a database user with administrative permissions.

This module assumes that the upgrades performed by a single upgrade script
must be carried out atomically; either all of the changes are committed, or
none are. Thus, this module starts a database transaction as soon as it loads,
and rolls back any changes if any exceptions are thrown. If all changes
succeed, then the transaction will be commited when the script exits.

=cut

##############################################################################

use strict;
require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(do_sql test_sql fetch_sql db_version);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use File::Spec::Functions qw(catdir);

# Load the options.
use Getopt::Std;
our ($opt_u, $opt_p);

BEGIN{
    getopts('u:p:');
    # Set the db admin user and password to some reasonable defaults.
    $ENV{BRIC_DBI_PASS} ||= $opt_p || 'postgres';
    $ENV{BRIC_DBI_USER} ||= $opt_u || 'postgres';
}

# Make sure we can load the Bricolage libraries.
BEGIN {
    # $BRICOLAGE_ROOT defaults to /usr/local/bricolage
    $ENV{BRICOLAGE_ROOT} ||= "/usr/local/bricolage";

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

# Load Bricolage DBI library.
use Bric::Util::DBI qw(:all);
use Bric::Config qw(DBI_USER);

##############################################################################
# Start a transaction. Everyting the script that loads this module
# does should be in a single transaction.
begin();

my $rolled_back;

# Catch all exceptions. We want to rollback any transactions before
# exiting.
$SIG{__DIE__} = sub {
    # For some reason, this seems to get called twice
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
# Grab the Bricolage version number and put it into a v-string. We can
# eliminate the eval if, in the future, we change the Bric version number
# to an actual v-string.
my $old_version = eval "v$Bric::VERSION";

# Tell STDERR to ignore PostgreSQL NOTICE messages by forking another Perl to
# filter them out.
open STDERR, "| perl -ne 'print unless /^NOTICE:  /'"
  or die "Cannot pipe STDERR: $!\n";

##############################################################################

=head1 EXPORTED FUNCTIONS

=head2 test_sql()

  exit if test_sql($sql);

Evaluates the SQL expression C<$sql> against the Bricolage database. If there
is an error preparing or executing C<$sql>, C<test_sql()> will return
false. If there are no errors, it will return true. Use this function to
determine whether the upgrades your script is about to perform have already
been performed.

For example, say you need to add a table C<foo_bar>. It's possible, for some
reason or other, that the table may already have been added -- perhaps your
script has already been run against the Bricolage installation. To determine
whether it has, call C<test_sql()> with an SQL query that will throw an
exception if the table doesn't exist, but succeed if it does. If it does
succeed, then simply exit your script without continuing to update the
database.

  exit if test_sql('SELECT * from foo_bar');

=cut

sub test_sql {
    eval {
	my $sth = prepare(shift);
	execute($sth);
    };
    return $@ ? 0 : 1;
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

This function is similar in functionality to C<test_sql()>, except that it
doesn't explicitly test for an exception. In other words, it's useful for
testing for database changes that may not trigger an exception even if they
haven't been run. For example, say you need to add a new value to the
"event_type" table with the "key_name" column value 'foo_grepped'. To
determine whether this value has already been entered into the database, you
simply try to select it. Use C<fetch_sql()> to do this, as it will return true
if it manages to fetch a value, and false otherwise.

  exit if fetch_sql('SELECT name FROM event_type WHERE key_name = 'foo_grepped');

=cut

sub fetch_sql {
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
    my @objs;
    # Execute each SQL statement.
    foreach my $sql (@_) {
        local $SIG{__WARN__} = sub {};
        my $sth = prepare($sql);
        execute($sth);
        if ($sql =~ /CREATE\s+TABLE\s+([^\s]*)/i
            || $sql =~ /CREATE\s+SEQUENCE\s+([^\s]*)/i)
          {
              # Grab the name of the object to grant permissions on.
              push @objs, $1;
          }
    }

    # Now grant the necessary permissions.
    if (@objs) {
        my $grant = prepare(qq{
                GRANT  SELECT, UPDATE, INSERT, DELETE
                ON     } . join(', ', @objs) . qq{
                TO     ${ \DBI_USER() }
            });
        execute($grant);
    }
}

##############################################################################

=head2 db_version()

  if (db_version() ge '7.3') {
      do_sql "ALTER TABLE foo DROP bar";
  }

This function returns the the version number of the database server we're
connected to. It can be used to determine what functionality is available in
order to perform different tasks. For example, PostgreSQL 7.3 and later
support dropping columns. Thus, the above exmple demonstrates checking that
the server is 7.3 or later before executing dropping a column.

=cut

my $version;

sub db_version {
    return $version if $version;
    $version = col_aref("SELECT version()")->[0];
    $version =~ s/\s*PostgreSQL\s+(\d\.\d(\.\d)?).*/$1/;
    return $version;
}

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric:Util::DBI|Bric::Util::DBI>

=cut
