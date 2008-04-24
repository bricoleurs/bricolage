#!/usr/bin/perl -w

=head1 NAME

dist_sql.pl - script to create init scripts for the database sql files found 
in sql directory depending in directory name

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$Id$

=head1 DESCRIPTION

This script is called during "make dist" to create the database init scripts
depending on the leading directory within sql (ex: sql/Pg will create inst/Pg.sql)

=head1 AUTHOR

Andrei Arsu <acidburn@asynet.ro>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;

our @SQL;

get_db_sql();
create_sqls();

#all done
exit 0;

sub get_db_sql {
    my $temp;
    while (@ARGV) {
        $temp=shift @ARGV;
        $temp=~s/sql\///;
        unshift @SQL, $temp;
    }    
}

sub create_sqls {
    my ($temp,$temp1);
    while (@SQL) {
        $temp=shift @SQL;
	system ("grep -vh '^--' `find sql/".$temp ." -name '*.sql' | env "
	         . "LANG= LANGUAGE= LC_ALL=POSIX sort` > inst/".$temp.".sql");
	system ("grep -vh '^--' `find sql/".$temp ." -name '*.val' | env "
	         . "LANG= LANGUAGE= LC_ALL=POSIX sort` >> inst/".$temp.".sql");
	system ("grep -vh '^--' `find sql/".$temp ." -name '*.con' | env "
	         . "LANG= LANGUAGE= LC_ALL=POSIX sort` >> inst/".$temp.".sql");
    }    
}

