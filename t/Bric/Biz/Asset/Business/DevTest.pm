package Bric::Biz::Asset::Business::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::DevTest);
use Test::More;
use Test::Exception;
use Bric::Biz::Asset::Business;
use Bric::Biz::ElementType;
use Bric::Biz::Person;
use Bric::Util::Grp::Parts::Member::Contrib;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Overrid this method in subclasses.
sub class { 'Bric::Biz::Asset::Business' }

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    return (
        element_type  => $self->get_elem,
        user__id      => $self->user_id,
        source__id    => 1,
        primary_oc_id => 1,
        site_id       => 100,
    );
}

sub pe {
    my $self = shift;
    diag @_;
    my $at = Bric::Biz::ElementType->lookup({ id => 1 });
    foreach my $oc ($at->get_output_channels) {
        diag $oc->get_name;
    }
}


sub cleanup_orgs : Test(teardown) {
    Bric::Util::DBI::prepare(qq{DELETE FROM org  WHERE id > 1023})->execute;
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({ $self->new_args, @_ });
}

##############################################################################
# Constructs a new contributor object.
sub contrib {
    my $self = shift;
    return $self->{contrib} if $self->{contrib};
    my $person = Bric::Biz::Person->new({ lname => 'Wall',
                                          fname => 'Larry' });
    $person->save;

    # Grab the "Writers" group and add Larry.
    my $group = Bric::Util::Grp::Person->lookup({ id => 39 });
    my $member = $group->add_member({ obj => $person });
    $group->save;
    $self->add_del_ids($member->get_id, 'member');
    $self->add_del_ids($person->get_id, 'person');
    return $self->{contrib} = Bric::Util::Grp::Parts::Member::Contrib->lookup
      ({ id => $member->get_id });
}

##############################################################################
# Test basic attributes
##############################################################################
sub test_atts : Test(9) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
    return "Attributes tested only by subclass" if $key eq 'biz';
    ok( my $ba = $self->construct(name => 'Foo'), "Construct $key object" );
    my %args = $self->new_args;
    like uc $ba->get_uuid,
      qr/[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/,
      "The UUID should be a UUID string";
    is $ba->get_title, 'Foo', "The title should be set";
    is $ba->get_source__id, $args{source__id}, "The source ID should be set";
    is $ba->get_user__id, $args{user__id}, "The user ID should be set";
    is $ba->get_element_type_id, $args{element_type}->get_id,
      "The element type should be set";
    is $ba->get_primary_oc_id, $args{primary_oc_id},
      "The primary OC ID should be set";
    is $ba->get_site_id, $args{site_id}, "The site ID should be set";
}

##############################################################################
# Test output channel associations.
##############################################################################
sub test_oc : Test(36) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
     return "OCs tested only by subclass" if $key eq 'biz';
    ok( my $ba = $self->construct, "Construct $key object" );
    ok( my $elem = $self->get_elem, "Get element type object" );

    # Make sure there are the same of OCs yet as in the element type.
    ok( my @eocs = $elem->get_output_channels, "Get Element type OCs" );
    ok( my @ocs = $ba->get_output_channels, "Get $key OCs" );
    is( scalar @ocs, 1, "Check for 1 OC" );
    is( scalar @eocs, scalar @ocs, "Check for same number of OCs" );
    is( $eocs[0]->get_id, $ocs[0]->get_id, "Compare for same OC ID" );

    # Save the asset object.
    ok( $ba->save, "Save ST" );
    ok( my $baid = $ba->get_id, "Get ST ID" );
    $self->add_del_ids($baid, $key);

    # Grab the element type's first OC.
    ok( my $oc = $eocs[0], "Grab the first OC" );
    ok( my $ocname = $oc->get_name, "Get the OC's name" );

    # Try removing the OC.
    ok( $ba->del_output_channels($oc), "Delete OC from $key" );
    @ocs = $ba->get_output_channels;
    is( scalar @ocs, 0, "No more OCs" );

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
    ok( $ba->checkout({ user__id => $self->user_id }), "Checkout new version" );
    ok( $ba->save, "Save new version" );
    ok( my $version = $ba->get_version, "Get Version number" );
    ok( $ba = $class->lookup({ id => $baid }), "Lookup new version of $key" );
    is( $ba->get_version, $version, "Check version number" );
    ok( @ocs = $ba->get_output_channels, "Get OCs 4" );
    is( scalar @ocs, 1, "Check for 1 OC 4" );
    is( $ocs[0]->get_name, $ocname, "Check OC name 4" );
}

