#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Config qw(:sys_user BURN_COMP_ROOT);
use Bric::Util::DBI qw(:all);
use Bric::Biz::Asset::Formatting;
use Bric::Util::Trans::FS;

my $tclass= 'Bric::Biz::Asset::Formatting';
my $fs = Bric::Util::Trans::FS->new;

# First, we'll need to get a list of Output Channel IDs that have a pre or post
# path.
my $oc_sel = prepare(qq{
    SELECT id, post_path, pre_path
    FROM   output_channel
    WHERE  (post_path IS NOT NULL
           AND post_path <> '')
           OR (pre_path IS NOT NULL
           AND pre_path <> '')
});

execute($oc_sel);
my ($oc_id, $post, $pre, $tid);
bind_columns($oc_sel, \$oc_id, \$post, \$pre);

# Next, we'll need to fetch the relevant template IDs for each OC ID we fetch.
# We have to use IDs to instantiate each one rather than call the template
# class' list() method because of a bug in the template class that was only
# fixed in version 1.2.2, so we can't expect it to be there for this upgrade.
my $tm_sel = prepare(qq{
    SELECT id
    FROM   formatting
    WHERE  output_channel__id = ?
});

# Now go throuh all the records.
while (fetch($oc_sel)) {
    # Get the list of template IDs for the OC we're processing.
    execute($tm_sel, $oc_id);
    bind_columns($tm_sel, \$tid);
    while (fetch($tm_sel)) {
    my $tplate = $tclass->lookup({ id => $tid });
    # Okay, we've got the template. Get the file name.
    my $old_file_name = $tplate->get_file_name;
    my @dirs = $fs->split_uri($old_file_name);
    my @old_dirs = @dirs;
    my ($is_post, $is_pre);

    # Dump any post directory.
    if ($post && $dirs[-2] eq $post) {
        $is_post = 1;
        splice @dirs, -2, 1;
    }

    # Dump any pre directory.
    if ($pre && $dirs[1] eq $pre) {
        $is_pre = 1;
        splice @dirs, 1, 1;
    }

    # Just jump to the next record unless there's domething for us to
    # actually do here.
    next unless $is_pre || $is_post;

    # Assign the proper file name and save it!
    my $new_file_name = $fs->cat_uri(@dirs);
    $tplate->{file_name} = $new_file_name;
    $tplate->_set__dirty(1);
    $tplate->save;

    # Skip to the next record unless this sucker is deployed.
    next unless $tplate->get_deploy_status;

    # Okay, now we have to move the file!
    my $oc_dir = "oc_$oc_id";
    my $old_file = $fs->cat_dir(BURN_COMP_ROOT, $oc_dir, @old_dirs);
    # Skip it unless it exists on the file system.
    next unless -e $old_file;
    # Get the new file name and directory name.
    my $new_file = $fs->cat_dir(BURN_COMP_ROOT, $oc_dir, @dirs);
    my $new_dir = $fs->dir_name($new_file);
    # Create the new directory and move the file.
    $fs->mk_path($new_dir);
    $fs->move($old_file, $new_file);
    # Make sure that the permissions are properly set.
    chown SYS_USER, SYS_GROUP, $new_file;
    }
}

