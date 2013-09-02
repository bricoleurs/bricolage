#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

for my $type (qw(story formatting media)) {
    do_sql "DELETE from member
            WHERE  id IN (SELECT member__id
                          FROM   $type\_member, $type, member, grp
                          WHERE  grp.name = 'Desk Assets'
                                 AND grp.id = member.grp__id
                                 AND member.id = $type\_member.member__id
                                 AND $type\_member.object_id = $type.id
                                 AND $type.desk__id = 0
                         )
           ";
}
