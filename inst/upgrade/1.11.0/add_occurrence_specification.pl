#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{SELECT 1 FROM field_type WHERE key_name = 'max_occurrence'};

do_sql q{ALTER TABLE field_type ADD max_occurrence INTEGER},
       q{UPDATE field_type SET max_occurrence='0' WHERE quantifier='1'},
       q{UPDATE field_type SET max_occurrence='1' WHERE quantifier='0'},

       q{ALTER TABLE field_type ADD min_occurrence INTEGER},
       q{UPDATE field_type SET min_occurrence='0' WHERE required='0'},
       q{UPDATE field_type SET min_occurrence='1' WHERE required='1'},

       q{ALTER TABLE field_type DROP COLUMN quantifier},
       q{ALTER TABLE field_type DROP COLUMN required},

       q{ALTER TABLE field_type ALTER COLUMN max_occurrence SET NOT NULL},
       q{ALTER TABLE field_type ALTER COLUMN min_occurrence SET NOT NULL},

       q{ALTER TABLE field_type ALTER COLUMN max_occurrence SET DEFAULT 0},
       q{ALTER TABLE field_type ALTER COLUMN min_occurrence SET DEFAULT 0},
;

# Add the table for subelements
do_sql q{CREATE TABLE subelement_type  (
    id              INTEGER        NOT NULL
                                   DEFAULT NEXTVAL('seq_subelement_type'),
    parent_id       INTEGER        NOT NULL,
    child_id        INTEGER        NOT NULL,
    place           INTEGER        NOT NULL DEFAULT 1,
    min_occurrence  INTEGER        NOT NULL DEFAULT 0,
    max_occurrence  INTEGER        NOT NULL DEFAULT 0,
    CONSTRAINT pk_subelement_type__id PRIMARY KEY (id)
)};
