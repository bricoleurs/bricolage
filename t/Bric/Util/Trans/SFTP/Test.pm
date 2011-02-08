package Bric::Util::Trans::SFTP::Test;
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
    eval { require Net::SSH2; 1 } or return 'Net::SSH2 not installed';
    use_ok('Bric::Util::Trans::SFTP');
    isa_ok 'Bric::Util::Trans::SFTP', 'Bric';

    can_ok 'Bric::Util::Trans::SFTP', qw(
        new
        put_res
        del_res
        _connect_to
    );
}

1;
__END__
