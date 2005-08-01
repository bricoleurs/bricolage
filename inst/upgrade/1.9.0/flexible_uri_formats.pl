#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# This is similar to an upgrade done for 1.7.0, but is designed to fix bad
# key names created by autopopulated fields defined since that upgrade.

my $get_uri_formats = prepare('SELECT id, uri_format, fixed_uri_format FROM output_channel');

my $set_uri_formats = prepare('
  UPDATE output_channel
  SET    uri_format = ?,
         fixed_uri_format = ?
  WHERE id = ?
');

my ($id, $uri_format, $fixed_uri_format);
execute($get_uri_formats);
bind_columns($get_uri_formats, \$id, \$uri_format, \$fixed_uri_format);

while (fetch($get_uri_formats)) {
    $uri_format =~ s/categories/\%{categories}/g;
    $uri_format =~ s/year/\%Y/g;
    $uri_format =~ s/month/\%m/g;
    $uri_format =~ s/day/\%d/g;
    $uri_format =~ s/slug/\%{slug}/g;
    $fixed_uri_format =~ s/categories/\%{categories}/g;
    $fixed_uri_format =~ s/year/\%Y/g;
    $fixed_uri_format =~ s/month/\%m/g;
    $fixed_uri_format =~ s/day/\%d/g;
    $fixed_uri_format =~ s/slug/\%{slug}/g;
    execute($set_uri_formats, $uri_format, $fixed_uri_format, $id);
}