##############################################################################
# Test primary_oc_id property.
##############################################################################
sub test_primary_oc_id : Test(8) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
    return "OCs tested only by subclass" if $key eq 'biz';

    ok( my $ba = $self->construct( name => 'Flubberman',
                                   slug => 'hugoman'),
        "Construct asset" );
    ok( $ba->save, "Save asset" );

    # Save the ID for cleanup.
    ok( my $id = $ba->get_id, "Get ID" );
    $self->add_del_ids([$id], $key);

    is( $ba->get_primary_oc_id, 1, "Check primary OC ID" );

    # Try list().
    ok( my @bas = $class->list({ primary_oc_id => 1,
                                 user__id => $self->user_id }),
        "Get asset list" );
    is( scalar @bas, 1, "Check for one asset" );
    is( $bas[0]->get_primary_oc_id, 1, "Check for OC ID 1" );
}

##############################################################################
# Test output_channel_id parameter.
##############################################################################
sub test_oc_id : Test(14) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
    return "OCs tested only by subclass" if $key eq 'biz';

    # Construct a secondary output channel.
    ok ( my $oc = Bric::Biz::OutputChannel->new({ name        => 'Bogus',
                                                  description => 'Bogus OC',
                                                  site_id     => 100,
                                                  protocol    => 'http://',
                                                }),
       "Create bogus OC" );
    ok( $oc->save, "Save bogus OC" );
    ok( my $ocid = $oc->get_id, "Get bogus OC ID" );
    $self->add_del_ids($ocid, 'output_channel' );

    # Construct a new document.
    ok( my $ba = $self->construct( name => 'Flubberman',
                                   slug => 'hugoman'),
        "Construct document" );
    # Add the new output channel to it and save it.
    ok( $ba->add_output_channels($oc), "Add bogus OC" );
    ok( $ba->save, "Save document" );

    # Save the ID for cleanup.
    ok( my $id = $ba->get_id, "Get ID" );
    $self->add_del_ids([$id], $key);

    is( $ba->get_primary_oc_id, 1, "Check primary OC ID" );

    # Try output_channel_id parameter to list with primary OC ID.
    ok( my @bas = $class->list({ output_channel_id => 1,
                                 user__id => $self->user_id }),
        "Get asset list" );
    is( scalar @bas, 1, "Check for one asset" );
    is( $bas[0]->get_primary_oc_id, 1, "Check for OC ID 1" );

    # Try output_channel_id parameter to list with secondary OC ID.
    ok( @bas = $class->list({ output_channel_id => $ocid,
                                 user__id => $self->user_id }),
        "Get asset list" );
    is( scalar @bas, 1, "Check for one asset" );
}

