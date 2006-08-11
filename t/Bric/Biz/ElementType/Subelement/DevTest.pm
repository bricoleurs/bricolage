package Bric::Biz::ElementType::Subelement::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::ElementType::DevTest);
use Test::More;
use Bric::Biz::ElementType::Subelement;

##############################################################################
# Test constructors.
##############################################################################
# Test the href() constructor.
sub test_href : Test(19) {
    my $self = shift;
     ok( my $href = Bric::Biz::ElementType::Subelement->href
        ({ element_type_id => 1 }), "Get Story's Subelement ElementTypes" );

    is( scalar keys %$href, 2, "Check for two subelements" );
    ok( my $sube = $href->{7}, "Check for subelement ID 7" );
    is( $sube->get_name, 'Pull Quote', "Check Subelement name 'Pull Quote'" );
    ok( $sube = $href->{10}, "Check for subelement ID 10" );
    is( $sube->get_name, 'Page', "Check Subelement name 'Page'" );

    # Check the occurrence attributes.
    is( scalar $sube->get_min_occurrence, 0, "Check the min occurrence");
    ok( $sube->set_min_occurrence(1), "Set the min occurrence to 1");
    is( scalar $sube->get_min_occurrence, 1, "Check the min occurrence");
    ok( $sube->set_min_occurrence(0), "Set the min occurrence back to 0");
    is( scalar $sube->get_max_occurrence, 0, "Check the max occurrence");
    ok( $sube->set_max_occurrence(1), "Set the max occurrence to 1");
    is( scalar $sube->get_max_occurrence, 1, "Check the max occurrence");
    ok( $sube->set_max_occurrence(0), "Set the max occurrence back to 0");

    # Check the child_id attribute.
    is( $sube->get_parent_id, 1, "Check parent_id eq 1" );
    is( $sube->get_id, 10, "Check the child id eq 1" );
    ok( $sube->set_parent_id(2), "Set parent_id to 2" );
    is( $sube->get_parent_id, 2, "Check parent_id eq 2" );
    ok( $sube->set_parent_id(1), "Set parent_id back to 1" );
}

