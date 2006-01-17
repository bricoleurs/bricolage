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
    media/images/%s/D_green.gif
    media/images/%s/D_red.gif
    media/images/%s/P_green.gif
    media/images/%s/P_red.gif
    comp/widgets/summary/formatting_meta.html
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
