package Bric::Biz::Element::Field::DevTest;
################################################################################

use strict;
use warnings;

use base qw(Bric::Biz::Element::DevTest);
use Test::More;
use Bric::Util::DBI qw(:junction);

use Bric::Biz::Element::Container;
use Bric::Biz::Element::Field;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Element::Field' }

my $cont_pkg = 'Bric::Biz::Element::Container';

################################################################################

my $cont;
my $story;

sub setup_story : Test(setup) {
    $story = shift->SUPER::get_story;
}

sub get_story {
    return $story;
}

sub get_container {
    my $self = shift;

    unless ($cont) {
        my $story = $self->get_story;
        $cont = $cont_pkg->new({
            object       => $story,
            element_type => $self->get_elem
         });
        $cont->save;
    }

    return $cont;
}

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    my $story = $self->get_story;
    my $cont  = $story->get_element;
    my $atd   = ($cont->get_element_type->get_field_types)[0];

    (active             => 1,
     object_type        => 'story',
     object_instance_id => $story->get_version_id,
     parent_id          => $cont->get_id,
     field_type         => $atd,
     object_order       => 0)
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({$self->new_args, @_});
}
################################################################################
# Test the constructors

sub test_new : Test(9) {
    my $self = shift;

    ok (my $delement = $self->construct,  'Construct Field Element');
    ok ($delement->set_value('Macaroon'), 'Add value to Field Element');
    ok ($delement->save,                  'Save Field Element');
    ok (my $d_id = $delement->get_id,     'Get Field Element ID');

    $self->add_del_ids([$d_id], $delement->S_TABLE);

    ok (my $lkup = $self->class->lookup({
        id          => $d_id,
        object_type => 'story'
    }), 'Lookup Field Element');
    is ($lkup->get_value, 'Macaroon',  'Compare value');

    ok (my $atd = $delement->get_field_type, 'Get Field Element Object');
    ok (my $list = $self->class->list({object_type => 'story'}),
       'List Field Elements');
    ok (grep($_->get_id == $delement->get_id, @$list),
        'Field Element is Listed');
}

##############
#
# NOTE: Not quite sure where the old field counts were coming from,
#         but each value has been reasoned before changing.
#
# UPDATE: My bad. There was an error elsewhere that was stopping the
#           default fields from being created
#
##############

# This is just a snippet of code for testing (outputs the field types)

#for my $foo_field (@fields) {
#    is scalar 2, 2, 'Element: ' . $foo_field->get_element_name;
#}


