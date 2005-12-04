package Bric::Biz::Asset::Template::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::DevTest);
use Test::More;
use Bric::Biz::Asset::Template;
use Bric::Biz::ElementType;
use Bric::Util::DBI qw(:junction);
use Bric::Util::Burner::Mason;
use Bric::Util::Burner::Template;
use Test::MockModule;

my $CATEGORY = Bric::Biz::Category->lookup({ id => 1 });

# this will be filled during setup
my $OBJ_IDS = {};
my $OBJ = {};
my @CATEGORY_GRP_IDS;
my @WORKFLOW_GRP_IDS;
my @DESK_GRP_IDS;
my @TEMPLATE_GRP_IDS;
my @ALL_DESK_GRP_IDS;
my @REQ_DESK_GRP_IDS;
my @EXP_GRP_IDS;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Template' }
sub table { 'template' }

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    ( output_channel__id => 1,
      user__id           => $self->user_id,
      category_id        => 1,
      name               => 'foodoo',
      site_id            => 100,
    )
}

##############################################################################
# Method for making an OC
##############################################################################
sub make_oc {
    my $self = shift;
    my $time = time;
    my $oc = Bric::Biz::OutputChannel->new({ name    => "_test_$time",
                                             site_id => 100 });
    $oc->save;
    my $id = $oc->get_id;
    $self->add_del_ids($id, 'output_channel');
    return $oc;
}


