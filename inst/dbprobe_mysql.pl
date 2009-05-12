#!/usr/bin/perl -w

=head1 Name

dbprobe_mysql.pl - installation script to probe MySQL configuration

=head1 Description

This script is called during "make" to probe the MySQL
configuration.  It accomplishes this by parsing the output from
mysql_config and asking the user questions.  Output collected in
"database.db".

=head1 Author

Andrei Arsu <acidburn@asynet.ro>

derived from code by Sam Tregar <stregar@about-inc.com>

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

print "\n\n==> Probing MySQL Configuration <==\n\n";

our %DB;

my $passwordsize = 10;
my @alphanumeric = ('a'..'z', 'A'..'Z', 0..9);
my $randpassword = join '', map $alphanumeric[rand @alphanumeric], 0..$passwordsize;

our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

# setup some defaults
$DB{db_type} = $REQ->{DB_TYPE};
$DB{root_user} = get_default("MYSQL_SUPERUSER") || 'root';
$DB{root_pass} = $ENV{MYSQL_SUPERPASS} || '';
$DB{sys_user}  = get_default("MYSQL_BRICUSER") || 'bric';
$DB{sys_pass}  = $QUIET ? $randpassword : 'NONE';
$DB{db_name}   = get_default("MYSQL_DB") || 'bric';
$DB{host_name} = $ENV{MYSQL_HOSTNAME} || '';
$DB{host_port} = $ENV{MYSQL_HOSTPASS} || '';
$DB{version} = '';

get_bin_dir();
get_mysql();
get_version();
get_host();
get_users();
get_server_version();

# all done, dump out mysql database, announce success and exit
open(OUT, ">database.db") or die "Unable to open database.db : $!";
print OUT Data::Dumper->Dump([\%DB],['DB']);
close OUT;

print "\n\n==> Finished Probing MySQL Configuration <==\n\n";
exit 0;

sub get_bin_dir {
    print "Extracting mysql bin dir from $REQ->{MYSQL_CONFIG}.\n";

    my $data = $REQ->{MYSQL_CONFIG};
    chomp($data);
    $data =~ s/mysql_config//;
    $DB{bin_dir} = $data;
}

sub get_mysql {
    print "Finding mysql.\n";
    my $mysql = catfile($DB{bin_dir}, 'mysql');
    hard_fail("Unable to locate mysql executable.")
    unless -e $mysql and -x $mysql;

    $DB{exec} = $mysql;
}

sub get_version {
    print "Finding MySQL version.\n";
    my $data = `$REQ->{MYSQL_CONFIG} --version`;
    hard_fail("Unable to extract needed data from $REQ->{MYSQL_CONFIG}.")
      unless $data;
    chomp $data;
    $DB{client_version} = $data;
    print $data;
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
        unless ($DB{host_name}) {
            $DB{system_user} = $DB{root_user};
            while(1) {
                ask_confirm("MySQL System Username", \$DB{system_user}, $QUIET);
                $DB{system_user_uid} = (getpwnam($DB{system_user}))[2];
                last if defined $DB{system_user_uid};
                print "User \"$DB{system_user}\" not found!  This user must exist ".
                    "on your system.\n";
            }
            ask_password(qq{Password for MySQL root user "$DB{root_user}"},
                         \$DB{root_pass}, $QUIET);

        }
    }

    while(1) {
        ask_confirm("Bricolage MySQL Username", \$DB{sys_user}, $QUIET);
        if ($DB{sys_user} eq $DB{root_user}) {
            print "Bricolage MySQL User cannot be the same as the Postgres Root User.\n";
        } else {
            last;
        }
    }

    ask_password(qq{Password for MySQL user "$DB{sys_user}"}, \$DB{sys_pass}, $QUIET);
    ask_confirm("Bricolage Database Name", \$DB{db_name}, $QUIET);
}

# ask for host specifics
sub get_host {
    print "\n";
    ask_confirm(
        "MySQL Database Server Hostname (default is unset, i.e., localhost)",
        \$DB{host_name},
        $QUIET,
    );
    ask_confirm(
        "MySQL Database Server Port Number (default is unset, i.e., 3306)",
        \$DB{host_port},
        $QUIET,
    );
}

# ask for host specifics
sub get_server_version {
    print "\n";
    my $cmd = "$DB{exec} ";
    if ($DB{create_db}) {
        $cmd .= "-u $DB{root_user} ";
        $cmd .= "-p$DB{root_pass} " if $DB{root_pass};
    }
    else {
        $cmd .= "-u $DB{sys_user} ";
        $cmd .= "-p$DB{sys_pass} " if $DB{sys_pass};
    }
    $cmd .= "-h $DB{host_name} " if $DB{host_name};
    $cmd .= "-P $DB{host_port} " if $DB{host_port};
    my $data = `$cmd -e status | grep 'Server version:'`;
    hard_fail("Could not connect to database server")
      unless $data;
    $data=~s/Server version:\s*//;
    my ($x, $y, $z) = $data=~ /(\d+)\.(\d+)(?:\.(\d+))?/;
    return soft_fail("Failed to parse MySQL server version from string ",
                      "\"$data\".")
        unless defined $x and defined $y;
    $z ||= 0;
    return soft_fail("Found old version of MySQL server: $x.$y.$z - ",
                     "5.0.3 or greater required.")
    unless $x > 5 or ($x == 5 and ( $y >= 1 or $z >= 3));
    print " Found acceptable version of MySQL server: $x.$y.$z.\n";
    $DB{server_version}="$x.$y.$z";
}
