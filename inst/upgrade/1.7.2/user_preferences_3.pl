#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Config;

exit if test_foreign_key 'usr_pref', 'fk_pref__usr_pref';
exit if test_foreign_key 'usr_pref', 'fk_usr__usr_pref';

do_sql
q/
ALTER TABLE    usr_pref
ADD CONSTRAINT fk_pref__usr_pref FOREIGN KEY (pref__id)
REFERENCES     pref(id) ON DELETE CASCADE
/,

q/
ALTER TABLE    usr_pref
ADD CONSTRAINT fk_usr__usr_pref FOREIGN KEY (usr__id)
REFERENCES     usr(id) ON DELETE CASCADE
/;
