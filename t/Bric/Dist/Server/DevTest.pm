package Bric::Dist::Server::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Dist::Server;
use Bric::Dist::ServerType;

sub table {'server'}

my $dest;

my %server = ( host_name      => 'www.example.org',
               os             => 'Unix',
               doc_root       => '/tmp',
               login          => 'castellan',
               password       => 'nalletsac',
               cookie         => '0U812',
             );

sub setup : Test(setup => 12) {
    my $self = shift;
    ok( my $dest = Bric::Dist::ServerType->new
        ({ name        => 'Bogus',
           description => 'Bogus Dest',
           move_method => 'File System'}),
        "Create destination" );
    ok( $dest->save, "Save destination" );
    $server{server_type_id} = $dest->get_id;
    $self->add_del_ids($server{server_type_id}, 'server_type');

    # Create some test records.
    $self->{servers} = [];
    for my $n (1..5) {
        my %args = %server;
        # Make sure the name is unique.
        $args{host_name} .= $n;
        if ($n % 2) {
            $args{login} .= $n;
            $args{cookie} .= $n;
            $args{doc_root} .= $n;
        } else {
            $args{os} = 'Mac';
            $args{password} .= $n;
        }
        ok( my $server = Bric::Dist::Server->new(\%args),
            "Create $args{host_name}" );
        ok( $server->save, "Save $args{host_name}" );
        # Save the ID for deleting.
        $self->add_del_ids($server->get_id);
        push @{$self->{servers}}, $server;
    }

}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(10) {
    my $self = shift;
    my $sid = $self->{servers}->[0]->get_id;
    ok( my $server = Bric::Dist::Server->lookup({ id => $sid }),
        "Look up the new server" );
    is( $server->get_id, $sid, "Check that the ID is the same" );
    # Check a few attributes.
    ok( $server->is_active, "Check that it's activated" );
    is( $server->get_host_name, "$server{host_name}1",
        "host name is '$server{host_name}1'" );
    is( $server->get_os, $server{os}, "OS is '$server{os}'" );
    is( $server->get_doc_root, "$server{doc_root}1",
        "Doc Root is '$server{doc_root}1'" );
    is( $server->get_login, "$server{login}1",
        "Login is '$server{login}1'" );
    is( $server->get_password, $server{password},
        "Password is '$server{password}'" );
    is( $server->get_cookie, "$server{cookie}1",
        "Cookie is '$server{cookie}1'" );
    is( $server->get_server_type_id, $server{server_type_id},
        "Server_type_id is '$server{server_type_id}'" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(24) {
    my $self = shift;

    # Try host_name + wildcard.
    ok( my @servers = Bric::Dist::Server->list
        ({ host_name => "$server{host_name}%" }),
        "Look up name '$server{host_name}%'" );
    is( scalar @servers, 5, "Check for 5 servers" );

    # Try server_type_id.
    ok( @servers = Bric::Dist::Server->list
        ({ server_type_id => $server{server_type_id} }),
        "Look up server_type_id '$server{server_type_id}'" );
    # Only the two defaults.
    is( scalar @servers, 5, "Check for 5 servers" );

    # Try os.
    ok( @servers = Bric::Dist::Server->list({ os => $server{os} }),
        "Look up os '$server{os}'" );
    is( scalar @servers, 3, "Check for 3 servers" );

    # Try doc_root.
    ok( @servers = Bric::Dist::Server->list
        ({ doc_root => $server{doc_root} }),
        "Look up doc root '$server{doc_root}'" );
    is( scalar @servers, 2, "Check for 2 servers" );

    # Try doc_root + wildcard.
    ok( @servers = Bric::Dist::Server->list
        ({ doc_root => "$server{doc_root}%" }),
        "Look up doc root '$server{doc_root}%'" );
    is( scalar @servers, 5, "Check for 5 servers" );

    # Try login.
    ok( @servers = Bric::Dist::Server->list({ login => $server{login} }),
        "Look up login '$server{login}'" );
    is( scalar @servers, 2, "Check for 2 servers" );

    # Try login + wildcard.
    ok( @servers = Bric::Dist::Server->list({ login => "$server{login}%" }),
        "Look up login '$server{login}%'" );
    is( scalar @servers, 5, "Check for 5 servers" );

    # Try password.
    ok( @servers = Bric::Dist::Server->list
        ({ password => $server{password} }),
        "Look up password '$server{password}'" );
    is( scalar @servers, 3, "Check for 3 servers" );

    # Try password + wildcard.
    ok( @servers = Bric::Dist::Server->list
        ({ password => "$server{password}%" }),
        "Look up password '$server{password}%'" );
    is( scalar @servers, 5, "Check for 5 servers" );

    # Try cookie.
    ok( @servers = Bric::Dist::Server->list({ cookie => $server{cookie} }),
        "Look up cookie '$server{cookie}'" );
    is( scalar @servers, 2, "Check for 2 servers" );

    # Try cookie + wildcard.
    ok( @servers = Bric::Dist::Server->list({ cookie => "$server{cookie}%" }),
        "Look up cookie '$server{cookie}%'" );
    is( scalar @servers, 5, "Check for 5 servers" );

    # Try active.
    ok( @servers = Bric::Dist::Server->list({ active => 1 }),
        "Look up active => 1" );
    is( scalar @servers, 5, "Check for 5 servers" );
}

##############################################################################
# Test the href() method.
sub test_href : Test(29) {
    my $self = shift;

    # Try host_name + wildcard.
    ok( my $servers = Bric::Dist::Server->href
        ({ host_name => "$server{host_name}%" }),
        "Look up name '$server{host_name}%'" );
    is( scalar keys %$servers, 5, "Check for 5 servers" );

    # Check the key/value pairs.
    while (my ($id, $server) = each %$servers) {
        my $sid = $server->get_id;
        is($id, $sid, "Check ID $sid");
    }

    # Try server_type_id.
    ok( $servers = Bric::Dist::Server->href
        ({ server_type_id => $server{server_type_id} }),
        "Look up server_type_id '$server{server_type_id}'" );
    # Only the two defaults.
    is( scalar keys %$servers, 5, "Check for 5 servers" );

    # Try os.
    ok( $servers = Bric::Dist::Server->href({ os => $server{os} }),
        "Look up os '$server{os}'" );
    is( scalar keys %$servers, 3, "Check for 3 servers" );

    # Try doc_root.
    ok( $servers = Bric::Dist::Server->href
        ({ doc_root => $server{doc_root} }),
        "Look up doc root '$server{doc_root}'" );
    is( scalar keys %$servers, 2, "Check for 2 servers" );

    # Try doc_root + wildcard.
    ok( $servers = Bric::Dist::Server->href
        ({ doc_root => "$server{doc_root}%" }),
        "Look up doc root '$server{doc_root}%'" );
    is( scalar keys %$servers, 5, "Check for 5 servers" );

    # Try login.
    ok( $servers = Bric::Dist::Server->href({ login => $server{login} }),
        "Look up login '$server{login}'" );
    is( scalar keys %$servers, 2, "Check for 2 servers" );

    # Try login + wildcard.
    ok( $servers = Bric::Dist::Server->href({ login => "$server{login}%" }),
        "Look up login '$server{login}%'" );
    is( scalar keys %$servers, 5, "Check for 5 servers" );

    # Try password.
    ok( $servers = Bric::Dist::Server->href
        ({ password => $server{password} }),
        "Look up password '$server{password}'" );
    is( scalar keys %$servers, 3, "Check for 3 servers" );

    # Try password + wildcard.
    ok( $servers = Bric::Dist::Server->href
        ({ password => "$server{password}%" }),
        "Look up password '$server{password}%'" );
    is( scalar keys %$servers, 5, "Check for 5 servers" );

    # Try cookie.
    ok( $servers = Bric::Dist::Server->href({ cookie => $server{cookie} }),
        "Look up cookie '$server{cookie}'" );
    is( scalar keys %$servers, 2, "Check for 2 servers" );

    # Try cookie + wildcard.
    ok( $servers = Bric::Dist::Server->href({ cookie => "$server{cookie}%" }),
        "Look up cookie '$server{cookie}%'" );
    is( scalar keys %$servers, 5, "Check for 5 servers" );

    # Try active.
    ok( $servers = Bric::Dist::Server->href({ active => 1 }),
        "Look up active => 1" );
    is( scalar keys %$servers, 5, "Check for 5 servers" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(24) {
    my $self = shift;

    # Try host_name + wildcard.
    ok( my @server_ids = Bric::Dist::Server->list_ids
        ({ host_name => "$server{host_name}%" }),
        "Look up name '$server{host_name}%'" );
    is( scalar @server_ids, 5, "Check for 5 server IDs" );

    # Try server_type_id.
    ok( @server_ids = Bric::Dist::Server->list_ids
        ({ server_type_id => $server{server_type_id} }),
        "Look up server_type_id '$server{server_type_id}'" );
    # Only the two defaults.
    is( scalar @server_ids, 5, "Check for 5 server IDs" );

    # Try os.
    ok( @server_ids = Bric::Dist::Server->list_ids({ os => $server{os} }),
        "Look up os '$server{os}'" );
    is( scalar @server_ids, 3, "Check for 3 server IDs" );

    # Try doc_root.
    ok( @server_ids = Bric::Dist::Server->list_ids
        ({ doc_root => $server{doc_root} }),
        "Look up doc root '$server{doc_root}'" );
    is( scalar @server_ids, 2, "Check for 2 server IDs" );

    # Try doc_root + wildcard.
    ok( @server_ids = Bric::Dist::Server->list_ids
        ({ doc_root => "$server{doc_root}%" }),
        "Look up doc root '$server{doc_root}%'" );
    is( scalar @server_ids, 5, "Check for 5 server IDs" );

    # Try login.
    ok( @server_ids = Bric::Dist::Server->list_ids({ login => $server{login} }),
        "Look up login '$server{login}'" );
    is( scalar @server_ids, 2, "Check for 2 server IDs" );

    # Try login + wildcard.
    ok( @server_ids = Bric::Dist::Server->list_ids({ login => "$server{login}%" }),
        "Look up login '$server{login}%'" );
    is( scalar @server_ids, 5, "Check for 5 server IDs" );

    # Try password.
    ok( @server_ids = Bric::Dist::Server->list_ids
        ({ password => $server{password} }),
        "Look up password '$server{password}'" );
    is( scalar @server_ids, 3, "Check for 3 server IDs" );

    # Try password + wildcard.
    ok( @server_ids = Bric::Dist::Server->list_ids
        ({ password => "$server{password}%" }),
        "Look up password '$server{password}%'" );
    is( scalar @server_ids, 5, "Check for 5 server IDs" );

    # Try cookie.
    ok( @server_ids = Bric::Dist::Server->list_ids({ cookie => $server{cookie} }),
        "Look up cookie '$server{cookie}'" );
    is( scalar @server_ids, 2, "Check for 2 server IDs" );

    # Try cookie + wildcard.
    ok( @server_ids = Bric::Dist::Server->list_ids({ cookie => "$server{cookie}%" }),
        "Look up cookie '$server{cookie}%'" );
    is( scalar @server_ids, 5, "Check for 5 server IDs" );

    # Try active.
    ok( @server_ids = Bric::Dist::Server->list_ids({ active => 1 }),
        "Look up active => 1" );
    is( scalar @server_ids, 5, "Check for 5 server IDs" );
}

##############################################################################
# Test my_meths().
sub test_my_meths : Test(7) {
    ok( my $meths = Bric::Dist::Server->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{host_name}{type}, 'short', "Check host_name type" );
    ok( $meths = Bric::Dist::Server->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    is( $meths->[0]->{name}, 'host_name', "Check first meth name" );

    # Try the identifier methods.
    my @meths = Bric::Dist::Server->my_meths(0, 1);
    is( scalar @meths, 0, "Check for 1 meth" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save()
sub test_save : Test(7) {
    my $self = shift;
    my $sid = $self->{servers}->[0]->get_id;
    ok( my $server = Bric::Dist::Server->lookup({ id => $sid }),
        "Look up the new server" );
    ok( $server = Bric::Dist::Server->lookup({ id => $sid }),
        "Look up the new server" );
    ok( my $old_name = $server->get_host_name, "Get its host name" );
    my $new_name = $old_name . ' foo';
    ok( $server->set_host_name($new_name),
        "Set its host name to '$new_name'" );
    ok( $server->save, "Save it" );
    ok( Bric::Dist::Server->lookup({ id => $sid }),
        "Look it up again" );
    is( $server->get_host_name, $new_name, "Check host name is '$new_name'" );
}

1;
__END__