##############################################################################
# Test aliasing.
##############################################################################
sub test_alias : Test(43) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
     return "Aliases tested only by subclass" if $key eq 'biz';

    throws_ok { $class->new }
      qr/Cannot create an asset without an element type or alias ID/,
      "Check that you cannot create empty stories";

    throws_ok { $class->new({ alias_id => 1, element_type_id => 1}) }
      qr/Cannot create an asset with both an element type and an alias ID/,
      "Check that you cannot create a asset with both element_type_id and an ".
      "alias";

    throws_ok { $class->new({ alias_id => 1, element_type => 1}) }
      qr/Cannot create an asset with both an element type and an alias ID/,
      "Check that you cannot create a asset with both element type and an ".
      "alias";

    ok( my $ba = $self->construct( name => 'Victor',
                                   slug => 'hugo' ),
        'Construct asset');
    ok( $ba->save, "Save asset" );

    # Save the ID for cleanup.
    ok( my $sid = $ba->get_id, "Get ID" );
    $self->add_del_ids($sid);

    ok( $ba = $class->lookup({id => $ba->get_id }), "Reload");

    throws_ok { $class->new({ alias_id => $ba->get_id }) }
      qr /Cannot create an asset without a site/,
      "Check that you need the Site parameter";

    # Create an extra site
    my $site1 = Bric::Biz::Site->new({ name => __PACKAGE__ . "1",
                                       domain_name => __PACKAGE__ . "1" });

    ok( $site1->save, "Create first dummy site");
    my $site1_id = $site1->get_id;
    $self->add_del_ids($site1_id, 'site');

    throws_ok { $class->new({ alias_id => $ba->get_id,
                              site_id => $site1_id }) }
      qr/Cannot create an alias to an asset based on an element type that is not associated with this site/,
      "Check that an element type needs to be associated with a site ".
      "for a target to aliasable";

    my $element = $ba->get_element_type();

    $element->add_sites([$site1]);

    # Add a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name    => __PACKAGE__ . "1",
                                                 site_id => $site1_id }),
        "Create OC" );
    ok( $oc->save, "Save OC" );
    ok( my $ocid = $oc->get_id, "Get OC ID" );
    $self->add_del_ids($ocid, 'output_channel');

    ok( $element->add_output_channels([$ocid]), "Associate OC" );
    ok( $element->set_primary_oc_id($ocid, $site1_id), "Associate primary OC" );
    ok( $element->save, "Save element" );

    ok( my $alias_asset = $class->new({ alias_id => $ba->get_id,
                                        site_id  => $site1_id,
                                        user__id => $self->user_id,
                                      }),
        "Create an alias asset" );

    isnt($alias_asset->get_element_type, undef,
         "Check that we get an element type object");

    is($alias_asset->get_element_type->get_id,
       $ba->get_element_type->get_id,
       "Check that alias_asset has an element type object");

    if ($class->key_name eq 'story') {
        is($alias_asset->get_slug, $ba->get_slug, "Check slug");
          # Change the slug to ensure it has a unique URI.
        ok( $alias_asset->set_slug('slug'), "Set slug" );

    } else {
      SKIP: {
            skip "No slug on media assets", 2;
        }
    }

    ok( $alias_asset->save , "Try to save it");
    my $alias_id = $alias_asset->get_id;
    $self->add_del_ids($alias_id);
    like($alias_id, qr/^\d+$/, "alias id should be a number");

    ok( $alias_asset = $class->lookup({ id => $alias_id }),
        "Refetch the alias");

    isa_ok($alias_asset, $class,
           "Checking that we got $alias_id back");

    is($alias_asset->get_alias_id, $ba->get_id,
       "Does it still point to the correct asset");

    is_deeply($ba->get_element, $alias_asset->get_element,
              "Should get identical elements");

    is_deeply([$alias_asset->get_all_keywords],
              [$ba->get_all_keywords],
              "Check get_all_keywords");

    is_deeply([$alias_asset->get_keywords],
              [$ba->get_keywords],
              "Check get_keywords");

    is_deeply([$alias_asset->get_contributors],
              [$ba->get_contributors],
              "Check get_contributors");

    # Try adding relateds.
    ok my $rel = $self->construct(
        name => 'Howdy',
        slug => 'doody',
        element_type => $element,
    ), 'Create a document for relating';
    ok $rel->save;
    $self->add_del_ids( $rel->get_id );

    ok my $elem = $ba->get_element;
    my $meth = "set_related_$key";
    ok $elem->$meth($rel), 'Add the related asset';
    ok $elem->save, 'Save the element';
    is $rel->get_id, $ba->get_related_objects->[0]->get_id,
        'The related should now be related to the original asset';

    # The alias should not return any relateds, however.
    is undef, $alias_asset->get_related_objects, 'The alias should see no relateds';

    # But if we alias the related to the same site, it should be returnable.
    ok my $rel_alias = $class->new({
        alias_id => $rel->get_id,
        site_id  => $site1_id,
        user__id => $self->user_id,
    }), 'Alias the related';

    ok $rel_alias->save , 'Save the related alias';
    my $rel_alias_id = $rel_alias->get_id;
    $self->add_del_ids($rel_alias_id);
    is $rel_alias_id, $alias_asset->get_related_objects->[0]->get_id,
        'The related alias should be related to the alias';

    # Clean up our mess.
    ok( $element->remove_sites([$site1]), "Remove site" );
    ok( $element->save, "Save element type" );
}

sub test_mark_as_published :Test(11) {
    my $self = shift;
    my $class = $self->class;
    ok my $key = $class->key_name, 'Get key';
    return "Publish marking tested only by subclass" if $key eq 'biz';
    ok my $doc = $self->construct(name => 'Foo'), "Construct $key object";

    # Before marking.
    ok !$doc->get_publish_status, 'Should not be published';
    ok !$doc->get_publish_date, 'Should have no publish date';
    ok !$doc->get_first_publish_date, 'Should have no first publish date';

    # Mark it.
    is $doc->mark_as_published, $doc,
        'Should get the doc back when marking as published';

    # After marking.
    ok $doc->get_publish_status, 'Should be published';
    ok $doc->get_publish_date, 'Should have publish date';
    ok $doc->get_first_publish_date, 'Should have first publish date';
    is $doc->get_publish_date, $doc->get_first_publish_date,
        'Publish date and first publish date should be the same';
    ok !$doc->get_id, 'Should have no ID';
}


1;
__END__
