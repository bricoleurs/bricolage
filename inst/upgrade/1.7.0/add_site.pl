#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Just bail if the site class has been added to the class table.
exit if fetch_sql "SELECT 1 FROM class WHERE id = 75";

do_sql

  ############################################################################
  # Create new entries in the class table.
  qq{INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name,
                        description, distributor)
     VALUES (75, 'site', 'Bric::Biz::Site', 'Site', 'Sites', 'Site class', 0)},

  qq{INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name,
                        description, distributor)
     VALUES (76, 'site_grp', 'Bric::Util::Grp::Site', 'Site Group',
             'Site Groups', 'Site group class', 0)},

  ############################################################################
  # Create the site table.
  qq{CREATE TABLE site (
       id          NUMERIC(10, 0)    NOT NULL,
       name        TEXT,
       description TEXT,
       domain_name TEXT,
       active      NUMERIC(1, 0)     NOT NULL
                                     DEFAULT 1
                                     CONSTRAINT ck_site__active
                                       CHECK (active IN (1,0)),
       CONSTRAINT pk_site__id PRIMARY KEY (id)
     )},

  # Create the site_member table.
  qq{CREATE TABLE site_member (
       id          NUMERIC(10,0)  NOT NULL
                                  DEFAULT NEXTVAL('seq_site_member'),
       object_id   NUMERIC(10,0)  NOT NULL,
       member__id  NUMERIC(10,0)  NOT NULL,
       CONSTRAINT pk_site_member__id PRIMARY KEY (id)
     )},

  ############################################################################
  # Add the sequence.
  qq{CREATE SEQUENCE seq_site_member START 1024},

  ############################################################################
  # Add the "All Sites" group.
  qq{INSERT INTO grp (id, parent_id, class__id, name, description, secret,
                      permanent)
     VALUES (47, NULL, 76, 'All Sites', 'All sites in the system.', 0, 1)},

  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (165, 35, 6, 1)},

  qq{INSERT INTO grp_member (id, object_id, member__id)
     VALUES (56, 47, 165)},

  ############################################################################
  # Add the default site asset group.
  qq{INSERT INTO grp (id, parent_id, class__id, name, description, secret,
                      permanent)
     VALUES (100, NULL, 43, 'Secret Site Asset Group', NULL, 1, 1)},

  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (166, 35, 6, 1)},

  qq{INSERT INTO grp_member (id, object_id, member__id)
     VALUES (57, 100, 166)},

  ############################################################################
  # Add the Default site READ secret user group and permissions.
  qq{INSERT INTO grp (id, parent_id, class__id, name, description, secret,
                      permanent)
     VALUES (200, 0, 8, 'Default Site READ Users', '__Site 100 Users__', 1,
             1)},

  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (700, 3, 6, 1)},

  qq{INSERT INTO grp_member (id, object_id, member__id)
     VALUES (700, 200, 700)},

  qq{INSERT INTO grp_priv (id, grp__id, value)
     VALUES(50, 200, 1)},

  qq{INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
     VALUES(50, 100)},

  ############################################################################
  # Add the Default site EDIT secret user group and permissions.
  qq{INSERT INTO grp (id, parent_id, class__id, name, description, secret,
                      permanent)
    VALUES (201, 0, 8, 'Default Site EDIT Users', '__Site 100 Users__', 1,
            1)},

  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (701, 3, 6, 1)},

  qq{INSERT INTO grp_member (id, object_id, member__id)
     VALUES (701, 201, 701)},

  qq{INSERT INTO grp_priv (id, grp__id, value)
     VALUES(51, 201, 2)},

  qq{INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
     VALUES(51, 100)},

  ############################################################################
  # Add the Default site CREATE secret user group and permissions.
  qq{INSERT INTO grp (id, parent_id, class__id, name, description, secret,
                      permanent)
     VALUES (202, 0, 8, 'Default Site CREATE Users', '__Site 100 Users__', 1,
             1)},

  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (702, 3, 6, 1)},

  qq{INSERT INTO grp_member (id, object_id, member__id)
     VALUES (702, 202, 702)},

  qq{INSERT INTO grp_priv (id, grp__id, value)
     VALUES(52, 202, 3)},

  qq{INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
     VALUES(52, 100)},

  ############################################################################
  # Add the Default site DENY secret user group and permissions.
  qq{INSERT INTO grp (id, parent_id, class__id, name, description, secret,
                      permanent)
     VALUES (203, 0, 8, 'Default Site DENY Users', '__Site 100 Users__', 1,
             1)},

  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (703, 3, 6, 1)},

  qq{INSERT INTO grp_member (id, object_id, member__id)
     VALUES (703, 203, 703)},

  qq{INSERT INTO grp_priv (id, grp__id, value)
     VALUES(53, 203, 255)},

  qq{INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
     VALUES(53, 100)},

  ############################################################################
  # Add the "Default Site" site.
  qq{INSERT INTO site (id, name, description, domain_name, active)
     VALUES (100, 'Default Site', 'The default site', 'www.example.com', 1)},

  # Add it to the "All Sites" Group.
  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (59, 47, 75, 1)},

  q{INSERT INTO site_member (id, object_id, member__id)
    VALUES (1, 100, 59)},

  # Add it to the default site secret group.
  qq{INSERT INTO member (id, grp__id, class__id, active)
     VALUES (60, 100, 75, 1)},

  q{INSERT INTO site_member (id, object_id, member__id)
    VALUES (2, 100, 60)},
  ;

1;
__END__
