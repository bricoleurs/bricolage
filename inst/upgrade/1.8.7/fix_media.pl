#!/usr/bin/perl -w

use strict;
use FindBin;
use File::Spec::Functions qw(catdir updir tmpdir);
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);
use Bric::Util::Trans::FS;
use Bric::Config qw(MEDIA_FILE_ROOT);

my $fs  = Bric::Util::Trans::FS->new;
my $zero_dir = $fs->cat_dir('', '0', '');

my $sel = prepare(qq{
    SELECT id, media__id, version, file_name, location
    FROM   media_instance
    WHERE  location LIKE '$zero_dir%'
});

my $upd = prepare(q{
    UPDATE media_instance
    SET    location = ?
    WHERE  id = ?
});

execute($sel);
bind_columns($sel, \my ($id, $mid, $version, $fn, $loc));
my $list_file = $fs->cat_file(tmpdir, 'fix_media.txt');
open my $file, '>', $list_file or die "Cannot open '$list_file': $!\n";

while (fetch($sel)) {
    my $new_path = Bric::Util::Trans::FS->cat_dir('/', $mid, $version);
    my $new_loc  = Bric::Util::Trans::FS->cat_dir($new_path, $fn);
    # Save date for fix_media2.pl.
    print $file "$loc\t$new_path\n";
    execute($upd, $new_loc, $id);
}

close $file;


__END__

