#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use File::Find;
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;

my $fs = Bric::Util::Trans::FS->new;

find(
    \&rm_super_bulk,
    $fa->cat_dir(MASON_COMP_ROOT->[0][1], qw(media images))
);

my %to_delete = ( map { $_ => 1 } qw(
    view_text_dgreen.gif
    recount_lgreen.gif
    view_log_teal.gif
    view_notes_dgreen.gif
    view_notes_teal.gif
));

sub rm_super_bulk {
    return unless $to_delete{$_};
    print "Deleting $File::Find::name\n";
    $fs->del($File::Find::name);
}

__END__
