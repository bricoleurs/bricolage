package Bric::Biz::Asset::Business::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::DevTest);
use Test::More;
use Bric::Biz::Asset::Business;
use Bric::Biz::AssetType;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }


##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Overrid this method in subclasses.
sub class { 'Bric::Biz::Asset::Business' }

##############################################################################
# The element object we'll use throughout. Override in subclass if necessary.
my $elem;
sub get_elem {
    $elem ||= Bric::Biz::AssetType->lookup({ id => 1 });
    $elem;
}

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    ( element    => $self->get_elem,
      user__id   => 1,
      source__id => 1
    )
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({ $self->new_args, @_ });
}

##############################################################################
# Test output channel associations.
##############################################################################
sub test_oc : Test(40) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
    return "OCs tested only by subclass" if $key eq 'biz';
    ok( my $ba = $self->construct, "Construct $key object" );
    ok( my $elem = $self->get_elem, "Get element object" );

    # Make sure there are the same of OCs yet as in the element.
    ok( my @eocs = $elem->get_output_channels, "Get Element OCs" );
    ok( my @ocs = $ba->get_output_channels, "Get $key OCs" );
    is( scalar @ocs, 1, "Check for 1 OC" );
    is( scalar @eocs, scalar @ocs, "Check for same number of OCs" );
    is( $eocs[0]->get_id, $ocs[0]->get_id, "Compare for same OC ID" );

    # Save the asset object.
    ok( $ba->save, "Save ST" );
    ok( my $baid = $ba->get_id, "Get ST ID" );
    push @{ $self->{$key} }, $baid;

    # Grab the element's first OC.
    ok( my $oc = $eocs[0], "Grab the first OC" );
    ok( my $ocname = $oc->get_name, "Get the OC's name" );

    # Try removing the OC.
    ok( $ba->del_output_channels($oc), "Delete OC from $key" );
    @ocs = $ba->get_output_channels;
    is( scalar @ocs, 0, "No more OCs" );

    # Make sure it looks the same after saving.
    ok( $ba->save, "Save ST again" );
    @ocs = $ba->get_output_channels;
    is( scalar @ocs, 0, "Still no OCs" );

    # And again after looking up the business asset again.
    ok( $ba = $class->lookup({ id => $baid }), "Lookup $key" );
    @ocs = $ba->get_output_channels;
    is( scalar @ocs, 0, "Again no OCs" );

    # Add the new output channel to the asset.
    ok( $ba->add_output_channels($oc), "Add OC" );
    ok( @ocs = $ba->get_output_channels, "Get OCs" );
    is( scalar @ocs, 1, "Check for 1 OC" );
    is( $ocs[0]->get_name, $ocname, "Check OC name" );

    # Save it and verify again.
    ok( $ba->save, "Save ST" );
    ok( @ocs = $ba->get_output_channels, "Get OCs again" );
    is( scalar @ocs, 1, "Check for 1 OC again" );
    is( $ocs[0]->get_name, $ocname, "Check OC name again" );

    # Look up the asset in the database and check OCs again.
    ok( $ba = $class->lookup({ id => $baid }), "Lookup $key" );
    ok( @ocs = $ba->get_output_channels, "Get OCs 3" );
    is( scalar @ocs, 1, "Check for 1 OC 3" );
    is( $ocs[0]->get_name, $ocname, "Check OC name 3" );

    # Now check it in and make sure that the OCs are still properly associated
    # with the new version.
    ok( $ba->checkin, "Checkin asset" );
    ok( $ba->save, "Save new version" );
    ok( $ba->checkout({ user__id => 1 }), "Checkout new version" );
    ok( $ba->save, "Save new version" );
    ok( my $version = $ba->get_version, "Get Version number" );
    ok( $ba = $class->lookup({ id => $baid }), "Lookup new version of $key" );
    is( $ba->get_version, $version, "Check version number" );
    ok( @ocs = $ba->get_output_channels, "Get OCs 4" );
    is( scalar @ocs, 1, "Check for 1 OC 4" );
    is( $ocs[0]->get_name, $ocname, "Check OC name 4" );
}

##############################################################################
# Clean up our mess.
##############################################################################
sub cleanup : Test(teardown => 0) {
    my $self = shift;

    # Clean up assets.
    my $key = $self->class->key_name;
    if (my $baids = delete $self->{$key}) {
        $baids = join ', ', @$baids;
        diag "Deleting $key asset IDs $baids";
        # Delete from the asset table...
        Bric::Util::DBI::prepare(qq{
            DELETE FROM $key
            WHERE  id in ($baids)
        })->execute;

        # ...and from the instance table.
        Bric::Util::DBI::prepare(qq{
            DELETE FROM ${key}_instance
            WHERE  ${key}__id in ($baids)
        })->execute;
    }
}

1;
__END__
