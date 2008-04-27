package bric_upgrade_mysql;

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
our @EXPORT_OK = qw(do_sql test_column test_table test_constraint
                    test_foreign_key test_index test_function test_trigger
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
    getopts('u:p:i:s:');
    # Set the db admin user and password to some reasonable defaults.
}

# Make sure we can load the Bricolage libraries.
BEGIN {
    # $BRICOLAGE_ROOT defaults to /usr/local/bricolage
    $ENV{BRICOLAGE_ROOT} ||= "/usr/local/bricolage";

    # Always use the Bric::Config and Bric::Util::DBI from the sources.
    unshift @INC, catdir $FindBin::Bin, updir, updir, updir, 'lib';
    require Bric::Config;
    Bric::Config->import(qw(DBI_USER DB));
    require Bric::Util::DBI;
    Bric::Util::DBI->import(qw(:all));
    shift @INC;

    # use $BRICOLAGE_ROOT/lib if exists
    $_ = catdir($ENV{BRICOLAGE_ROOT}, "lib");
    unshift(@INC, $_) if -e $_;

    my $db = DB;

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

##############################################################################

=head2 test_table

  exit if test_table $table_to_add;

This function returns true if a table exists in the Bricolage database, and
false if it does not. Use C<test_table()> in an upgrade script that adds a new
table to the database to make sure that the script has not already been run.

=cut

sub test_table($) {
    my $table = shift;

    return fetch_sql(qq{
        SELECT 1
        FROM   information_schema.tables
        WHERE  table_schema = '$db'
               AND relname = '$table'
    });
}

##############################################################################

=head2 test_column

  exit if test_column $table_name, $column_name;
  exit if test_column $table_name, $column_name, $min_size;
  exit if test_column $table_name, $column_name, undef, $not_null;
  exit if test_column $table_name, $column_name, $min_size, $not_null;
  exit if test_column $table_name, $column_name, $min_size, $not_null, $type;

This function returns true if the specified column exists in specified table
in the Bricolage database, and false if it does not. Use C<test_column()> in
an upgrade script that adds a new column to the database to make sure that the
script has not already been run.

An optional third argument specifies a minimum size for the specified column
("size" generally meaning the length of a VARCHAR column). The function will
return true if the column exists and has at least the size specified. This is
useful in upgrade scripts that are changing the size of a column.

An optional fourth argument specifies whether the column is C<NOT NULL>. Thus
the function will return true if the column exists I<and> is not null, and
false if the column doesn't exist or can store NULL values. B<Note:> This
function will return true if a column has been made C<NOT NULL> by the use of
a constraint rather than a C<NOT NULL> in the statement that created the
column.

An optional fifth argument specifies the column type. The function will return
true if the column exists and is of the specified type. Typical examples
include "integer", "smallint", "boolean", "text", and "character varying(64)".

Of course, if both optional arguments are passed to C<test_column()>, it will
test that the column exists, that it is at least the size specified, and that
it is C<NOT NULL>.

=cut

sub test_column($$;$$$) {
    my ($table, $column, $size, $not_null, $type) = @_;
    my $sql = qq{
        SELECT 1
        FROM   information_schema.columns a
        WHERE  a.table_schema= '$db'
               AND a.table_name = '$table'
               AND a.column_name = '$column'
    };

    if (defined $size) {
        $sql .= "           AND a.character_maximum_length >= $size";
    }

    if (defined $not_null) {
        $not_null = $not_null ? 't' : 'f';
        $sql .= "           AND a.is_nullable = '$not_null'";
    }

    if (defined $type) {
        $sql .= "           AND a.data_type = '"
          . lc $type . "'";
    }

    return fetch_sql($sql)
}

##############################################################################

=head2 test_constraint

  exit if test_constraint $table_name, $constraint_name;
  exit if test_constraint $table_name, $constraint_name, $delete_code;

This function returns true if the specified constraint exists on the specified
table in the Bricolage database, and false if it does not. This is useful in
upgrade scripts that add a new constraint, and want to verify that the
constraint has not already been created. The optional third argument specifies
the code for the C<DELETE> control on the constraint. The possible values are
as follows:

  VALUE    ON DELETE...
  -----    ------------
    r      RESTRICT
    c      CASCACDE
    n      SET NULL
    a      NO ACTION
    d      SET DEFAULT

=cut

sub test_constraint($$;$) {
    my ($table, $con, $delcode) = @_;
    my $sql = qq{
        SELECT 1
        FROM   information_schema.table_constraints a
        WHERE  a.table_schema = '$db'
    	       AND a.table_name = '$table'
               AND r.constraint_type = 'CHECK'
               AND r.constraint_name = '$con'
    };
    return fetch_sql($sql);
}

##############################################################################

=head2 test_foreign_key

  exit if test_foreign_key $table_name, $foreign_key_name;
  exit if test_foreign_key $table_name, $foreign_key_name, $delete_code;

This function returns true if the specified foreign key constraint exists on
the specified table in the Bricolage database, and false if it does not. This
is useful in upgrade scripts that add a new foreign key, and want to verify
that the constraint has not already been created. The optional third argument
specifies the code for the C<DELETE> control on the foreign key
constraint. See the documentation for C<test_constraint()> for the possible
values for this argument.

=cut

sub test_foreign_key($$;$) {
    my ($table, $fk, $delcode) = @_;
    my $sql = qq{
        SELECT 1
        FROM   information_schema.table_constraints a
        WHERE  a.table_schema = '$db'
    	       AND a.table_name = '$table'
               AND r.constraint_type = 'FOREIGN KEY'
               AND r.constraint_name = '$fk'    
    };
    return fetch_sql($sql);
}

##############################################################################

=head2 test_primary_key

  exit if test_primary_key $table_name, $primary_key_name;

This function returns true if the specified primary key constraint exists on
the specified table in the Bricolage database, and false if it does not. This
is useful in upgrade scripts that add a new primary key, and want to verify
that the constraint has not already been created.

=cut

sub test_primary_key($$) {
    my ($table, $fk) = @_;
    my $sql = qq{
        SELECT 1
        FROM   information_schema.table_constraints a
        WHERE  a.table_schema = '$db'
    	       AND a.table_name = '$table'
               AND r.constraint_type = 'PRIMARY KEY'
               AND r.constraint_name = '$fk'        
    };
    return fetch_sql($sql);
}

##############################################################################

=head2 test_index

  exit if test_index $index_name;

This function returns true if the specified index exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new index, and want to verify that the index has not already been created.

=cut

sub test_index($) {
    my $index = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   information_schema.statistics a
        WHERE  a.table_schema = '$db'
               and a.index_name = '$index'
    });
}

##############################################################################

=head2 test_function

  exit if test_function $function_name;

This function returns true if the specified function exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new function, and want to verify that the function has not already been created.

=cut

sub test_function($) {
    my $function = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   information_schema.routines a
        WHERE  a.routine_schema = '$db'
               and a.routine_name = '$function'
    });
}

##############################################################################

=head2 test_trigger

  exit if test_trigger $trigger_name;

This function returns true if the specified trigger exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new trigger, and want to verify that the trigger has not already been created.

=cut

sub test_trigger($) {
    my $trigger = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   information_schema.triggers a
        WHERE  a.trigger_schema = '$db'
               and a.trigger_name = '$function'
    });
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
        local $SIG{__WARN__} = sub {};
        my $sth = prepare($sql);
        execute($sth);
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

sub db_version() {
    return $version if $version;
    $version = col_aref("status")->[0];
    $version =~ s/\s*Distrib\s+(\d\.\d(\.\d)?).*/$1/;
    return $version;
}

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@justatheory.com>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric:Util::DBI|Bric::Util::DBI>

=cut
