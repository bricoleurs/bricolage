#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Just exit if these changes have already been made.
exit if test_column 'element', 'key_name';

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
    my $get_name     = prepare('SELECT id, name FROM element');
    my $set_key_name = prepare('UPDATE element SET key_name = ? WHERE id = ?');

    my ($id, $name, %seen);
    execute($get_name);
    bind_columns($get_name, \$id, \$name);

    while (fetch($get_name)) {
        my $key_name = lc $name;
        $key_name =~ y/a-z0-9/_/cs;
        $key_name = incr_kn($name, $key_name, \%seen)
          if $seen{$key_name};
        execute($set_key_name, $key_name, $id);
        $seen{$key_name} = 1;
    }
}

sub incr_kn {
    my ($name, $kn, $seen) = @_;
    my $x = '2';
    while ($seen->{"$kn$x"}) {
        $x++;
    }
    print qq{
    ##########################################################################

    WARNING! The element with the name "$name" creates the key name "$kn".
    However, this key name is a duplicate of another key name for anohter
    element. To get around this problem, the key name for element "$name"
    has been set to "$kn$x". If this is not acceptable to you, you can change
    it to another value manually by updating the database directly with:

       UPDATE element
       SET    key_name = 'new_key'
       WHERE  key_name = '$kn$x';

    To fist see what other elements exist and what their key names are,
    execute this query:

      SELECT key_name
      FROM   element;

    ##########################################################################

};
    return "$kn$x";
}

__END__
