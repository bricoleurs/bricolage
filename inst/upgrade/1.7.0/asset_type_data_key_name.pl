#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if these changes have already been made.
exit if test_sql "SELECT 1 WHERE EXISTS (SELECT key_name FROM at_data)";

do_sql
  # Rename the column.
  q/ALTER TABLE at_data RENAME name TO key_name/,
;

update_all();

sub update_all {
    my $get_key_name = prepare('SELECT key_name FROM at_data');
    my $set_key_name = prepare('UPDATE at_name SET key_name=? WHERE key_name=?');

    my $name;
    execute($get_key_name);
    bind_columns($get_key_name, \$name);

    while (fetch($get_key_name)) {
        my $key_name = lc($name);
        $key_name =~ y/a-z/_/cs;
        execute($set_key_name, $key_name, $name);
    }
}

__END__

