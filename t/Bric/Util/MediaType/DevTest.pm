package Bric::Util::MediaType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::MediaType;

sub table { 'media_type' }
my $class = 'Bric::Util::MediaType';

##############################################################################
# Test class methods.
##############################################################################
# Test get_name_by_ext().
sub test_get_name_by_ext : Test(2) {
    my $self = shift;
    is( Bric::Util::MediaType->get_name_by_ext('foo.jpg'), 'image/jpeg',
        "Check image/jpeg" );
    is( Bric::Util::MediaType->get_name_by_ext('foo.jpeg'), 'image/jpeg',
        "Check image/jpeg" );
}


##############################################################################
# Test constructors.
##############################################################################
# test lookup().
sub test_lookup : Test(10) {
    my $self = shift;

    # Look up by ID.
    ok( my $mt = $class->lookup({ id => 48 }),
        "Look up by name 'audio/midi'");

    # Check basic properties.
    is( $mt->get_name, 'audio/midi', "Check name is 'audio/midi''" );
    ok( ! defined $mt->get_description, "No description" );

    # Make sure we got three extensions.
    ok( my @exts = $mt->get_exts, "Get extensions" );
    is_deeply(\@exts, [qw(kar mid midi)], "Check extentions" );

    # Now look up by name.
    ok( $mt = $class->lookup({ name => 'audio/midi'} ),
        "Look up by name 'audio/midi'");

    # Check basic properties again.
    is( $mt->get_name, 'audio/midi', "Check name is 'audio/midi'' again" );
    ok( ! defined $mt->get_description, "No description again" );

    # Make sure we got three extensions again.
    ok( @exts = $mt->get_exts, "Get extensions again" );
    is_deeply(\@exts, [qw(kar mid midi)], "Check extentions again" );

}

##############################################################################
# Test list().
sub test_list : Test(16) {
    my $self = shift;

    # Create a new media type group.
    ok( my $grp = Bric::Util::Grp::MediaType->new({ name => 'Test MTGrp' }),
        "Create group" );

    # Add a couple of media types to it and save it.
    $grp->add_member({ package => $class, id => 48 });
    $grp->add_member({ package => $class, id => 49 });

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @mts = $class->list({ name => 'audio/%'} ),
        "Look up by name 'audio/%'");
    is( scalar @mts, 8, "Check for 8 MTs" );

    my $desc = 'Use when no MIME Type applies, or when they all do.';
    ok( @mts = $class->list({ description => $desc }),
        "Look up by description" );
    is( scalar @mts, 1, "Check for 1 MT" );
    is( $mts[0]->get_description, $desc, "Check description" );

    # Test grp_id.
    ok( @mts = $class->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @mts, 2, "Check for 2 MTs" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = $class->INSTANCE_GROUP_ID;
    foreach my $mt (@mts) {
        is_deeply([sort {$a <=> $b } $mt->get_grp_ids],
                  [$all_grp_id, $grp_id],
                  "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $mts[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id. again
    ok( @mts = $class->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @mts, 1, "Check for 1 MTs" );
}

##############################################################################
# Test list_ids().
sub test_list_ids : Test(9) {
    my $self = shift;

    # Create a new media type group.
    ok( my $grp = Bric::Util::Grp::MediaType->new({ name => 'Test MTGrp' }),
        "Create group" );

    # Add a couple of media types to it and save it.
    $grp->add_member({ package => $class, id => 48 });
    $grp->add_member({ package => $class, id => 49 });

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @mt_ids = $class->list_ids({ name => 'audio/%'} ),
        "Look up by name 'audio/%'");
    is( scalar @mt_ids, 8, "Check for 8 MT IDs" );

    my $desc = 'Use when no MIME Type applies, or when they all do.';
    ok( @mt_ids = $class->list_ids({ description => $desc }),
        "Look up by description" );
    is( scalar @mt_ids, 1, "Check for 1 MT ID" );

    # Test grp_id.
    ok( @mt_ids = $class->list_ids({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @mt_ids, 2, "Check for 2 MT IDs" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save().
sub test_save : Test(21) {
    my $self = shift;
    my $exts = [qw(barby fooby)];
    my $name = 'Foo';
    my $desc = 'Bar';
    my $grp_ids = [$class->INSTANCE_GROUP_ID];

    # Create a new MT.
    ok( my $mt = $class->new({ name        => $name,
                               description => $desc,
                               ext         => $exts }),
        "Create new MT" );

    # Check its attributes.
    is( $mt->get_name, $name, "Check name" );
    is( $mt->get_description, $desc, "Check description" );
    is_deeply( [$mt->get_exts], $exts, "Check extentions" );
    is_deeply( [$mt->get_grp_ids], $grp_ids, "Check group IDs" );

    # Save it and look it up in the database.
    ok( $mt->save, "Save new MT" );
    ok( my $id = $mt->get_id, "Get ID" );
    $self->add_del_ids($id);
    ok( $mt = $class->lookup({ id => $id }), "Look up new MT" );

    # Check its attributes again.
    is( $mt->get_name, $name, "Check name again" );
    is( $mt->get_description, $desc, "Check description again" );
    is_deeply( [$mt->get_exts], $exts, "Check extentions again" );
    is_deeply( [$mt->get_grp_ids], $grp_ids, "Check group IDs again" );

    # Now change its attributes.
    push @$exts, 'yippee';
    $name = 'Harold';
    $desc = 'Ick';
    ok( $mt->set_name($name), "Set its name to '$name'" );
    ok( $mt->set_description($desc), "Set its description to '$desc'" );
    ok( $mt->add_exts('yippee'), "Add extention 'yippee'" );

    # Save it and look it up again.
    ok( $mt->save, "Save it" );
    ok( $mt = $class->lookup({ id => $id }), "Look it up again" );

    # Check its attributes one last time.
    is( $mt->get_name, $name, "Check name final" );
    is( $mt->get_description, $desc, "Check description final" );
    is_deeply( [$mt->get_exts], $exts, "Check extentions final" );
    is_deeply( [$mt->get_grp_ids], $grp_ids, "Check group IDs final" );
}

1;
__END__
