#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# This is similar to an upgrade done for 1.7.0, but is designed to fix bad
# key names created by autopopulated fields defined since that upgrade.

my $get_key_name = prepare('
  SELECT id, element__id, key_name
  FROM   at_data
  WHERE  autopopulated = 1
');

my $set_key_name = prepare('
  UPDATE at_data
  SET    key_name = ?
  WHERE id = ?
');

my ($id, $eid, $name, %seen);
execute($get_key_name);
bind_columns($get_key_name, \$id, \$eid, \$name);

while (fetch($get_key_name)) {
    my $key_name = lc $name;
    $key_name =~ y/a-z0-9/_/cs;
    $key_name = incr_kn($name, $eid, $key_name, \%seen)
      if $seen{"$eid|$key_name"};
    execute($set_key_name, $key_name, $id);
    $seen{"$eid|$key_name"} = 1;
}

sub incr_kn {
    my ($name, $eid, $kn, $seen) = @_;
    my $x = '2';
    while ($seen->{"$eid|$kn$x"}) {
        $x++;
    }
    print qq{
    ##########################################################################

    WARNING! The element with the ID "$eid" has a field named "$name" that
    creates the key name "$kn". However, this key name is a
    duplicate of another key name for a field in that element. To get around
    this problem, the key name for element "$eid" has been set to "$kn$x". If
    this is not acceptable to you, you can change it to another value manually
    by updating the database directly with:

       UPDATE at_data
       SET    key_name = 'new_key'
       WHERE  key_name = '$kn$x';

    To fist see what other fields exist for this element and what their key
    names are, execute this query:

      SELECT key_name
      FROM   at_data
      WHERE  element__id = $eid;

    ##########################################################################

};
    return "$kn$x";
}
