#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(qq{
    SELECT 1
    FROM   pg_relcheck
    WHERE  rcname = 'ck_grp__parent_id_not_eq_id'
});

if (fetch_sql('select 1 from grp where id = parent_id')) {
    print "\n\n", '#' x 66, "\n",
      "# Cannot upgrade because you have circular references in the grp #\n",
      "# table in the database. Please resolve this conflict and then   #\n",
      "# try to upgrade again.                                          #\n",
      '#' x 66, "\n\n";
    exit 1;
}


do_sql(q{
    ALTER TABLE grp
    ADD CONSTRAINT ck_grp__parent_id_not_eq_id
        CHECK (parent_id <> id)
});

__END__
