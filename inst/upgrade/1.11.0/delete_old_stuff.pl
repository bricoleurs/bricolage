#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;

my $fs = Bric::Util::Trans::FS->new;

my @langs = qw(bo de_de en_us it_it km ko_ko lo my pt_pt ru_ru ug vi_vn zh_cn
               zh_hk zh_tw);

my @lang_dels = qw(
    media/images/%s/new_organization_lgreen.gif
    media/images/%s/checkin_assets_red.gif
    media/images/%s/move_assets_lgreen.gif
);

my @comp_dels = qw(
    widgets/media_prof/edit_contributor_role.html
    widgets/media_prof/edit_contributors.html
    widgets/media_prof/edit_keyword.html
    widgets/story_prof/edit_contributor_role.html
    widgets/story_prof/edit_contributors.html
    widgets/story_prof/edit_keyword.html
    widgets/add_more/index.html
    workflow/trail
    workflow/profile/media/keywords.html
    workflow/profile/media/contributor_role.html
    workflow/profile/story/keywords.html
    workflow/profile/story/contributor_role.html
);

my @dels = qw(
    lib/Bric/App/Callback/AddMore.pm
    lib/Bric/App/Callback/Workspace.pm
);

# Delete defunct language-specific UI components.
for my $lang (@langs) {
    for my $del (@lang_dels) {
        $fs->del( $fs->cat_file(
            MASON_COMP_ROOT->[0][1],
            split '/', sprintf($del, $lang)
        ) );
    }
}

# Delete other defunct files
for my $del (@comp_dels) {
    $fs->del( $fs->cat_file(
        MASON_COMP_ROOT->[0][1],
        split '/', $del
    ) );
}

for my $del (@dels) {
    $fs->del( $fs->cat_file(
        split '/', $del
    ) );
}