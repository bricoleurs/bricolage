package Bric::Biz::Asset::Formatting::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Asset::Formatting;
use Bric::Biz::AssetType;
use Bric::Biz::ATType;

my ($CATEGORY) = Bric::Biz::Category->list();

# this will be filled during setup
my $OBJ_IDS = {};
my $OBJ = {};
my @CATEGORY_GRP_IDS;
my @WORKFLOW_GRP_IDS;
my @DESK_GRP_IDS;
my @FORMATTING_GRP_IDS;
my @ALL_DESK_GRP_IDS;
my @REQ_DESK_GRP_IDS;
my @EXP_GRP_IDS;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Formatting' }
sub table { 'formatting' }

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    ( output_channel__id => 1,
      user__id           => $self->user_id,
      category_id        => 1,
      name               => 'foodoo'
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
    return $id;
}


##############################################################################
# The element object we'll use throughout. Override in subclass if necessary.
##############################################################################
my $elem;
sub get_elem {
    $elem ||= Bric::Biz::AssetType->lookup({ id => 1 });
    $elem;
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({ $self->new_args, @_ });
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
    eval { $class->new({ $self->new_args, element => $self->get_elem }) };
    ok( my $err = $@, "Catch exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    my $msg = "The template '/story.mc' already exists in output channel " .
      "'Web'";
    is( $err->get_msg, $msg, "Check message" );

    # Create a new output channel.
    my $oc_id = $self->make_oc;

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
    $msg = "Missing required parameter 'element' or 'element__id'";
    is( $err->get_msg, $msg, "Check another message" );

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
    my $oc_id = $self->make_oc;

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
    $msg = "Invalid file_type parameter 'foo'";
    is( $err->get_msg, $msg, "Check another message" );

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
    my $oc_id = $self->make_oc;

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


sub test_select_b_new_objs: Test(32) {
    my $self = shift;

    # let's grab existing 'All' group info
    my $all_workflow_grp_id = Bric::Util::Grp->lookup({ name => 'All Workflows' })->get_id();
    my $all_cats_grp_id = Bric::Util::Grp->lookup({ name => 'All Categories' })->get_id();
    my $all_desks_grp_id = Bric::Util::Grp->lookup({ name => 'All Desks' })->get_id();
    my $all_formatting_grp_id = Bric::Util::Grp->lookup({ name => 'All Templates' })->get_id();

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
                                        type => Bric::Biz::Workflow::TEMPLATE_WORKFLOW,
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
        
        # create some formatting groups
        $grp = Bric::Util::Grp::Formatting->new({ name => "_GRP_test_$time.$i" });
        # save the group ids
        $grp->save();
        push @{$OBJ_IDS->{grp}}, $grp->get_id();
        push @{$OBJ->{formatting_grp}}, $grp;
        push @FORMATTING_GRP_IDS, $grp->get_id();
    }

    # set up to do the deletes
    foreach my $table (qw(grp category workflow desk)) {
        $self->add_del_ids( $OBJ_IDS->{$table}, $table );
    }

    # we'll be making a new element for each
    my $element;

    # and a user
    my $admin_id = $self->user_id();

    # create some formatting objects and test them
    my (@formatting, $time, $got, $expected);

    # grab and ATT
    my ($att) = Bric::Biz::ATType->list({ name => 'Insets' });

    # A formatting with one category (admin user)
    $time = time;
    $element = Bric::Biz::AssetType->new(
        {
             key_name    => "_test_$time",
             name        => "_test_$time",
             burner      => 1,
             description => 'this is a test',
             type__id    => $att->get_id(),

        });
    $element->save();
    $self->add_del_ids($element->get_id, 'element');
    $formatting[0] = class->new({
                               priority           => 1,
                               user__id           => $admin_id,
                               element            => $element, 
                               tplat_type         => 1,
                               output_channel__id => 1,
                               category_id        => $OBJ->{category}->[0]->get_id(),
                           });
    $formatting[0]->save();
    push @{$OBJ_IDS->{formatting}}, $formatting[0]->get_id();
    $self->add_del_ids( $formatting[0]->get_id() );

    # Try doing a lookup 
    $expected = $formatting[0];
    ok( $got = class->lookup({ id => $OBJ_IDS->{formatting}->[0] }), 'can we call lookup on a Formatting Object' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), '... does it have the right desc');

    # check the grp IDs
    my $exp_grp_ids = [ $all_cats_grp_id, $all_formatting_grp_id, $OBJ_IDS->{grp}->[0] ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    my $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... as a grp member
    $time = time;
    $element = Bric::Biz::AssetType->new(
        {
             key_name    => "_test_$time.1",
             name        => "_test_$time.1",
             burner      => 1,
             description => 'this is a test',
             type__id    => $att->get_id(),

        });
    $element->save();
    $self->add_del_ids($element->get_id, 'element');
    $formatting[1] = class->new({
                               priority           => 1,
                               user__id           => $admin_id,
                               element            => $element, 
                               tplat_type         => 1,
                               output_channel__id => 1,
                               category_id        => $OBJ->{category}->[0]->get_id(),
                           });
    $formatting[1]->save();
    push @{$OBJ_IDS->{formatting}}, $formatting[1]->get_id();
    $self->add_del_ids( $formatting[1]->get_id() );

    $OBJ->{formatting_grp}->[0]->add_member({ obj => $formatting[1] });
    $OBJ->{formatting_grp}->[0]->save();

    $expected = $formatting[1];
    ok( $got = class->lookup({ id => $OBJ_IDS->{formatting}->[1] }), 'can we call lookup on a Formatting Object which is itself in a grp' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), '... does it have the right desc');

    # check the grp IDs
    $exp_grp_ids = [ $all_cats_grp_id, 
                     $all_formatting_grp_id,
                     $CATEGORY_GRP_IDS[0],
                     $FORMATTING_GRP_IDS[0],
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... a bunch of grps
    $time = time;
    $element = Bric::Biz::AssetType->new(
        {
             key_name    => "_test_$time.2",
             name        => "_test_$time.2",
             burner      => 1,
             description => 'this is a test',
             type__id    => $att->get_id(),

        });
    $element->save();
    $self->add_del_ids($element->get_id, 'element');
    $formatting[2] = class->new({
                               priority           => 1,
                               user__id           => $admin_id,
                               element            => $element, 
                               tplat_type         => 1,
                               output_channel__id => 1,
                               category_id        => $OBJ->{category}->[0]->get_id(),
                           });
    $formatting[2]->save();
    push @{$OBJ_IDS->{formatting}}, $formatting[2]->get_id();
    $self->add_del_ids( $formatting[2]->get_id() );

    $OBJ->{formatting_grp}->[0]->add_member({ obj => $formatting[2] });
    $OBJ->{formatting_grp}->[0]->save();

    $OBJ->{formatting_grp}->[1]->add_member({ obj => $formatting[2] });
    $OBJ->{formatting_grp}->[1]->save();

    $OBJ->{formatting_grp}->[2]->add_member({ obj => $formatting[2] });
    $OBJ->{formatting_grp}->[2]->save();

    $OBJ->{formatting_grp}->[3]->add_member({ obj => $formatting[2] });
    $OBJ->{formatting_grp}->[3]->save();

    $OBJ->{formatting_grp}->[4]->add_member({ obj => $formatting[2] });
    $OBJ->{formatting_grp}->[4]->save();

    $expected = $formatting[2];
    ok( $got = class->lookup({ id => $OBJ_IDS->{formatting}->[2] }), 'can we call lookup on a Formatting Object which is itself in a grp' );
    is( $got->get_name(), $expected->get_name(), '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), '... does it have the right desc');

    # check the grp IDs
    $exp_grp_ids = [ $all_cats_grp_id, 
                     $all_formatting_grp_id,
                     $CATEGORY_GRP_IDS[0],
                     $FORMATTING_GRP_IDS[0],
                     $FORMATTING_GRP_IDS[1],
                     $FORMATTING_GRP_IDS[2],
                     $FORMATTING_GRP_IDS[3],
                     $FORMATTING_GRP_IDS[4],
                   ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... now try a workflow
    $time = time;
    $element = Bric::Biz::AssetType->new(
        {
             key_name    => "_test_$time.3",
             name        => "_test_$time.3",
             burner      => 1,
             description => 'this is a test',
             type__id    => $att->get_id(),

        });
    $element->save();
    $self->add_del_ids($element->get_id, 'element');
    $formatting[3] = class->new({
                               priority           => 1,
                               user__id           => $admin_id,
                               element            => $element, 
                               tplat_type         => 1,
                               output_channel__id => 1,
                               category_id        => $OBJ->{category}->[0]->get_id(),
                           });
    $formatting[3]->set_workflow_id( $OBJ->{workflow}->[0]->get_id() );
    $formatting[3]->save();
    push @{$OBJ_IDS->{formatting}}, $formatting[3]->get_id();
    $self->add_del_ids( $formatting[3]->get_id() );

    # add it to the workflow

    # Try doing a lookup 
    $expected = $formatting[3];
    ok( $got = class->lookup({ id => $OBJ_IDS->{formatting}->[3] }), 
      'can we call lookup on a Formatting Object' );
    is( $got->get_name(), $expected->get_name(), 
      '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), 
      '... does it have the right desc');

    # check the grp IDs
    $exp_grp_ids = [ 
                        $all_workflow_grp_id,
                        $all_cats_grp_id, 
                        $all_formatting_grp_id, 
                        $CATEGORY_GRP_IDS[0],
                        $WORKFLOW_GRP_IDS[0],
                    ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, '... does it have the right grp_ids' );

    # ... desk
    $time = time;
    $element = Bric::Biz::AssetType->new(
        {
             key_name    => "_test_$time.4",
             name        => "_test_$time.4",
             burner      => 1,
             description => 'this is a test',
             type__id    => $att->get_id(),

        });
    $element->save();
    $self->add_del_ids($element->get_id, 'element');
    $formatting[4] = class->new({
                               priority           => 1,
                               user__id           => $admin_id,
                               element            => $element, 
                               tplat_type         => 1,
                               output_channel__id => 1,
                               category_id        => $OBJ->{category}->[0]->get_id(),
                           });
    $formatting[4]->set_workflow_id( $OBJ->{workflow}->[0]->get_id() );
    $formatting[4]->set_current_desk( $OBJ->{desk}->[0] );
    $formatting[4]->save();
    push @{$OBJ_IDS->{formatting}}, $formatting[4]->get_id();
    $self->add_del_ids( $formatting[4]->get_id() );

    # add it to the workflow

    # Try doing a lookup 
    $expected = $formatting[4];
    ok( $got = class->lookup({ id => $OBJ_IDS->{formatting}->[4] }), 
      'can we call lookup on a Formatting Object' );
    is( $got->get_name(), $expected->get_name(), 
      '... does it have the right name');
    is( $got->get_description(), $expected->get_description(), 
      '... does it have the right desc');

    # check the grp IDs
    $exp_grp_ids = [ 
                        $all_workflow_grp_id,
                        $all_cats_grp_id, 
                        $all_formatting_grp_id, 
                        $all_desks_grp_id, 
                        $CATEGORY_GRP_IDS[0],
                        $DESK_GRP_IDS[0],
                        $ALL_DESK_GRP_IDS[0],
                        $REQ_DESK_GRP_IDS[0],
                        $WORKFLOW_GRP_IDS[0],
                    ];
    push @EXP_GRP_IDS, $exp_grp_ids;
    $got_grp_ids = $got->get_grp_ids();
    eq_set( $got_grp_ids , $exp_grp_ids, 
      '... does it have the right grp_ids' );

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
    eq_set( \@got_ids, $OBJ_IDS->{formatting}, '... did we get the right list of ids out' );
    eq_set( \@got_grp_ids, \@EXP_GRP_IDS, '... and did we get the right grp_ids' );
    undef @got_ids;
    undef @got_grp_ids;

    ok( $got = class->list({ title => '_test%', Order => 'id' }), 'lets do a search by title' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_->get_id();
        push @got_grp_ids, \@{$_->get_grp_ids()};
    }
    eq_set( \@got_ids, $OBJ_IDS->{formatting}, '... did we get the right list of ids out' );
    eq_set( \@got_grp_ids, \@EXP_GRP_IDS, '... and did we get the right grp_ids' );
    undef @got_ids;
    undef @got_grp_ids;

    # finally do this by grp_ids
    ok( $got = class->list({ grp_id => $OBJ->{formatting_grp}->[0]->get_id(), Order => 'id' }), 'getting by grp_id' );
    my $number = @$got;
    is( $number, 2, 'there should be two formatting in the first grp' );
    is( $got->[0]->get_id(), $formatting[1]->get_id(), '... and they should be numbers 2' );
    is( $got->[1]->get_id(), $formatting[2]->get_id(), '... and 3' );

    # try listing IDs, again at least one key per table
    ok( $got = class->list_ids({ name => '_test%', Order => 'id' }), 'lets do an IDs search by name' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_;
    }
    eq_set( \@got_ids, $OBJ_IDS->{formatting}, '... did we get the right list of ids out' );
    undef @got_ids;

    ok( $got = class->list_ids({ title => '_test%', Order => 'id' }), 'lets do an ids search by title' );
    # check the ids
    foreach (@$got) {
        push @got_ids, $_;
    }
    eq_set( \@got_ids, $OBJ_IDS->{formatting}, '... did we get the right list of ids out' );
    undef @got_ids;

    # finally do this by grp_ids
    ok( $got = class->list_ids({ grp_id => $OBJ->{formatting_grp}->[0]->get_id(), Order => 'id' }), 'getting by grp_id' );
    $number = @$got;
    is( $number, 2, 'there should be two formatting objects in the first grp' );
    is( $got->[0], $formatting[1]->get_id(), '... and they should be numbers 2' );
    is( $got->[1], $formatting[2]->get_id(), '... and 3' );


    # now let's try a limit
    ok( $got = class->list({ Order => 'id', Limit => 3 }), 'try setting a limit of 3');
    is( @$got, 3, '... did we get exactly 3 formatting objects back' );

    # test Offset
    ok( $got = class->list({ grp_id => $OBJ->{formatting_grp}->[0]->get_id(), Order => 'id', Offset => 1 }), 'try setting an offset of 2 for a search that just returned 3 objs');
    is( @$got, 1, '... Offset gives us #2 of 2' );
}

1;
__END__
