package Bric::Util::AuthEngines::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Test::MockModule;
use Bric::Biz::Person::User;
use Bric::Util::AuthInternal;
use Bric::Config qw(:ldap);

sub test_internal_auth : Test(4) {
    my $self = shift;
    ok my $user = Bric::Biz::Person::User->new({
        login => 'rupert',
    }), "Create user";
    my $pwd = 'W#$gni Q# #fd&93r di,DiGF`"n34 i';
    my $engine = 'Bric::Util::AuthInternal';
    ok $engine->set_password($user, $pwd), "Set password";
    ok $engine->authenticate($user, $pwd), "Check password";
    ok !$engine->authenticate($user, 'foo'), "Check bogus password";
}

sub test_ldap_auth : Test(24) {
    my $self = shift;

    require Bric::Util::AuthLDAP;
    ok my $user = Bric::Biz::Person::User->new({
        login => 'rupert',
    }), "Create user";

    # Set LDAP up for success.
    my $ldap = Net::LDAP->new;
    $ldap->{codes} = [0, 0, 0];
    $ldap->{counts} = [1, 1];
    $ldap->{dn} = 'rupert';
    my $pwd = 'W#$gni Q# #fd&93r di,DiGF`"n34 i';
    my $engine = 'Bric::Util::AuthLDAP';
    ok $user->set_password($pwd), "Set password";
    ok $engine->set_password($user, $pwd), "Set password (no-op)";
    ok $engine->authenticate($user, $pwd), "Check password";

    # Check the contents of the LDAP object.
    is $ldap->{server}, LDAP_SERVER, "The LDAP server should be set";
    is $ldap->{version}, LDAP_VERSION, "The LDAP version should be set";
    isa_ok $ldap->{onerror}, 'CODE';
    is $ldap->{tls}, (LDAP_TLS ? 1 : undef),
      "TLS should have been started or not, as appropriate";
    if (LDAP_USER) {
        is_deeply $ldap->{user}, [LDAP_USER, 'rupert'],
          "Usernames should have been passed to bind()";
        is_deeply $ldap->{password}, [LDAP_PASS, $pwd],
          "Passwords should have been passed to bind()";
    } else {
        is_deeply $ldap->{user}, [undef, 'rupert'],
          "Only auth username should have been passed to bind()";
        is_deeply $ldap->{password}, [$pwd],
          "Only auth password should have been passed to bind()";
    }

    my $filter = sprintf "(&(%s=%s)%s)",
      LDAP_UID_ATTR, 'rupert', LDAP_FILTER;
    isa_ok $ldap->{search}[0]{filter}, 'Net::LDAP::Filter';
    is ${$ldap->{search}[0]{filter}}, $filter,
      "The filter should have been set properly";
    is $ldap->{search}[0]{base}, LDAP_BASE,
      "The LDAP base should have been set for the search";
    is $ldap->{search}[0]{attrs}[0], 'dn',
      "The search should fetch only the DN attribute";

    SKIP : {
        skip "No LDAP Group", 5 unless LDAP_GROUP;
        my $filter = sprintf "(%s=%s)",
          LDAP_MEMBER_ATTR, 'rupert';
        isa_ok $ldap->{search}[1]{filter}, 'Net::LDAP::Filter';
        is ${$ldap->{search}[1]{filter}}, $filter,
          "The filter should have been set properly";
        is $ldap->{search}[1]{base}, LDAP_GROUP,
          "The LDAP base should have been set for the search";
        is $ldap->{search}[1]{attrs}[0], 'dn',
          "The search should fetch only the DN attribute";
        is $ldap->{search}[1]{scope}, 'base',
          "The search scope should be the base";
    }

    # Reset.
    %$ldap = ();

    # I mock you, Net::LDAP!
    my $netldap = Test::MockModule->new('Net::LDAP');

    # Fail in the LDAP constructor.
    $netldap->mock(new => sub { $@ = "yow!"; return; });
    eval { $engine->authenticate };
    ok my $err = $@, "Catch exception";
    isa_ok $err, 'Bric::Util::Fault::Exception::Auth';
    is $err->error, 'Unable to connect to LDAP Server',
      "Should get connect error message";
    is $err->payload, 'yow!', "Payload should be message from Net::LDAP";
    $netldap->unmock('new');

    # Set up for failure.
    $ldap->{codes} = [0, 49];
    $ldap->{counts} = [0];
    $ldap->{dn} = 'foo';
    ok !$engine->authenticate($user, 'foo'), "Check bogus password";
}

##############################################################################
# LDAP Mock classes.
BEGIN {
    # Hush now!
    no warnings 'redefine';

    # Fake-out loading.
    use File::Spec;
    $INC{File::Spec->catfile(qw(Net LDAP.pm))}        ||= __FILE__;
    $INC{File::Spec->catfile(qw(Net LDAP Util.pm))}   ||= __FILE__;
    $INC{File::Spec->catfile(qw(Net LDAP Filter.pm))} ||= __FILE__;

    ##########################################################################
    package Net::LDAP;

    sub import {
        my $caller = caller or return;
        no strict 'refs';
        *{"${caller}::LDAP_INVALID_CREDENTIALS"} = sub () { 49 };
        *{"${caller}::LDAP_INAPPROPRIATE_AUTH"} = sub () { 48 };
        *{"${caller}::LDAP_SUCCESS"} = sub () { 0 };
    }
    my $ldap = bless {};

    sub new {
        my ($pkg, $server) = (shift, shift);
        $ldap->{server} = $server;
        while (@_) {
            my $key = shift;
            $ldap->{$key} = shift;
        }
        return $ldap;
    }

    sub start_tls { shift->{tls} = 1 }
    sub bind {
        my $self = shift;
        push @{$self->{user}}, shift;
        while (@_) {
            my $key = shift;
            push @{$self->{$key}}, shift;
        }
        return $self;
    }
    sub search {
        my $self = shift;
        push @{$self->{search}}, {@_};
        return $self;
    }

    sub code {
        my $codes = shift->{codes};
        shift @$codes;
    }

    sub count {
        my $counts = shift->{counts};
        shift @$counts;
    }

    sub first_entry { shift }
    sub dn { shift->{dn} }

    ##########################################################################
    package Net::LDAP::Util;

    sub import {
        my $caller = caller or return;
        no strict 'refs';
        *{"${caller}::ldap_error_desc"} = sub { shift }
    }

    ##########################################################################
    package Net::LDAP::Filter;

    sub new {
        my $pkg = shift;
        bless \shift() => $pkg;
    }
}

1;
__END__
