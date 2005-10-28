#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column 'story_instance', 'note';

for my $type (qw(story media formatting)) {
    do_sql
      # Add the note column.
      qq{ALTER TABLE $type\_instance ADD COLUMN  note TEXT},

      # Migrate notes for checked-in stories; version off by one.
      qq{
             UPDATE $type\_instance
             SET    note = val.short_val
             FROM   attr_$type AS type, attr_$type\_val as val
             WHERE  type.id = val.attr__id
                    AND val.object__id = $type\_instance.$type\__id
                    AND $type\_instance.version = type.name::text::int4 + 1
                    AND $type\_instance.checked_out = '0'
      },

      # Migrate notes for checked-out stories.
      qq{
             UPDATE $type\_instance
             SET    note = val.short_val
             FROM   attr_$type AS type, attr_$type\_val as val
             WHERE  type.id = val.attr__id
                    AND val.object__id = $type\_instance.$type\__id
                    AND $type\_instance.version = type.name::text::int4
                    AND $type\_instance.checked_out = '1'
       },

      # Add the index.
      qq{CREATE INDEX idx_$type\_instance__note
         ON     $type\_instance(note)
         WHERE  note IS NOT NULL},

      # Drop the attribute tables and sequences. W00t!
      qq{DROP TABLE attr_$type\_val},
      qq{DROP TABLE attr_$type\_meta},
      qq{DROP TABLE attr_$type},
      qq{DROP SEQUENCE seq_attr_$type\_meta},
      qq{DROP SEQUENCE seq_attr_$type\_val},
     ;
}
