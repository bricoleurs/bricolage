package Bric::Biz::AssetType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Biz::AssetType;
use Bric::Biz::OutputChannel;

##############################################################################
# Test Output Channel methods.
##############################################################################
sub test_oc : Test(32) {
    ok( my $at = Bric::Biz::AssetType->lookup({ id => 1 }),
        "Lookup story element" );

    # Try get_ocs.
    ok( my $oces = $at->get_output_channels, "Get existing OCs" );
    is( scalar @$oces, 1, "Check for one OC" );
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel');
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel::Element');
    is( $oces->[0]->get_name, "Web", "Check name 'Web'" );

    # Add a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'Foober' }),
        "Create 'Foober' OC" );
    ok( $oc->save, "Save Foober" );
    ok( my $ocid = $oc->get_id, "Get Foober ID" );

    # Add it to the Element object and try get_ocs again.
    ok( $at->add_output_channels([$oc]), "Add Foober" );
    ok( $oces = $at->get_output_channels, "Get existing OCs again" );
    is( scalar @$oces, 2, "Check for two OCs" );
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel::Element');
    isa_ok($oces->[1], 'Bric::Biz::OutputChannel::Element');

    # Save the element object and try get_ocs again.
    ok( $at->save, "Save Story element" );
    ok( $oces = $at->get_output_channels, "Get existing OCs 3" );
    is( scalar @$oces, 2, "Check for two OCs again" );

    # Now lookup the story element from the database and try get_ocs again.
    ok( $at = Bric::Biz::AssetType->lookup({ id => 1 }),
        "Lookup story element again" );
    ok( $oces = $at->get_output_channels, "Get existing OCs 4" );
    is( scalar @$oces, 2, "Check for two OCs 3" );
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel::Element');
    isa_ok($oces->[1], 'Bric::Biz::OutputChannel::Element');

    # Now delete it.
    ok( $at->delete_output_channels([$oc]), "Delete OC" );
    ok( $oces = $at->get_output_channels, "Get existing OCs 5" );
    is( scalar @$oces, 1, "Check for one OC again" );

    # Save the element object, then check the output channels again.
    ok( $at->save, "Save story element again" );
    ok( $oces = $at->get_output_channels, "Get existing OCs 6" );
    is( scalar @$oces, 1, "Check for one OC 3" );

    # Now look it up and check it one last time.
    ok( $at = Bric::Biz::AssetType->lookup({ id => 1 }),
        "Lookup story element again" );
    ok( $oces = $at->get_output_channels, "Get existing OCs 7" );
    is( scalar @$oces, 1, "Check for one OC 4" );
    is( $oces->[0]->get_name, "Web", "Check name 'Web' again" );

    # And finally, clean out the OC table.
    Bric::Util::DBI::prepare(qq{
        DELETE FROM output_channel
        WHERE  id = $ocid
    })->execute;

}

1;
__END__
