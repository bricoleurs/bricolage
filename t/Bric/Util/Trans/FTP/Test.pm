package Bric::Util::Trans::FTP::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::ApacheUtil qw(unescape_uri escape_uri);
use File::Spec::Functions qw(catdir);
use File::Spec::Unix;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(3) {
    use_ok('Bric::Util::Trans::FTP');
    isa_ok 'Bric::Util::Trans::FTP', 'Bric';

    can_ok 'Bric::Util::Trans::FTP', qw(
        new
        put_res
        del_res
    );
}

1;
__END__
