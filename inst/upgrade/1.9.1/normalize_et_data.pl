#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if test_column 'at_data', 'cols';

# Create new columns
do_sql
    q{
        ALTER TABLE at_data
        ADD COLUMN  name        VARCHAR(32),
        ADD COLUMN  widget_type VARCHAR(30) DEFAULT 'text'
        ADD COLUMN  precision   SMALLINT,
        ADD COLUMN  cols        INTEGER,
        ADD COLUMN  rows        INTEGER,
        ADD COLUMN  length      INTEGER,
        ADD COLUMN  vals        TEXT,
        ADD COLUMN  multiple    BOOLEAN DEFAULT FALSE,
        ADD COLUMN  default_val TEXT,
    }
;

my $sel = prepare(q{
    SELECT attr.id, meta.name, meta.value
    FROM   attr_at_data attr, attr_at_data_meta meta
    WHERE  attr.id = meta.attr__id
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
           widget_type = ?
    WHERE  id          = ?
});

my @attr_names = qw(disp cols rows length vals multiple def type precision);

execute($sel);
bind_columns($sel, \my ($aid, $attr_name, $val));
my $last = -1;
my %attrs;
my %ints = map { $_ => 1 } qw(cols rows length precision);
while (fetch($sel)) {
    $val = $val ? 1 : 0 if $attr_name eq 'multiple';
    $val ||= 0 if $ints{$attr_name};
    if ($aid == $last) {
        $attrs{$attr_name} = $val;
        next;
    }
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
    q{
        ALTER TABLE  at_data
        ALTER COLUMN key_name    SET NOT NULL,
        ALTER COLUMN quantifier  SET NOT NULL,
        ALTER COLUMN name        SET NOT NULL,
        ALTER COLUMN multiple    SET NOT NULL,
        ALTER COLUMN cols        SET NOT NULL,
        ALTER COLUMN rows        SET NOT NULL,
        ALTER COLUMN length      SET NOT NULL,
        ALTER COLUMN widget_type SET NOT NULL
    },

    q{CREATE INDEX udx_atd__name__at_id ON at_data(LOWER(name))},
;
