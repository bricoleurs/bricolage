package Bric::Util::Pref::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Pref;

my $tz_pref_id = 1;

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(13) {
    my $self = shift;
    ok( my $pref = Bric::Util::Pref->lookup({ id => $tz_pref_id }),
        "Look up TZ pref" );
    is( $pref->get_id, $tz_pref_id, "Check that the ID is the same" );
    # Check its attributes.
    is( $pref->get_name, 'Time Zone', "Check name" );
    is( $pref->get_description, 'Time Zone', "Check description" );
    is( $pref->get_value, 'America/Los_Angeles', "Check value" );
    is( $pref->get_val_name, 'Pacific Time - Los Angeles',
        "Check value_name" );
    is( $pref->get_default, 'America/Los_Angeles', "Check default" );
    is( $pref->get_manual, 0, "Check manual" );
    is( $pref->get_opt_type, 'select', "Check opt_type" );
    ok( my @opts = $pref->get_opts, "Get options" );
    ok( my $opts_ref = $pref->get_opts_href, "Get options href" );
    is( $opts_ref->{Cuba}, 'Cuba', "Check Cuba" );
    is( $opts_ref->{UTC}, 'Coordinated Universal Time (UTC)', "Check UTC" );
}

##############################################################################
# Test list().
sub test_list : Test(41) {
    my $self = shift;

    # Create a new job group.
    ok( my $grp = Bric::Util::Grp::Pref->new({ name => 'Test PrefGrp' }),
        "Create group" );

    # Add four of the prefs to the group.
    my $n;
    foreach my $pref (Bric::Util::Pref->list) {
        $n++;
        $grp->add_member({ obj => $pref }) if $n % 2;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name.
    ok( my @prefs = Bric::Util::Pref->list({ name => 'Time Zone' }),
        "Look up name 'Time Zone'" );
    is( scalar @prefs, 1, "Check for 1 prefs" );
    is( $prefs[0]->get_name, 'Time Zone', "Check name" );

    # Try name + wildcard.
    ok( @prefs = Bric::Util::Pref->list({ name => "%Name%" }),
        "Look up name '%Name%'" );
    is( scalar @prefs, 3, "Check for 3 prefs" );

    # Try grp_id.
    ok( @prefs = Bric::Util::Pref->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @prefs, 7, "Check for 7 prefs" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Util::Pref::INSTANCE_GROUP_ID;
    foreach my $pref (@prefs) {
        my %grp_ids = map { $_ => 1 } $pref->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $prefs[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be three using grp_id.
    ok( @prefs = Bric::Util::Pref->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @prefs, 6, "Check for 6 prefs" );


    # Try val_name.
    ok( @prefs = Bric::Util::Pref->list
        ({ val_name => 'Pacific Time - Los Angeles' }),
        "Look up val_name 'Pacific Time - Los Angeles'" );
    is( scalar @prefs, 1, "Check for 1 prefs" );
    is( $prefs[0]->get_val_name, 'Pacific Time - Los Angeles', "Check name" );

    # Try description.
    ok( @prefs = Bric::Util::Pref->list({ description => 'Time Zone' }),
        "Look up description 'Time Zone'" );
    is( scalar @prefs, 1, "Check for 1 prefs" );
    is( $prefs[0]->get_description, 'Time Zone', "Check name" );

    # Try description + wildcard.
    ok( @prefs = Bric::Util::Pref->list({ description => 'how%' }),
        "Look up description 'how%'" );
    is( scalar @prefs, 2, "Check for 2 prefs" );

    # Try value.
    ok( @prefs = Bric::Util::Pref->list({ value => "radio" }),
        "Look up value 'radio'" );
    is( scalar @prefs, 1, "Check for 1 prefs" );

    # Try default.
    ok( @prefs = Bric::Util::Pref->list({ default => "bricolage" }),
        "Look up default 'bricolage'" );
    is( scalar @prefs, 1, "Check for 1 prefs" );

    # Try manual.
    ok( @prefs = Bric::Util::Pref->list({ manual => 1 }),
        "Look up manual => 1" );
    is( scalar @prefs, 1, "Check for 1 prefs" );
    ok( @prefs = Bric::Util::Pref->list({ manual => 0 }),
        "Look up manual => 0" );
    is( scalar @prefs, 13, "Check for 13 prefs" );

    # Try opt_type.
    ok( @prefs = Bric::Util::Pref->list({ opt_type => 'radio' }),
        "Look up opt_type 'radio'" );
    is( scalar @prefs, 1, "Check for 1 prefs" );
    ok( @prefs = Bric::Util::Pref->list({ opt_type => 'select' }),
        "Look up opt_type 'select'" );
    is( scalar @prefs, 12, "Check for 12 prefs" );

}
