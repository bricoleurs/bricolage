package Bric::Util::Trans::FS::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use URI::Escape;
use File::Spec::Functions qw(catdir);
use File::Spec::Unix;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(2) {
    use_ok('Bric::Util::Trans::FS');

    can_ok 'Bric::Util::Trans::FS', qw(
        new
        DESTROY
        put_res
        del_res
        copy
        move
        mk_path
        del
        cat_dir
        cat_file
        cat_uri
        split_dir
        split_uri
        trunc_dir
        trunc_uri
        dir_to_uri
        uri_to_dir
        base_name
        uri_base_name
        dir_name
        uri_dir_name
    );

}

sub test_uri_meths : Test(37) {
    ok my $fs = Bric::Util::Trans::FS->new, 'Get an FS object';
    for my $uri (
        '/foo',
        '/foo/bar',
        '/foo%20bar',
        '/foo%20bar/baz',
        '/2009/10/16/Madmen%20Icon.JPG',
    ) {
        my @parts = File::Spec::Unix->splitdir(uri_unescape($uri));
        my $fn = catdir @parts;
        is $fs->uri_to_dir($uri), $fn, "uri_to_dir('$uri') should return '$fn'";
        is $fs->dir_to_uri($fn), $uri, "dir_to_uri('$fn') should return '$uri'";
        is $fs->cat_uri(@parts), $uri, "cat_uri(@parts) should return '$uri'";
        is_deeply [$fs->split_uri($uri)], \@parts,
            "split_uri('$uri') should return @parts";

        my $base = uri_escape($parts[-1]);
        is $fs->uri_base_name($uri), $base,
            "uri_base_name('$uri') should return '$base'";

        pop @parts;
        my $trunced = catdir map { uri_escape $_  } @parts;
        is $fs->trunc_uri($uri), $trunced,
            "trunc_uri('$uri') should return $trunced";
        is $fs->uri_dir_name($uri), $trunced,
            "uri_dir_name('$uri') should return $trunced";

    }
    is $fs->trunc_uri('/'), undef, "trunc_uri('/') should return undef";
}

sub test_cat_uri : Test(7) {
    ok my $fs = Bric::Util::Trans::FS->new, 'Get an FS object';
    for my $parts (
        [qw(this that other )],
        ['this', 'this/that' ],
        ['this', 'this%20that' ],
        ['/this/here', 'this%20that' ],
        ['/this/here/', 'this%20that' ],
        ['/this/here/' ],
    ) {
        my $uri = catdir( map {
            map { uri_escape $_} File::Spec::Unix->splitdir( uri_unescape $_ )
        } @$parts );
        is $fs->cat_uri(@$parts), $uri, "cat_file(@$parts) should return '$uri'";
    }
}

1;
__END__
