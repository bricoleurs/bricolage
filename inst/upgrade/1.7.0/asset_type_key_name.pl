#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Just exit if these changes have already been made.
exit if test_sql "SELECT 1 WHERE EXISTS (SELECT key_name FROM element)";


do_sql
  # Add the new column.
  q/ALTER TABLE element ADD key_name VARCHAR(64)/,
;

update_all();

do_sql
  # Add a NOT NULL constraint.
  q{ALTER TABLE element
      ADD CONSTRAINT ck_key_name__null
      CHECK (key_name IS NOT NULL)},

  # Add an index.
  qq{CREATE UNIQUE INDEX udx_element__key_name ON element(LOWER(key_name))},

  # Drop the old index on the name column.
  qq{DROP INDEX udx_element__name}
  ;


sub update_all {
    my $get_name     = prepare('SELECT name FROM element');
    my $set_key_name = prepare('UPDATE element SET key_name=? WHERE name=?');

    my $name;
    execute($get_name);
    bind_columns($get_name, \$name);

    while (fetch($get_name)) {
        my $key_name = lc($name);
        $key_name =~ y/a-z0-9/_/cs;
        execute($set_key_name, $key_name, $name);
    }
}

__END__
