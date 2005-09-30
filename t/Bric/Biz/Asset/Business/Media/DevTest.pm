package Bric::Biz::Asset::Business::Media::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::DevTest);
use Test::More;
use Test::Exception;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Media::Image;
use Bric::Util::DBI qw(:standard :junction);
use Bric::Biz::Keyword;
use Bric::Util::Time qw(strfdate);
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
    $elem ||= Bric::Biz::ElementType->lookup({ id => 4 });
    $elem;
}

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
my $z;
sub new_args {
    my $self = shift;
    ( element_type  => $self->get_elem,
      user__id      => $self->user_id,
      file_name     => 'fun.foo' . ++$z,
      source__id    => 1,
      primary_oc_id => 1,
      site_id       => 100,
      category__id  => 1,
      cover_date    => '2005-03-22 21:07:56',
    )
}

##############################################################################
# Test the SELECT methods
##############################################################################

sub test_select_methods: Test(120) {
    my $self = shift;
    my $class = $self->class;

    # let's grab existing 'All' group info
    my $all_workflow_grp_id = Bric::Biz::Workflow->INSTANCE_GROUP_ID;
    my $all_cats_grp_id = Bric::Biz::Category->INSTANCE_GROUP_ID;
    my $all_desks_grp_id =  Bric::Biz::Workflow::Parts::Desk->INSTANCE_GROUP_ID;
    my $all_media_grp_id = $class->INSTANCE_GROUP_ID;

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
        $self->add_del_ids([$cat->get_id()], 'category');
        push @{$OBJ_IDS->{category}}, $cat->get_id();
        push @{$OBJ->{category}}, $cat;
        # create some category groups
        $grp = Bric::Util::Grp::CategorySet->new({ name => "_test_$time.$i",
                                                   description => '',
                                                   obj => $cat });

        $grp->add_member({obj => $cat });
        # save the group ids
        $grp->save();
        $self->add_del_ids([$grp->get_id()], 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @CATEGORY_GRP_IDS, $grp->get_id();

        # create desks 
        $desk = Bric::Biz::Workflow::Parts::Desk->new({ 
                                        name => "_test_$time.$i", 
                                        description => '',
                                     });
        $desk->save();
        $self->add_del_ids([$desk->get_id()], 'desk');
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
        $self->add_del_ids([$grp->get_id()], 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @DESK_GRP_IDS, $grp->get_id();

        # create workflows
        $workflow = Bric::Biz::Workflow->new
          ({ type        => Bric::Biz::Workflow::MEDIA_WORKFLOW,
             name        => "_test_$time.$i",
             start_desk  => $desk,
             description => 'test',
             site_id     => 100, #Use default site_id
           });
        $workflow->save;
        $self->add_del_ids([$workflow->get_id()], 'workflow');
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
        $self->add_del_ids([$grp->get_id()], 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @WORKFLOW_GRP_IDS, $grp->get_id();

        # create some media groups
        $grp = Bric::Util::Grp::Media->new({ name => "_GRP_test_$time.$i" });
        # save the group ids
        $grp->save();
        $self->add_del_ids([$grp->get_id()], 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @{$OBJ->{media_grp}}, $grp;
        push @MEDIA_GRP_IDS, $grp->get_id();
    }

    # look up a media element
    my ($element) = get_elem;

    # and a user
    my $admin_id = $self->user_id();

    # create some media
    my (@media, $time, $got, $expected);

    # A media with one category (admin user)
    $time = time;
    $media[0] = class->new({ name        => "_test_$time",
                             file_name   => 'test.foo' . ++$z,
                             description => 'this is a test',
                             priority    => 1,
                             source__id  => 1,
                             user__id    => $admin_id,
                             element     => $element,
                             checked_out => 1,
                             site_id     => 100,
                             note        => 'Note 1',
                           });
    $media[0]->set_category__id($OBJ->{category}->[0]->get_id());
    $media[0]->set_cover_date('2005-03-23 06:11:29');
    $media[0]->add_contributor($self->contrib, 'DEFAULT');
    $media[0]->checkin();
    $media[0]->save();
    $media[0]->checkout({ user__id => $self->user_id });
    $media[0]->checkin();
    $media[0]->save();
    $media[0]->checkout({ user__id => $self->user_id });
    $media[0]->checkin();
    $media[0]->save();
    push @{$OBJ_IDS->{media}}, $media[0]->get_id();
    $self->add_del_ids( $media[0]->get_id() );

    # Try doing a lookup by ID and UUID.
    $expected = $media[0];
    for my $idf (qw(id uuid)) {
        my $meth = "get_$idf";
        ok $got = class->lookup({ $idf => $expected->$meth }),
          "Look up by $idf";
        is $got->get_id, $expected->get_id, "... does it have the right ID";
        is $got->get_uuid, $expected->get_uuid,
          "... does it have the right UUID";
        is $got->get_name(), $expected->get_name(),
            '... does it have the right name';
        is $got->get_description, $expected->get_description,
            '... does it have the right desc';
    }

    # check the URI
    my $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri, qr/^$exp_uri/,
          '...does the uri match the category');

    # check the grp IDs
    my $exp_grp_ids = [ sort { $a <=> $b }
                        $OBJ->{category}->[0]->get_asset_grp_id(),
                        $all_media_grp_id,
                        100
                      ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # now find out if return_version get the right number of versions
    ok( $got = class->list({ id => $OBJ_IDS->{media}->[0],
                             return_versions => 1,
                             Order => 'version'}),
        'does return_versions work?' );
    is( scalar @$got, 3, '... and did we get three versions of media[0]');

    # Make sure we got them back in order.
    my $n;
    foreach my $m (@$got) {
        is( $m->get_version, ++$n, "Check for version $n");
    }

    # Now fetch a specific version.
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[0],
                               version => 2 }),
        "Get version 2" );
    is( $got->get_version, 2, "Check that we got version 2" );

    # ... with multiple cats
    $time = time;
    $media[1] = class->new({
                            name        => "_test_$time",
                            file_name   => 'test.foo' . ++$z,
                            description => 'this is a test',
                            priority    => 1,
                            source__id  => 1,
                            user__id    => $admin_id,
                            element     => $element,
                            checked_out => 1,
                            site_id     => 100,
                            note        => 'Note 2',
                           });
    $media[1]->set_category__id($OBJ->{category}->[1]->get_id());
    $media[1]->set_cover_date('2005-03-23 06:11:29');
    $media[1]->save();
    $media[1]->save();
    push @{$OBJ_IDS->{media}}, $media[1]->get_id();
    $self->add_del_ids( $media[1]->get_id());

    # Try doing a lookup 
    $expected = $media[1];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[1] }),
        'can we call lookup on a Media with multiple categories' );
    is( $got->get_name, $expected->get_name,
        '... does it have the right name');
    is( $got->get_description, $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[1]->get_uri;
    like( $got->get_primary_uri, qr/^$exp_uri/,
          '...does the uri match the category');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_media_grp_id,
                     $OBJ->{category}->[1]->get_asset_grp_id,
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # ... as a grp member
    $time = time;
    $media[2] = class->new({ name        => "_test_$time",
                             file_name   => 'test.foo' . ++$z,
                             description => 'this is a test',
                             priority    => 1,
                             source__id  => 1,
                             user__id    => $admin_id,
                             element     => $element,
                             checked_out => 1,
                             site_id     => 100,
                             note        => 'Note 3',
                           });
    $media[2]->set_category__id( $OBJ->{category}->[0]->get_id() );
    $media[2]->set_cover_date('2005-03-23 06:11:29');
    $media[2]->add_contributor($self->contrib, 'DEFAULT');
    $media[2]->checkin();
    $media[2]->save();
    $media[2]->checkout({ user__id => $self->user_id });
    $media[2]->save();
    push @{$OBJ_IDS->{media}}, $media[2]->get_id();
    $self->add_del_ids( $media[2]->get_id() );

    $OBJ->{media_grp}->[0]->add_member({ obj => $media[2] });
    $OBJ->{media_grp}->[0]->save();

    $expected = $media[2];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[2] }),
        'can we call lookup on a Media which is itself in a grp' );
    is( $got->get_name, $expected->get_name,
        '... does it have the right name');
    is( $got->get_description, $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri, qr/^$exp_uri/,
          '...does the uri match the category');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_media_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id(),
                     $MEDIA_GRP_IDS[0],
                     100,
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply([sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
              '... does it have the right grp_ids' );

    # ... a bunch of grps
    $time = time;
    $media[3] = class->new({ name        => "_test_$time",
                             file_name   => 'test.foo' . ++$z,
                             description => 'this is a test',
                             priority    => 1,
                             source__id  => 1,
                             user__id    => $admin_id,
                             element     => $element,
                             checked_out => 1,
                             site_id     => 100,
                             note        => 'Note 4',
                           });
    $media[3]->set_category__id( $OBJ->{category}->[0]->get_id );
    $media[3]->set_cover_date('2005-03-23 06:11:29');
    $media[3]->save();
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
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[3] }),
        'can we call lookup on a Media which is itself in a grp' );
    is( $got->get_name, $expected->get_name,
        '... does it have the right name');
    is( $got->get_description, $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri, qr/^$exp_uri/,
          '...does the uri match the category');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_media_grp_id,
                     $MEDIA_GRP_IDS[0],
                     $MEDIA_GRP_IDS[1],
                     $MEDIA_GRP_IDS[2],
                     $MEDIA_GRP_IDS[3],
                     $MEDIA_GRP_IDS[4],
                     $OBJ->{category}->[0]->get_asset_grp_id,
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [sort { $a <=> $b } $got->get_grp_ids ], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # ... now try a workflow
    $time = time;
    $media[4] = class->new({ name        => "_test_$time",
                             file_name   => 'test.foo' . ++$z,
                             description => 'this is a test',
                             priority    => 1,
                             source__id  => 1,
                             user__id    => $admin_id,
                             element     => $element,
                             checked_out => 1,
                             site_id     => 100,
                             note        => 'Note 5',
                           });
    $media[4]->add_contributor($self->contrib, 'DEFAULT');
    $media[4]->set_category__id($OBJ->{category}->[0]->get_id());
    $media[4]->set_cover_date('2005-03-23 06:11:29');
    $media[4]->set_workflow_id( $OBJ->{workflow}->[0]->get_id() );
    $media[4]->save;
    $media[4]->save;
    push @{$OBJ_IDS->{media}}, $media[4]->get_id();
    $self->add_del_ids( $media[4]->get_id() );

    # add it to the workflow

    # Try doing a lookup 
    $expected = $media[4];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[4] }),
        'can we call lookup on a Media' );
    is( $got->get_name, $expected->get_name,
        '... does it have the right name');
    is( $got->get_description, $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri, qr/^$exp_uri/,
          '...does the uri match the category');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_media_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id,
                     $OBJ->{workflow}->[0]->get_asset_grp_id,
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # ... desk
    $time = time;
    $media[5] = class->new({ name        => "_test_$time",
                             file_name   => 'test.foo' . ++$z,
                             description => 'this is a test',
                             priority    => 1,
                             source__id  => 1,
                             user__id    => $admin_id,
                             element     => $element,
                             checked_out => 1,
                             site_id     => 100,
                             note        => 'Note 6',
                           });
    $media[5]->set_category__id( $OBJ->{category}->[0]->get_id );
    $media[5]->set_cover_date('2005-03-23 06:11:29');
    $media[5]->set_workflow_id( $OBJ->{workflow}->[0]->get_id );
    $media[5]->save;

    $OBJ->{desk}->[0]->accept({ asset  => $media[5] });
    $OBJ->{desk}->[0]->save;
    $media[5]->checkin();
    $media[5]->save();
    push @{$OBJ_IDS->{media}}, $media[5]->get_id();
    $self->add_del_ids( $media[5]->get_id() );

    # add it to the workflow

    # Try doing a lookup 
    $expected = $media[5];
    ok( $got = class->lookup({ id => $OBJ_IDS->{media}->[5] } ),
      'can we call lookup on a Media' );
    is( $got->get_name, $expected->get_name,
      '... does it have the right name');
    is( $got->get_description, $expected->get_description,
      '... does it have the right desc');
    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri;
    like( $got->get_primary_uri, qr/^$exp_uri/,
      '...does the uri match the category');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_media_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id,
                     $OBJ->{desk}->[0]->get_asset_grp,
                     $OBJ->{workflow}->[0]->get_asset_grp_id,
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply([sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
      '... does it have the right grp_ids' );

    # try listing something up by at least key in each table
    # be sure to try to get them both as a ref and a list
    my @got_ids;
    my @got_grp_ids;

    ok( $got = class->list({ name    => '_test%',
                             Order   => 'name' }),
        'lets do a search by name, ordered by name' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id;
        push @got_grp_ids, [ sort { $a <=> $b } $_->get_grp_ids ];
    }
    $OBJ_IDS->{media} = [ sort { $a <=> $b } @{ $OBJ_IDS->{media} } ];

    is_deeply( [sort { $a <=> $b } @got_ids], $OBJ_IDS->{media},
               '... did we get the right list of ids out' );
    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for media $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    # Try a search by element_key_name.
    ok( $got = class->list({ element_key_name => $element->get_key_name }),
        'lets do a search by element_key_name' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id;
        push @got_grp_ids, [ sort { $a <=> $b } $_->get_grp_ids ];
    }
    $OBJ_IDS->{media} = [ sort { $a <=> $b } @{ $OBJ_IDS->{media} } ];

    is_deeply( [sort { $a <=> $b } @got_ids], $OBJ_IDS->{media},
               '... did we get the right list of ids out' );
    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for media $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    ok( $got = class->list({ title   => '_test%',
                             Order   => 'name' }),
        'lets do a search by title' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id;
        push @got_grp_ids, [ sort { $a <=> $b } $_->get_grp_ids ];
    }
    is_deeply( [sort { $a <=> $b } @got_ids], $OBJ_IDS->{media},
               '... did we get the right list of ids out' );
    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for media $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    # finally do this by grp_ids
    ok( $got = class->list({ grp_id => $OBJ->{media_grp}->[0]->get_id,
                             Order => 'name' }),
        'getting by grp_id' );
    my $number = @$got;
    is( $number, 2, 'there should be two media in the first grp' );
    is( $got->[0]->get_id, $media[2]->get_id,
        '... and they should be numbers 2' );
    is( $got->[1]->get_id, $media[3]->get_id, '... and 3' );

    # try listing IDs, again at least one key per table
    ok( $got = class->list_ids({ name    => '_test%',
                                 Order   => 'name' }),
        'lets do an IDs search by name' );
    # check the ids
    is_deeply( $got, $OBJ_IDS->{media},
               '... did we get the right list of ids out' );

    ok( $got = class->list_ids({ title   => '_test%',
                                 Order   => 'name' }),
        'lets do an ids search by title' );
    # check the ids
    is_deeply( $got, $OBJ_IDS->{media},
               '... did we get the right list of ids out' );

    # finally do this by grp_ids
    ok( $got = class->list_ids({ grp_id  => $OBJ->{media_grp}->[0]->get_id,
                                 Order   => 'name' }),
        'getting by grp_id' );
    $number = @$got;
    is( $number, 2, 'there should be three media in the first grp' );
    is( $got->[0], $media[2]->get_id, '... and they should be numbers 2' );
    is( $got->[1], $media[3]->get_id, '... and 3' );


    # now let's try a limit
    ok( $got = class->list({ Order   => 'name',
                             Limit   => 3 }),
        'try setting a limit of 3');
    is( @$got, 3, '... did we get exactly 3 media back' );

    # test Offset
    ok( $got = class->list({ grp_id  => $OBJ->{media_grp}->[0]->get_id,
                             Order   => 'name',
                             Offset  => 1 }),
        'try setting an offset of 2 for a search that just returned 6 objs');
    is( @$got, 1, '... Offset gives us #2 of 2' );

    # Test contrib_id.
    ok( $got = class->list({ contrib_id => $self->contrib->get_id }),
       "Try contrib_id" );
    is( @$got, 3, 'Check for three stories' );

    # Tets unexpired.
    ok( $got = $self->class->list({ unexpired => 1 }), "List by unexpired");
    is( scalar @$got, 6, 'Check for six media');

    # Set an expire date in the future.
    ok( $media[3]->set_expire_date(strfdate(time + 3600)),
        'Set future expire date.');
    ok( $media[3]->save, 'Save future expire media');
    ok( $got = $self->class->list({ unexpired => 1 }), "List by unexpired");
    is( scalar @$got, 6, 'Check for six media again');

    # Set an expire date in the past.
    ok( $media[2]->set_expire_date(strfdate(time - 3600)),
        'Set future expire date.');
    ok( $media[2]->save, 'Save future expire media');
    ok( $got = $self->class->list({ unexpired => 1 }), "List by unexpired");
    is( scalar @$got, 5, 'Check for five media now');

    # User ID should return only assets checked out to the user.
    ok $got = class->list({
        title   => '_test%',
        Order   => 'title',
        user_id => $admin_id,
    }), 'Get media for user';
    is @$got, 4, 'Should have four media checked out to user';

    # Now try the checked_out parameter. Four media should be checked out.
    ok $got = class->list({
        title       => '_test%',
        Order       => 'title',
        checked_out => 1,
    }), 'Get checked out media';
    is @$got, 4, 'Should have four checked out media';

    # With checked_out => 0, we should get the other two media.
    ok $got = class->list({
        title       => '_test%',
        Order       => 'title',
        checked_out => 0,
    }), 'Get non-checked out media';
    is @$got, 2, 'Should have two non-checked out media';

    # Try the checked_in parameter, which should return all six media.
    ok $got = class->list({
        title       => '_test%',
        Order       => 'name',
        checked_in  => 1,
    }), 'Get checked in media';
    is @$got, 6, 'Should have six checked in media';

    # And even the checked-out media should return us the checked-in
    # version.
    is_deeply [ map { $_->get_checked_out } @$got ], [0, 1, 0, 1, 1, 0],
      "We should get the checked-in copy of the checked-out media";

    # Without checked_in parameter we should get the the checked-out
    # media.
    ok $got = class->list({
        title       => '_test%',
        Order       => 'name',
    }), 'Get all media';
    is @$got, 6, 'Should have six media';

    # And now the checked-out media should return us the checked-in
    # version.
    is_deeply [ map { $_->get_checked_out } @$got ], [0, 1, 1, 1, 1, 0],
      "We should get the checked-out media where available";

    # Test list using output channel IDs.
    my $oc1 = Bric::Biz::OutputChannel->new({ name => '_toc1', site_id => 100 });
    $oc1->save;
    $self->add_del_ids([$oc1->get_id], 'output_channel');
    my $oc2 = Bric::Biz::OutputChannel->new({ name => '_toc2', site_id => 100 });
    $oc2->save;
    $self->add_del_ids([$oc2->get_id], 'output_channel');
    my $oc3 = Bric::Biz::OutputChannel->new({ name => '_toc3', site_id => 100 });
    $oc3->save;
    $self->add_del_ids([$oc3->get_id], 'output_channel');

    $media[0]->add_output_channels($oc1);
    $media[0]->set_primary_oc_id($oc1->get_id);
    $media[0]->save;

    ok $got = class->list({
        output_channel_id => $oc1->get_id
    }), 'Get stories with first OC';
    is @$got, 1, 'Should have one media';

    # Add a second OC to the media.
    $media[0]->add_output_channels($oc2);
    $media[0]->save;

    # We should still be able to find that media.
    ok $got = class->list({
        output_channel_id => $oc2->get_id
    }), 'Get stories with second OC';
    is @$got, 1, 'Should still have one media';

    # Now add the thrird OC as the secondary OC of another media.
    $media[1]->add_output_channels($oc2, $oc3);
    $media[1]->set_primary_oc_id($oc2->get_id);
    $media[1]->save;

    # Now look for the second and thrid OC.
    ok $got = class->list({
        output_channel_id => ANY($oc1->get_id, $oc3->get_id)
    }), 'Get stories with first and third OC';
    is @$got, 2, 'Should now have two stories';

    # Now search on notes.
    ok $got = class->list({ note => 'Note 1'}), 'Search on note "Note 1"';
    is @$got, 1, 'Should have one media';
    ok $got = class->list({ note => 'Note %'}), 'Search on note "Note %"';
    is @$got, 6, 'Should have six media';
    ok $got = class->list({ note => ANY('Note 1', 'Note 2')}),
                          'Search on note "ANY(Note 1, Note 2)"';
    is @$got, 2, 'Should have two media';
}

