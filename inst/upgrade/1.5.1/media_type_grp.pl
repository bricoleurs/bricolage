#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if fetch_sql "SELECT 1 FROM class WHERE id = 77";

do_sql
  # Create a class entry for the media type group.
  q{INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name,
                       description, distributor)
    VALUES (77, 'media_type_grp', 'Bric::Util::Grp::MediaType',
            'Media Type Group', 'Media Type Groups',
            'Media type group objects', 0)},

  # Create the media types group.
  q{INSERT INTO grp (id, parent_id, class__id, name, description, secret, permanent)
    VALUES (48, 0, 77, 'All Media Types', 'All media types in the system.', 0, 1)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (200, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (200, 48, 200)},

  # Create the SQL structures required to manage members.
  q{CREATE SEQUENCE seq_media_type_member START 1024},

  q{CREATE TABLE media_type_member (
        id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_media_type_member'),
        object_id   NUMERIC(10,0)  NOT NULL,
        member__id  NUMERIC(10,0)  NOT NULL,
        CONSTRAINT pk_media_type_member__id PRIMARY KEY (id)
    )},
  ;

# Now add all existing media types to the "All Media Types" group.
my $sel = prepare('SELECT id FROM media_type');
my $next_mem = next_key('member');
my $next_mtmem = next_key('media_type_member');
my $mem = prepare(qq{
    INSERT INTO member (id, grp__id, class__id, active)
    VALUES ($next_mem, 48, 72, 1)
});

my $mtmem = prepare(qq{
    INSERT INTO media_type_member (id, object_id, member__id)
    VALUES ($next_mtmem, ?, CURRVAL('seq_member'))
});

execute($sel);
my $id;
bind_columns($sel, \$id);
while (fetch($sel)) {
    execute($mem);
    execute($mtmem, $id);
}

1;
__END__