##############################################################################
# Test constructor.
##############################################################################
# Test new() creating an element template.
sub test_new_elem : Test(17) {
    my $self = shift;
    ok( my $class = $self->class, "Get class" );
    ok( my $key = $class->key_name, "Get key_name" );

    # Create a conflicting template.
    eval { $self->construct(element => $self->get_elem) };
    ok( my $err = $@, "Catch exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    my $msg = "The template '/story.mc' already exists in output channel " .
      "'Web'";
    is( $err->get_msg, $msg, "Check message" );

    # Create a new output channel.
    my $oc_id = $self->make_oc->get_id;

    # Create one that doesn't conflict.
    ok( my $t = $class->new({ $self->new_args,
                              element => $self->get_elem,
                              output_channel__id => $oc_id
                            }),
        "Create non-conflicting element template");
    is( $t->get_tplate_type, $class->ELEMENT_TEMPLATE, "Check tplate_type" );
    is( $t->get_tplate_type_string, 'Element Template',
        "Check tplate_type string" );

    # Do it again explicitly passing in a tplate_type argument.
    ok( $t = $class->new({ $self->new_args,
                              element => $self->get_elem,
                              output_channel__id => $oc_id,
                              tplate_type => 1
                            }),
        "Create non-conflicting with tplate_type");
    is( $t->get_tplate_type, $class->ELEMENT_TEMPLATE, "Check tplate_type" );
    is( $t->get_file_name, '/story.mc', "Check file_name" );

    # Now break it with the right tplate_type, but no parameters.
    eval {
        $class->new({ $self->new_args,
                      output_channel__id => $oc_id,
                      tplate_type => 1
                    })
    };
    ok( $err = $@, "Catch exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    $msg = "Missing required parameter 'element_type' or 'element_type_id'";
    is( $err->get_msg, $msg, "Check another message" );

    # Mock HTML::Template support into the output channel.
    my $oc_class = Test::MockModule->new('Bric::Biz::OutputChannel');
    $oc_class->mock(get_burner => Bric::Biz::OutputChannel::BURNER_TEMPLATE);

    # Create an HTML::Template template.
    ok( $t = $class->new({ $self->new_args,
                           element => $self->get_elem,
                           file_type => 'tmpl'
                         }),
        "Create HTML::Template template" );
    is( $t->get_tplate_type, $class->ELEMENT_TEMPLATE, "Check tplate_type" );
    is( $t->get_file_name, '/story.tmpl', "Check file_name" );
}

###############################################################################
## Test new() creating a category template.
sub test_new_cat : Test(18) {
    my $self = shift;
    ok( my $class = $self->class, "Get class" );
    ok( my $key = $class->key_name, "Get key_name" );

    # Create a conflicting category template.
    eval { $class->new({ $self->new_args, name => undef }) };
    ok( my $err = $@, "Catch exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    my $msg = "The template '/autohandler' already exists in output channel " .
      "'Web'";
    is( $err->get_msg, $msg, "Check message" );

    # Create an OC.
    my $oc = $self->make_oc;
    my $oc_id = $oc->get_id;

    # Create one that doesn't conflict.
    ok( my $t = $class->new({ $self->new_args,
                              name => undef,
                              output_channel__id => $oc_id
                            }),
        "Create non-conflicting element template");
    is( $t->get_tplate_type, $class->CATEGORY_TEMPLATE, "Check tplate_type" );
    is( $t->get_tplate_type_string, 'Category Template',
        "Check tplate_type string" );
    is( $t->get_file_name, '/autohandler', "Check name" );

    # Do it again explicitly passing in a tplate_type argument.
    ok( $t = $class->new({ $self->new_args,
                              tplate_type => 2,
                              output_channel__id => $oc_id
                            }),
        "Create non-conflicting element template");
    is( $t->get_tplate_type, $class->CATEGORY_TEMPLATE, "Check tplate_type" );
    is( $t->get_file_name, '/autohandler', "Check name" );

    # Now break it with the tplate_type, but broken parameters.
    eval {
        $class->new({ $self->new_args,
                      output_channel__id => $oc_id,
                      tplate_type => 2,
                      file_type => 'foo'
                    })
    };
    ok( $err = $@, "Catch exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    my $oc_name = $oc->get_name;
    $msg = qq{"foo" is not a valid file type in the "$oc_name" output channel};
    is( $err->get_msg, $msg, "Check another message" );

    # Mock HTML::Template support into the output channel.
    my $oc_class = Test::MockModule->new('Bric::Biz::OutputChannel');
    $oc_class->mock(get_burner => Bric::Biz::OutputChannel::BURNER_TEMPLATE);

    # Create an HTML::Template category template.
    ok( $t = $class->new({ $self->new_args,
                           output_channel__id => $oc_id,
                           tplate_type => 2,
                           file_type => 'tmpl'
                         }),
        "Create HTML::Template category template" );
    is( $t->get_tplate_type, $class->CATEGORY_TEMPLATE, "Check tplate_type" );
    is( $t->get_file_name, '/category.tmpl', "Check file_name" );
}

##############################################################################
# Test new() creating a utility template.
sub test_new_util : Test(23) {
    my $self = shift;
    ok( my $class = $self->class, "Get class" );
    ok( my $key = $class->key_name, "Get key_name" );

    # Create a new utility template.
    ok( my $t = $self->construct, "Create new utility template" );
    is( $t->get_tplate_type, $class->UTILITY_TEMPLATE, "Check tplate_type" );
    is( $t->get_tplate_type_string, 'Utility Template',
        "Check tplate_type string" );
    is( $t->get_file_name, '/foodoo.mc', "Check name" );

    ok( $t->save, "Save utility template" );
    # Save the ID for cleanup.
    ok( my $tid = $t->get_id, "Get template ID" );
    $self->add_del_ids([$tid], $key);

    # Create a conflicting utility template.
    eval { $self->construct };
    ok( my $err = $@, "Catch exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    my $msg = "The template '/foodoo.mc' already exists in output channel " .
      "'Web'";
    is( $err->get_msg, $msg, "Check message" );

    # Grab an OC ID.
    my $oc_id = $self->make_oc->get_id;

    # Create one that doesn't conflict.
    ok( $t = $class->new({ $self->new_args,
                              output_channel__id => $oc_id
                            }),
        "Create non-conflicting element template");
    is( $t->get_tplate_type, $class->UTILITY_TEMPLATE, "Check tplate_type" );
    is( $t->get_file_name, '/foodoo.mc', "Check name" );

    # Do it again explicitly passing in a tplate_type argument.
    ok( $t = $class->new({ $self->new_args,
                              tplate_type => 3,
                              output_channel__id => $oc_id
                            }),
        "Create non-conflicting element template");
    is( $t->get_tplate_type, $class->UTILITY_TEMPLATE, "Check tplate_type" );
    is( $t->get_file_name, '/foodoo.mc', "Check name" );

    # Now break it with the tplate_type, but broken parameters.
    eval {
        $class->new({ $self->new_args,
                      tplate_type => 3,
                      name => undef
                    })
    };
    ok( $err = $@, "Catch exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    $msg = "Missing required parameter 'name'";
    is( $err->get_msg, $msg, "Check another message" );

    # Mock HTML::Template support into the output channel.
    my $oc_class = Test::MockModule->new('Bric::Biz::OutputChannel');
    $oc_class->mock(get_burner => Bric::Biz::OutputChannel::BURNER_TEMPLATE);

    # Create an HTML::Template utility template.
    ok( $t = $class->new({ $self->new_args,
                           file_type => 'tmpl'
                         }),
        "Create HTML::Template utility template" );
    is( $t->get_tplate_type, $class->UTILITY_TEMPLATE, "Check tplate_type" );
    is( $t->get_file_name, '/foodoo.tmpl', "Check file_name" );
}


sub test_select_a_default_objs: Test(12) {
    my $got;

    ok( $got = class->lookup({ id => 512 }), 
      'Try looking up one of the default templates.');
    is( $got->get_name(), 'Story', '... did we get the right one?');

    # test list by name on each one of the default templates
    # 512 | Story
    ok( $got = class->list({ name => 'Story' }),
      'Try listing one of the default templates by name.');
    is( $got->[0]->get_id(), 512, '... did we get the right one?');
    is( @$got, 1, '... and only the one');

    # test list_ids by name on each default template
    # 512 | Story
    ok( $got = class->list_ids({ name => 'Story' }),
      'Try list_ids on one of the default templates by name.');
    is( $got->[0], 512, '... did we get the right one?');
    is( @$got, 1, '... and only the one');

    # test list on an open search
    ok( $got = class->list(), 
      'Try getting all of the templates using list');
    is( @$got, 12, '... there should be 12');

    # test list_ids on an open search
    ok( $got = class->list(), 
      'Try getting all of the templates using list_ids');
    is( @$got, 12, '... there should be 12');
}

##############################################################################
sub test_select_b_new_objs: Test(82) {
    my $self = shift;
    my $class = $self->class;

    # let's grab existing 'All' group info
    my $all_workflow_grp_id = Bric::Biz::Workflow->INSTANCE_GROUP_ID;
    my $all_cats_grp_id = Bric::Biz::Category->INSTANCE_GROUP_ID;
    my $all_desks_grp_id =  Bric::Biz::Workflow::Parts::Desk->INSTANCE_GROUP_ID;
    my $all_template_grp_id = $class->INSTANCE_GROUP_ID;

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
        $self->add_del_ids($cat->get_id(), 'category');
        push @{$OBJ_IDS->{category}}, $cat->get_id();
        push @{$OBJ->{category}}, $cat;
        # create some category groups
        $grp = Bric::Util::Grp::CategorySet->new({ name => "_test_$time.$i",
                                                   description => '',
                                                   obj => $cat });

        $grp->add_member({obj => $cat });
        # save the group ids
        $grp->save();
        $self->add_del_ids($grp->get_id(), 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @CATEGORY_GRP_IDS, $grp->get_id();

        # create desks 
        $desk = Bric::Biz::Workflow::Parts::Desk->new
          ({ name => "_test_$time.$i",
             description => '',
           });
        $desk->save();
        $self->add_del_ids($desk->get_id(), 'desk');
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
        $self->add_del_ids($grp->get_id(), 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @DESK_GRP_IDS, $grp->get_id();

        # create workflows
        $workflow = Bric::Biz::Workflow->new
          ({ type => Bric::Biz::Workflow::TEMPLATE_WORKFLOW,
             name => "_test_$time.$i",
             start_desk => $desk,
             description => 'test',
             site_id => 100, #Use default site_id
           });
        $workflow->save();
        $self->add_del_ids($workflow->get_id(), 'workflow');
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
        $self->add_del_ids($grp->get_id(), 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @WORKFLOW_GRP_IDS, $grp->get_id();

        # create some template groups
        $grp = Bric::Util::Grp::Template->new
          ({ name => "_GRP_test_$time.$i" });
        # save the group ids
        $grp->save();
        $self->add_del_ids($grp->get_id(), 'grp');
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @{$OBJ->{template_grp}}, $grp;
        push @TEMPLATE_GRP_IDS, $grp->get_id();
    }

    # set up to do the deletes
    foreach my $table (qw(grp category workflow desk)) {
        $self->add_del_ids( $OBJ_IDS->{$table}, $table );
    }

    # we'll be making a new element for each
    my $element;

    # and a user
    my $admin_id = $self->user_id();

    # create some template objects and test them
    my (@template, $time, $got, $expected);

    # A template with one category (admin user)
    $time = time;
    $element = Bric::Biz::ElementType->new({ key_name    => "_test_$time",
                                           name        => "_test_$time",
                                           burner      => 1,
                                           description => 'this is a test',
                                         });
    $element->save();
    $self->add_del_ids($element->get_id, 'element_type');
    $template[0] = class->new({
        priority           => 1,
        user__id           => $admin_id,
        description        => 'test object',
        element            => $element,
        tplat_type         => 1,
        output_channel__id => 1,
        category_id        => $OBJ->{category}->[0]->get_id,
        site_id            => 100,
        note               => 'Note 1',
    });
    $template[0]->checkin();
    $template[0]->save();
    $template[0]->checkout({ user__id => $self->user_id });
    $template[0]->checkin();
    $template[0]->save();
    $template[0]->checkout({ user__id => $self->user_id });
    $template[0]->checkin();
    $template[0]->save();

    push @{$OBJ_IDS->{template}}, $template[0]->get_id();
    $self->add_del_ids( $template[0]->get_id() );

    # Try doing a lookup 
    $expected = $template[0];
    ok( $got = class->lookup({ id => $OBJ_IDS->{template}->[0] }),
      'can we call lookup on a Template Object' );
    is( $got->get_name, $expected->get_name,
      '... does it have the right name');
    is( $got->get_description, $expected->get_description,
      '... does it have the right desc');

    # check the grp IDs
    my $exp_grp_ids = [ sort { $a <=> $b }
                        $all_template_grp_id,
                        $OBJ->{category}->[0]->get_asset_grp_id,
                        100
                      ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply([sort  { $a <=> $b } $got->get_grp_ids] , $exp_grp_ids,
              '... does it have the right grp_ids' );

    # now find out if return_version get the right number of versions
    ok( $got = class->list({ id => $OBJ_IDS->{template}->[0],
                             return_versions => 1,
                             Order => 'version'}),
        'does return_versions work?' );
    is( scalar @$got, 3, '...and did we get three versions of template[0]');

    # Make sure we got them back in order.
    my $n;
    foreach my $f (@$got) {
        is( $f->get_version, ++$n, "Check for version $n");
    }

    # Now fetch a specific version.
    ok( $got = class->lookup({ id => $OBJ_IDS->{template}->[0],
                               version => 2 }),
        "Get version 2" );
    is( $got->get_version, 2, "Check that we got version 2" );

    # ... as a grp member
    $time = time;
    $element = Bric::Biz::ElementType->new
      ({ key_name    => "_test_$time.1",
         name        => "_test_$time.1",
         burner      => 1,
         description => 'this is a test',
       });
    $element->save();
    $self->add_del_ids($element->get_id, 'element_type');
    $template[1] = class->new
      ({ priority           => 1,
         user__id           => $admin_id,
         element            => $element,
         tplat_type         => 1,
         output_channel__id => 1,
         category_id        => $OBJ->{category}->[0]->get_id,
         site_id            => 100,
         note               => 'Note 2',
       });
    $template[1]->save;
    push @{$OBJ_IDS->{template}}, $template[1]->get_id();
    $self->add_del_ids( $template[1]->get_id() );

    $OBJ->{template_grp}->[0]->add_member({ obj => $template[1] });
    $OBJ->{template_grp}->[0]->save();

    $expected = $template[1];
    ok( $got = class->lookup({ id => $OBJ_IDS->{template}->[1] }),
        'can we call lookup on a template which is itself in a grp' );
    is( $got->get_name, $expected->get_name,
        '... does it have the right name');
    is( $got->get_description, $expected->get_description,
        '... does it have the right desc');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_template_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id,
                     $TEMPLATE_GRP_IDS[0],
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply([sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
              '... does it have the right grp_ids' );

    # ... a bunch of grps
    $time = time;
    $element = Bric::Biz::ElementType->new({ key_name    => "_test_$time.2",
                                           name        => "_test_$time.2",
                                           burner      => 1,
                                           description => 'this is a test',
                                         });
    $element->save;
    $self->add_del_ids($element->get_id, 'element_type');

    $template[2] = class->new({
        priority           => 1,
         user__id           => $admin_id,
         element            => $element,
         tplat_type         => 1,
         output_channel__id => 1,
         category_id        => $OBJ->{category}->[0]->get_id,
         site_id            => 100,
         note               => 'Note 3',
    });

    $template[2]->checkin();
    $template[2]->save();
    $template[2]->checkout({ user__id => $self->user_id });
    $template[2]->save();

    push @{$OBJ_IDS->{template}}, $template[2]->get_id();
    $self->add_del_ids( $template[2]->get_id() );

    $OBJ->{template_grp}->[0]->add_member({ obj => $template[2] });
    $OBJ->{template_grp}->[0]->save();

    $OBJ->{template_grp}->[1]->add_member({ obj => $template[2] });
    $OBJ->{template_grp}->[1]->save();

    $OBJ->{template_grp}->[2]->add_member({ obj => $template[2] });
    $OBJ->{template_grp}->[2]->save();

    $OBJ->{template_grp}->[3]->add_member({ obj => $template[2] });
    $OBJ->{template_grp}->[3]->save();

    $OBJ->{template_grp}->[4]->add_member({ obj => $template[2] });
    $OBJ->{template_grp}->[4]->save();

    $expected = $template[2];
    ok( $got = class->lookup({ id => $OBJ_IDS->{template}->[2] }),
        'can we call lookup on a template which is itself in a grp' );
    is( $got->get_name, $expected->get_name,
        '... does it have the right name');
    is( $got->get_description, $expected->get_description,
        '... does it have the right desc');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_template_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id,
                     $TEMPLATE_GRP_IDS[0],
                     $TEMPLATE_GRP_IDS[1],
                     $TEMPLATE_GRP_IDS[2],
                     $TEMPLATE_GRP_IDS[3],
                     $TEMPLATE_GRP_IDS[4],
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply([sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
              '... does it have the right grp_ids' );

    # ... now try a workflow
    $time = time;
    $element = Bric::Biz::ElementType->new({ key_name    => "_test_$time.3",
                                           name        => "_test_$time.3",
                                           burner      => 1,
                                           description => 'this is a test',
                                         });
    $element->save();
    $self->add_del_ids($element->get_id, 'element_type');
    $template[3] = class->new
      ({ priority           => 1,
         user__id           => $admin_id,
         element            => $element,
         tplat_type         => 1,
         output_channel__id => 1,
         category_id        => $OBJ->{category}->[0]->get_id(),
         site_id            => 100,
         note               => 'Note 4',
       });
    $template[3]->set_workflow_id( $OBJ->{workflow}->[0]->get_id() );
    $template[3]->save();
    push @{$OBJ_IDS->{template}}, $template[3]->get_id();
    $self->add_del_ids( $template[3]->get_id() );

    # add it to the workflow

    # Try doing a lookup 
    $expected = $template[3];
    ok( $got = class->lookup({ id => $OBJ_IDS->{template}->[3] }),
      'can we call lookup on a Template Object' );
    is( $got->get_name(), $expected->get_name(),
      '... does it have the right name');
    is( $got->get_description(), $expected->get_description(),
      '... does it have the right desc');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_template_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id,
                     $OBJ->{workflow}->[0]->get_asset_grp_id,
                     100
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    is_deeply( [sort { $a <=> $b } $got->get_grp_ids], $exp_grp_ids,
               '... does it have the right grp_ids' );

    # ... desk
    $time = time;
    $element = Bric::Biz::ElementType->new({ key_name    => "_test_$time.4",
                                           name        => "_test_$time.4",
                                           burner      => 1,
                                           description => 'this is a test',
                                         });
    $element->save();
    $self->add_del_ids($element->get_id, 'element_type');
    $template[4] = class->new
      ({ priority           => 1,
         user__id           => $admin_id,
         element            => $element,
         tplat_type         => 1,
         output_channel__id => 1,
         category_id        => $OBJ->{category}->[0]->get_id(),
         site_id            => 100,
         note               => 'Note 5',
       });
    $template[4]->set_workflow_id( $OBJ->{workflow}->[0]->get_id );
    $template[4]->save;

    $OBJ->{desk}->[0]->accept({ asset  => $template[4] });
    $OBJ->{desk}->[0]->save;
    $template[4]->checkin();
    $template[4]->save();

    push @{$OBJ_IDS->{template}}, $template[4]->get_id();
    $self->add_del_ids( $template[4]->get_id() );

    # add it to the workflow

    # Try doing a lookup 
    $expected = $template[4];
    ok( $got = class->lookup({ id => $OBJ_IDS->{template}->[4] }),
        'can we call lookup on a Template Object' );
    is( $got->get_name, $expected->get_name,
        '... does it have the right name');
    is( $got->get_description, $expected->get_description,
        '... does it have the right desc');

    # check the grp IDs
    $exp_grp_ids = [ sort { $a <=> $b }
                     $all_template_grp_id,
                     $OBJ->{category}->[0]->get_asset_grp_id,
                     $OBJ->{workflow}->[0]->get_asset_grp_id,
                     $OBJ->{desk}->[0]->get_asset_grp,
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
        'lets do a search by name' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id;
        push @got_grp_ids, [sort { $a <=> $b } $_->get_grp_ids ];
    }

    $OBJ_IDS->{template} = [ sort { $a <=> $b }
                               @{ $OBJ_IDS->{template} } ];

    is_deeply( [sort { $a <=> $b } @got_ids], $OBJ_IDS->{template},
               '... did we get the right list of ids out' );
    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for template $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    # Try a search by element_key_name.
    ok( $got = class->list({ element_key_name => '_test_%',
                             Order            => 'name' }),
        'lets do a search by element_key_name' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id;
        push @got_grp_ids, [sort { $a <=> $b } $_->get_grp_ids ];
    }

    $OBJ_IDS->{template} = [ sort { $a <=> $b }
                               @{ $OBJ_IDS->{template} } ];

    is_deeply( [sort { $a <=> $b } @got_ids], $OBJ_IDS->{template},
               '... did we get the right list of ids out' );
    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for template $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    ok( $got = class->list({ name   => '_test%',
                             Order   => 'name' }),
        'lets do a search by name' );

    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id;
        push @got_grp_ids, [sort { $a <=> $b } $_->get_grp_ids];
    }
    is_deeply( [sort { $a <=> $b } @got_ids], $OBJ_IDS->{template},
               '... did we get the right list of ids out' );
    for (my $i = 0; $i < @got_grp_ids; $i++) {
        is_deeply( $got_grp_ids[$i], $EXP_GRP_IDS[$i],
                   "... and did we get the right grp_ids for template $i" );
    }
    undef @got_ids;
    undef @got_grp_ids;

    # finally do this by grp_ids
    ok( $got = class->list({ grp_id  => $OBJ->{template_grp}->[0]->get_id,
                             Order   => 'name' }),
        'getting by grp_id' );
    my $number = @$got;
    is( $number, 2, 'there should be two template in the first grp' );
    is( $got->[0]->get_id, $template[1]->get_id,
        '... and they should be numbers 2' );
    is( $got->[1]->get_id, $template[2]->get_id, '... and 3' );

    # try listing IDs, again at least one key per table
    ok( $got = class->list_ids({ name    => '_test%',
                                 Order   => 'name' }),
        'lets do an IDs search by name' );
    # check the ids
    is_deeply( $got, $OBJ_IDS->{template},
               '... did we get the right list of ids out' );

    ok( $got = class->list_ids({ name   => '_test%',
                                 Order   => 'name' }),
        'lets do an ids search by name' );

    # check the ids
    is_deeply($got, $OBJ_IDS->{template},
              '... did we get the right list of ids out' );

    # finally do this by grp_ids
    ok( $got = class->list_ids({ grp_id  => $OBJ->{template_grp}->[0]->get_id,
                                 Order   => 'name' }),
        'getting by grp_id' );
    $number = @$got;
    is( $number, 2,
        'there should be two template objects in the first grp' );
    is( $got->[0], $template[1]->get_id,
        '... and they should be numbers 2' );
    is( $got->[1], $template[2]->get_id,
        '... and 3' );


    # now let's try a limit
    ok( $got = class->list({ Order   => 'name',
                             Limit   => 3 }),
        'try setting a limit of 3');
    is( @$got, 3, '... did we get exactly 3 template objects back' );

    # test Offset
    ok( $got = class->list({ grp_id => $OBJ->{template_grp}->[0]->get_id,
                             Order => 'name',
                             Offset => 1 }),
        'try setting an offset of 2 for a search that just returned 3 objs');
    is( @$got, 1, '... Offset gives us #2 of 2' );

    # User ID should return only assets checked out to the user.
    ok $got = class->list({
        name   => '_test%',
        Order   => 'name',
        user_id => $admin_id,
    }), 'Get templates for user';
    is @$got, 3, 'Should have three templates checked out to user';

    # Now try the checked_out parameter. Three templates should be checked out.
    ok $got = class->list({
        name       => '_test%',
        Order       => 'name',
        checked_out => 1,
    }), 'Get checked out templates';
    is @$got, 3, 'Should have three checked out templates';

    # With checked_out => 0, we should get the other two templates.
    ok $got = class->list({
        name       => '_test%',
        Order       => 'name',
        checked_out => 0,
    }), 'Get non-checked out templates';
    is @$got, 2, 'Should have two non-checked out templates';

    # Try the checked_in parameter, which should return all five templates.
    ok $got = class->list({
        name       => '_test%',
        Order       => 'name',
        checked_in  => 1,
    }), 'Get checked in templates';
    is @$got, 5, 'Should have five checked in templates';

    # And even the checked-out template should return us the checked-in
    # version.
    is_deeply [ map { $_->get_checked_out } @$got ], [0, 1, 0, 1, 0],
      "We should get the checked-in copy of the checked-out template";

    # Without checked_in parameter we should get the the checked-out
    # templates.
    ok $got = class->list({
        name       => '_test%',
        Order       => 'name',
    }), 'Get all templates';
    is @$got, 5, 'Should have five templates';

    # And now the checked-out template should return us the checked-in
    # version.
    is_deeply [ map { $_->get_checked_out } @$got ], [0, 1, 1, 1, 0],
      "We should get the checked-out templates where available";

    # Now search on notes.
    ok $got = class->list({ note => 'Note 1'}), 'Search on note "Note 1"';
    is @$got, 1, 'Should have one template';
    ok $got = class->list({ note => 'Note %'}), 'Search on note "Note %"';
    is @$got, 5, 'Should have five templates';
    ok $got = class->list({ note => ANY('Note 1', 'Note 2')}),
                          'Search on note "ANY(Note 1, Note 2)"';
    is @$got, 2, 'Should have two templates';

}

sub test_new_grp_ids: Test(4) {
    my $self = shift;
    my $class = $self->class;
    my $all_template_grp_id = $class->INSTANCE_GROUP_ID;
    my $time = time;
    my $element = Bric::Biz::ElementType->new({ name        => "_test_$time.new",
                                              key_name    => "_test_$time.new",
                                              burner      => 1,
                                              description => 'this is a test',
                                            });
    $element->save();
    $self->add_del_ids($element->get_id, 'element_type');
    my $cat = Bric::Biz::Category->new
      ({ name        => "_test_$time.new",
         description => 'foo',
         site_id     => 100,
         directory   => "_test_$time.new",
       });
    $CATEGORY->add_child([$cat]);
    $cat->save();
    $self->add_del_ids($cat->get_id(), 'category');
    # first we'll try it with a category_id
    my $template = class->new({ priority           => 1,
                                  user__id           => $self->user_id,
                                  element            => $element,
                                  tplat_type         => 1,
                                  output_channel__id => 1,
                                  site_id            => 100,
                                  category_id        => $cat->get_id,
                                });
    my $expected = [ sort { $a <=> $b }
                     $cat->get_asset_grp_id,
                     $all_template_grp_id,
                     100
                   ];
    is_deeply( [sort { $a <=> $b } $template->get_grp_ids], $expected,
               'does template instanciated with a cat_id have the right ' .
               'grp ids?');
    # first we'll try it with a category
    undef $template;
    $template = class->new({ priority           => 1,
                               user__id           => $self->user_id,
                               element            => $element,
                               tplat_type         => 1,
                               output_channel__id => 1,
                               site_id            => 100,
                               category           => $cat
                             });
    $expected = [ sort { $a <=> $b }
                  $cat->get_asset_grp_id,
                  $all_template_grp_id,
                  100
                ];
    is_deeply( [sort { $a <=> $b } $template->get_grp_ids ], $expected,
               'does template instanciated with a cat have the right grp ids?');
    my $desk = Bric::Biz::Workflow::Parts::Desk->new
      ({ name => "_test_$time",
         description => '',
       });
    $desk->save();
    $self->add_del_ids($desk->get_id(), 'desk');
    my $workflow = Bric::Biz::Workflow->new
      ({ type        => Bric::Biz::Workflow::TEMPLATE_WORKFLOW,
         name        => "_test_$time",
         start_desk  => $desk,
         description => 'test',
         site_id     => 100,
       });
    $workflow->save();
    $self->add_del_ids($workflow->get_id(), 'workflow');
    $template->set_current_desk($desk);
    $expected = [ sort { $a <=> $b }
                  $cat->get_asset_grp_id,
                  $all_template_grp_id,
                  $desk->get_asset_grp,
                  100
                ];
    is_deeply([sort { $a <=> $b } $template->get_grp_ids], $expected,
              'setting the current desk of a template adds the correct ' .
              'asset_grp_ids');
    $template->set_workflow_id($workflow->get_id());
    $expected = [ sort { $a <=> $b }
                  $cat->get_asset_grp_id,
                  $workflow->get_asset_grp_id,
                  $all_template_grp_id,
                  $desk->get_asset_grp,
                  100
                ];
    is_deeply( [sort { $a <=> $b } $template->get_grp_ids], $expected,
               'setting the workflow id of a template adds the correct ' .
               'asset_grp_ids');
}

1;
__END__
