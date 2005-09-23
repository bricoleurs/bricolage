#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{SELECT 1 FROM class where pkg_name = 'Bric::Biz::ElementType'};

do_sql

  q{DELETE FROM class WHERE id = 24},

  q{
    UPDATE class
    SET    pkg_name    = 'Bric::Biz::ElementType'
    WHERE  key_name    = 'element_type'
  },

  q{
    UPDATE class
    SET    pkg_name    = 'Bric::Biz::ElementType::Parts::FieldType'
    WHERE  key_name    = 'field_type'
  },

  q{
    UPDATE class
    SET    pkg_name    = 'Bric::Util::Grp::ATType'
    WHERE  key_name    = 'element_type_set_grp'
  },

  q{
    UPDATE class
    SET    pkg_name    = 'Bric::Util::Grp::ElementType'
    WHERE  key_name    = 'element_type_grp'
  },

  q{
    UPDATE class
    SET    key_name    = 'subelement_type_grp',
           pkg_name    = 'Bric::Util::Grp::SubelementType',
           disp_name   = 'Subelement Type Group',
           plural_name = 'Subelement Type Groups',
           description = 'Subelement Type Group'
    WHERE  key_name    = 'asset_type_grp'
  },

;
