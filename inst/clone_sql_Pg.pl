#!/usr/bin/perl -w

=head1 Name

clone_sql_Pg.pl - installation script to clone an existing PG database

=head1 Description

This script is called during "make clone" to clone the Bricolage
database.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut


use FindBin;
use File::Spec::Functions qw(:ALL);

print "\n\n==> Cloning Bricolage Database <==\n\n";

our $DB;
do "./database.db" or die "Failed to read database.db: $!";

# Make sure that we don't overwrite the existing Pg.sql.
chdir 'dist';
my $file = 'inst/Pg.sql';

# Switch to postgres system user
if (my $sys_user = $DB->{system_user}) {
    print "Becoming $sys_user...\n";

    # Make sure that the user can write out inst/Pg.sql.
    my $to_chown = -e 'inst/Pg.sql' ? 'inst/Pg.sql' : 'inst';
    chown $DB->{system_user_uid}, -1, $to_chown
        or die "Cannot chown $to_chown to $DB->{system_user_uid} ($sys_user).\n";

    # Become the user.
    require Config;
    $> = $DB->{system_user_uid};
    $< = $DB->{system_user_uid} if $Config::Config{d_setruid};
    die "Failed to switch EUID to $DB->{system_user_uid} ($sys_user).\n"
        unless $> == $DB->{system_user_uid};
}

$ENV{PGHOST} = $DB->{host_name} if $DB->{host_name};
$ENV{PGPORT} = $DB->{host_port} if $DB->{host_port};

# dump out postgres database
my @pgdump = (
    catfile($DB->{bin_dir}, 'pg_dump'),
    '-U', $DB->{root_user},
    '-f', $file,
    '-O',
    '-x',
    $DB->{db_name},
);

# dump out postgres database
system( @pgdump ) and die 'Error executing `' . join(' ', @pgdump), "`\n";
print "\n\n==> Finished cloning Bricolage Database <==\n\n";