##############################################################################
# Test list().
sub test_list : Test(91) {
    my $self       = shift->create_element_types;
    my $class      = $self->class;
    my $story_type = $self->{story_type};
    my $para       = $self->{para};
    my $pull_quote = $self->{pull_quote};
    my $head       = $self->{head};
    my @story_ids;

    # Create a story.
    ok my $story = Bric::Biz::Asset::Business::Story->new({
        user__id        => $self->user_id,
        site_id         => 100,
        element_type_id => $story_type->get_id,
        source__id      => 1,
        title           => 'This is Test',
        slug            => 'test_list'
    }), 'Create test story';

    ok $story->add_categories([1]), 'Add it to the root category';
    ok $story->set_primary_category(1),
        'Make the root category the primary category';
    ok $story->set_cover_date('2005-03-22 21:07:56'), 'Set the cover date';
    ok $story->checkin, 'Check in the story';
    ok $story->save, 'Save the story';
    $self->add_del_ids($story->get_id, 'story');

    # Add some content to it.
    ok my $elem = $story->get_element, 'Get the story element';
    ok $elem->add_field($para, 'This is a paragraph'), 'Add a paragraph';
    ok $elem->add_field($para, 'Second paragraph'), 'Add another paragraph';
    ok $elem->add_field($head, 'And then...'), 'Add a header';
    ok $elem->add_field($para, 'Third paragraph'), 'Add a third paragraph';
    ok $elem->add_field($para, 'Fourth paragraph'), 'Add a fourth paragraph';
    ok $elem->add_field($head, 'What next?'), 'Add another header';

    # Add a pull quote.
    ok my $pq = $elem->add_container($pull_quote), 'Add a pull quote';
    ok $pq->get_field('para')->set_value(
        'Ask not what your country can do for you.\n='
        . 'Ask what you can do for your country.'
        ), 'Add a paragraph with an apparent POD tag';
    ok $pq->get_field('by')->set_value('John F. Kennedy'),
        'Add a By to the pull quote';
    ok $pq->get_field('date')->set_value('1961-01-20 00:00:00'),
        'Add a date to the pull quote';

    # Make it so!
    ok $elem->save, 'Save the story element';

    # List all story fields.
    ok my @fields = $class->list({
        object_type => 'story',
    }), 'List fields by object type';


    is scalar @fields, 10, 'There should be ten story fields';
    isa_ok $_, $class for @fields;

    # Test list by key_name.
    ok @fields = $class->list({
        object_type => 'story',
        key_name    => $para->get_key_name
    }), 'Test list by key_name';
    is scalar @fields, 5, 'Should have five fields';
    ok @fields = $class->list({
        object_type => 'story',
        key_name    => '%a%',
    }), 'Test list by key_name plus wild card';
    is scalar @fields, 8, 'Should have eight fields';
    ok @fields = $class->list({
        object_type => 'story',
        key_name    => ANY( $para->get_key_name, $head->get_key_name)
    }), 'Test list by ANY(key_name)';
    is scalar @fields, 7, 'Should have seven fields';

    # Test list by name.
    ok @fields = $class->list({
        object_type => 'story',
        name        => $para->get_name
    }), 'Test list by name';
    is scalar @fields, 5, 'Should have five fields';
    ok @fields = $class->list({
        object_type => 'story',
        name        => '%a%',
    }), 'Test list by name plus wild card';
    is scalar @fields, 8, 'Should have eight fields';
    ok @fields = $class->list({
        object_type => 'story',
        name        => ANY( $para->get_name, $head->get_name)
    }), 'Test list by ANY(name)';
    is scalar @fields, 7, 'Should have seven fields';

    # Test list by ID.
    my @field_ids = map { $_->get_id } @fields;
    ok @fields = $class->list({
        object_type => 'story',
        id          => $field_ids[0],
    }), 'Test list by id';
    is scalar @fields, 1, 'Should have one field';
    ok @fields = $class->list({
        object_type => 'story',
        id          => ANY( @field_ids ),
    }), 'Test list by ANY(id)';
    is scalar @fields, 7, 'Should have seven fields';

    # List by parent ID.
    ok my $story_elem = $story->get_element, 'Get story element';
    ok my $pq_elem    = $story_elem->get_container('_pull_quote_'),
        'Get pull quote element';
    ok @fields = $class->list({
        object_type => 'story',
        parent_id   => $story_elem->get_id,
    }), 'Test list() by parent_id';
    is scalar @fields, 6, 'There should be six fields';
    ok @fields = $class->list({
        object_type => 'story',
        parent_id   => ANY( $story_elem->get_id, $pq_elem->get_id ),
    }), 'Test list() by ANY(parent_id)';
    is scalar @fields, 9, 'There should be nine fields';

    # List by object_intance_id.
    ok @fields = $class->list({
        object_type        => 'story',
        object_instance_id => $story->get_version_id,
    }), 'List fields by instance id';
    is scalar @fields, 9, 'There should be nine story fields';

    # List by object.
    ok @fields = $class->list({
        object      => $story,
    }), 'List fields by object';
    is scalar @fields, 9, 'There should be nine story fields';

    # List by field_type_id.
    ok @fields = $class->list({
        object_type   => 'story',
        field_type_id => $para->get_id,
    }), 'List fields by field_type_id';

    is scalar @fields, 4, 'There should be four fields';
    ok @fields = $class->list({
        object_type   => 'story',
        field_type_id => ANY( $para->get_id, $head->get_id ),
    }), 'List fields by ANY(field_type_id)';
    is scalar @fields, 6, 'There should be six fields';

    # Try by active.
    $fields[0]->deactivate->save;
    $fields[1]->deactivate->save;
    ok @fields = $class->list({
        object_type => 'story',
        active      => 1,
    }), 'List active fields';

    is scalar @fields, 8, 'There should be eight active fields';

    # List by inactive.
    ok @fields = $class->list({
        object_type => 'story',
        active      => 0,
    }), 'List inactive fields';
    is scalar @fields, 2, 'There should be two inactive fields';
}

