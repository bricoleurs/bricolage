#!/usr/bin/perl -w

=head1 NAME

clone_db.pl - installation script to clone an existing database

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

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

print "\n\n==> Cloning Bricolage Database <==\n\n";

our $PG;
do "./postgres.db" or die "Failed to read postgres.db: $!";

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
    $> = $PG->{system_user_uid};
    die "Failed to switch EUID to $PG->{system_user_uid} ($sys_user).\n"
        unless $> == $PG->{system_user_uid};
}

$ENV{PGHOST} = $PG->{host_name} if $PG->{host_name};
$ENV{PGPORT} = $PG->{host_port} if $PG->{host_port};

# dump out database
system(catfile($PG->{bin_dir}, 'pg_dump') .
       " -U$PG->{root_user} -O -x $PG->{db_name} > inst/Pg.sql");

exit 0;
