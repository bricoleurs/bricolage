#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column 'field_type', 'key_name', undef, undef, 'TEXT';

my @cols = ('description');
for (qw(name key_name)) {
    push @cols, $_ unless test_column 'field_type', $_, undef, undef, 'TEXT';
}

if (db_version() ge '8.0') {
    # Just change the column types.
    do_sql map { "ALTER TABLE field_type ALTER COLUMN $_ TYPE TEXT" } @cols;
} else {
    # We have a lot more work to do for older versions of PostgreSQL.
    do_sql map { "DROP INDEX $_" }
        qw(udx_field_type__key_name__et_id
           idx_field_type__name__at_id
        );
    for my $col (@cols) {
        do_sql
            q{ALTER TABLE field_type RENAME $_ to __$_\__},
            q{ALTER TABLE field_type ADD COLUMN $_ TEXT},
            q{UPDATE field_type SET key_name = __$_\__},
            q{ALTER TABLE field_type DROP COLUMN __$_\__},
        ;
    }
    do_sql
        q{CREATE UNIQUE INDEX udx_field_type__key_name__et_id
          ON field_type(lower_text_num(key_name, element_type__id))},
        q{CREATE INDEX idx_field_type__name__at_id ON field_type(LOWER(name))},
}
