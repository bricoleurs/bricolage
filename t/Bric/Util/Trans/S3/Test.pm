package Bric::Util::Trans::S3::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(3) {
    eval { require Net::Amazon::S3; 1 } or
	    return 'Net::Amazon::S3 not installed';
    use_ok('Bric::Util::Trans::S3');
    isa_ok 'Bric::Util::Trans::S3', 'Bric';
    can_ok 'Bric::Util::Trans::S3', qw(
        new
        put_res
        del_res
    );
}

1;
__END__
