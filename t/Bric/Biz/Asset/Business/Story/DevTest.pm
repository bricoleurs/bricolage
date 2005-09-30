package Bric::Biz::Asset::Business::Story::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::DevTest);
use Test::More;
use Test::Exception;
use Bric::Util::DBI qw(:standard :junction);
use Bric::Util::Time qw(strfdate);
use Bric::Biz::ElementType;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Biz::Workflow;
use Bric::Biz::Category;
use Bric::Util::Grp::Desk;
use Bric::Util::Grp::Story;
use Bric::Util::Grp::Workflow;
use Bric::Util::Grp::CategorySet;

sub class { 'Bric::Biz::Asset::Business::Story' }
sub table { 'story' }

my $CATEGORY = Bric::Biz::Category->lookup({ id => 1 });
my $ELEMENT_CLASS = 'Bric::Biz::ElementType';
my $OC_CLASS = 'Bric::Biz::OutputChannel';

# this will be filled during setup
my $OBJ_IDS = {};
my $OBJ = {};
my @CATEGORY_GRP_IDS;
my @WORKFLOW_GRP_IDS;
my @DESK_GRP_IDS;
my @STORY_GRP_IDS;
my @ALL_DESK_GRP_IDS;
my @REQ_DESK_GRP_IDS;
my @EXP_GRP_IDS;

##############################################################################
# Constructs a new object.
my $z;
sub new_args {
    my $self = shift;
    return ($self->SUPER::new_args, slug => 'slug' . ++$z);
}

sub construct {
    my $s = shift->SUPER::construct(@_);
    $s->add_categories([1]);
    $s->set_primary_category(1);
    $s->set_cover_date('2005-03-22 21:07:56');
    return $s;
}

##############################################################################
# Test the clone() method.
##############################################################################

sub test_clone : Test(18) {
    my $self = shift;
    ok( my $story = $self->construct( name => 'Flubber',
                                      slug => 'hugo'),
        "Construct story" );
    ok( $story->save, "Save story" );

    # Save the ID for cleanup.
    ok( my $sid = $story->get_id, "Get ID" );
    my $key = $self->class->key_name;
    $self->add_del_ids([$sid], $key);

    # Clone the story.
    ok( $story->clone, "Clone story" );
    ok( $story->set_slug('jarkko'), "Change the slug" );
    ok( $story->save, "Save cloned story" );
    ok( my $cid = $story->get_id, "Get cloned ID" );
    $self->add_del_ids([$cid], $key);

    # Lookup the original story.
    ok( my $orig = $self->class->lookup({ id => $sid }),
        "Lookup original story" );

    # Lookup the cloned story.
    ok( my $clone = $self->class->lookup({ id => $cid }),
        "Lookup cloned story" );

    # Check that the story is really cloned!
    isnt( $sid, $cid, "Check for different IDs" );
    isnt( $clone->get_uuid, $orig->get_uuid, "Check for different UUIDs" );
    is( $clone->get_title, $orig->get_title, "Compare titles" );
    is( $clone->get_slug, 'jarkko', "Compare slugs" );
    ok( my $ouri = $orig->get_uri, "Get original URI" );
    $ouri =~ s/hugo/jarkko/;
    is( $clone->get_uri, $ouri, "Compare uris" );

    # Check that the output channels are the same.
    ok( my @oocs = $orig->get_output_channels, "Get original OCs" );
    ok( my @cocs = $clone->get_output_channels, "Get cloned OCs" );
    is_deeply(\@oocs, \@cocs, "Compare OCs" );
}

##############################################################################
# Test the SELECT methods
##############################################################################

