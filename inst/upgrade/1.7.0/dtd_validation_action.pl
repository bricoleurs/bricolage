#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql("SELECT 1 FROM action_type WHERE id = 5");

do_sql
  (
   # Determine if we need to insert the 'application/xhtml+xml' media type.
   (fetch_sql("SELECT 1 FROM media_type WHERE name = 'application/xhtml+xml'")
    ? ()
    : ( q{INSERT INTO media_type (id, name, description, active)
          VALUES (92, 'application/xhtml+xml', NULL, 1)},
        q{INSERT INTO media_type_ext (id, media_type__id, extension)
           VALUES (130, 92, 'xhtml')},
        q{INSERT INTO media_type_ext (id, media_type__id, extension)
           VALUES (131, 92, 'xht')},
        q{INSERT INTO member (id, grp__id, class__id, active)
          VALUES (892, 48, 72, 1)},
        q{INSERT INTO media_type_member (id, object_id, member__id)
          VALUES (892, 92, 892)},
      )
   ),

   # Insert the validation action type.
   q{INSERT INTO action_type ( id, name, description, active)
      VALUES (5, 'DTD Validation', 'XML DTD validation.', 1)},

   # And insert its media type assocations.
   qq{INSERT INTO action_type__media_type (action_type__id, media_type__id)
      VALUES (5, (SELECT id FROM media_type WHERE name = 'text/html'))},
   qq{INSERT INTO action_type__media_type (action_type__id, media_type__id)
      VALUES (5, (SELECT id FROM media_type WHERE name = 'text/xml'))},
   qq{INSERT INTO action_type__media_type (action_type__id, media_type__id)
      VALUES (5, (SELECT id FROM media_type WHERE name = 'application/xhtml+xml'))},
  );

1;
