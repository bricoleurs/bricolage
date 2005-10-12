#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;

our $CONFIG;
do './config.db' or die "Failed to read config.db: $!";

my $fs = Bric::Util::Trans::FS->new;

my @langs = qw(bo de_de en_us it_it km ko_ko lo my pt_pt ru_ru ug vi_vn zh_cn
               zh_hk zh_tw);

my @lang_dels = qw(
    help/%s/admin/manager/element.html
    help/%s/admin/profile/element.html
    help/%s/admin/profile/element_data.html
    help/%s/workflow/active/templates.html
    help/%s/workflow/manager/templates.html
    help/%s/workflow/profile/media/container
    help/%s/workflow/profile/story/container
    help/%s/workflow/profile/templates
    help/%s/workflow/profile/templates.html
    media/images/%s/bricolage.gif
    media/images/%s/recount_lgreen.gif
    media/images/%s/view_log_teal.gif
    media/images/%s/view_notes_dgreen.gif
    media/images/%s/view_notes_teal.gif
    media/images/%s/view_text_dgreen.gif
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

# Delete other defunct UI components.
while (my $del = <DATA>) {
    chomp $del;
    $fs->del( $fs->cat_dir( MASON_COMP_ROOT->[0][1], split '/', $del ) );
}

my @libs = qw(
    Bric::App::Callback::Profile::ElementData
    Bric::App::Callback::Profile::ElementType
    Bric::SOAP::Element
    Bric::Util::Async
    Bric::Util::Attribute::AssetType
    Bric::Util::Attribute::AssetTypeData
    Bric::Util::Attribute::Formatting
    Bric::Util::Attribute::Media
    Bric::Util::Attribute::MediaDataTile
    Bric::Util::Attribute::Person
    Bric::Util::Attribute::Story
    Bric::Util::Attribute::StoryDataTile
    Bric::Util::Attribute::Workspace
    Bric::Util::Grp::AssetType
    Bric::Util::Grp::Element
    Bric::Util::Grp::Formatting
    Bric::Util::WebDav
);

# Delete defunct libraries and their mag pages.
for my $lib (@libs) {
    $fs->del( $fs->cat_file($CONFIG->{MODULE_DIR}, split '::', "$lib.pm" ) );
    $fs->del( $fs->cat_file($CONFIG->{MAN_DIR}), "$lib.3" );
}

__DATA__
admin/control/change_user
admin/manager/element
admin/profile/element
admin/profile/element/dhandler
admin/profile/element_data
help/en_us/admin/manager/element.html
help/en_us/admin/profile/element.html
help/en_us/admin/profile/element_data.html
help/en_us/workflow/active/templates.html
help/en_us/workflow/manager/templates.html
help/en_us/workflow/profile/media/container
help/en_us/workflow/profile/story/container
help/en_us/workflow/profile/templates
help/en_us/workflow/profile/templates.html
lib/process
media/images/006666_curve_left.gif
media/images/006666_curve_right.gif
media/images/646430_arrow_open.gif
media/images/646430_curve_left.gif
media/images/646430_curve_right.gif
media/images/663366_curve_left.gif
media/images/663366_curve_right.gif
media/images/666633_arrow_open.gif
media/images/666633_curve_left.gif
media/images/666633_curve_right.gif
media/images/669999_curve_left.gif
media/images/669999_curve_right.gif
media/images/999966_arrow_closed.gif
media/images/999966_arrow_open.gif
media/images/999966_curve_left.gif
media/images/999966_curve_right.gif
media/images/CC6633_arrow_open.gif
media/images/CC6633_curve_left.gif
media/images/CC6633_curve_right.gif
media/images/CC9900_curve_left.gif
media/images/CC9900_curve_right.gif
media/images/CCCC99_curve_left.gif
media/images/CCCC99_curve_right.gif
media/images/box_edge_bottom.gif
media/images/box_edge_right.gif
media/images/dkgreen_curve_left.gif
media/images/dkgreen_curve_right.gif
media/images/en_us/bricolage.gif
media/images/en_us/recount_lgreen.gif
media/images/en_us/view_log_teal.gif
media/images/en_us/view_notes_dgreen.gif
media/images/en_us/view_notes_teal.gif
media/images/en_us/view_text_dgreen.gif
media/images/first_bottom.gif
media/images/ID_bottom.gif
media/images/ID_bottom2.gif
media/images/ID_right.gif
media/images/lt_green_curve_right.gif
media/images/mdgreen_curve_left.gif
media/images/mdgreen_curve_right.gif
media/images/numbers
media/images/red_arrow_open.gif
media/images/red_curve_left.gif
media/images/red_curve_right.gif
media/images/yellow_star.gif
widgets/container_prof/edit_super_bulk.html
widgets/desk/desk_item_old.html
widgets/element_data
widgets/help/help.mc
widgets/htmlarea/load.mc
widgets/htmlarea/timeout.mc
widgets/listManager/index.html
widgets/profile/create_button.html
widgets/publish/index.html
widgets/qa
widgets/search/formatting.html
widgets/select_object/index.html
widgets/select_time/index.html
workflow/profile/media/container/edit_super_bulk.html
workflow/profile/story/container/edit_super_bulk.html
workflow/profile/templates
