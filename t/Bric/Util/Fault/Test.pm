package Bric::Util::Fault::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::Fault qw(:all);

sub test_alias : Test(8) {
    my $self = shift;
    eval { throw_dp error => "Error"; };
    ok( my $err = $@, "Catch exception" );
    isa_ok($err, "Bric::Util::Fault::Exception::DP" );
    isa_ok($err, "Bric::Util::Fault::Exception" );
    isa_ok($err, "Bric::Util::Fault" );
    isa_ok($err, "Exception::Class::Base" );
    ok( isa_bric_exception($err), "Test isa_bric_exception" );
    eval { rethrow_exception($err) };
    ok( my $err2 = $@, "Catch rethrown exception" );
    is( $err2->error, $err->error, "Caught the same exception" );
}

sub test_error : Test(6) {
    my $self = shift;
    eval { throw_not_unique maketext => ["Error"]; };
    ok( my $err = $@, "Catch exception" );
    isa_ok($err, "Bric::Util::Fault::Error::NotUnique" );
    isa_ok($err, "Bric::Util::Fault::Error" );
    isa_ok($err, "Bric::Util::Fault" );
    isa_ok($err, "Exception::Class::Base" );
    ok( eq_array( $err->maketext, ["Error"]), "Test maketext" );
}

1;
__END__
