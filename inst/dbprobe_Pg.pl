#!/usr/bin/perl -w

=head1 Name

dbprobe_pg.pl - installation script to probe PostgreSQL configuration

=head1 Description

This script is called during "make" to probe the PostgreSQL
configuration.  It accomplishes this by parsing the output from
pg_config and asking the user questions.  Output collected in
"database.db".

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions;
use Data::Dumper;

# check whether questions should be asked
my $QUIET = ($ARGV[0] and $ARGV[0] eq 'QUIET') || $ENV{DEVELOPER};

print "\n\n==> Probing PostgreSQL Configuration <==\n\n";

our %DB;

my $passwordsize = 10;
my @alphanumeric = ('a'..'z', 'A'..'Z', 0..9);
my $randpassword = join '', map $alphanumeric[rand @alphanumeric], 0..$passwordsize;

our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

# setup some defaults
$DB{db_type}   = $REQ->{DB_TYPE};
$DB{root_user} = get_default('PG_SUPERUSER') || 'postgres';
$DB{root_pass} = $ENV{PG_SUPERPASS} || get_default( 'PG_SUPERPASS') || '';
$DB{sys_user}  = get_default('PG_BRICUSER') || 'bric';
$DB{sys_pass}  = $QUIET ? $randpassword : 'NONE';
$DB{db_name}   = get_default('PG_DB') || 'bric';
$DB{host_name} = $ENV{PG_HOSTNAME} || get_default('PG_HOSTNAME') || '';
$DB{host_port} = $ENV{PG_HOSTPASS} || get_default('PG_HOSTPASS') || '';
$DB{version} = '';

get_include_dir();
get_lib_dir();
get_bin_dir();
get_psql();
get_version();
get_host();
get_users();

# all done, dump out postgresql database, announce success and exit
open(OUT, ">database.db") or die "Unable to open database.db : $!";
print OUT Data::Dumper->Dump([\%DB],['DB']);
close OUT;

print "\n\n==> Finished Probing PostgreSQL Configuration <==\n\n";
exit 0;


sub get_include_dir {
    print "Extracting postgres include dir from $REQ->{PG_CONFIG}.\n";

    my $data = `$REQ->{PG_CONFIG} --includedir`;
    hard_fail("Unable to extract needed data from $REQ->{PG_CONFIG}.")
    unless $data;
    chomp($data);
    $DB{include_dir} = $data;
}

sub get_lib_dir {
    print "Extracting postgres lib dir from $REQ->{PG_CONFIG}.\n";

    my $data = `$REQ->{PG_CONFIG} --libdir`;
    hard_fail("Unable to extract needed data from $REQ->{PG_CONFIG}.")
    unless $data;
    chomp($data);
    $DB{lib_dir} = $data;
}

sub get_bin_dir {
    print "Extracting postgres bin dir from $REQ->{PG_CONFIG}.\n";

    my $data = `$REQ->{PG_CONFIG} --bindir`;
    hard_fail("Unable to extract needed data from $REQ->{PG_CONFIG}.")
    unless $data;
    chomp($data);
    $DB{bin_dir} = $data;
}

sub get_psql {
    print "Finding psql.\n";
    my $psql = catfile($DB{bin_dir}, 'psql');
    hard_fail("Unable to locate psql executable.")
    unless -e $psql and -x $psql;
    $DB{exec} = $psql;
}

sub get_version {
    print "Finding PostgreSQL version.\n";
    my $data = `$REQ->{PG_CONFIG} --version`;
    hard_fail("Unable to extract needed data from $REQ->{PG_CONFIG}.")
      unless $data;
    chomp $data;
    $data =~ s/\s*PostgreSQL\s+(\d\.\d(\.\d)?).*/$1/;
    $DB{version} = $data;
}

# ask the user for user settings
sub get_users {
    print "\n";
    $DB{create_db} = ask_yesno(
        'Should the installer connect to the database as a super user?',
        get_default('CREATE_DB') || 1,
        $QUIET
    );
    if ($DB{create_db}) {
        print "\n";
        ask_confirm('Postgres Super Username', \$DB{root_user}, $QUIET);
        ask_password(qq{Password for super user "$DB{root_user}"}, \$DB{root_pass}, $QUIET);

        unless ($DB{host_name}) {
            print "\n";
            print "Should the installer become the Postgres system user?\n";
            if ( ask_yesno(
                'This requires that the installer be run as root.',
                get_default('PG_BECOME_USER') || 0,
                $QUIET,
            )) {
                $DB{system_user} = $DB{root_user};
                while(1) {
                    ask_confirm('Postgres System Username', \$DB{system_user}, $QUIET);
                    $DB{system_user_uid} = (getpwnam($DB{system_user}))[2];
                    last if defined $DB{system_user_uid};
                    print "User \"$DB{system_user}\" not found!  This user must exist ".
                        "on your system.\n";
                }
            }
        }
    }

    while(1) {
        ask_confirm("Bricolage Postgres Username", \$DB{sys_user}, $QUIET);
        if ($DB{sys_user} eq $DB{root_user}) {
            print "Bricolage Postgres User cannot be the same as the Postgres Root User.\n";
        } else {
            last;
        }
    }

    ask_password(qq{Password for Postgres user "$DB{sys_user}"}, \$DB{sys_pass}, $QUIET);
    ask_confirm("Bricolage Database Name", \$DB{db_name}, $QUIET);
}

# ask for host specifics
sub get_host {
    print "\n";
    ask_confirm(
        "Postgres Database Server Hostname (default is unset, i.e., localhost)",
        \$DB{host_name},
        $QUIET,
    );
    ask_confirm(
        "Postgres Database Server Port Number (default is unset, i.e., 5432)",
        \$DB{host_port},
        $QUIET,
    );
}
