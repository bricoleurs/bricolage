package Bric::Dist::Server::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Dist::Server;

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(12) {
    my $self = shift;
    my $args = { host_name      => 'www.example.org',
                 os             => 'Unix',
                 doc_root       => '/tmp',
                 login          => 'castellan',
                 password       => 'nalletsac',
                 cookie         => '0U812',
                 server_type_id => 1,
               };

    ok ( my $server = Bric::Dist::Server->new({ %$args }), "Test construtor" );
    isa_ok($server, 'Bric::Dist::Server');
    isa_ok($server, 'Bric');
    ok( ! defined $server->get_id, 'Undefined ID' );
    is( $server->get_host_name, $args->{host_name},
        "host name is '$args->{host_name}'" );
    is( $server->get_os, $args->{os}, "OS is '$args->{os}'" );
    is( $server->get_doc_root, $args->{doc_root},
        "Doc Root is '$args->{doc_root}'" );
    is( $server->get_login, $args->{login},
        "Login is '$args->{login}'" );
    is( $server->get_password, $args->{password},
        "Password is '$args->{password}'" );
    is( $server->get_cookie, $args->{cookie},
        "Cookie is '$args->{cookie}'" );
    is( $server->get_server_type_id, $args->{server_type_id},
        "Server_type_id is '$args->{server_type_id}'" );
    ok( $server->is_active, "Check that it's activated" );
}

1;
__END__
