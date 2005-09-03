#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(row_array);
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;

exit if fetch_sql q{SELECT 1 FROM class where disp_name = 'Element Type Set'};

do_sql

  # Update element type set class.
  q{
    UPDATE class
    SET    key_name    = 'element_type_set',
           disp_name   = 'Element Type Set',
           plural_name = 'Element Type Sets',
           description = 'Element Type Set objects'
    WHERE  key_name    = 'element_type'
  },

  # Update element type class.
  q{
    UPDATE class
    SET    key_name    = 'element_type',
           disp_name   = 'Element Type',
           plural_name = 'Element Types',
           description = 'Element Type objects'
    WHERE  key_name    = 'element'
  },

  # Update element type set group class.
  q{
    UPDATE class
    SET    key_name    = 'element_type_set_grp',
           disp_name   = 'Element Type Set Group',
           plural_name = 'Element Type Set Groups',
           description = 'Group of element type sets'
    WHERE  key_name    = 'element_type_grp'
  },

  # Update element type group class.
  q{
    UPDATE class
    SET    key_name    = 'element_type_grp',
           disp_name   = 'Element Type Group',
           plural_name = 'Element Type Groups',
           description = 'Group of element types'
    WHERE  key_name    = 'element_grp'
  },

  # Update element type set event types.
  q{
    UPDATE class
    SET    key_name    = 'element_type_data'
    WHERE  key_name    = 'element_data'
  },

  # Create element class record.
  q{
    INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name,
                       description, distributor)
    VALUES ('81', 'element', 'Bric::Biz::Asset::Busines::Parts::Tile',
            'Element', 'Elements', 'Element objects.', '0')
  },

  # Update element type event types.
  q{
    UPDATE event_type
    SET    key_name    = 'element_type_set_new',
           name        = 'Element Type Set Created',
           description = 'Element type set profile was created.'
    WHERE  key_name    = 'element_type_new'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_set_save',
           name        = 'Element Type Set Changes Saved',
           description = 'Element type set profile changes were saved.'
    WHERE  key_name    = 'element_type_save'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_set_deact',
           name        = 'Element Type Set Deactivated',
           description = 'Element type set profile was deactivated.'
    WHERE  key_name    = 'element_type_deact'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_new',
           name        = 'Element Type Created',
           description = 'Element type profile was created.'
    WHERE  key_name    = 'element_new'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_save',
           name        = 'Element Type Changes Saved',
           description = 'Element type profile changes were saved.'
    WHERE  key_name    = 'element_save'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_deact',
           name        = 'Element Type Deactivated',
           description = 'Element type profile was deactivated.'
    WHERE  key_name    = 'element_deact'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_data_add',
           name        = 'Field Added to Element Type',
           description = 'A field was added to the element type profile.'
    WHERE  key_name    = 'element_attr_add'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_data_rem',
           name        = 'Field Removed from Element Type',
           description = 'A field was removed from the element type profile.'
    WHERE  key_name    = 'element_attr_del'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_data_new',
           name        = 'Element Type Field Created',
           description = 'Element Type Field was created.'
    WHERE  key_name    = 'element_data_new'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_data_save',
           name        = 'Element Type Field Saved',
           description = 'Element Type Field was saved.'
    WHERE  key_name    = 'element_data_save'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'element_type_data_deact',
           name        = 'Element Type Field Deactivated',
           description = 'Element Type Field was deactivated.'
    WHERE  key_name    = 'element_data_del'
  },

;

# Delete defunct directories.
my $fs = Bric::Util::Trans::FS->new;
for my $dirs (
    [qw(admin profile element_data)],
    [qw(admin profile element)],
    [qw(admin manager element)],
    [qw(widgets element_data)]
) {
    $fs->del( $fs->cat_dir( MASON_COMP_ROOT->[0][1], @$dirs ) );
}


