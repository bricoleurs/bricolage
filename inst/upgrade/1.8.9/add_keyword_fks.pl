#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_constraint 'category_keyword', 'fk_keyword__category_keyword';

for my $thing (qw(story media category)) {
    do_sql
        qq{ DELETE from $thing\_keyword
            WHERE  $thing\_id IN (
                SELECT kc.$thing\_id
                FROM   $thing\_keyword kc LEFT JOIN $thing c
                       ON kc.$thing\_id = c.id
                WHERE  c.id IS NULL
            )
        },

        qq{ DELETE from $thing\_keyword
            WHERE  keyword_id IN (
                SELECT kc.keyword_id
                FROM   $thing\_keyword kc LEFT JOIN keyword k
                       ON kc.keyword_id = k.id
                WHERE  k.id IS NULL
            )
        },

        qq{ ALTER TABLE    $thing\_keyword
            ADD CONSTRAINT fk_$thing\__$thing\_keyword FOREIGN KEY ($thing\_id)
            REFERENCES     $thing\(id) ON DELETE CASCADE
        },

        qq{ ALTER TABLE    $thing\_keyword
            ADD CONSTRAINT fk_keyword__$thing\_keyword FOREIGN KEY (keyword_id)
            REFERENCES     keyword(id) ON DELETE CASCADE
        },

        qq{CREATE INDEX fkx_keyword__$thing\_keyword ON $thing\_keyword(keyword_id)},
        qq{CREATE INDEX fkx_$thing\__$thing\_keyword ON $thing\_keyword($thing\_id)},

    ;
}

__END__
