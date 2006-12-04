#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit unless test_table 'at_data';
exit if test_column 'at_data', 'cols';

# Create new columns
do_sql
    map({ qq{ALTER TABLE at_data $_} }
        q{ADD COLUMN  name        TEXT},
        q{ADD COLUMN  widget_type VARCHAR(30)},
        q{ALTER COLUMN widget_type SET DEFAULT 'text'},
        q{ADD COLUMN  precision   SMALLINT},
        q{ADD COLUMN  cols        INTEGER},
        q{ADD COLUMN  rows        INTEGER},
        q{ADD COLUMN  length      INTEGER},
        q{ADD COLUMN  vals        TEXT},
        q{ADD COLUMN  multiple    BOOLEAN},
        q{ALTER COLUMN multiple SET DEFAULT FALSE},
        q{ADD COLUMN  default_val TEXT},
    )
;

if (db_version() ge '8.0') {
    do_sql 'ALTER TABLE at_data ALTER COLUMN key_name TYPE TEXT';
} else {
    do_sql
        q{DROP INDEX udx_atd__key_name__at_id},
        q{ALTER TABLE at_data RENAME key_name to __key_name__},
        q{ALTER TABLE at_data ADD COLUMN key_name TEXT},
        q{UPDATE at_data SET key_name = __key_name__},
        q{CREATE UNIQUE INDEX udx_atd__key_name__at_id
          ON at_data(lower_text_num(key_name, element__id))},
        q{ALTER TABLE at_data DROP COLUMN __key_name__},
    ;
}

my $sel = prepare(q{
    SELECT attr.id, coalesce(val.short_val, val.blob_val, val.date_val::text),
           meta.name, meta.value
    FROM   attr_at_data attr, attr_at_data_val val, attr_at_data_meta meta
    WHERE  attr.id = val.attr__id AND attr.id = meta.attr__id
           AND attr.name = 'html_info'
           AND attr.active = '1'
           AND meta.active = '1'
           AND meta.name NOT IN ('pos', 'maxlength')
    ORDER  BY attr.id
});

my $update = prepare(q{
    UPDATE at_data
    SET    name        = ?,
           cols        = ?,
           rows        = ?,
           length      = ?,
           vals        = ?,
           multiple    = ?,
           default_val = ?,
           precision   = ?,
           widget_type = ?,
           quantifier  = coalesce(quantifier, '0')
    WHERE  id          = ?
});

my @attr_names = qw(disp cols rows length vals multiple def precision type);

execute($sel);
bind_columns($sel, \my ($aid, $default, $attr_name, $val));
my $last = -1;
my %attrs;
my %ints = map { $_ => 1 } qw(cols rows length precision);
while (fetch($sel)) {
    $attr_name = 'def' if $attr_name eq 'value';
    $val = $val ? '1' : '0' if $attr_name eq 'multiple';
    $val ||= '0' if $ints{$attr_name};
    if ($aid == $last) {
        $attrs{$attr_name} = $val;
        next;
    }
    $attrs{def} = $default unless exists $attrs{def};
    execute($update, @attrs{@attr_names}, $last) unless $last == -1;
    %attrs = ($attr_name => $val);
    $last  = $aid;
}
execute($update, @attrs{@attr_names}, $last);

# Delete old attrs, populate missing attrs, and add NOT NULL constraints.
do_sql
    q{  DELETE FROM attr_at_data                WHERE name = 'html_info'    },
    q{  UPDATE at_data SET multiple = '0'       WHERE multiple    IS NULL   },
    q{  UPDATE at_data SET cols     = 0         WHERE cols        IS NULL   },
    q{  UPDATE at_data SET rows     = 0         WHERE rows        IS NULL   },
    q{  UPDATE at_data SET length   = 0         WHERE length      IS NULL   },
    q{  UPDATE at_data SET name     = key_name  WHERE name        IS NULL   },
    q{  UPDATE at_data SET widget_type = 'text' WHERE widget_type IS NULL   },
    map( { qq{ALTER TABLE  at_data $_}}
        q{ALTER COLUMN key_name    SET NOT NULL},
        q{ALTER COLUMN quantifier  SET NOT NULL},
        q{ALTER COLUMN name        SET NOT NULL},
        q{ALTER COLUMN multiple    SET NOT NULL},
        q{ALTER COLUMN cols        SET NOT NULL},
        q{ALTER COLUMN rows        SET NOT NULL},
        q{ALTER COLUMN length      SET NOT NULL},
        q{ALTER COLUMN widget_type SET NOT NULL},
    ),
    q{CREATE INDEX udx_atd__name__at_id ON at_data(LOWER(name))},
;
