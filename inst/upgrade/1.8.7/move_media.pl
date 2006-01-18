#!/usr/bin/perl -w

use strict;
use FindBin;
use File::Spec::Functions qw(catdir updir);
use lib catdir $FindBin::Bin, updir, 'lib';
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;
use File::Copy qw(mv);

my $fs = Bric::Util::Trans::FS->new;
my $orig_dir = $fs->cat_dir(MASON_COMP_ROOT->[0][1], qw(data media));
my $temp_dir = $fs->cat_dir(MASON_COMP_ROOT->[0][1], qw(data temp));

# Just exit if there is no media directory.
exit unless -e $orig_dir;

# Check the media directory to see if  upgrade script has already run.
opendir my $check_dir, $orig_dir or die "Cannot open $orig_dir: $!\n";
while (my $check_file = readdir $check_dir) {
    exit if $check_file =~ /^\d\d$/;   # New directory convention.
    last if $check_file =~ /^\d{4,}$/; # Old directory convention.
}
closedir $check_dir;

# Move the old media directory out of the way.
mv $orig_dir, $temp_dir;

# Create a new media directory.
$fs->mk_path($orig_dir);

# Now rename all of the directories.
opendir my $dir, $temp_dir or die "Cannot open $temp_dir: $!\n";
while (my $media_id = readdir $dir) {
    next unless $media_id =~ /^\d+$/;
    my $media_dir = $fs->cat_dir($temp_dir, $media_id);
    next unless -d $media_dir;

    # Create the new directory.
    my @dirs = $media_id =~ /(\d\d?)/g;
    my $new_dir = $fs->cat_dir($orig_dir, @dirs);
    $fs->mk_path($new_dir);

    # Now copy over all the versions.
    opendir my $old_dir, $media_dir or die "Cannot open $media_dir: $!\n";
    while (my $version = readdir $old_dir) {
        next unless $version =~ /^\d+$/;
        my $old_vdir = $fs->cat_dir($media_dir, $version);
        next unless -d $old_vdir;

        opendir my $vdir, $old_vdir or die "Cannot open $old_vdir: $!\n";
        while (my $file = readdir $vdir) {
            next if $file eq '.' or $file eq '..';
            my $old_file = $fs->cat_file($old_vdir, $file);
            my $file_dir = $fs->cat_dir($new_dir, "v.$version");
            $fs->mk_path($file_dir);
            mv $old_file, $file_dir;
        }
    }
}

$fs->del($temp_dir);

__END__

