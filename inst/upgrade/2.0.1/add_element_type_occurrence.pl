#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Modify tables for subelement occurrence
exit if test_column 'subelement_type', 'parent_id';

do_sql
  q{CREATE SEQUENCE seq_subelement_type START 1024},

  q{CREATE TABLE subelement_type  (
    id              INTEGER        NOT NULL
                                   DEFAULT NEXTVAL('seq_subelement_type'),
    parent_id       INTEGER        NOT NULL,
    child_id        INTEGER        NOT NULL,
    place           INTEGER        NOT NULL DEFAULT 1,
    min_occurrence  INTEGER        NOT NULL DEFAULT 0,
    max_occurrence  INTEGER        NOT NULL DEFAULT 0,
    CONSTRAINT pk_subelement_type__id PRIMARY KEY (id)
)},

  q{CREATE INDEX fkx_element_type__subelement__parent_id ON subelement_type(parent_id)},
  q{CREATE INDEX fkx_element_type__subelement__child_id ON subelement_type(child_id)},
  q{CREATE UNIQUE INDEX udx_subelement_type__parent__child ON subelement_type(parent_id, child_id)},

  q{ALTER TABLE subelement_type ADD
    CONSTRAINT fkx_element_type__subelement__parent_id FOREIGN KEY (parent_id)
    REFERENCES element_type(id) ON DELETE CASCADE},

  q{ALTER TABLE subelement_type ADD
    CONSTRAINT fkx_element_type__subelement__child_id FOREIGN KEY (child_id)
    REFERENCES element_type(id) ON DELETE CASCADE},


;

my $sel = prepare(q{
    SELECT et.id AS parent_id, etm.object_id AS child_id
    FROM   element_type et, member m, element_type_member etm
    WHERE  et.et_grp__id = m.grp__id
            AND m.id = etm.member__id
    ORDER BY parent_id, child_id
});

my $ins = prepare(q{
    INSERT INTO subelement_type (parent_id, child_id, place, min_occurrence, max_occurrence)
    VALUES (?, ?, ?, 0, 0)
});

execute($sel);
bind_columns($sel, \my ($parent_id, $child_id));
my %seen;
while (fetch($sel)) {
    execute($ins, $parent_id, $child_id, ++$seen{$parent_id});
}
