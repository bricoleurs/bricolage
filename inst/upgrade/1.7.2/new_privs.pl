#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# If there are 4s or 5s, we've definitely done this before.
exit if fetch_sql('SELECT 1 FROM grp_priv WHERE value in (4, 5)');

do_sql
  # Adjust CREATE permissions to their new number.
  q{UPDATE grp_priv
    SET    value = 4
    WHERE  value = 3},

  # Set CREATE permissions to PUBLISH for "All" asset groups.
  q{UPDATE grp_priv
    SET    value = 5
    WHERE  value = 4
           AND id in (
               SELECT grp_priv__id
               FROM   grp_priv__grp_member
               WHERE  grp__id in (31, 32, 33)
           )},

  # Set EDIT permissions to RECALL for "All" asset groups.
  q{UPDATE grp_priv
    SET    value = 3
    WHERE  value = 2
           AND id in (
               SELECT grp_priv__id
               FROM   grp_priv__grp_member
               WHERE  grp__id in (31, 32, 33)
           )},

  # Set EDIT permissions to PUBLISH on publish desks.
  q{UPDATE grp_priv
    SET    value = 5
    WHERE  value = 2
           AND id in (
               SELECT grp_priv__id
               FROM   grp_priv__grp_member, desk
               WHERE  grp_priv__grp_member.grp__id = desk.asset_grp
                      AND desk.publish = 1
           )},

  # Set EDIT permissions to RECALL on start desks.
  q{UPDATE grp_priv
    SET    value = 3
    WHERE  value = 2
           AND id in (
               SELECT grp_priv__id
               FROM   grp_priv__grp_member, desk, workflow
               WHERE  grp_priv__grp_member.grp__id = desk.asset_grp
                      AND desk.id = workflow.head_desk_id
           )},

  # Set EDIT permissions to PUBLISH for category asset groups.
  q{UPDATE grp_priv
    SET    value = 5
    WHERE  value = 2
           AND id in (
               SELECT grp_priv__id
               FROM   grp_priv__grp_member, category
               WHERE  grp_priv__grp_member.grp__id = category.asset_grp_id
           )},

  # Set EDIT permissions to PUBLISH for all user-created asset groups.
  q{UPDATE grp_priv
    SET    value = 5
    WHERE  value = 2
           AND id in (
               SELECT grp_priv__id
               FROM   grp_priv__grp_member, grp
               WHERE  grp_priv__grp_member.grp__id = grp.id
                      AND grp.class__id in (43, 65, 66, 67)
                      AND grp.permanent = 0
                      AND grp.secret = 0
           )},
  ;