###############################################################################
## Test primary_oc_id property.
###############################################################################
sub test_primary_oc_id : Test(7) {
    my $self = shift;
    my $class = $self->class;
    ok( my $key = $class->key_name, "Get key" );
    return "OCs tested only by subclass" if $key eq 'biz';

    ok( my $ba = $self->construct( name      => 'Flubberman',
                                   file_name => 'fun.foo',
                                 ),
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
    # is( scalar @bas, 2, "Check for one asset" ); XXX too hardcoded?
    # fails because other tests lives asset around?

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

sub test_new_grp_ids: Test(4) {
    my $self = shift;
    my $time = time;
    my $class = $self->class;
    my $all_media_grp_id = $class->INSTANCE_GROUP_ID;

    my $element = get_elem();
    my $cat = Bric::Biz::Category->new({ name        => "_test_$time.new",
                                         description => 'foo',
                                         directory   => "_test_$time.new",
                                         site_id     => 100
                                       });
    $CATEGORY->add_child([$cat]);
    $cat->save();
    $self->add_del_ids($cat->get_id(), 'category');
    # first we'll try it with no cats
    my $media = class->new({ name        => "_test_$time",
                             file_name   => 'test.foo' . ++$z,
                             description => 'this is a test',
                             priority    => 1,
                             source__id  => 1,
                             user__id    => $self->user_id,
                             element     => $element,
                             checked_out => 1,
                             site_id     => 100,
                           });
    my $expected = [ sort { $a <=> $b }
                     $all_media_grp_id,
                     100,
                   ];
    is_deeply([sort { $a <=> $b } $media->get_grp_ids], $expected,
              'does a media get initialized with the right grp_id?');
    # add the categories
    $media->set_category__id($cat->get_id);
    $expected = [ sort { $a <=> $b }
                  $cat->get_asset_grp_id,
                  $all_media_grp_id,
                  100
                ];
    is_deeply([sort { $a <=> $b } $media->get_grp_ids ], $expected,
              'does adding cats get the right asset_grp_ids?');

    $media = class->new({ name        => "_test_$time",
                          file_name   => 'test.foo' . ++$z,
                          description => 'this is a test',
                          priority    => 1,
                          source__id  => 1,
                          user__id    => $self->user_id,
                          element     => $element,
                          site_id     => 100,
                          checked_out => 1
                        });
    my $desk = Bric::Biz::Workflow::Parts::Desk->new
      ({ name => "_test_$time",
         description => '',
       });
    $desk->save;

    $self->add_del_ids($desk->get_id(), 'desk');
    my $workflow = Bric::Biz::Workflow->new
      ({ type        => Bric::Biz::Workflow::MEDIA_WORKFLOW,
         name        => "_test_$time",
         start_desk  => $desk,
         description => 'test',
         site_id     => 100,
       });
    $workflow->save();
    $self->add_del_ids($workflow->get_id, 'workflow');
    $media->set_current_desk($desk);
    $expected = [ sort { $a <=> $b }
                  $all_media_grp_id,
                  $desk->get_asset_grp,
                  100
                ];
    is_deeply([sort { $a <=> $b } $media->get_grp_ids], $expected,
              'setting the current desk of a media adds the correct ' .
              'asset_grp_ids');

    $media->set_workflow_id($workflow->get_id);
    $expected = [ sort { $a <=> $b }
                  $workflow->get_asset_grp_id,
                  $all_media_grp_id,
                  $desk->get_asset_grp,
                  100
                ];
    is_deeply([sort { $a <=> $b } $media->get_grp_ids], $expected,
              'setting the workflow id of a media adds the correct ' .
              'asset_grp_ids');
}

1;
__END__
