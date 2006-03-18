#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit unless test_table 'element_member';
exit if test_foreign_key 'element_member', 'fk_member__at_member';

do_sql
    q{ DELETE FROM element_member
       WHERE id IN (
                 SELECT j.id
                 FROM  element_member j LEFT JOIN member m ON (j.member__id = m.id)
                 WHERE m.id IS NULL
             )
    },

    q{ ALTER TABLE element_member ADD
       CONSTRAINT fk_member__at_member FOREIGN KEY (member__id)
       REFERENCES member(id) ON DELETE CASCADE
    }

;

__END__
