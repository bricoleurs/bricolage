#!/usr/bin/perl -w

=head1 NAME

clone_sql_Pg.pl - installation script to clone an existing PG database

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$Id$

=head1 DESCRIPTION

This script is called during "make clone" to clone the Bricolage
database.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut


use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use File::Find qw(find);
use DBI;

our $DB;
do "./database.db" or die "Failed to read database.db: $!";

# Make sure that we don't overwrite the existing Pg.sql.
chdir 'dist';

# Switch to postgres system user
if (my $sys_user = $PG->{system_user}) {
    print "Becoming $sys_user...\n";

    # Make sure that the user can write out inst/Pg.sql.
    my $file = -e 'inst/Pg.sql' ? 'inst/Pg.sql' : 'inst';
    chown $PG->{system_user_uid}, -1, $file
        or die "Cannot chown $file to $PG->{system_user_uid} ($sys_user).\n";

    # Become the user.
    require Config;
    $> = $PG->{system_user_uid};
    $< = $DB->{system_user_uid} if $Config::Config{d_setruid};
    die "Failed to switch EUID to $PG->{system_user_uid} ($sys_user).\n"
        unless $> == $PG->{system_user_uid};
}

$ENV{PGHOST} = $DB->{host_name} if $DB->{host_name};
$ENV{PGPORT} = $DB->{host_port} if $DB->{host_port};

# dump out postgres database
system(catfile($DB->{bin_dir}, 'pg_dump') .
       " -U$DB->{root_user} -O -x $DB->{db_name} > Pg.sql");

printf "\n\n==> Finished cloning Bricolage Database <==\n\n";

exit 0;
