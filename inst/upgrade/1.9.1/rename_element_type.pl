#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

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
    SET    key_name    = 'field_type',
           disp_name   = 'Field Type',
           plural_name = 'Element Types',
           description = 'Field Types'
    WHERE  key_name    = 'element_data'
  },

  # Create element class record.
  q{
    INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name,
                       description, distributor)
    VALUES ('81', 'element', 'Bric::Biz::Asset::Business::Parts::Tile',
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
    SET    key_name    = 'field_type_add',
           name        = 'Field Type Added to Element Type',
           description = 'A field was added to the element type profile.'
    WHERE  key_name    = 'element_attr_add'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'field_type_rem',
           name        = 'Field Type Removed from Element Type',
           description = 'A field type was removed from the element type profile.'
    WHERE  key_name    = 'element_attr_del'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'field_type_new',
           name        = 'Field Type Created',
           description = 'Field Type was created.'
    WHERE  key_name    = 'element_data_new'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'field_type_save',
           name        = 'Field Type Saved',
           description = 'Feid Type was saved.'
    WHERE  key_name    = 'element_data_save'
  },

  q{
    UPDATE event_type
    SET    key_name    = 'field_type_deact',
           name        = 'Field Type Deactivated',
           description = 'Field Type was deactivated.'
    WHERE  key_name    = 'element_data_del'
  },

;
