#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Just bail if the keyword group class has been added to the class table.
exit if fetch_sql "SELECT 1 FROM class WHERE id = 28";

do_sql
  # Create a class entry for the keyword group class.
  qq{INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name,
                        description, distributor)
     VALUES (28, 'keyword_grp', 'Bric::Util::Grp::Keyword', 'Keyword Group',
             'Keyword Groups', 'Keyword group', 0)},

  # Create an "All Keywords" group.
  qq{INSERT INTO grp (id, parent_id, class__id, name, description, secret,
                       permanent)
     VALUES (50, NULL, 28, 'All Keywords', 'All keywords in the system.',
             0, 1)},

  # Associate the "All Keywords" group with the "All Groups" group.
  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (190, 35, 6, 1)},

  qq{INSERT INTO grp_member (id, object_id, member__id)
     VALUES (60, 50, 190)},

  # Create the keyword sequence.
  qq{CREATE SEQUENCE seq_keyword_member START 1024},

  # Create the keyword group member table.
  qq{CREATE TABLE keyword_member (
        id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_keyword_member'),
        object_id   NUMERIC(10,0)  NOT NULL,
        member__id  NUMERIC(10,0)  NOT NULL,
        CONSTRAINT pk_keyword_member__id PRIMARY KEY (id)
    )},
  ;

# Now add all existing media types to the "All Media Types" group.
my $sel = prepare('SELECT id FROM keyword');
my $next_mem = next_key('member');
my $next_mtmem = next_key('keyword_member');
my $mem = prepare(qq{
    INSERT INTO member (id, grp__id, class__id, active)
    VALUES ($next_mem, 50, 41, 1)
});

my $mtmem = prepare(qq{
    INSERT INTO keyword_member (id, object_id, member__id)
    VALUES ($next_mtmem, ?, CURRVAL('seq_member'))
});

execute($sel);
my $id;
bind_columns($sel, \$id);
while (fetch($sel)) {
    execute($mem);
    execute($mtmem, $id);
}

__END__
