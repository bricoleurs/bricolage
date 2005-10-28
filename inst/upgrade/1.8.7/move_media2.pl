#!/usr/bin/perl -w

use strict;
use FindBin;
use File::Spec::Functions qw(catdir updir);
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);
use Bric::Util::Trans::FS;

exit unless fetch_sql q{
  SELECT 1
  FROM   media_instance
  WHERE  location LIKE '/____/0/%'
  LIMIT  1
};

my $fs  = Bric::Util::Trans::FS->new;
my $sel = prepare('SELECT id, location FROM media_instance WHERE location IS NOT NULL');
my $upd = prepare('UPDATE media_instance SET location = ? WHERE id = ?');

execute($sel);
bind_columns($sel, \my ($id, $loc));

while (fetch($sel)) {
    my ($empty, $media_id, $version, $file) = split m{/}, $loc;
    my @dirs = $media_id =~ /(\d\d?)/g;
    my $uri = $fs->cat_uri($empty, @dirs, "v.$version", $file);
    execute($upd, $uri, $id);
}


__END__

