#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);


# check if we're already upgraded.
exit if fetch_sql(q{
    SELECT id
    FROM   event_type_attr
    WHERE  event_type__id = (SELECT id FROM event_type WHERE key_name = 'story_checkin')
});


do_sql
  map { "INSERT INTO event_type_attr (id, event_type__id, name)
         VALUES (NEXTVAL('seq_event_type_attr'),
                 (SELECT id FROM event_type WHERE key_name = '$_\_checkin'),
                 'Version')"
    } qw(story media formatting)

  ;

__END__
