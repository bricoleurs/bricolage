#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Just exit if these changes have already been made.
exit if test_sql "SELECT 1 WHERE EXISTS (SELECT key_name FROM story_data_tile)";


do_sql
  # Add the new column.
  q/ALTER TABLE story_data_tile ADD key_name VARCHAR(64)/,
  q/ALTER TABLE media_data_tile ADD key_name VARCHAR(64)/,
;

update_all('story_data_tile');
update_all('media_data_tile');

do_sql
  # Add a NOT NULL constraint.
  q{ALTER TABLE story_data_tile ADD CONSTRAINT ck_sdt_key_name__null
    CHECK (key_name IS NOT NULL)},

  q{ALTER TABLE media_data_tile ADD CONSTRAINT ck_mdt_key_name__null
    CHECK (key_name IS NOT NULL)},

  # Add an index
  qq{CREATE INDEX idx_story_data_tile__key_name
     ON story_data_tile(LOWER(key_name))},
  qq{CREATE INDEX idx_media_data_tile__key_name
     ON media_data_tile(LOWER(key_name))},

  # Drop the old index on the name column.
  qq{DROP INDEX idx_story_data_tile__name},
  qq{DROP INDEX idx_media_data_tile__name}
  ;

sub update_all {
    my ($table) = @_;
    my $select = prepare("SELECT DISTINCT name FROM $table");
    my $update = prepare("UPDATE $table SET key_name = ? WHERE name = ?");

    my $name;
    execute($select);
    bind_columns($select, \$name);

    while (fetch($select)) {
        my $key_name = lc($name);
        $key_name =~ y/a-z0-9/_/cs;
        execute($update, $key_name, $name);
    }
}

__END__