##############################################################################
# Test the new() constructor.
sub test_new : Test(17) {
    my $self = shift;
    # Try creating one from an ElementType ID.
    ok( my $sube = Bric::Biz::ElementType::Subelement->new({child_id => 1}),
        "Create Subelement from ElementType ID 1" );
    isa_ok($sube, 'Bric::Biz::ElementType::Subelement');
    isa_ok($sube, 'Bric::Biz::ElementType');
    is( $sube->get_name, "Story", "Check name 'Story'" );

    ok( $sube = Bric::Biz::ElementType::Subelement->new({min_occurrence => 1,
                                                       site_id => 100}),
        "Create Subelement with min occurrence" );
    is( scalar $sube->get_min_occurrence, 1, "Subelement is has right occurrence" );

    ok( $sube = Bric::Biz::ElementType::Subelement->new({max_occurrence => 3,
                                                       site_id => 100}),
        "Create Subelement with max occurrence" );
    is( scalar $sube->get_max_occurrence, 3, "Subelement is has right occurrence" );

    # Create a new element type object.
    my %et = (
        name        => 'Test ElementType',
        key_name    => 'test_element_type',
        description => 'Testing Element Type API',
    );

    ok( my $et = Bric::Biz::ElementType->new, 'Create empty element type' );
    ok( $et = Bric::Biz::ElementType->new(\%et), 'Create a new element');
    isa_ok($et, 'Bric::Biz::ElementType');
    isa_ok($et, 'Bric');
    ok( $et->save, "Save the ElementType");
    ok( my $etid = $et->get_id, "Get the id" );
    $self->add_del_ids([$etid]);

    # Create a new Subelement.
    ok( $sube = Bric::Biz::ElementType::Subelement->new({ child_id => $etid }),
        "Create Subelement from element type ID $etid" );
    # It should not yet have a Map ID!
    ok(! defined $sube->_get('_map_id'), "Map ID is undefined" );
    # It should have only one group membership.
    my @gids = $sube->get_grp_ids;
    is( scalar @gids, 1, "Check for one group ID" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save() method's update ability.
sub test_update : Test(13) {
    my $self = shift;
    # Grab an existing subelement from the database.
    ok( my $href = Bric::Biz::ElementType::Subelement->href
        ({ element_type_id => 1 }), "Get Story subelements" );
    ok( my $sube = $href->{10}, "Grab subelement ID 10" );

    # Set min occurrence to 3.
    is( $sube->get_min_occurrence, 0, "Check min occurrence is 0" );
    ok( $sube->set_min_occurrence(3), "Set min occurrence to 3" );
    ok( $sube->save, "Save the subelement" );

    # Look it up again.
    ok( $href = Bric::Biz::ElementType::Subelement->href
        ({ element_type_id => 1 }), "Get Story subelements again" );
    ok( $sube = $href->{10}, "Grab subelement ID 10 again" );

    # Min occurrence should be 3, now.
    is( $sube->get_min_occurrence, 3, "Check min_occurrence is 3" );
    ok( $sube->set_min_occurrence(0), "Set min_occurrence back to 0" );
    ok( $sube->save, "Save subelement again" );

    # Look it up one last time.
    ok( $href = Bric::Biz::ElementType::Subelement->href
        ({ element_id => 1 }), "Get Story subelements last" );
    ok( $sube = $href->{10}, "Grab subelement ID 10 last" );
    is( $sube->get_min_occurrence, 0, "Check min_occurrence is 0 last" );
}

##############################################################################
# Test save()'s insert and delete abilities.
sub test_insert : Test(10) {
    my $self = shift;
    # Create a new subelement.
    ok(my $sube = Bric::Biz::ElementType::Subelement->new({
        name       => "Foober",
        key_name   => "foober",
        element_type_id => 1,
        parent_id =>2,
        site_id    => 100,
    }), "Create a brand new subelement" );

    # Now save it. It should be inserted as both an ElementType and as an Subelement.
    ok( $sube->save, "Save new Subelement" );

    ok( my $etid = $sube->get_id, "Get ID" );
    $self->add_del_ids([$etid]);

    # Now retreive it.
    ok( my $href = Bric::Biz::ElementType::Subelement->href
        ({ element_type_id => 2 }), "Get subelements with parent id of 2" );
    # Check its attributes.
    is( $sube->get_id, $etid, "Check ID" );
    is( $sube->get_name, "Foober", "Check name 'Foober'" );

    # Now delete it.
    ok( $sube->remove, "Remove Subelement" );
    ok( $sube->save, "Save removed Subelement" );

    # Now try to retreive it.
    ok( $href = Bric::Biz::ElementType::Subelement->href
        ({ element_type_id => 1 }), "Get Story Subelements" );
    ok( ! exists $href->{$etid}, "ID $etid gone" );
}

##############################################################################
# A concentrated test to make sure that the right subelement gets deleted no
# matter how many there are and which was changed most recently.
sub test_delete : Test(24) {
    my $self = shift;
    my @subes;
    # Create some Subelement objects
    foreach my $name (qw(Gar GarGar GarGarGar Bar BarBar BarBarBar)) {
        ok( my $sube = Bric::Biz::ElementType::Subelement->new({
            name            => $name,
            key_name        => $name . "_key",
            element_type_id => 1,
            parent_id       => 2,
            site_id         => 100,
        }), "Create Subelement '$name'" );

        # Now save it. It should be inserted as both an ElementType and as a Subelement.
        ok( $sube->save, "Save Subelement '$name'" );
        $self->add_del_ids([$sube->get_id]);
        push @subes, $sube;
    }

    # Change and save the fourth Subelement, so that it will be the most recently
    # updated, which might then cause PostgreSQL to return it instead of
    # another one.
    ok( $subes[3]->set_name('Ha Ha!'), "Set fourth Subelement name's to 'Ha Ha!'" );
    ok( $subes[3]->save, "Save subelement 'Ha Ha!'" );

    # Try deleting the third OC.
    ok( my $testid = $subes[2]->get_id, "Get third Subelement's ID" );
    ok( $subes[2]->remove, "Remove third Subelement" );
    ok( $subes[2]->save, "Save third Subelement" );

    # Now get the hash ref of all subelements associated with element
    # ID 1.
    ok( my $href = Bric::Biz::ElementType::Subelement->href({
        element_type_id => 1
    }), "Get Subelement href" );

    ok( ! exists $href->{$testid}, "ID $testid gone" );

    # Now try deleting the first and see if we get the right one.
    ok( $testid = $subes[0]->get_id, "Get first Subelement's ID" );
    ok( $subes[0]->remove, "Remove first subelement" );
    ok( $subes[0]->save, "Save first subelement" );

    # Get the hash ref of all subelements associated with element ID 1
    # again.
    ok( $href = Bric::Biz::ElementType::Subelement->href({
        element_type_id => 1
    }), "Get subelement href again" );

    ok( ! exists $href->{$testid}, "ID $testid gone" );
}

1;
__END__
