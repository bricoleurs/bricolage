#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# check if we're already upgraded.
exit if fetch_sql q{SELECT 1 FROM event_type WHERE key_name = 'story_expire'};

do_sql
  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'story_expire', 'Story Expired',
            'Story was expired.', 10, '1')},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'media_expire', 'Media Expired',
            'Media was expired.', 46, '1')},
  ;

__END__
