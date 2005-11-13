#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit unless test_column 'output_channel', 'pre_path';

do_sql
    q{UPDATE output_channel
      SET    uri_format       = '/' || pre_path || uri_format,
             fixed_uri_format = '/' || pre_path || fixed_uri_format
      WHERE  pre_path <> ''
    },

    q{UPDATE output_channel
      SET    uri_format       = uri_format       || post_path || '/',
             fixed_uri_format = fixed_uri_format || post_path || '/'
      WHERE  post_path <> ''
    },

    q{ALTER TABLE output_channel
      DROP  column pre_path
    },

    q{ALTER TABLE output_channel
      DROP  column post_path
    },
;

1;
__END__
