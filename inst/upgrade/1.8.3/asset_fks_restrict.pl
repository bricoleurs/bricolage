#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

#exit if test_foreign_key 'story', 'fk_source__story', 'r';

for my $table (qw(story media)) {
    for my $attr (qw(source usr element workflow site desk)) {
        do_sql
          "ALTER TABLE $table DROP CONSTRAINT fk_$attr\__$table",
          "ALTER TABLE $table
           ADD CONSTRAINT fk_$attr\__$table FOREIGN KEY ($attr\__id)
           REFERENCES $attr(id) ON DELETE RESTRICT";
    }

    do_sql
      "ALTER TABLE $table DROP CONSTRAINT fk_$table\__$table\_id",
      "ALTER TABLE $table
       ADD CONSTRAINT fk_$table\__$table\_id FOREIGN KEY (alias_id)
       REFERENCES $table(id) ON DELETE RESTRICT";
}

for my $attr (qw(usr output_channel element category workflow site desk)) {
    my $fkt = $attr eq 'output_channel' ? 'fromatting' : 'formatting';
    do_sql
      "ALTER TABLE formatting DROP CONSTRAINT fk_$attr\__$fkt",
      "ALTER TABLE formatting
       ADD CONSTRAINT fk_$attr\__formatting FOREIGN KEY ($attr\__id)
       REFERENCES $attr(id) ON DELETE RESTRICT";
}
