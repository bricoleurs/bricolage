#!/usr/bin/perl -w

=head1 NAME

postgres.pl - installation script to probe PostgreSQL configuration

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2002-04-08 20:00:14 $

=head1 DESCRIPTION

This script is called during "make" to probe the PostrgeSQL
configuration.  It accomplishes this by parsing the output from
pg_config and asking the user questions.  Output collected in
"postgres.db".

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions;
use Data::Dumper;

print "\n\n==> Probing PostgreSQL Configuration <==\n\n";

our %PG;

# setup some defaults
$PG{root_user} = 'postgres';
$PG{root_pass} = '';
$PG{sys_user}  = 'bric';
$PG{sys_pass}  = 'NONE';
$PG{db_name}   = 'bric';

our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

get_include_dir();
get_lib_dir();
get_bin_dir();
get_users();

# all done, dump out apache database, announce success and exit
open(OUT, ">postgres.db") or die "Unable to open postgres.db : $!";
print OUT Data::Dumper->Dump([\%PG],['PG']);
close OUT;

print "\n\n==> Finished Probing PostgreSQL Configuration <==\n\n";
exit 0;


sub get_include_dir {
    print "Extracting postgres include dir from $REQ->{PG_CONFIG}.\n";

    my $data = `$REQ->{PG_CONFIG} --includedir`;
    hard_fail("Unable to extract needed data from $REQ->{PG_CONFIG}.")
	unless $data;
    chomp($data);
    $PG{include_dir} = $data;
}

sub get_lib_dir {
    print "Extracting postgres lib dir from $REQ->{PG_CONFIG}.\n";

    my $data = `$REQ->{PG_CONFIG} --libdir`;
    hard_fail("Unable to extract needed data from $REQ->{PG_CONFIG}.")
	unless $data;
    chomp($data);
    $PG{lib_dir} = $data;
}

sub get_bin_dir {
    print "Extracting postgres bin dir from $REQ->{PG_CONFIG}.\n";

    my $data = `$REQ->{PG_CONFIG} --bindir`;
    hard_fail("Unable to extract needed data from $REQ->{PG_CONFIG}.")
	unless $data;
    chomp($data);
    $PG{bin_dir} = $data;
}

# ask the user for user settings
sub get_users {
    print "\n";
    ask_confirm("Postgres Root Username", \$PG{root_user});
    ask_confirm("Postgres Root Password (leave empty for no password)", 
		\$PG{root_pass});

    # make sure this account is really a root user and that postgres
    # is really running.
    print "Checking provided Postgres Root Username and Password...\n";
    open(PSQL, "|$PG{bin_dir}/psql -U $PG{root_user} -A -q template1 > psql.tmp")
	or die "Unable to run psql using $PG{bin_dir}/psql: $!";
    print PSQL qq{\\x 
                  SELECT 1 as super
                  FROM pg_shadow 
                  WHERE usename='$PG{root_user}' AND usesuper;
                 };
    close(PSQL);

    # check query results
    my $result = "";
    if (open(TMP, "psql.tmp")) {
	$result = join('',<TMP>);
	close(TMP);
	unlink("psql.tmp");
    }

    hard_fail(<<END) unless $result =~ /super\|1/;
Unable to verify Postgres Root Username and Password.  You should
check that Postgres is running and verify that the username and
password you provided are the Postgres Root Username and Password
on your system.
END
    print "Ok.\n\n";

    while(1) {
      ask_confirm("Bricolage Postgres Username", \$PG{sys_user});
      if ($PG{sys_user} eq $PG{root_user}) {
	print "Bricolage Postgres User cannot be the same as the Postgres Root User.\n";
      } else {
	last;
      }
    }

    ask_confirm("Bricolage Postgres Password", \$PG{sys_pass});
    ask_confirm("Bricolage Database Name", \$PG{db_name});
}
