package Bric::Biz::OutputChannel::Element::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::OutputChannel::DevTest);
use Test::More;
use Bric::Biz::OutputChannel::Element;

##############################################################################
# Test instance methods.
##############################################################################
# Test save() method's update ability.
sub test_update : Test(13) {
    # Grab an existing OCE from the database.
    ok( my $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs" );
    ok( my $oce = $href->{1}, "Grab OC ID 1" );

    # Set enable to false.
    ok( $oce->is_enabled, "Check is_enabled" );
    ok( $oce->set_enabled_off, "Set enable off" );
    ok( $oce->save, "Save OCE" );

    # Look it up again.
    ok( $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs again" );
    ok( $oce = $href->{1}, "Grab OC ID 1 again" );

    # Enable should be false, now.
    ok( ! $oce->is_enabled, "Check is_enabled off" );
    ok( $oce->set_enabled_on, "Set enable on" );
    ok( $oce->save, "Save OCE again" );

    # Look it up one last time.
    ok( $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs last" );
    ok( $oce = $href->{1}, "Grab OC ID 1 last" );
    ok( $oce->is_enabled, "Check is_enabled on again" );
}

##############################################################################
# Test save()'s insert and delete abilities.
sub test_insert : Test(11) {
    # Create a new output channel.
    ok( my $oce = Bric::Biz::OutputChannel::Element->new({ name => "Foober",
                                                           element_id => 1
                                                         }),
      "Create a brand new OCE" );

    # Now save it. It should be inserted as both an OC and as an OCE.
    ok( $oce->save, "Save new OCE" );
    ok( my $ocid = $oce->get_id, "Get ID" );

    # Now retreive it.
    ok( my $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs" );
    ok( $oce = $href->{$ocid}, "Grab OC ID $ocid" );

    # Check its attributes.
    is( $oce->get_id, $ocid, "Check ID" );
    is( $oce->get_name, "Foober", "Check name 'Foober'" );

    # Now delete it.
    ok( $oce->remove, "Remove OCE" );
    ok( $oce->save, "Save removed OCE" );

    # Now try to retreive it.
    ok( $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs" );
    ok( ! exists $href->{$ocid}, "ID $ocid gone" );

    # And finally, clean out the OC table.
    Bric::Util::DBI::prepare(qq{
        DELETE FROM output_channel
        WHERE  id = $ocid
    })->execute;
}

1;
__END__
