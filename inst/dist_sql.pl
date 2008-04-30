#!/usr/bin/perl -w

=head1 NAME

dist_sql.pl - script to create init scripts for the database sql files found
in sql directory depending in directory name

=head1 DESCRIPTION

This script is called during "make dist" to create the database init scripts
depending on the leading directory within sql (ex: sql/Pg will create inst/Pg.sql)

=head1 AUTHOR

Andrei Arsu <acidburn@asynet.ro>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;

my @rdbmss = map { s{^sql/}{}; $_ } grep { $_ !~ /[.]svn/ } @ARGV;

for my $rdbms (@rdbmss) {
    for my $type qw(sql val con) {
        my $dir = $type eq 'sql' ? '>' : '>>';
        system (
            "grep -vh '^--' `find sql/$rdbms -name '*.$type' | env "
            . "LANG= LANGUAGE= LC_ALL=POSIX sort` $dir inst/$rdbms.sql"
        ) and die "Errror concatenating *.$type files in sql/$rdbms into inst/$rdbms.sql";
    }
}