sub test_select_methods: Test(151) {
    my $self = shift;
    my $class = $self->class;
    my $all_stories_grp_id = $class->INSTANCE_GROUP_ID;

    # now we'll create some test objects
    my ($i);
    for ($i = 0; $i < 5; $i++) {
        my $time = time;
        my ($cat, $desk, $workflow, $story, $grp);
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
        $workflow = Bric::Biz::Workflow->new({
            type => Bric::Biz::Workflow::STORY_WORKFLOW,
            name => "_test_$time.$i",
            start_desk => $desk,
            description => 'test',
            site_id => 100, #Use default site_id
        });
        $workflow->save();
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

        # create some story groups
        $grp = Bric::Util::Grp::Story->new({ name => "_GRP_test_$time.$i" });
        # save the group ids
        $grp->save();
        $self->add_del_ids([$grp->get_id()], 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @{$OBJ->{story_grp}}, $grp;
        push @STORY_GRP_IDS, $grp->get_id();
    }

    # look up a story element
    my ($element) = Bric::Biz::ElementType->list({ name => 'Story' });

    # and a user
    my $admin_id = $self->user_id;

    # create some stories
    my (@story,$time, $got, $expected);

    # A story with one category (admin user)
    $time = time;
    $story[0] = $class->new({ name        => "_test_$time",
                              description => 'this is a test',
                              priority    => 1,
                              source__id  => 1,
                              slug        => 'test',
                              user__id    => $admin_id,
                              element     => $element,
                              site_id     => 100,
                              note        => 'Note 1',
                            });

    $story[0]->add_categories([ $OBJ->{category}->[0] ]);
    $story[0]->set_primary_category($OBJ->{category}->[0]);
    $story[0]->add_contributor($self->contrib, 'DEFAULT');
    $story[0]->set_cover_date('2005-03-23 06:11:29');
    $story[0]->checkin();
    $story[0]->save();
    push @{$OBJ_IDS->{story}}, $story[0]->get_id();
    $self->add_del_ids( $story[0]->get_id() );

    $story[0]->checkout({ user__id => $self->user_id });
    $story[0]->checkin();
    $story[0]->save();
    $story[0]->checkout({ user__id => $self->user_id });
    $story[0]->save();

    # Test checked_out and checkout.
    ok my $st = class->lookup({
        id => $OBJ_IDS->{story}->[0]
    }), "Look up the checked out story.";
    is $st->get_version, 2, "Story is at version 2";

    # Test checked_in => 1 to make sure that it works.
    ok $st = class->lookup({
        id => $OBJ_IDS->{story}->[0],
        checked_in => 1,
    }), "Look up the checked out story.";
    is $st->get_version, 2, "Story is at version 2";

    # Check in the story and move on.
    $story[0]->checkin();
    $story[0]->save();

    # Try doing a lookup by ID and UUID.
    $expected = $story[0];
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
    my $exp_uri = $OBJ->{category}->[0]->get_uri . '2005/03/23/test';
    like( $got->get_primary_uri(), qr/^$exp_uri/,
          '...does the uri match the category and slug');

    # check the grp IDs
    my $exp_grp_ids = [ sort { $a <=> $b }
                        $OBJ->{category}->[0]->get_asset_grp_id,
                        $all_stories_grp_id,
                        100
                      ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply([sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
              '... does it have the right grp_ids' );

    # now find out if return_version get the right number of versions
    ok( $got = class->list({ id => $OBJ_IDS->{story}->[0],
                             return_versions => 1,
                             Order => 'version' }),
        'does return_versions work?' );
    is( scalar @$got, 3, '... and did we get three versions of story[0]');

    # Make sure we got them back in order.
    my $n;
    foreach my $s (@$got) {
        is( $s->get_version, ++$n, "Check for version $n");
    }

    # Now fetch a specific version.
    ok( $got = class->lookup({ id => $OBJ_IDS->{story}->[0],
                               version => 2 }),
        "Get version 2" );
    is( $got->get_version, 2, "Check that we got version 2" );

    # ... with multiple cats
    $time = time;
    $story[1] = $class->new({ name        => "_test_$time",
                              description => 'this is a test',
                              priority    => 1,
                              source__id  => 1,
                              slug        => 'test' . ++$z,
                              user__id    => $admin_id,
                              element     => $element,
                              site_id     => 100,
                              note        => 'Note 2',
                            });

    $story[1]->add_categories( $OBJ->{category} );
    $story[1]->set_primary_category( $OBJ->{category}->[1] );
    $story[1]->set_cover_date('2005-03-23 06:11:29');
    $story[1]->checkin();
    $story[1]->save();
    push @{$OBJ_IDS->{story}}, $story[1]->get_id();
    $self->add_del_ids( $story[1]->get_id());

    # Try doing a lookup
    $expected = $story[1];
    ok( $got = class->lookup({ id => $OBJ_IDS->{story}->[1] }),
        'can we call lookup on a Story with multiple categories' );
    is( $got->get_name, $expected->get_name,
        '... does it have the right name');
    is( $got->get_description, $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[1]->get_uri . '2005/03/23/test';
    like( $got->get_primary_uri, qr/^$exp_uri/,
          '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_stories_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id(),
                     $OBJ->{category}->[1]->get_asset_grp_id(),
                     $OBJ->{category}->[2]->get_asset_grp_id(),
                     $OBJ->{category}->[3]->get_asset_grp_id(),
                     $OBJ->{category}->[4]->get_asset_grp_id(),
                     100 # site_id
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [ sort { $a <=> $b } $got->get_grp_ids ], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # ... as a grp member
    $time = time;
    $story[2] = $class->new({ name        => "_test_$time",
                              description => 'this is a test',
                              priority    => 1,
                              source__id  => 1,
                              slug        => 'test' . ++$z,
                              user__id    => $admin_id,
                              element     => $element,
                              site_id     => 100,
                              note        => 'Note 3',
                            });

    $story[2]->add_categories([ $OBJ->{category}->[0] ]);
    $story[2]->set_primary_category( $OBJ->{category}->[0] );
    $story[2]->add_contributor($self->contrib, 'DEFAULT');
    $story[2]->set_cover_date('2005-03-23 06:11:29');
    $story[2]->checkin();
    $story[2]->save();
    $story[2]->checkout({ user__id => $self->user_id });
    $story[2]->save();
    push @{$OBJ_IDS->{story}}, $story[2]->get_id();
    $self->add_del_ids( $story[2]->get_id() );

    $OBJ->{story_grp}->[0]->add_member({ obj => $story[2] });
    $OBJ->{story_grp}->[0]->save();

    $expected = $story[2];
    ok( $got = class->lookup({ id => $OBJ_IDS->{story}->[2] }),
        'can we call lookup on a Story which is itself in a grp' );
    is( $got->get_name(), $expected->get_name,
        '... does it have the right name');
    is( $got->get_description(), $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri . '2005/03/23/test';
    like( $got->get_primary_uri, qr/^$exp_uri/,
          '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_stories_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id(),
                     $STORY_GRP_IDS[0],
                     100, # site_id
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [sort { $a <=> $b } $got->get_grp_ids ], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # ... a bunch of grps
    $time = time;
    $story[3] = $class->new({ name        => "_test_$time",
                              description => 'this is a test',
                              priority    => 1,
                              source__id  => 1,
                              slug        => 'test' . ++$z,
                              user__id    => $admin_id,
                              element     => $element,
                              site_id     => 100,
                              note        => 'Note 4',
                            });

    $story[3]->add_categories([ $OBJ->{category}->[0] ]);
    $story[3]->set_primary_category( $OBJ->{category}->[0] );
    $story[3]->set_cover_date('2005-03-23 06:11:29');
    $story[3]->checkin();
    $story[3]->save();
    push @{$OBJ_IDS->{story}}, $story[3]->get_id();
    $self->add_del_ids( $story[3]->get_id() );

    $OBJ->{story_grp}->[0]->add_member({ obj => $story[3] });
    $OBJ->{story_grp}->[0]->save();

    $OBJ->{story_grp}->[1]->add_member({ obj => $story[3] });
    $OBJ->{story_grp}->[1]->save();

    $OBJ->{story_grp}->[2]->add_member({ obj => $story[3] });
    $OBJ->{story_grp}->[2]->save();

    $OBJ->{story_grp}->[3]->add_member({ obj => $story[3] });
    $OBJ->{story_grp}->[3]->save();

    $OBJ->{story_grp}->[4]->add_member({ obj => $story[3] });
    $OBJ->{story_grp}->[4]->save();

    $expected = $story[3];
    ok( $got = class->lookup({ id => $OBJ_IDS->{story}->[3] }),
        'can we call lookup on a Story which is itself in a grp' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri . '2005/03/23/test';
    like( $got->get_primary_uri, qr/^$exp_uri/,
          '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_stories_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id(),
                     $STORY_GRP_IDS[0],
                     $STORY_GRP_IDS[1],
                     $STORY_GRP_IDS[2],
                     $STORY_GRP_IDS[3],
                     $STORY_GRP_IDS[4],
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [ sort { $a <=> $b } $got->get_grp_ids ], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # ... now try a workflow
    $time = time;
    $story[4] = $class->new({ name        => "_test_$time",
                              description => 'this is a test',
                              priority    => 1,
                              source__id  => 1,
                              slug        => 'test' . ++$z,
                              user__id    => $admin_id,
                              element     => $element,
                              site_id     => 100,
                              note        => 'Note 4',
                            });

    $story[4]->add_categories([ $OBJ->{category}->[0] ]);
    $story[4]->set_primary_category($OBJ->{category}->[0]);
    $story[4]->set_cover_date('2005-03-23 06:11:29');
    $story[4]->set_workflow_id( $OBJ->{workflow}->[0]->get_id() );
    $story[4]->add_contributor($self->contrib, 'DEFAULT');
    $story[4]->checkin();
    $story[4]->save();
    push @{$OBJ_IDS->{story}}, $story[4]->get_id();
    $self->add_del_ids( $story[4]->get_id() );

    # add it to the workflow

    # Try doing a lookup
    $expected = $story[4];
    ok( $got = class->lookup({ id => $OBJ_IDS->{story}->[4] }),
        'can we call lookup on a Story' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri . '2005/03/23/test';
    like( $got->get_primary_uri(), qr/^$exp_uri/,
          '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_stories_grp_id, 
                     $OBJ->{category}->[0]->get_asset_grp_id(),
                     $OBJ->{workflow}->[0]->get_asset_grp_id(),
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [ sort { $a <=> $b } $got->get_grp_ids ], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # ... desk
    $time = time;
    $story[5] = $class->new({ name        => "_test_$time",
                              description => 'this is a test',
                              priority    => 1,
                              source__id  => 1,
                              slug        => 'test' . ++$z,
                              user__id    => $admin_id,
                              element     => $element,
                              site_id     => 100,
                              note        => 'Note 6',
                            });

    $story[5]->add_categories([ $OBJ->{category}->[0] ]);
    $story[5]->set_primary_category($OBJ->{category}->[0]);
    $story[5]->set_cover_date('2005-03-23 06:11:29');
    $story[5]->set_workflow_id( $OBJ->{workflow}->[0]->get_id() );
    $story[5]->save;

    $OBJ->{desk}->[0]->accept({ asset  => $story[5] });
    $OBJ->{desk}->[0]->save;
    $story[5]->checkin();
    $story[5]->save();

    push @{$OBJ_IDS->{story}}, $story[5]->get_id();
    $self->add_del_ids( $story[5]->get_id() );

    # add it to the workflow

    # Try doing a lookup
    $expected = $story[5];
    ok( $got = class->lookup({ id => $OBJ_IDS->{story}->[5] }),
        'can we call lookup on a Story' );
    is( $got->get_name(), $expected->get_name,
        '... does it have the right name');
    is( $got->get_description(), $expected->get_description,
        '... does it have the right desc');

    # check the URI
    $exp_uri = $OBJ->{category}->[0]->get_uri . '2005/03/23/test';
    like( $got->get_primary_uri(), qr/^$exp_uri/,
          '...does the uri match the category and slug');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_stories_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id(),
                     $OBJ->{workflow}->[0]->get_asset_grp_id(),
                     $OBJ->{desk}->[0]->get_asset_grp(),
                     100, # site_id
                    ];
    push @EXP_GRP_IDS, $exp_grp_ids;

    is_deeply( [sort { $a <=> $b } $got->get_grp_ids ], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # try listing something up by at least key in each table
    # be sure to try to get them both as a ref and a list
    my @got_ids;
    my @got_grp_ids;

    ok( $got = class->list({ name => '_test%',
                             Order => 'name' }),
        'lets do a search by name' );

    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id;
        push @got_grp_ids, [ sort { $a <=> $b } $_->get_grp_ids ];
    }
    $OBJ_IDS->{story} = [ sort { $a <=> $b } @{ $OBJ_IDS->{story} } ];

    is_deeply( \@got_ids, $OBJ_IDS->{story},
               '... did we get the right list of ids out' );

    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for story $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    # Try a search by element_key_name.
    ok( $got = class->list({ element_key_name => $element->get_key_name,
                             Order            => 'name' }),
        'lets do a search by element_key_name' );

   # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id;
        push @got_grp_ids, [ sort { $a <=> $b } $_->get_grp_ids ];
    }
    $OBJ_IDS->{story} = [ sort { $a <=> $b } @{ $OBJ_IDS->{story} } ];

    is_deeply( \@got_ids, $OBJ_IDS->{story},
               '... did we get the right list of ids out' );

    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for story $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    ok( $got = class->list({ title => '_test%', Order => 'name' }),
        'lets do a search by title' );

    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id();
        push @got_grp_ids, [ sort { $a <=> $b } $_->get_grp_ids ];
    }
    is_deeply( \@got_ids, $OBJ_IDS->{story},
               '... did we get the right list of ids out' );

    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
          "... and did we get the right grp_ids for story $i" );
    }

    undef @got_ids;
    undef @got_grp_ids;

    # Try the ANY operator.
    ok( $got = $self->class->list({ slug => ANY("test" . ($z - 1), "test$z")}),
        "List by slug => ANY");
    is( scalar @$got, 2, 'Check for two stories');
    is( $got->[0]->get_id, $story[-2]->get_id, "Check first story" );
    is( $got->[1]->get_id, $story[-1]->get_id, "Check last story" );

    # Try a complex ANY specification.
    ok( $got = $self->class->list({
        Order        => 'name',
        category_uri => ANY($OBJ->{category}->[0]->get_uri,
                            $OBJ->{category}->[1]->get_uri)
    }), "List by category_uri => ANY");
    is( scalar @$got, 6, 'Check for six stories');
    # Make sure we got the correct stories.
    is_deeply( [ map { $_->get_id } @$got ], $OBJ_IDS->{story},
               "Got correct six stories");

    # Try primary_uri + Order by title.
    ok( $got = class->list({ primary_uri => '/_test%', Order => 'title' }),
        'lets do a search by primary uri' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id();
        push @got_grp_ids, [sort { $a <=> $b } $_->get_grp_ids ];
    }
    is_deeply( \@got_ids, $OBJ_IDS->{story},
               '... did we get the right list of ids out' );

    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for story $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    ok( $got = class->list({ category_id => $OBJ_IDS->{category}->[0],
                             Order       => 'title' }),
        'lets do a search by category_id' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id();
        push @got_grp_ids, [sort { $a <=> $b } $_->get_grp_ids ];
    }

    is_deeply( \@got_ids, $OBJ_IDS->{story},
               '... did we get the right list of ids out' );

    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for story $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    # finally do this by grp_ids
    ok( $got = class->list({ grp_id => $OBJ->{story_grp}->[0]->get_id,
                             Order => 'name' }),
        'getting by grp_id' );
    my $number = @$got;
    is( $number, 2, 'there should be two stories in the first grp' );
    is( $got->[0]->get_id(), $story[2]->get_id,
        '... and they should be numbers 2' );
    is( $got->[1]->get_id(), $story[3]->get_id, '... and 3' );

    # try listing IDs, again at least one key per table
    ok( $got = class->list_ids({ name => '_test%', Order => 'name' }),
        'lets do an IDs search by name' );
    # check the ids
    is_deeply( $got, $OBJ_IDS->{story},
               '... did we get the right list of ids out' );

    ok( $got = class->list_ids({ title => '_test%',
                                 Order => 'name' }),
        'lets do an ids search by title' );
    # check the ids
    is_deeply( $got, $OBJ_IDS->{story},
               '... did we get the right list of ids out' );

    ok( $got = class->list_ids({ primary_uri => '/_test%',
                                 Order => 'name' }),
        'lets do an ids search by primary uri' );
    # check the ids
    is_deeply( $got, $OBJ_IDS->{story},
      '... did we get the right list of ids out' );

    # finally do this by grp_ids
    ok( $got = class->list_ids({ grp_id => $OBJ->{story_grp}->[0]->get_id,
                                 Order => 'title' }),
        'getting by grp_id' );
    $number = @$got;
    is( $number, 2, 'there should be two stories in the first grp' );
    is( $got->[0], $story[2]->get_id(), '... and they should be numbers 2' );
    is( $got->[1], $story[3]->get_id(), '... and 3' );


    # now let's try a limit
    ok( $got = class->list({ Order => 'title', Limit => 3 }),
        'try setting a limit of 3');
    is( @$got, 3, '... did we get exactly 3 stories back' );

    # test Offset
    ok( $got = class->list({ grp_id => $OBJ->{story_grp}->[0]->get_id,
                             Order  => 'title',
                             Offset => 1 }),
        'try setting an offset of 2 for a search that just returned 3 objs');
    is( @$got, 1, '... Offset gives us #2 of 2' );

    # Test contrib_id.
    ok( $got = class->list({ contrib_id => $self->contrib->get_id }),
       "Try contrib_id" );
    is( @$got, 3, 'Check for three stories' );

    # Make sure that Order parameters that aren't attributes, such as
    # category_uri, work.
    ok( $got = class->list({ Order => 'category_uri' }),
       "Try ordering by category_uri" );
    is( @$got, 10, 'Check for ten stories' );

    # Test unexpired.
    ok( $got = $self->class->list({ unexpired => 1 }), "List by unexpired");
    is( scalar @$got, 6, 'Check for six stories');

    # Set an expire date in the future.
    ok( $story[3]->set_expire_date(strfdate(time + 3600)),
        'Set future expire date.');
    ok( $story[3]->save, 'Save future expire story');
    ok( $got = $self->class->list({ unexpired => 1 }), "List by unexpired");
    is( scalar @$got, 6, 'Check for six stories again');

    # Set an expire date in the past.
    ok( $story[2]->set_expire_date(strfdate(time - 3600)),
        'Set future expire date.');
    ok( $story[2]->save, 'Save future expire story');
    ok( $got = $self->class->list({ unexpired => 1 }), "List by unexpired");
    is( scalar @$got, 5, 'Check for five stories now');

    # User ID should return only assets checked out to the user.
    ok $got = class->list({
        title   => '_test%',
        Order   => 'title',
        user_id => $admin_id,
    }), 'Get stories for user';
    is @$got, 1, 'Should have one stories checked out to user';

    # Now try the checked_out parameter. One story should be checked out.
    ok $got = class->list({
        title       => '_test%',
        Order       => 'title',
        checked_out => 1,
    }), 'Get checked out stories';
    is @$got, 1, 'Should have one checked out story';

    # With checked_out => 0, we should get the other five stories.
    ok $got = class->list({
        title       => '_test%',
        Order       => 'title',
        checked_out => 0,
    }), 'Get non-checked out stories';
    is @$got, 5, 'Should have five non-checked out stories';

    # Try the checked_in parameter, which should return all six stories.
    ok $got = class->list({
        title       => '_test%',
        Order       => 'name',
        checked_in  => 1,
    }), 'Get checked in stories';
    is @$got, 6, 'Should have six checked in stories';

    # And even the checked-out story should return us the checked-in
    # version.
    is_deeply [ map { $_->get_checked_out } @$got ], [0, 0, 0, 0, 0, 0],
      "We should get the checked-in copy of the checked-out story";

    # Without checked_in parameter we should get the the checked-out
    # story.
    ok $got = class->list({
        title       => '_test%',
        Order       => 'name',
    }), 'Get all stories';
    is @$got, 6, 'Should have six stories';

    # And now the checked-out story should return us the checked-in
    # version.
    is_deeply [ map { $_->get_checked_out } @$got ], [0, 0, 1, 0, 0, 0],
      "We should get the checked-out story where available";

    # Test list using output channel IDs.
    my $oc1 = $OC_CLASS->new({ name => '_toc1', site_id => 100 });
    $oc1->save;
    $self->add_del_ids([$oc1->get_id], 'output_channel');
    my $oc2 = $OC_CLASS->new({ name => '_toc2', site_id => 100 });
    $oc2->save;
    $self->add_del_ids([$oc2->get_id], 'output_channel');
    my $oc3 = $OC_CLASS->new({ name => '_toc3', site_id => 100 });
    $oc3->save;
    $self->add_del_ids([$oc3->get_id], 'output_channel');

    $story[0]->add_output_channels($oc1);
    $story[0]->set_primary_oc_id($oc1->get_id);
    $story[0]->save;

    ok $got = class->list({
        output_channel_id => $oc1->get_id
    }), 'Get stories with first OC';
    is @$got, 1, 'Should have one story';

    # Add a second OC to the story.
    $story[0]->add_output_channels($oc2);
    $story[0]->save;

    # We should still be able to find that story.
    ok $got = class->list({
        output_channel_id => $oc2->get_id
    }), 'Get stories with second OC';
    is @$got, 1, 'Should still have one story';

    # Now add the thrird OC as the secondary OC of another story.
    $story[1]->add_output_channels($oc2, $oc3);
    $story[1]->set_primary_oc_id($oc2->get_id);
    $story[1]->save;

    # Now look for the second and thrid OC.
    ok $got = class->list({
        output_channel_id => ANY($oc1->get_id, $oc3->get_id)
    }), 'Get stories with first and third OC';
    is @$got, 2, 'Should now have two stories';

    # Now search on notes.
    ok $got = class->list({ note => 'Note 1'}), 'Search on note "Note 1"';
    is @$got, 1, 'Should have one story';
    ok $got = class->list({ note => 'Note %'}), 'Search on note "Note %"';
    is @$got, 6, 'Should have six stories';
    ok $got = class->list({ note => ANY('Note 1', 'Note 2')}),
                          'Search on note "ANY(Note 1, Note 2)"';
    is @$got, 2, 'Should have two stories';
}


##############################################################################
# Private class methods
##############################################################################
sub test_add_get_categories: Test(4) {
    # make a story
    my $time = time;
    my $element = $ELEMENT_CLASS->new({
                                        id          => 1,
                                        name        => 'test element',
                                        description => 'testing',
                                        active      => 1,
                                     });
    my $story = class->new({
                           name        => "_test_$time",
                           description => 'this is a test',
                           priority    => 1,
                           source__id  => 1,
                           slug        => 'test',
                           user__id    => 0,
                           element     => $element,
                           site_id     => 100,
                       });
    # make a couple of categories
    my $cats = [];
    $cats->[0] = Bric::Biz::Category->new({
                                           name => "_test_$time.1",
                                           description => '',
                                           directory => "_test_$time.1",
                                           id => 1,
                                        });
    $cats->[1] = Bric::Biz::Category->new({
                                           name => "_test_$time.2",
                                           description => '',
                                           directory => "_test_$time.2",
                                           id => 2,
                                        });
    # add the categories 
    ok( $story->add_categories($cats), 'can add an arrayref of new categories');
    # get the categories
    my $rcats;
    ok( $rcats = $story->get_categories, '... and we can call get');
    # are the ones we just added in there?
    $rcats = [ sort { $a->get_name cmp $b->get_name } @$rcats ];
    is( $rcats->[0]->get_name(), "_test_$time.1", ' ... and they both' );
    is( $rcats->[1]->get_name(), "_test_$time.2", ' ... have the right name' );
}

sub test_set_get_primary_category: Test(8) {
    # make a story
    my $time = time;
    my $element = $ELEMENT_CLASS->new({
                                        id          => 1,
                                        name        => 'test element',
                                        description => 'testing',
                                        active      => 1,
                                     });
    my $story = class->new({
                           name        => "_test_$time",
                           description => 'this is a test',
                           priority    => 1,
                           source__id  => 1,
                           slug        => 'test',
                           user__id    => 0,
                           element     => $element,
                           site_id     => 100,
                       });
    # Test: make sure it has no primary category
    is( $story->get_primary_category(), undef, 'a new story has no primary category' );
    # make a couple of categories
    my $cats = [];
    $cats->[0] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.1", 
                                           description => '',
                                           directory => "_test_$time.1",
                                           id => 1,
                                        });
    $cats->[1] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.2", 
                                           description => '',
                                           directory => "_test_$time.2",
                                           id => 2,
                                        });
    # add the categories 
    ok( $story->add_categories($cats), 'can add an arrayref of new categories');
    # set it as the primary
    ok( $story->set_primary_category($cats->[0]), 'can set it as the primary category');
    # get the primary category
    my $pcat;
    ok( $pcat = $story->get_primary_category(), ' ... and can get it.');
    # Test: is the primary category the one we set
    is( $pcat->get_name(), $cats->[0]->get_name(), ' ... and it appears to be the same one.');
    # set it as the primary
    ok( $story->set_primary_category($cats->[1]), "now let's try to change it");
    # get the primary category
    ok( $pcat = $story->get_primary_category(), ' ... and can get it.');
    # Test: is the primary category the one we set
    is( $pcat->get_name(), $cats->[1]->get_name(), ' ... and it appears to be the new one.');
}

sub test_get_uri: Test(1) {
    # make a story with the slug 'test'
    my $time = time;
    my ($oc) = $OC_CLASS->list(); # any oc will do
    my $element = $ELEMENT_CLASS->new({
                                        id             => 1,
                                        name           => 'test element',
                                        description    => 'testing',
                                        active         => 1,
                                        output_channel => $oc,
                                     });
#    $element->set_primary_oc_id($oc->get_id, 100);
    my $story = class->new({
                           name        => "_test_$time",
                           description => 'this is a test',
                           priority    => 1,
                           source__id  => 1,
                           slug        => 'test',
                           user__id    => 0,
                           element     => $element,
                           site_id     => 100,
                       });
    # tryto get the uri before a category assigned. should catch an error
    eval { $story->get_uri };
    isnt( $@, undef, 'Should get an error if we try to get a uri with no category.' );
    # make a couple of categories
    my $cats = [];
    $cats->[0] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.1", 
                                           description => '',
                                           directory => "_test_$time.1",
                                           id => 1,
                                        });
    $cats->[1] = Bric::Biz::Category->new({ 
                                           name => "_test_$time.2", 
                                           description => '',
                                           directory => "_test_$time.2",
                                           id => 2,
                                        });
    # add the categories
    $story->add_categories($cats);
    $story->set_primary_category($cats->[0]);
    # the uri should now be '/$dir/.*test'
    # XXX try to get the uri with a cat set
    # XXX then try it with a different cat
}

