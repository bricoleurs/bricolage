package Bric::Biz::Asset::Business::Media::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Media::Image;

sub class { 'Bric::Biz::Asset::Business::Media' }
sub table { 'media' }

my ($CATEGORY) = Bric::Biz::Category->list();

# this will be filled during setup
my $OBJ_IDS = {};
my $OBJ = {};
my @CATEGORY_GRP_IDS;
my @WORKFLOW_GRP_IDS;
my @DESK_GRP_IDS;
my @MEDIA_GRP_IDS;
my @ALL_DESK_GRP_IDS;
my @REQ_DESK_GRP_IDS;
my @EXP_GRP_IDS;



##############################################################################
# The element object we'll use throughout.
my $elem;
sub get_elem {
    $elem ||= Bric::Biz::AssetType->lookup({ id => 4 });
    $elem;
}

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    ( element       => $self->get_elem,
      user__id      => $self->user_id,
      file_name     => 'fun.foo',
      source__id    => 1,
      primary_oc_id => 1,
    )
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({ $self->new_args, @_ });
}

##############################################################################
# Test the SELECT methods
##############################################################################

sub test_select_methods: Test(41) {
    my $self = shift;

    # let's grab existing 'All' group info
    my $all_workflow_grp_id = Bric::Util::Grp->lookup({ name => 'All Workflows' })->get_id();
    my $all_cats_grp_id = Bric::Util::Grp->lookup({ name => 'All Categories' })->get_id();
    my $all_desks_grp_id = Bric::Util::Grp->lookup({ name => 'All Desks' })->get_id();
    my $all_media_grp_id = Bric::Util::Grp->lookup({ name => 'All Media' })->get_id();

    # now we'll create some test objects
    my ($i);
    for ($i = 0; $i < 5; $i++) {
        my $time = time;
        my ($cat, $desk, $workflow, $grp);
        # create categories
        $cat = Bric::Biz::Category->new({ site_id => 100,
                                          name => "_test_$time.$i",
                                          description => '',
                                          directory => "_test_$time.$i",
                                       });
        $CATEGORY->add_child([$cat]);
        $cat->save();
        push @{$OBJ_IDS->{category}}, $cat->get_id();
        push @{$OBJ->{category}}, $cat;
        # create some category groups
        $grp = Bric::Util::Grp::CategorySet->new({ name => "_test_$time.$i",
                                                   description => '',
                                                   obj => $cat });

        $grp->add_member({obj => $cat });
        # save the group ids
        $grp->save();
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @CATEGORY_GRP_IDS, $grp->get_id();

        # create desks 
        $desk = Bric::Biz::Workflow::Parts::Desk->new({ 
                                        name => "_test_$time.$i", 
                                        description => '',
                                     });
        $desk->save();
        push @{$OBJ_IDS->{desk}}, $desk->get_id();
        push @{$OBJ->{desk}}, $desk;
        # create some desk groups
        $grp = Bric::Util::Grp::Desk->new({ name => "_test_$time.$i",
                                            description => '',
                                            obj => $desk,
                                         });
        # save the group ids
        $grp->add_member({ obj => $desk });
        $grp->save();
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @DESK_GRP_IDS, $grp->get_id();

        # create workflows
        $workflow = Bric::Biz::Workflow->new({
                                        type => Bric::Biz::Workflow::MEDIA_WORKFLOW,
                                        name => "_test_$time.$i",
                                        start_desk => $desk,
                                        description => 'test',
                                        site_id => 100, #Use default site_id
                                     });
        $workflow->save();
        push @ALL_DESK_GRP_IDS, $workflow->get_all_desk_grp_id;
        push @REQ_DESK_GRP_IDS, $workflow->get_req_desk_grp_id;
        push @{$OBJ_IDS->{workflow}}, $workflow->get_id();
        push @{$OBJ->{workflow}}, $workflow;
        # create some workflow groups
        $grp = Bric::Util::Grp::Workflow->new({ name => "_test_$time.$i",
                                                description => '',
                                                obj => $workflow,
                                             });
        # save the group ids
        $grp->add_member({ obj => $workflow });
        $grp->save();
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @WORKFLOW_GRP_IDS, $grp->get_id();
        
        # create some media groups
        $grp = Bric::Util::Grp::Media->new({ name => "_GRP_test_$time.$i" });
        # save the group ids
        $grp->save();
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @{$OBJ->{media_grp}}, $grp;
        push @MEDIA_GRP_IDS, $grp->get_id();
    }

    # set up to do the deletes
    foreach my $table (qw(grp category workflow desk)) {
        $self->add_del_ids( $OBJ_IDS->{$table}, $table );
    }

    # look up a media element
    my ($element) = get_elem;

    # and a user
    my $admin_id = $self->user_id();

    # create some media
    my (@media, $time, $got, $expected);

    # A media with one category (admin user)
    $time = time;
    $media[0] = class->new({
                               name        => "_test_$time",
                               file_name   => 'test.foo',
                               description => 'this is a test',
                               priority    => 1,
                               source__id  => 1,
                               user__id    => $admin_id,
                               element     => $element, 
                           });
    $media[0]->set_category__id($OBJ->{category}->[0]->get_id());
    $media[0]->save();
    push @{$OBJ_IDS->{media}}, $media[0]->get_id();
    $self->add_del_ids( $media[0]->get_id() );

    # Try doing a lookup 
    $expected = $media[0];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[0] }), 'can we call lookup on a Media' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), '... does it have the right desc');

    # check the URI
    my $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri(), qr/^$exp_uri/, '...does the uri match the category');

    # check the grp IDs
    my $exp_grp_ids = [ $all_cats_grp_id, $all_media_grp_id, $OBJ_IDS->{grp}->[0] ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    my $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... with multiple cats
    $time = time;
    $media[1] = class->new({
                               name        => "_test_$time",
                               file_name   => 'test.foo',
                               description => 'this is a test',
                               priority    => 1,
                               source__id  => 1,
                               user__id    => $admin_id,
                               element     => $element, 
                           });
    $media[1]->set_category__id($OBJ->{category}->[1]->get_id());
    $media[1]->save();
    push @{$OBJ_IDS->{media}}, $media[1]->get_id();
    $self->add_del_ids( $media[1]->get_id());

    # Try doing a lookup 
    $expected = $media[1];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[1] }), 'can we call lookup on a Media with multiple categories' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[1]->get_uri;
    like( $got->get_primary_uri(), qr/^$exp_uri/, '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ $all_cats_grp_id, 
                     $all_media_grp_id, 
                     $CATEGORY_GRP_IDS[1],
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... as a grp member
    $time = time;
    $media[2] = class->new({
                               name        => "_test_$time",
                               file_name   => 'test.foo',
                               description => 'this is a test',
                               priority    => 1,
                               source__id  => 1,
                               user__id    => $admin_id,
                               element     => $element, 
                           });
    $media[2]->set_category__id( $OBJ->{category}->[0]->get_id() );
    $media[2]->save();
    push @{$OBJ_IDS->{media}}, $media[2]->get_id();
    $self->add_del_ids( $media[2]->get_id() );

    $OBJ->{media_grp}->[0]->add_member({ obj => $media[2] });
    $OBJ->{media_grp}->[0]->save();

    $expected = $media[2];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[2] }), 'can we call lookup on a Media which is itself in a grp' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri(), qr/^$exp_uri/, '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ $all_cats_grp_id, 
                     $all_media_grp_id,
                     $CATEGORY_GRP_IDS[0],
                     $MEDIA_GRP_IDS[0],
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... a bunch of grps
    $time = time;
    $media[3] = class->new({
                               name        => "_test_$time",
                               file_name   => 'test.foo',
                               description => 'this is a test',
                               priority    => 1,
                               source__id  => 1,
                               user__id    => $admin_id,
                               element     => $element, 
                           });
    $media[3]->set_category__id( $OBJ->{category}->[0]->get_id() );
    $media[3]->save();
    push @{$OBJ_IDS->{media}}, $media[3]->get_id();
    $self->add_del_ids( $media[3]->get_id() );

    $OBJ->{media_grp}->[0]->add_member({ obj => $media[3] });
    $OBJ->{media_grp}->[0]->save();

    $OBJ->{media_grp}->[1]->add_member({ obj => $media[3] });
    $OBJ->{media_grp}->[1]->save();

    $OBJ->{media_grp}->[2]->add_member({ obj => $media[3] });
    $OBJ->{media_grp}->[2]->save();

    $OBJ->{media_grp}->[3]->add_member({ obj => $media[3] });
    $OBJ->{media_grp}->[3]->save();

    $OBJ->{media_grp}->[4]->add_member({ obj => $media[3] });
    $OBJ->{media_grp}->[4]->save();

    $expected = $media[3];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[3] }), 'can we call lookup on a Media which is itself in a grp' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri(), qr/^$exp_uri/, '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ $all_cats_grp_id, 
                     $all_media_grp_id,
                     $CATEGORY_GRP_IDS[0],
                     $MEDIA_GRP_IDS[0],
                     $MEDIA_GRP_IDS[1],
                     $MEDIA_GRP_IDS[2],
                     $MEDIA_GRP_IDS[3],
                     $MEDIA_GRP_IDS[4],
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... now try a workflow
    $time = time;
    $media[4] = class->new({
                               name        => "_test_$time",
                               file_name   => 'test.foo',
                               description => 'this is a test',
                               priority    => 1,
                               source__id  => 1,
                               user__id    => $admin_id,
                               element     => $element, 
                           });
    $media[4]->set_category__id($OBJ->{category}->[0]->get_id());
    $media[4]->set_workflow_id( $OBJ->{workflow}->[0]->get_id() );
    $media[4]->save();
    push @{$OBJ_IDS->{media}}, $media[4]->get_id();
    $self->add_del_ids( $media[4]->get_id() );

    # add it to the workflow

    # Try doing a lookup 
    $expected = $media[4];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[4] }), 'can we call lookup on a Media' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri(), qr/^$exp_uri/, '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ 
                        $all_workflow_grp_id,
                        $all_cats_grp_id, 
                        $all_media_grp_id, 
                        $CATEGORY_GRP_IDS[0],
                        $WORKFLOW_GRP_IDS[0],
                    ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... desk
    $time = time;
    $media[5] = class->new({
                               name        => "_test_$time",
                               file_name   => 'test.foo',
                               description => 'this is a test',
                               priority    => 1,
                               source__id  => 1,
                               user__id    => $admin_id,
                               element     => $element, 
                           });
    $media[5]->set_category__id($OBJ->{category}->[0]->get_id());
    $media[5]->set_workflow_id( $OBJ->{workflow}->[0]->get_id() );
    $media[5]->set_current_desk( $OBJ->{desk}->[0] );
    $media[5]->save();
    push @{$OBJ_IDS->{media}}, $media[5]->get_id();
    $self->add_del_ids( $media[5]->get_id() );

    # add it to the workflow

    # Try doing a lookup 
    $expected = $media[5];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[5] } ), 
      'can we call lookup on a Media' );
    is( $got->get_name(), $expected->get_name(), 
      '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), 
      '... does it have the right desc'); 
    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri(), qr/^$exp_uri/, 
      '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ 
                        $all_workflow_grp_id,
                        $all_cats_grp_id, 
                        $all_media_grp_id, 
                        $all_desks_grp_id, 
                        $CATEGORY_GRP_IDS[0],
                        $DESK_GRP_IDS[0],
                        $ALL_DESK_GRP_IDS[0],
                        $REQ_DESK_GRP_IDS[0],
                        $WORKFLOW_GRP_IDS[0],
                    ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # try listing something up by at least key in each table
    # be sure to try to get them both as a ref and a list
    my @got_ids;
    my @got_grp_ids;

    ok( my @got = class->list({ name => '_test%'}), 'lets do a search by name' );
    ok( $got = class->list({ name => '_test%', Order => 'id' }), 'lets do a search by name' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id();
        push @got_grp_ids, \@{$_->get_grp_ids()};
    }
    eq_set( \@got_ids, $OBJ_IDS->{media}, '... did we get the right list of ids out' );
    eq_set( \@got_grp_ids, \@EXP_GRP_IDS, '... and did we get the right grp_ids' );
    undef @got_ids;
    undef @got_grp_ids;

    ok( $got = class->list({ title => '_test%', Order => 'id' }), 'lets do a search by title' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id();
        push @got_grp_ids, \@{$_->get_grp_ids()};
    }
    eq_set( \@got_ids, $OBJ_IDS->{media}, '... did we get the right list of ids out' );
    eq_set( \@got_grp_ids, \@EXP_GRP_IDS, '... and did we get the right grp_ids' );
    undef @got_ids;
    undef @got_grp_ids;

    # finally do this by grp_ids
    ok( $got = class->list({ grp_id => $OBJ->{media_grp}->[0]->get_id(), Order => 'id' }), 'getting by grp_id' );
    my $number = @$got;
    is( $number, 2, 'there should be two media in the first grp' );
    is( $got->[0]->get_id(), $media[2]->get_id(), '... and they should be numbers 2' );
    is( $got->[1]->get_id(), $media[3]->get_id(), '... and 3' );

    # try listing IDs, again at least one key per table
    ok( $got = class->list_ids({ name => '_test%', Order => 'id' }), 'lets do an IDs search by name' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_;
    }
    eq_set( \@got_ids, $OBJ_IDS->{media}, '... did we get the right list of ids out' );
    undef @got_ids;

    ok( $got = class->list_ids({ title => '_test%', Order => 'id' }), 'lets do an ids search by title' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_;
    }
    eq_set( \@got_ids, $OBJ_IDS->{media}, '... did we get the right list of ids out' );
    undef @got_ids;

    # finally do this by grp_ids
    ok( $got = class->list_ids({ grp_id => $OBJ->{media_grp}->[0]->get_id(), Order => 'id' }), 'getting by grp_id' );
    $number = @$got;
    is( $number, 2, 'there should be three media in the first grp' );
    is( $got->[0], $media[2]->get_id(), '... and they should be numbers 2' );
    is( $got->[1], $media[3]->get_id(), '... and 3' );


    # now let's try a limit
    ok( $got = class->list({ Order => 'id', Limit => 3 }), 'try setting a limit of 3');
    is( @$got, 3, '... did we get exactly 3 media back' );

    # test Offset
    ok( $got = class->list({ grp_id => $OBJ->{media_grp}->[0]->get_id(), Order => 'id', Offset => 1 }), 'try setting an offset of 2 for a search that just returned 6 objs');
    is( @$got, 1, '... Offset gives us #2 of 2' );
    
}

