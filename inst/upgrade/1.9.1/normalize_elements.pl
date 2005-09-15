#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

for my $doc_type (qw(story media)) {
    next unless test_column "$doc_type\_container_tile", 'name';
    do_sql qq{
        ALTER TABLE $doc_type\_container_tile
        DROP COLUMN key_name,
        DROP COLUMN name,
        DROP COLUMN description,
        ALTER COLUMN id SET DEFAULT NEXTVAL('seq_$doc_type\_container_tile')
    },

   qq{
        ALTER TABLE $doc_type\_data_tile
        DROP COLUMN key_name,
        DROP COLUMN name,
        DROP COLUMN description
    },
}
