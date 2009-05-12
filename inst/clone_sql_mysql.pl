#!/usr/bin/perl -w

=head1 Name

clone_sql_mysql.pl - installation script to clone an existing mysql database 

=head1 Description

This script is called during "make clone" to clone the Bricolage
database.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use File::Spec::Functions;

print "\n\n==> Cloning Bricolage Database <==\n\n";

my $DB = do './database.db' or die "Failed to read database.db: $!\n";

# Make sure that we don't overwrite the existing Pg.sql.
chdir 'dist';
my $file = catfile qw( inst mysql.sql);

my @dbclone = (catfile($DB->{bin_dir}, 'mysqldump'));
push @dbclone, '-h', $DB->{host_name} if $DB->{host_name};
push @dbclone, '-P', $DB->{host_port} if $DB->{host_port};
push @dbclone, (
    '-u', $DB->{root_user},
    ( $DB->{root_pass} ? "-p$DB->{root_pass}" : ()),
    '-r', $file,
    $DB->{db_name},
);

# dump out mysql database
system( @dbclone ) and die 'Error executing `' . join(' ', @dbclone), "`\n";

printf "\n\n==> Finished cloning Bricolage Database <==\n\n";
