#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;

exit if fetch_sql q{SELECT 1 FROM class where key_name = 'field_type'};

do_sql
  # Update element type set event types.
  q{
    UPDATE class
    SET    key_name    = 'field_type',
           disp_name   = 'Field Type',
           plural_name = 'Element Types',
           description = 'Field Types'
    WHERE  key_name    = 'element_data'
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
