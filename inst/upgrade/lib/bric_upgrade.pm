package bric_upgrade;

=pod

=head1 NAME

bric_upgrade - Library with functions to assist upgrading a Bricolage
installation.

=head1 VERSION

$Revision: 1.6 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.6 $ )[-1];

=head1 DATE

$Date: 2002-03-14 01:51:33 $

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
required by and upgrade will be performed via this module. It provides functions
to test to see if an upgrade has previously been performed, as well as functions
to update the database. Furthermore, it will automatically process -p and -u
arguments to your upgrade script so that the change can be done by a database
user with administrative permissions.

=cut

use strict;
use Bric::Config qw(:dbi);
use Bric::Util::DBI qw(:all);
require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(do_sql test_sql fetch_sql is_later);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

BEGIN {
    $ENV{BRICOLAGE_ROOT} ||= '/usr/local/bricolage';
    eval { require Bric };
    if ($@) {
	# We need to set PERL5LIB.
	require File::Spec::Functions;
	my $lib =  File::Spec::Functions::catdir($ENV{BRICOLAGE_ROOT}, 'lib');
	unshift @INC, $lib;
	$ENV{PERL5LIB} = $lib;

	# Try again.
	eval { require Bric };
	die "Cannot locate Bricolage libraries.\n" if $@;
    }
};

# Get the options.
use Getopt::Std;
our ($opt_u, $opt_p);
getopts('u:p:');
# Set the db admin user and password to some reasonable defaults.
$opt_u ||= 'postgres';
$opt_p ||= 'postgres';

# Grab the Bricolage version number and put it into a v-string. We can eliminate
# the eval if, in the future, we change the Bric version number to an actual
# v-string.
my $old_version = eval "v$Bric::VERSION";

# Connect to the database.
my $ATTR =  { RaiseError => 1,
	      PrintError => 0,
	      AutoCommit => 1,
	      ChopBlanks => 1,
	      ShowErrorStatement => 1,
	      LongReadLen => 32768,
	      LongTruncOk => 0
};

$Bric::Util::DBI::dbh = DBI->connect(join(':', 'DBI', DBD_TYPE,
					  Bric::Util::DBI::DSN_STRING),
				     $opt_u, $opt_p, $ATTR);

=head1 EXPORTED FUNCTIONS

=head2 is_later()

  exit unless is_later($version_vstring);

B<Note:> This function is experimental.

This function compares the version number of the currently installed Bricolage
against a v-string argument that represents the new version we're upgrading to.
It does a bit of fancy work to ensure that it compares v-strings. It also tracks
a hash that lists exceptions to the basic rules of v-string comparison. For
example, if version 1.3.0 was released before 1.2.2, and you're "upgrading" from
1.2.2 to 1.3.0, this function will return false when called like this:

  exit unless is_later(1.3.0);

This is imperfect, however, as there may still be some scripts that need to be
run to upgrade from 1.2.2 to 1.3.0 (to take advantage of new features in 1.3.0,
for example), so use this function with care.

=cut

# Set up version exceptions.
my %except = (1.3.0, { 1.2.2, 1 });

sub is_later {
    my $new_version = shift;
    if ($new_version gt $old_version) {
	return 1 unless exists $except{$new_version}
	  && $except{$new_version}{$old_version};
    }
    return;
}

=head2 test_sql()

  exit if test_sql($sql);

Evaluates the SQL expression $sql against the Bricolage database. If there is an
error preparing or executing $sql, test_sql() will return false. If there are no
errors, it will return true. Use this function to determine whether the upgrades
your script is about to perform have already been performed.

For example, say you need to add a table C<foo_bar>. It's possible, for some
reason or other, that the table may already have been added -- perhaps your
script has already been run agaisnt the Bricolage installation. To determine
whether it has, call C<test_sql> with a SQL query that will throw an exception
if the table doesn't exist, but succeed if it does. If it does succeed, then
simply exit your script without continuing to update the database.

  exit if test_sql('SELECT * from foo_bar');

=cut

sub test_sql {
    eval {
	my $sth = prepare(shift);
	execute($sth);
    };
    return $@ ? 0 : 1;
}

=head2 fetch_sql()

  exit if fetch_sql($sql);

Evaluates the C<SELECT> SQL expression $sql against the Bricoalge database and
attempts to fetch a value from the query. If a value is successfully returned,
C<fetch_sql> returns true. Otherwise, it returns false. An exception will also
cause C<fetch_sql> to return false. Use this function to determine whether the
upgrades your script is about to perform have already been performed.

This function is similar in functionality to C<test_sql>, except that it doesn't
explicitly test for an exception. In other words, it's useful for testing for
database changes that may not trigger an exception even if they haven't been
run. For example, say you need to add a new value to the event_type table with
the key_name colunn value 'foo_grepped'. To determine whether this value has
already been entered into the database, you simply try to select it. Use
C<fetch_sql> to do this, as it will return true if it manages to fetch a value,
and false otherwise.

  exit if fetch_sql('SELECT name FROM event_type WHERE key_name = 'foo_grepped');

=cut

sub fetch_sql {
    my $val;
    eval {
	my $sth = prepare(shift);
	execute($sth);
	$val = fetch($sth);
    };
    return $val && !$@ ? 1 : 0;
}


=head2 do_sql()

  do_sql(@sql_statements);

This function takes a list of SQL statements and executes each in turn. For
each, it also sets the propper permissions for the Bricolage database user to be
able to access the tables and sequences it creates. Use this function to
actually make changes to the Bricolage database.

For example, say you need to add the table "soap_scum". Simply pass the proper
SQL to create the table to this function, and the SQL will be executed, and the
Bricolage databse user provided the proper permissions to access it.

  my $sql = qq{
      CREATE TABLE soap_scum (
          lname VARCHAR(64),
          fname VARCHAR(64),
          mname VARCHAR(64)
     )
  };

  do_sql($sql);

If for some reason there are any errors executing any of the SQL statements, all
the changes started with this call to do_sql() will be rolled back and an
exception thrown. Thus, any error will prevent any of the changes from affecting
the database unless all of the SQL statements succeed.

=cut

sub do_sql {
    begin();
    eval {
	my @objs;
	# Execute each SQL statement.
	foreach my $sql (@_) {
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
                ON     @objs
                TO     ${ \DBI_USER() }
            });
	    execute($grant);
	}
    };
    if (my $err = $@) {
	rollback();
	die "Update failed. Database was not affected. Error: $err";
    } else {
	commit();
    }
}

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler E<lt>david@wheeler.netE<gt>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric:Util::DBI|Bric::Util::DBI>

=cut
