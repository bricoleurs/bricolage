package Bric::Util::UserPref::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;

use Bric::Util::UserPref;

my $tz_pref_id = 1;
my $admin_user_id = 0;

sub table { 'usr_pref' }

# Test subs need to be run in order, thus the leadin A_, B_, C_
# prefixes on sub names.

##############################################################################
# Test constructors.
##############################################################################
# Test the new() method.

sub test_record : Test(setup => 3) {
    my $self = shift;
    ok my $user_pref = Bric::Util::UserPref->new({
        user_id => $admin_user_id,
        pref_id => $tz_pref_id,
        value   => 'America/Chicago'
    }), "Create TZ pref";

    isa_ok($user_pref, 'Bric::Util::UserPref');
    ok $user_pref->save, "Save TZ pref";
    $self->add_del_ids($user_pref->get_id);
    $self->{user_pref} = $user_pref;
}

sub test_new : Test(5) {
    my $self = shift;
    my $user_pref = $self->{user_pref};

    is( $user_pref->get_name, 'Time Zone', "name is Time Zone (before save)" );

    my $id = $user_pref->get_id;
    ok( defined $id, "after saving user pref has an id" );

    is( $user_pref->get_name, 'Time Zone', "name is Time Zone (after save)" );
    is( $user_pref->get_description, 'Time Zone', "Check description" );
    is( $user_pref->get_value, 'America/Chicago', "Check value" );
}

##############################################################################
# Test list().
sub test_lookup : Test(6) {
    my $self = shift;

    my $user_pref = Bric::Util::UserPref->lookup({ user_id => $admin_user_id,
                                                   pref_id => $tz_pref_id });
    ok( $user_pref, "lookup() by user_id and pref_id" );
    is( $user_pref->get_name, 'Time Zone', "name is Time Zone (after lookup)" );
    is( $user_pref->get_description, 'Time Zone', "Check description" );
    is( $user_pref->get_value, 'America/Chicago', "Check value" );

    $user_pref->set_value( 'America/New_York' );
    is( $user_pref->get_value, 'America/New_York', "Check value after set_value" );

    my $user_pref2 = Bric::Util::UserPref->lookup({ user_id => 999,
                                                    pref_id => $tz_pref_id });
    ok( ! $user_pref2, "lookup() a row that doesn't exist" );
}

##############################################################################
# Test the delete() method.
sub test_delete : Test(2) {
    my $self = shift;

    {
        my $user_pref = Bric::Util::UserPref->lookup({ user_id => $admin_user_id,
                                                       pref_id => $tz_pref_id });
        ok( $user_pref, "lookup() by user_id and pref_id" );

        $user_pref->delete;
    }

    {
        my $user_pref = Bric::Util::UserPref->lookup({ user_id => $admin_user_id,
                                                       pref_id => $tz_pref_id });

        ok( ! $user_pref, "lookup() on a pref that was just deleted finds nothing" );
    }
}

##############################################################################
# Test Bric::App::Util::get_pref().

# Well, I'd like to, but it wants an Apache config file, and Apache
# modules, and blah blah blah.  Too much Util stuff in one module,
# methinks.

1;
