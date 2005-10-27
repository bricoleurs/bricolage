#!/usr/bin/perl -w

use strict;
use FindBin;
use File::Spec::Functions qw(catdir updir);
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);
use Bric::Config qw(MEDIA_FILE_ROOT);
use Bric::Util::Trans::FS;

my $media_file_root = MEDIA_FILE_ROOT;
exit unless fetch_sql qq{
  SELECT 1
  FROM   resource
  WHERE  path LIKE '$media_file_root/____/0/%'
  LIMIT  1
};

my $fs  = Bric::Util::Trans::FS->new;
my $sel = prepare("SELECT id, path FROM resource WHERE path LIKE '$media_file_root%'");
my $upd = prepare('UPDATE resource SET path = ? WHERE id = ?');

execute($sel);
bind_columns($sel, \my ($id, $loc));

while (fetch($sel)) {
    $loc =~ s{$media_file_root/}{};
    my ($media_id, $version, $file) = split m{/}, $loc;
    my @dirs = $media_id =~ /(\d\d?)/g;
    my $path = $fs->cat_file($media_file_root, @dirs, "v.$version", $file);
    execute($upd, $path, $id);
}


__END__

