package Bric::Biz::ATType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::ATType;
use Bric::Util::Grp::ATType;
use Bric::Util::DBI ':junction';

sub table {'at_type '}
my $story_att_id = 1;
my $story_class_id = Bric::Biz::ATType::STORY_CLASS_ID;
my $media_class_id = 46;
my $image_class_id = 50;

my %et = ( name => 'Bogus',
           description => 'Bogus ATType',
         );

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(9) {
    my $self = shift;
    ok( my $et = Bric::Biz::ATType->lookup({ id => $story_att_id }),
        "Look up story ATType" );
    is( $et->get_id, $story_att_id, "Check that the ID is the same" );
    # Check a few attributes.
    ok( $et->is_active, "Check that it's activated" );
    ok( !$et->get_fixed_url, "Check not fixed URL" );
    ok( $et->get_top_level, "Check is top level" );
    ok( !$et->get_media, "Check not media" );
    ok( !$et->get_related_story, "Check not related story" );
    ok( !$et->get_related_media, "Check not related media" );
    is( $et->get_biz_class_id, $story_class_id, "Check no biz class ID" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(60) {
    my $self = shift;

    # Create a new element type group.
    ok( my $grp = Bric::Util::Grp::ATType->new({
        name => 'Test ElementTypeGrp'
    }), "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %et;
        # Make sure the name is unique.
        $args{name} .= $n;
        if ($n % 2) {
            # There'll be three of these.
            $args{description} .= $n;
            @args{qw(fixed_url related_media related_story)} = (1,1,1);
        } else {
            # There'll be two of these.
            @args{qw(top_level media biz_class_id)} = (1,1,$media_class_id);
        }

        ok( my $et = Bric::Biz::ATType->new(\%args),
            "Create $args{name}" );
        ok( $et->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($et->get_id);
        $grp->add_member({ obj => $et }) if $n % 2;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @ets = Bric::Biz::ATType->list({ name => "$et{name}%" }),
        "Look up name $et{name}%" );
    is( scalar @ets, 5, "Check for 5 element types" );

    # Try ANY(name).
    ok( @ets = Bric::Biz::ATType->list({
        name => ANY("$et{name}1", 'Insets')
    }), "Look up name ANY('$et{name}1', 'Insets')" );
    is( scalar @ets, 2, "Check for 2 element types" );

    # Try ANY(name + wildcard).
    ok( @ets = Bric::Biz::ATType->list({
        name => ANY("$et{name}%", 'Related%')
    }), "Look up name ANY('$et{name}%', 'Related%')" );
    is( scalar @ets, 7, "Check for 7 element types" );

    # Try ANY(ID).
    ok @ets = Bric::Biz::ATType->list({
        id => ANY($ets[0]->get_id, $ets[1]->get_id )
    }), "Look up ANY(\@ids)";
    is( scalar @ets, 2, "Check for 2 element types" );

    # Try description.
    ok( @ets = Bric::Biz::ATType->list
        ({ description => $et{description} }),
        "Look up description '$et{description}'" );
    is( scalar @ets, 2, "Check for 2 element types" );

    # Try description + wild card.
    ok( @ets = Bric::Biz::ATType->list({
        description => "$et{description}%"
    }), "Look up description '$et{description}%'" );
    is( scalar @ets, 5, "Check for 5 element types" );

    # Try ANY(description).
    ok( @ets = Bric::Biz::ATType->list({
        description => ANY($et{description}, "$et{description}1")
    }), "Look up description ANY('$et{description}', '$et{description}1'" );
    is( scalar @ets, 3, "Check for 3 element types" );

    # Try ANY(description + wildcard).
    ok( @ets = Bric::Biz::ATType->list({
        description => ANY("$et{description}%", "Related%")
    }), "Look up description ANY('$et{description}%', 'Related%'" );
    is( scalar @ets, 7, "Check for 7 element types" );

    # Try grp_id.
    ok( @ets = Bric::Biz::ATType->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ets, 3, "Check for 3 element types" );

    # Try ANY(grp_id).
    ok( @ets = Bric::Biz::ATType->list({ grp_id => ANY ($grp_id) }),
        "Look up grp_id ANY($grp_id)" );
    is( scalar @ets, 3, "Check for 3 element types" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::ATType::INSTANCE_GROUP_ID;
    foreach my $et (@ets) {
        my %grp_ids = map { $_ => 1 } $et->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $ets[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @ets = Bric::Biz::ATType->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ets, 2, "Check for 2 element types" );

    # Try active. There are 7 existing already.
    ok( @ets = Bric::Biz::ATType->list({ active => 1 }),
        "Look up active => 1" );
    is( scalar @ets, 12, "Check for 12 element types" );

    # Try fixed_uri, related_story, and related_media. There's one of each
    # already.
    foreach my $prop (qw(fixed_url related_media related_story)) {
        ok( @ets = Bric::Biz::ATType->list({ $prop => 1 }),
            "Look up $prop => 1" );
        is( scalar @ets, 4, "Check for 4 element types" );

    }

    # Try top_level. There are three already.
    ok( @ets = Bric::Biz::ATType->list({ top_level => 1 }),
        "Look up top_level => 1" );
    is( scalar @ets, 5, "Check for 5 element types" );

    # Try media. There is one already.
    ok( @ets = Bric::Biz::ATType->list({ media => 1 }),
        "Look up media => 1" );
    is( scalar @ets, 3, "Check for 3 element types" );

    # Try story class type. There are six already.
    ok( @ets = Bric::Biz::ATType->list({ biz_class_id => $story_class_id }),
        "Look up biz_class_id $story_class_id" );
    is( scalar @ets, 9, "Check for 9 element types" );

    # Try media class type. There is one already.
    ok( @ets = Bric::Biz::ATType->list({ biz_class_id => $media_class_id }),
        "Look up biz_class_id $media_class_id" );
    is( scalar @ets, 2, "Check for 1 element types" );

    # Try image class type.
    ok( @ets = Bric::Biz::ATType->list({ biz_class_id => $image_class_id }),
        "Look up biz_class_id $image_class_id" );
    is( scalar @ets, 1, "Check for 1 element type" );

    # Try story and media class types.
    ok( @ets = Bric::Biz::ATType->list({
        biz_class_id => ANY($story_class_id, $media_class_id),
    }), "Look up biz_class_id ANY($story_class_id, $media_class_id)" );
    is( scalar @ets, 11, "Check for 11 element types" );

}

##############################################################################
# Test class methods.
##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(21) {
    my $self = shift;

    # Create a new element type group.
    ok( my $grp = Bric::Util::Grp::ATType->new
        ({ name => 'Test ElementTypeGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %et;
        # Make sure the name is unique.
        $args{name} .= $n;
        if ($n % 2) {
            # There'll be three of these.
            $args{description} .= $n;
            @args{qw(fixed_url related_media related_story)} = (1,1,1);
        } else {
            # There'll be two of these.
            @args{qw(top_level media biz_class_id)} = (1,1,$media_class_id);
        }

        ok( my $et = Bric::Biz::ATType->new(\%args),
            "Create $args{name}" );
        ok( $et->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($et->get_id);
        $grp->add_member({ obj => $et }) if $n % 2;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @et_ids = Bric::Biz::ATType->list_ids({ name => "$et{name}%" }),
        "Look up name $et{name}%" );
    is( scalar @et_ids, 5, "Check for 5 element types" );

    # Try description.
    ok( @et_ids = Bric::Biz::ATType->list_ids
        ({ description => $et{description} }),
        "Look up description '$et{description}'" );
    is( scalar @et_ids, 2, "Check for 2 element types" );

    # Try grp_id.
    ok( @et_ids = Bric::Biz::ATType->list_ids({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @et_ids, 3, "Check for 3 element types" );

    # Try active. There are 7 existing already.
    ok( @et_ids = Bric::Biz::ATType->list_ids({ active => 1 }),
        "Look up active => 1" );
    is( scalar @et_ids, 12, "Check for 12 element types" );
}

##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::ATType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::ATType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $att = Bric::Biz::ATType->new({ name => 'NewFoo' }),
        "Create ATType" );
    ok( my @meths = $att->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($att), 'NewFoo', "Check name 'NewFoo'" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save()
sub test_save : Test(9) {
    my $self = shift;
    my %args = %et;
    ok( my $et = Bric::Biz::ATType->new(\%args),
        "Create element type" );
    ok( $et->save, "Save the element type" );
    ok( my $etid = $et->get_id, "Get the element type ID" );
    $self->add_del_ids($etid);
    ok( $et = Bric::Biz::ATType->lookup({ id => $etid }),
        "Look up the new element type" );
    ok( my $old_name = $et->get_name, "Get its name" );
    my $new_name = $old_name . ' Foo';
    ok( $et->set_name($new_name), "Set its name to '$new_name'" );
    ok( $et->save, "Save it" );
    ok( Bric::Biz::ATType->lookup({ id => $etid }),
        "Look it up again" );
    is( $et->get_name, $new_name, "Check name is '$new_name'" );
}

1;
__END__