##############################################################################
# Test list_ids().
sub test_list_ids : Test(92) {
    my $self       = shift->create_element_types;
    my $class      = $self->class;
    my $story_type = $self->{story_type};
    my $para       = $self->{para};
    my $pull_quote = $self->{pull_quote};
    my $head       = $self->{head};
    my @story_ids;

    # Create a story.
    ok my $story = Bric::Biz::Asset::Business::Story->new({
        user__id        => $self->user_id,
        site_id         => 100,
        element_type_id => $story_type->get_id,
        source__id      => 1,
        title           => 'This is Test',
        slug            => 'test_list_ids'
    }), 'Create test story';

    ok $story->add_categories([1]), 'Add it to the root category';
    ok $story->set_primary_category(1),
        'Make the root category the primary category';
    ok $story->set_cover_date('2005-03-22 21:07:56'), 'Set the cover date';
    ok $story->checkin, 'Check in the story';
    ok $story->save, 'Save the story';
    $self->add_del_ids($story->get_id, 'story');

    # Add some content to it.
    ok my $elem = $story->get_element, 'Get the story element';
    ok $elem->add_field($para, 'This is a paragraph'), 'Add a paragraph';
    ok $elem->add_field($para, 'Second paragraph'), 'Add another paragraph';
    ok $elem->add_field($head, 'And then...'), 'Add a header';
    ok $elem->add_field($para, 'Third paragraph'), 'Add a third paragraph';
    ok $elem->add_field($para, 'Fourth paragraph'), 'Add a fourth paragraph';
    ok $elem->add_field($head, 'What next?'), 'Add another header';

    # Add a pull quote.
    ok my $pq = $elem->add_container($pull_quote), 'Add a pull quote';
    ok $pq->get_field('para')->set_value(
        'Ask not what your country can do for you.\n='
        . 'Ask what you can do for your country.'
        ), 'Add a paragraph with an apparent POD tag';
    ok $pq->get_field('by')->set_value('John F. Kennedy'),
        'Add a By to the pull quote';
    ok $pq->get_field('date')->set_value('1961-01-20 00:00:00'),
        'Add a date to the pull quote';

    # Make it so!
    ok $elem->save, 'Save the story element';

    # List IDs all story field ids.
    ok my @field_ids = $class->list_ids({
        object_type => 'story',
    }), 'List IDs field ids by object type';
    is scalar @field_ids, 10, 'There should be ten story field ids';
    like $_, qr/^\d+$/, "$_ should be an ID" for @field_ids;

    # Test list_ids by key_name.
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        key_name    => $para->get_key_name
    }), 'Test list_ids by key_name';
    is scalar @field_ids, 5, 'Should have five field ids';
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        key_name    => '%a%',
    }), 'Test list_ids by key_name plus wild card';
    is scalar @field_ids, 8, 'Should have eight field ids';
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        key_name    => ANY( $para->get_key_name, $head->get_key_name)
    }), 'Test list_ids by ANY(key_name)';
    is scalar @field_ids, 7, 'Should have seven field ids';

    # Test list_ids by name.
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        name        => $para->get_name
    }), 'Test list_ids by name';
    is scalar @field_ids, 5, 'Should have five field ids';
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        name        => '%a%',
    }), 'Test list_ids by name plus wild card';
    is scalar @field_ids, 8, 'Should have eight field ids';
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        name        => ANY( $para->get_name, $head->get_name)
    }), 'Test list_ids by ANY(name)';
    is scalar @field_ids, 7, 'Should have seven field ids';
    my @some_ids = @field_ids;

    # Test list_ids by ID.
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        id          => $some_ids[0],
    }), 'Test list_ids by id';
    is scalar @field_ids, 1, 'Should have one field id';
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        id          => ANY( @some_ids ),
    }), 'Test list_ids by ANY(id)';
    is scalar @field_ids, 7, 'Should have seven field ids';

    # List IDs by parent ID.
    ok my $story_elem = $story->get_element, 'Get story element';
    ok my $pq_elem    = $story_elem->get_container('_pull_quote_'),
        'Get pull quote element';
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        parent_id   => $story_elem->get_id,
    }), 'Test list_ids() by parent_id';
    is scalar @field_ids, 6, 'There should be six field ids';
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        parent_id   => ANY( $story_elem->get_id, $pq_elem->get_id ),
    }), 'Test list_ids() by ANY(parent_id)';
    is scalar @field_ids, 9, 'There should be nine field ids';

    # List IDs by object_intance_id.
    ok @field_ids = $class->list_ids({
        object_type        => 'story',
        object_instance_id => $story->get_version_id,
    }), 'List IDs field ids by instance id';
    is scalar @field_ids, 9, 'There should be nine story field ids';

    # List IDs by object.
    ok @field_ids = $class->list_ids({
        object      => $story,
    }), 'List IDs field ids by object';
    is scalar @field_ids, 9, 'There should be nine story field ids';

    # List IDs by field_type_id.
    ok @field_ids = $class->list_ids({
        object_type   => 'story',
        field_type_id => $para->get_id,
    }), 'List IDs fields by field_type_id';
    is scalar @field_ids, 4, 'There should be four field ids';
    ok @field_ids = $class->list_ids({
        object_type   => 'story',
        field_type_id => ANY( $para->get_id, $head->get_id ),
    }), 'List IDs fields by ANY(field_type_id)';
    is scalar @field_ids, 6, 'There should be six field ids';

    # Try by active.
    ok my @fields = $class->list({
        object_type => 'story',
        id => ANY( @field_ids[1,2])
    }), 'Get two fields to deactivate';
    $fields[0]->deactivate->save;
    $fields[1]->deactivate->save;
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        active      => 1,
    }), 'List IDs active field ids';
    is scalar @field_ids, 8, 'There should be eight active field ids';

    # List IDs by inactive.
    ok @field_ids = $class->list_ids({
        object_type => 'story',
        active      => 0,
    }), 'List IDs inactive field ids';
    is scalar @field_ids, 2, 'There should be two inactive field ids';
}

1;

__END__