sub test_get_fields_from_new {
    # XXX make a new story with all of the fields
    # XXX Test: does each field have a value matching
    #           that set in the params?
}

sub test_set_get_fields {
    # XXX make a new story with minimal fields set
    # XXX For each field:
    # XXX set the field
    # XXX Test: get the field and compare with what we set
}

sub test_new_grp_ids: Test(5) {
    my $self = shift;
    my $class = $self->class;
    my $all_stories_grp_id = $class->INSTANCE_GROUP_ID;
    my $time = time;
    my $element = Bric::Biz::ElementType->new
      ({ name        => "_test_$time.new",
         key_name    => "_test_$time.new",
         burner      => 1,
         description => 'this is a test',
       });
    $element->save;
    $self->add_del_ids($element->get_id, 'element_type');
    my $cat = Bric::Biz::Category->new({ name => "_test_$time.new",
                                         description => 'foo',
                                         directory => "_test_$time.new",
                                         site_id => 100
                                       });
    $CATEGORY->add_child([$cat]);
    $cat->save();
    $self->add_del_ids($cat->get_id(), 'category');
    my $cat1 = Bric::Biz::Category->new({ name => "_test_$time.new1",
                                          description => 'foo',
                                          directory => "_test_$time.new1",
                                          site_id => 100
                                        });
    $CATEGORY->add_child([$cat1]);
    $cat1->save;
    $self->add_del_ids($cat1->get_id, 'category');
    # first we'll try it with no cats
    my $story = class->new({ name        => "_test_$time",
                             description => 'this is a test',
                             priority    => 1,
                             source__id  => 1,
                             slug        => 'test',
                             user__id    => 0,
                             site_id     => 100,
                             element     => $element,
                           });
    my $expected = [ sort { $a <=> $b } $all_stories_grp_id, 100 ];
    is_deeply([sort { $a <=> $b } $story->get_grp_ids], $expected,
              'does a story get initialized with the right grp_id?');
    # add the categories
    $story->add_categories([$cat, $cat1]);
    $expected = [ sort { $a <=> $b }
                  $cat->get_asset_grp_id,
                  $cat1->get_asset_grp_id,
                  $all_stories_grp_id,
                  100
                ];
    is_deeply( [sort { $a <=> $b } $story->get_grp_ids], $expected,
               'does adding cats get the right asset_grp_ids?');
    # now remove one
    $story->delete_categories([$cat]);
    $expected = [ sort { $a <=> $b }
                  $cat1->get_asset_grp_id,
                  $all_stories_grp_id,
                  100,
                ];
    is_deeply([sort { $a <=> $b } $story->get_grp_ids], $expected,
              'does removing a cat remove the right asset_grp_id?');

    $story = class->new({ name        => "_test_$time",
                          description => 'this is a test',
                          priority    => 1,
                          source__id  => 1,
                          slug        => 'test',
                          user__id    => 0,
                          site_id     => 100,
                          element     => $element,
                        });
    my $desk = Bric::Biz::Workflow::Parts::Desk->new({ name => "_test_$time",
                                                       description => '',
                                                     });
    $desk->save();
    $self->add_del_ids($desk->get_id(), 'desk');
    my $workflow = Bric::Biz::Workflow->new
      ({ type        => Bric::Biz::Workflow::STORY_WORKFLOW,
         name        => "_test_$time",
         start_desk  => $desk,
         description => 'test',
         site_id     => 100
       });
    $workflow->save();
    $self->add_del_ids($workflow->get_id(), 'workflow');
    $story->set_current_desk($desk);
    $expected = [ sort { $a <=> $b }
                  $all_stories_grp_id,
                  $desk->get_asset_grp,
                  100
                ];
    is_deeply([sort { $a <=> $b } $story->get_grp_ids], $expected,
              'setting the current desk of a story adds the correct asset_grp_ids');
    $story->set_workflow_id($workflow->get_id);
    $expected = [ sort { $a <=> $b }
                  $workflow->get_asset_grp_id,
                  $all_stories_grp_id,
                  $desk->get_asset_grp,
                  100
                ];
    is_deeply([sort { $a <=> $b } $story->get_grp_ids], $expected,
              'setting the workflow id of a story adds the correct asset_grp_ids');
}

1;
__END__
