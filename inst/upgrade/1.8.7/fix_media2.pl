#!/usr/bin/perl -w

use strict;
use FindBin;
use File::Spec::Functions qw(catdir updir tmpdir);
use lib catdir $FindBin::Bin, updir, 'lib';
use Bric;
use Bric::Util::Trans::FS;
use Bric::Config qw(MEDIA_FILE_ROOT);
use File::Copy qw(mv);

my $fs  = Bric::Util::Trans::FS->new;
my $list_file = $fs->cat_file(tmpdir, 'fix_media.txt');
open my $file, '<', $list_file or die "Cannot open '$list_file': $!\n";
while (<$file>) {
    chomp;
    my ($file, $new_dir) = split /\t/;
    $file    = $fs->cat_dir(MEDIA_FILE_ROOT, $file);
    $new_dir = $fs->cat_dir(MEDIA_FILE_ROOT, $new_dir);
    $fs->mk_path($new_dir);
    mv $file, $new_dir;
}

close  $file;
$fs->del($list_file);
$fs->del($fs->cat_dir(MEDIA_FILE_ROOT, '0'));

__END__

