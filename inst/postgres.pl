#!/usr/bin/perl -w

=head1 NAME

postgres.pl - installation script to probe PostgreSQL configuration

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2003-10-10 19:21:16 $

=head1 DESCRIPTION

This script is called during "make" to probe the PostgreSQL
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
$PG{host_name} = 'localhost';
$PG{host_port} = '';

our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

get_include_dir();
get_lib_dir();
get_bin_dir();
get_psql();
get_users();
get_host();

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

sub get_psql {
    print "Finding psql.\n";
    my $psql = catfile($PG{bin_dir}, 'psql');
    hard_fail("Unable to locate psql executable.")
	unless -e $psql and -x $psql;
    $PG{psql} = $psql;
}

# ask the user for user settings
sub get_users {
    print "\n";
    ask_confirm("Postgres Root Username", \$PG{root_user});
    ask_confirm("Postgres Root Password (leave empty for no password)", 
		\$PG{root_pass});

    while(1) {
	$PG{system_user} = $PG{root_user};
	ask_confirm("Postgres System Username", \$PG{system_user});
	$PG{system_user_uid} = (getpwnam($PG{system_user}))[2];
	last if defined $PG{system_user_uid};
	print "User \"$PG{system_user}\" not found!  This user must exist ".
	    "on your system.\n";
    }

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

# ask for host specifics
sub get_host {
    print "\n";
    ask_confirm("Postgres Database Server Hostname", \$PG{host_name});
    ask_confirm("Postgres Database Server Port Number", \$PG{host_port});
}

