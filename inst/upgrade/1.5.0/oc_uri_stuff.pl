#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if test_sql(qq{SELECT uri_format FROM output_channel});

# Get the URI Case preference value.
my $case = col_aref(qq{SELECT value FROM pref WHERE id = 9});
if    ($case->[0] eq 'mixed') { $case = 1 }
elsif ($case->[0] eq 'lower') { $case = 2 }
elsif ($case->[0] eq 'upper') { $case = 3 }
else { die "Error fetching URI case preference value" }

do_sql
  # Create the new columns.
  q{ALTER TABLE output_channel ADD column uri_format VARCHAR(64)},
  q{ALTER TABLE output_channel ADD column fixed_uri_format VARCHAR(64)},
  q{ALTER TABLE output_channel ADD column uri_case NUMERIC(1,0)},
  q{ALTER TABLE output_channel ADD column use_slug NUMERIC(1,0)},

  # Set their values.
  q{UPDATE output_channel SET uri_format =
      (SELECT value FROM pref WHERE id = 7 )},
  q{UPDATE output_channel SET fixed_uri_format =
      (SELECT value FROM pref WHERE id = 8 )},
  qq{UPDATE output_channel SET uri_case = $case},
  q{UPDATE output_channel SET use_slug = 0},

  # Add uri_format constraints.
  q{ALTER TABLE output_channel
      ADD CONSTRAINT ck_oc_uri_format_null
      CHECK (uri_format is NOT NULL)},
  q{ALTER TABLE output_channel
      ADD CONSTRAINT ck_oc_fixed_uri_format_null
      CHECK (fixed_uri_format is NOT NULL)},

  # Add uri_case constraints.
  q{ALTER TABLE output_channel
      ADD CONSTRAINT ck_oc_uri_case_null
      CHECK (uri_case is NOT NULL)},
  q{ALTER TABLE output_channel
      ALTER COLUMN uri_case SET DEFAULT 1},
  q{ALTER TABLE output_channel
      ADD CONSTRAINT ck_output_channel__uri_case
      CHECK (uri_case IN (1,2,3))},

  # Add use_slug constraints.
  q{ALTER TABLE output_channel
      ADD CONSTRAINT ck_oc_use_slug_null
      CHECK (use_slug is NOT NULL)},
  q{ALTER TABLE output_channel
      ALTER COLUMN use_slug SET DEFAULT 0},
  q{ALTER TABLE output_channel
      ADD CONSTRAINT ck_output_channel__use_slug
      CHECK (use_slug IN (0,1))},

  # Delete old preferences.
  q{DELETE FROM pref WHERE id IN(7,8,9)}
  ;
