#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Just exit if these changes have already been made.
exit if test_column 'story_container_tile', 'key_name';

do_sql
  # Add the new column.
  q/ALTER TABLE story_container_tile ADD key_name VARCHAR(64)/,
  q/ALTER TABLE media_container_tile ADD key_name VARCHAR(64)/,
;

update_all('story_container_tile');
update_all('media_container_tile');

do_sql
  # Add a NOT NULL constraint.
  q{ALTER TABLE story_container_tile ADD CONSTRAINT ck_sct_key_name__null
    CHECK (key_name IS NOT NULL)},

  q{ALTER TABLE media_container_tile ADD CONSTRAINT ck_mct_key_name__null
    CHECK (key_name IS NOT NULL)},

  # Add an index
  qq{CREATE INDEX idx_sc_tile__key_name
     ON story_container_tile(LOWER(key_name))},
  qq{CREATE INDEX idx_mc_tile__key_name
     ON media_container_tile(LOWER(key_name))},

  # Drop the old index on the name column.
  qq{DROP INDEX idx_sc_tile__name},
  qq{DROP INDEX idx_mc_tile__name}
  ;


sub update_all {
    my ($table) = @_;
    my $select     = prepare("SELECT DISTINCT name FROM $table");
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
