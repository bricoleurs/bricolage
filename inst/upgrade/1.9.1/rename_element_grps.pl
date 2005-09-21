#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{SELECT 1 FROM grp where name = 'All Element Type Sets'};

do_sql
    q{UPDATE grp
      SET name = 'All Element Type Sets',
          description = 'All element type sets in the system.'
      WHERE  id = 28
    },

    q{UPDATE grp
      SET name = 'All Element Type',
          description = 'All element types in the system.'
      WHERE  id = 27
    },

    q{UPDATE grp
      SET name = 'Element Type Admins',
          description = 'Users who administer element types and element type sets.'
      WHERE  id = 10
    },

    # Old pasto.
    q{UPDATE grp
      SET name = 'Contributor Type Admins'
      WHERE  id = 38
    },
;
