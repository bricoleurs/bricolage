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

do_sql(q{
    ALTER TABLE grp
    ADD CONSTRAINT ck_grp__parent_id_not_eq_id
        CHECK (parent_id <> id)
});

__END__
