package Bric::Biz::Asset::Formatting::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::DevTest);
use Test::More;
use Bric::Biz::Asset::Formatting;
use Bric::Biz::AssetType;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Formatting' }

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    ( output_channel__id => 1,
      user__id   => $self->user_id,
      category_id => 0,
      name => 'foodoo'
    )
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

##############################################################################
# Test new() creating a category template.
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

##############################################################################
# Utility methods.
##############################################################################
sub make_oc {
    my $self = shift;
    my $oc = Bric::Biz::OutputChannel->new({name    => 'Bogus',
                                            site_id => 100});
    $oc->save;
    my $id = $oc->get_id;
    $self->add_del_ids($id, 'output_channel');
    return $id;
}

1;
__END__
