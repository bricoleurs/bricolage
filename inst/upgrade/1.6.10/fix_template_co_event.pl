use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql "UDPATE event_type
        SET    name = 'Template Checked Out'
        WHERE  key_name = 'formatting_checkout'";