###############################################################################
## Test primary_oc_id property.
###############################################################################
sub test_primary_oc_id : Test(8) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
    return "OCs tested only by subclass" if $key eq 'biz';

    ok( my $ba = $self->construct( name      => 'Flubberman',
                                   file_name => 'fun.foo',
                                   slug      => 'hugoman'),
        "Construct asset" );
    $ba->set_category__id($CATEGORY->get_id());
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
# Test output channel associations.
##############################################################################
sub test_oc : Test(35) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
     return "OCs tested only by subclass" if $key eq 'biz';
    ok( my $ba = $self->construct, "Construct $key object" );
    $ba->set_category__id($CATEGORY->get_id());
    ok( my $elem = $self->get_elem, "Get element object" );

    # Make sure there are the same of OCs yet as in the element.
    ok( my @eocs = $elem->get_output_channels, "Get Element OCs" );
    ok( my @ocs = $ba->get_output_channels, "Get $key OCs" );
    #is( scalar @ocs, 1, "Check for 1 OC" );
    is( scalar @eocs, scalar @ocs, "Check for same number of OCs" );
    is( $eocs[0]->get_id, $ocs[0]->get_id, "Compare for same OC ID" );

    # Save the asset object.
    ok( $ba->save, "Save ST" );
    ok( my $baid = $ba->get_id, "Get ST ID" );
    $self->add_del_ids($baid, $key);

    # Grab the element's first OC.
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

1;
__END__
