#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Check the version number.
#exit unless is_later(1.3.1);

exit if fetch_sql(qq{
    SELECT 1
    FROM   class
    WHERE  id = 11
           AND distributor = 1
});

=pod

=begin comment

In general, if you're adding a mover, you're going to want to do something like
this instead of the above:

  exit if fetch_sql(qq{
      SELECT 1
      FROM   class
      WHERE  id = [insert value specified in Class.val here]
  });

=end comment

=cut

do_sql(qq{
    UPDATE class
    SET    distributor = 1
    WHERE  id = 11
});

=pod

=begin comment

In general, if you're adding a mover, you're going to want to do something like
this instead of the above:

do_sql({
    INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name,
                       description, distributor)
    VALUES (11, 'ftp', 'Bric::Util::Trans::MyMover', 'MyMover',
            'MyMover Transport', 'Class with methods to move files via FTP.', 1)
});

=end comment

=cut
