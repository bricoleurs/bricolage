package Bric::Biz::Asset::Business::Parts::Tile::Container::DevTest;
################################################################################

use strict;
use warnings;

use base qw(Bric::Biz::Asset::Business::Parts::Tile::DevTest);

use Test::More;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Parts::Tile::Container;
use Bric::Biz::ATType;
use Bric::Biz::ElementType;
use Test::MockModule;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Business::Parts::Tile::Container' }
my $rel_story_uuid = '4162F712-1DD2-11B2-B17E-C09EFE1DC403';
my $rel_media_uuid = '4162F713-1DD3-11B3-B17F-C09EFE1DC404';

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;

    return (
        object       => $self->get_story,
        element_type => $self->get_elem,
        site_id      => 100,
    );
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;

    $self->class->new({$self->new_args, @_});
}
################################################################################
# Test the constructors

sub test_new : Test(11) {
    my $self = shift;

    ok (my $cont = $self->construct,          'Construct Container');
    ok (my $at  = $cont->get_element_type,    'Get Element Type Object');
    ok (my $atd = ($at->get_field_types)[0],  'Get Field Type Object');
    ok ($cont->add_field($atd, 'Chomp'),      'Add Field Type');
    ok ($cont->save,                          'Save Container');
    ok (my $c_id = $cont->get_id,             'Get Container ID');

    $self->add_del_ids([$c_id], $cont->S_TABLE);

    ok (my $lkup = $self->class->lookup({
        object_type => 'story',
        id          => $c_id
    }), 'Lookup Container');
    isa_ok $lkup, $self->class;

    is ($lkup->get_value('deck', 2), 'Chomp',   'Compare Value');

    ok (my $list = $self->class->list({object_type => 'story'}),
        'List Story Containers');
    ok (grep($_->get_id == $cont->get_id, @$list), 'Container is listed');
}

##############################################################################
# Test lookup.
sub test_lookup : Test(44) {
    my $self       = shift->create_element_types;
    my $class      = $self->class;
    my $story_type = $self->{story_type};

    # Create a story.
    ok my $story = Bric::Biz::Asset::Business::Story->new({
        user__id        => $self->user_id,
        site_id         => 100,
        element_type_id => $story_type->get_id,
        source__id      => 1,
        title           => 'This is a Test',
        slug            => 'test_lookup',
    }), "Create test story";

    ok $story->add_categories([1]), "Add it to the root category";
    ok $story->set_primary_category(1),
      "Make the root category the primary category";
    ok $story->set_cover_date('2005-03-22 21:07:56'), "Set the cover date";
    ok $story->checkin, "Check in the story";
    ok $story->save, "Save the story";
    $self->add_del_ids($story->get_id, 'story');

    # Now look it up by the story object.
    ok my $elem = $class->lookup({
        object => $story,
    }), 'Look up element by story object';
    isa_ok $elem, $class;
    ok my $elem_id = $elem->get_id, 'Grab the element id';

    # Now look it up by its ID.
    ok $elem = $class->lookup({
        object_type => 'story',
        id          => $elem_id,
    }), 'Look up by ID';
    is $elem->get_id, $elem_id, 'It should have the same id';
}

##############################################################################
# Test list.
sub test_list : Test(166) {
    my $self       = shift->create_element_types;
    my $class      = $self->class;
    my $story_type = $self->{story_type};
    my $para       = $self->{para};
    my $pull_quote = $self->{pull_quote};
    my $head       = $self->{head};
    my @story_ids;

    for my $i (1..5) {
        # Create a story.
        ok my $story = Bric::Biz::Asset::Business::Story->new({
            user__id        => $self->user_id,
            site_id         => 100,
            element_type_id => $story_type->get_id,
            source__id      => 1,
            title           => "This is Test $i",
            slug            => "test_list$i"
        }), "Create test story $i";

        ok $story->add_categories([1]), "Add it to the root category";
        ok $story->set_primary_category(1),
            "Make the root category the primary category";
        ok $story->set_cover_date('2005-03-22 21:07:56'), "Set the cover date";
        ok $story->checkin, "Check in the story";
        ok $story->save, "Save the story";
        $self->add_del_ids($story->get_id, 'story');
        push @story_ids, $story->get_id;

        # Add some content to it.
        ok my $elem = $story->get_element, "Get the story element";
        ok $elem->add_field($para, 'This is a paragraph'), "Add a paragraph";
        ok $elem->add_field($para, 'Second paragraph'), "Add another paragraph";
        ok $elem->add_field($head, "And then..."), "Add a header";
        ok $elem->add_field($para, 'Third paragraph'), "Add a third paragraph";

        # Add a pull quote.
        ok my $pq = $elem->add_container($pull_quote), "Add a pull quote";
        ok $pq->get_field('para')->set_value(
            "Ask not what your country can do for you.\n="
                . 'Ask what you can do for your country.'
            ), "Add a paragraph with an apparent POD tag";
        ok $pq->get_field('by')->set_value("John F. Kennedy"),
            "Add a By to the pull quote";
        ok $pq->get_field('date')->set_value('1961-01-20 00:00:00'),
            "Add a date to the pull quote";

        # Add another pull quote.
        ok my $pq2 = $elem->add_container($pull_quote), "Add another pull quote";
        ok $pq2->get_field('para')->set_value(
            "So, first of all, let me assert my firm belief that the only\n\n"
            . '=thing we have to fear is fear itself -- nameless, unreasoning, '
            . 'unjustified terror which paralyzes needed efforts to convert '
            . 'retreat into advance.'
        ), "Add a paragraph with a near POD tag to the pull quote";
        ok $pq2->get_field('by')->set_value("Franklin D. Roosevelt"),
            "Add a By to the pull quote";
        ok $pq2->get_field('date')->set_value('1933-03-04 00:00:00'),
            "Add a date to the pull quote";

        # Make it so!
        ok $elem->save, "Save the story element";
    }

    # Now list top-level story elements.
    ok my @elems = $class->list({
        object_type => 'story',
        parent_id   => undef
    }), 'List story elements by object type';
    is scalar @elems, 5, 'There should be five top-level story elements';
    isa_ok $_, $class for @elems;
    my $top = $elems[0];

    # List by parent ID.
    ok @elems = $class->list({
        object_type => 'story',
        parent_id   => $top->get_id,
    }), 'List subelements of a single element';
    is scalar @elems, 2, 'There should be two subelements';

    # Try the elements() method.
    ok @elems = $top->get_elements, 'Get subelements';
    is scalar @elems, 6, 'Should be six subelements';
    for my $e ($top->get_containers) {
        ok @elems = $e->get_elements, 'Get subelement subelements';
        is scalar @elems, 3, 'Should have three subelements';
        isa_ok $_, 'Bric::Biz::Asset::Business::Parts::Tile::Data',
            for @elems;
    }

    # List all story elements.
    ok @elems = $class->list({
        object_type => 'story',
    }), 'List elements by object type';
    is scalar @elems, 15, 'There should be fifteen story elements';

    # List by element_type_id.
    ok @elems = $class->list({
        object_type     => 'story',
        element_type_id => $pull_quote->get_id,
    }), 'List elements by element_type_id';
    is scalar @elems, 10, 'There should be ten elements';

    # List by key_name.
    ok @elems = $class->list({
        object_type => 'story',
        key_name    => $pull_quote->get_key_name,
    }), 'List elements by key_name';
    is scalar @elems, 10, 'There should be ten elements';

    # List by name.
    ok @elems = $class->list({
        object_type => 'story',
        name    => $pull_quote->get_name,
    }), 'List elements by name';
    is scalar @elems, 10, 'There should be ten elements';

    # Try by active.
    $elems[0]->deactivate->save;
    $elems[1]->deactivate->save;
    ok @elems = $class->list({
        object_type => 'story',
        active      => 1,
    }), 'List active elements';
    is scalar @elems, 13, 'There should be thirteen active elements';

    # List by inactive.
    ok @elems = $class->list({
        object_type => 'story',
        active      => 0,
    }), 'List inactive elements';
    is scalar @elems, 2, 'There should be two inactive elements';
}


##############################################################################
# Test pod.
sub test_pod : Test(229) {
    my $self       = shift->create_element_types;
    my $story_type = $self->{story_type};
    my $para       = $self->{para};
    my $pull_quote = $self->{pull_quote};
    my $head       = $self->{head};
    my $media_type = $self->{media_type};

    # Now it's time to create a story!
    ok my $story = Bric::Biz::Asset::Business::Story->new({
        user__id        => $self->user_id,
        site_id         => 100,
        element_type_id => $story_type->get_id,
        source__id      => 1,
        title           => 'This is a Test',
        slug            => 'test_pod',
    }), "Create test story";

    ok $story->add_categories([1]), "Add it to the root category";
    ok $story->set_primary_category(1),
      "Make the root category the primary category";
    ok $story->set_cover_date('2005-03-22 21:07:56'), "Set the cover date";
    ok $story->checkin, "Check in the story";
    ok $story->save, "Save the story";
    $self->add_del_ids($story->get_id, 'story');

    # Add some content to it.
    ok my $elem = $story->get_element, "Get the story element";
    ok $elem->add_field($para, 'This is a paragraph'), "Add a paragraph";
    ok $elem->add_field($para, 'Second paragraph'), "Add another paragraph";
    ok $elem->add_field($head, "And then..."), "Add a header";
    ok $elem->add_field($para, 'Third paragraph'), "Add a third paragraph";

    # Add a pull quote.
    ok my $pq = $elem->add_container($pull_quote), "Add a pull quote";
    ok $pq->get_field('para')->set_value(
        "Ask not what your country can do for you.\n="
          . 'Ask what you can do for your country.'
    ), "Add a paragraph with an apparent POD tag";
    ok $pq->get_field('by')->set_value("John F. Kennedy"),
      "Add a By to the pull quote";
    ok $pq->get_field('date')->set_value('1961-01-20 00:00:00'),
      "Add a date to the pull quote";

    # Add some Unicode content.
    ok $elem->add_field(
        $para,
        '圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年'
    ), "Add a Chinese paragraph";
    ok $elem->add_field(
        $para,
        '橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱'
    ), "Add a Japanese paragraph";
    ok $elem->add_field(
        $para,
        '뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐'
    ), "Add a Korean paragraph";

    # Add another pull quote.
    ok my $pq2 = $elem->add_container($pull_quote), "Add another pull quote";
    ok $pq2->get_field('para')->set_value(
        "So, first of all, let me assert my firm belief that the only\n\n"
        . '=thing we have to fear is fear itself -- nameless, unreasoning, '
        . 'unjustified terror which paralyzes needed efforts to convert '
        . 'retreat into advance.'
    ), "Add a paragraph with a near POD tag to the pull quote";
    ok $pq2->get_field('by')->set_value("Franklin D. Roosevelt"),
      "Add a By to the pull quote";
    ok $pq2->get_field('date')->set_value('1933-03-04 00:00:00'),
      "Add a date to the pull quote";

    # Make it so!
    ok $elem->save, "Save the story element";

    # Fake out UUID generation for the relstory.
    my $mock_uuid = Test::MockModule->new('Data::UUID');
    $mock_uuid->mock(create_str => $rel_story_uuid);

    # Create a story that can be a related story.
    ok my $rel_story = Bric::Biz::Asset::Business::Story->new({
        user__id        => $self->user_id,
        site_id         => 100,
        element_type_id => $story_type->get_id,
        source__id      => 1,
        title           => 'Test Related Story',
        slug            => 'test_related',
    }), "Create test story";
    $mock_uuid->unmock('create_str');

    ok $rel_story->add_categories([1]), "Add it to the root category";
    ok $rel_story->set_primary_category(1),
      "Make the root category the primary category";
    ok $rel_story->set_cover_date('2005-03-23 21:07:56'), "Set the cover date";
    ok $rel_story->checkin, "Check in the story";
    ok $rel_story->save, "Save the story";
    my $rel_story_uri  = $rel_story->get_primary_uri;
    my $rel_story_id   = $rel_story->get_id;
    $self->add_del_ids($rel_story->get_id, 'story');

    # Create a media document.
    $mock_uuid->mock(create_str => $rel_media_uuid);
    ok my $media = Bric::Biz::Asset::Business::Media->new({
        user__id        => $self->user_id,
        site_id         => 100,
        element_type_id => $media_type->get_id,
        source__id      => 1,
        title           => 'This is a Test',
        slug            => 'test_pod',
    }), "Create test media";
    $mock_uuid->unmock('create_str');

    ok $media->set_category__id(1), "Add it to the root category";
    ok $media->set_cover_date('2005-03-22 21:07:56'), "Set the cover date";
    ok $media->save, "Save the media";
    $self->add_del_ids($media->get_id, 'media');

    # Associate the media file and check it in.
    ok $media->upload_file(*DATA, 'testfile.txt');
    ok $media->checkin, "Check in the media";
    ok $media->save, "Save the media again";
    my $rel_media_id  = $media->get_id;
    my $rel_media_uri = $media->get_uri;

    # Relate the story and media.
    ok $elem->set_related_story_id($rel_story_id), 'Add related story';
    ok $elem->set_related_media_id($rel_media_id), 'Add related media';

    # Okay, now down to business.
    is $elem->serialize_to_pod, $self->pod_output,
        'Check the POD serialization';

    # Update from POD.
    ok $elem->update_from_pod($self->pod_output), 'Update from POD';

    # Check the contents.
    is $elem->get_value('para'),    'This is a paragraph', 'Check first para';
    is $elem->get_value('para', 2), 'Second paragraph',    'Check second para';
    is $elem->get_value('header'),  'And then...',         'Check header';
    is $elem->get_value('para', 3), 'Third paragraph',     'Check third para';
    is $elem->get_related_story_id, $rel_story_id,     'Check relstory id';

    # Check the pull quote.
    is $elem->get_container('_pull_quote_'), $pq,
        'The pull quote object should be the same';
    is $pq->get_value('para'),
        "Ask not what your country can do for you.\n"
        . '\=Ask what you can do for your country.',
        'Check pull quote paragraph';
    is $pq->get_value('by'), 'John F. Kennedy', 'Check pull quote by';
    is $pq->get_value('date'), '1961-01-20 00:00:00', 'Check pull quote date';

    # Try deserializeing with a default field.
    (my $stripped_pod = $self->pod_output) =~ s/(?:    )?=para\n\n//g;
    ok $elem->update_from_pod($stripped_pod, 'para'),
        "Update from POD with a default field";

    # Check the contents.
    is $elem->get_value('para'), 'This is a paragraph', 'Check first para';
    is $elem->get_value('para', 2), 'Second paragraph', 'Check second para';
    is $elem->get_value('header'), 'And then...', 'Check header';
    is $elem->get_value('para', 3), 'Third paragraph', 'Check third para';
    ok my $header = $elem->get_field('header'), 'Grab the header';

    # Check the pull quote.
    is $elem->get_container('_pull_quote_'), $pq,
        'The pull quote object should be the same';
    is $pq->get_value('para'),
        "Ask not what your country can do for you.\n"
        . '\=Ask what you can do for your country.',
        'Check pull quote paragraph';
    is $pq->get_value('by'), 'John F. Kennedy', 'Check pull quote by';
    is $pq->get_value('date'), '1961-01-20 00:00:00', 'Check pull quote date';
    ok my $pq_para_field = $pq->get_field('para'),
        'Grab the pull quote para';

    # Add a new field.
    $stripped_pod = "=header\n\nIn the beginning...\n\n$stripped_pod";
    ok $elem->update_from_pod($stripped_pod, 'para'),
        "Update from POD with a default field";

    # Check the contents.
    is $elem->get_field('header'), $header,
        'First header should still be first';
    is $elem->get_value('header'), 'In the beginning...',
        'But its content should be different';
    is $elem->get_value('para'), 'This is a paragraph', 'Check first para';
    is $elem->get_value('para', 2), 'Second paragraph', 'Check second para';
    is $elem->get_value('header', 2), 'And then...', 'Check second header';
    is $elem->get_value('para', 3), 'Third paragraph', 'Check third para';

    # Now add another paragraph to the pull quote.
    $stripped_pod =~ s/Ask not/My fellow Americans,\n\n    Ask not/;
    ok $elem->update_from_pod($stripped_pod, 'para'),
        "Update from POD with a default field";

    # Check the contents.
    is $elem->get_field('header'), $header,
        'First header should still be first';
    is $elem->get_value('header'), 'In the beginning...',
        '... And its content should still be different';
    is $elem->get_value('para'), 'This is a paragraph', 'Check first para';
    is $elem->get_value('para', 2), 'Second paragraph', 'Check second para';
    is $elem->get_value('header', 2), 'And then...', 'Check second header';
    is $elem->get_value('para', 3), 'Third paragraph', 'Check third para';

    # Check the pull quote.
    is $elem->get_container('_pull_quote_'), $pq,
        'The pull quote object should be the same';
    is $pq->get_field('para'), $pq_para_field,
        '... And its first para should be the same object';
    is $pq->get_value('para'), 'My fellow Americans,',
        'But its contents should be different';
    is $pq->get_value('para', 2),
        "Ask not what your country can do for you.\n"
        . '\=Ask what you can do for your country.',
        '... While the second paragraph is the original';
    is $pq->get_value('by'), 'John F. Kennedy', 'Check pull quote by';
    is $pq->get_value('date'), '1961-01-20 00:00:00', 'Check pull quote date';

    # Add another pull quote.
    ok $elem->update_from_pod($self->pod_output_plus_pq),
        'Update from POD with extra pull quote';
    ok my @pqs = $elem->get_elements('_pull_quote_'), 'Get pull quotes';
    is scalar @pqs, 3, 'Should have three pull quotes';
    is $pqs[0]->get_value('by'),   'John F. Kennedy',       'Check first PQ by';
    is $pqs[0]->get_value('date'), '1961-01-20 00:00:00',   'Check first PQ date';
    is $pqs[1]->get_value('by'),   'Franklin D. Roosevelt', 'Check second PQ by';
    is $pqs[1]->get_value('date'), '1933-03-04 00:00:00',   'Check second PQ date';
    is $pqs[2]->get_value('by'),   'Neil Armstrong',        'Check second PQ by';
    is $pqs[2]->get_value('date'), '1970-07-20 00:00:00',   'Check second PQ date';

    # Now update it with the original POD to ensure one pq is removed.
    ok $elem->update_from_pod($self->pod_output),
        'Update from POD without extra pull quote';
    ok @pqs = $elem->get_elements('_pull_quote_'), 'Get pull quotes';
    is scalar @pqs, 2, 'Should have two pull quotes';
    is $pqs[0]->get_value('by'),   'John F. Kennedy',       'Check first PQ by';
    is $pqs[0]->get_value('date'), '1961-01-20 00:00:00',   'Check first PQ date';
    is $pqs[1]->get_value('by'),   'Franklin D. Roosevelt', 'Check second PQ by';
    is $pqs[1]->get_value('date'), '1933-03-04 00:00:00',   'Check second PQ date';

    # Try adding a page with its own pull quote subelement.
    ok $elem->update_from_pod($self->pod_output_plus_page),
        'Update from POD with page and different indent';

    # Check the contents.
    is $elem->get_value('para'), 'This is a paragraph', 'Check first para';
    is $elem->get_value('para', 2), 'Second paragraph', 'Check second para';
    is $elem->get_value('header'), 'And then...', 'Check header';
    is $elem->get_value('para', 3), 'Third paragraph', 'Check third para';

    # Check the pull quote.
    is $elem->get_container('_pull_quote_'), $pq,
        'The pull quote object should be the same';
    is $pq->get_value('para'),
        "Ask not what your country can do for you.\n"
        . '\=Ask what you can do for your country.',
        'Check pull quote paragraph';
    is $pq->get_value('by'), 'John F. Kennedy', 'Check pull quote by';
    is $pq->get_value('date'), '1961-01-20 00:00:00', 'Check pull quote date';

    # Check the page.
    ok my $page_elem = $elem->get_container('_page_');
    is $page_elem->get_value('para'),
        "This is the first paragraph from page one.\nIt isn't a long "
        . "paragraph.\nBut it'll do.",
        'Check the page paragraph';
    ok my $ppara = $page_elem->get_field('para'), 'Get page para';
    is $ppara->get_place, 0, q{Check page paragraph's place};
    is $ppara->get_object_order, 1, q{Check page paragraph's obj order};
    ok my $subpq = $page_elem->get_container('_pull_quote_'),
        q{Get page's pull quote};
    is $subpq->get_place, 1, q{Check the pull quote's place};
    is $ppara->get_object_order, 1, q{Check pull quote's obj order};
    is $subpq->get_value('para'),
        q{Granted, Opera has been available for a while, but it remains the }
        . q{province of a devoted few -- the Amiga of Web browsers.},
        q{Check the page pull quote's paragraph};
    is $subpq->get_value('by'), 'Chad Dickerson', q{... And its by};
    is $subpq->get_value('date'), '2004-12-03 00:00:00', q{... And its date};

    # Test a bad default field.
    eval { $elem->update_from_pod('', 'par') };
    ok my $err = $@, 'Catch invalid default field excetpion';
    isa_ok $err, 'Bric::Util::Fault::Error::Invalid';
    is $err->error, 'No such field "par", did you mean "para"?',
        'Should get the correct exception message';
    is_deeply $err->maketext,
        ['No such field "[_1]", did you mean "[_2]"?', 'par', 'para' ],
        'Should get the correct maketext array';

    # Try a bad field.
    eval { $elem->update_from_pod("=para\n\nfoo\n\n=par\n\n") };
    ok $err = $@, 'Catch invalid field exception';
    isa_ok $err, 'Bric::Util::Fault::Error::Invalid';
    is $err->error, 'No such field "par" at line 5. Did you mean "para"?',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No such field "[_1]" at line [_2]. Did you mean "[_3]"?',
        'par',
        5,
        'para',
    ], 'Should get the correct maketext array';

    # Try a bad subelement.
    eval { $elem->update_from_pod("=para\n\nfoo\n\n=begin page\n\n") };
    ok $err = $@, 'Catch invalid subelement exception';
    isa_ok $err, 'Bric::Util::Fault::Error::Invalid';
    is $err->error, 'No such subelement "page" at line 5. Did you mean "_page_"?',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No such subelement "[_1]" at line [_2]. Did you mean "[_3]"?',
        'page',
        5,
        '_page_',
    ], 'Should get the correct maketext array';

    # Try repeating a fields not allowed to be repeated.
    eval { $elem->update_from_pod("=begin _pull_quote_\n\n=by\n\nFoo\n\n=by\n\n") };
    ok $err = $@, 'Catch non-repeatable field exception';
    isa_ok $err, 'Bric::Util::Fault::Error::Invalid';
    is $err->error,
        'Non-repeatable field "by" appears more than once beginning at '
      . 'line 7. Please remove all but one.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'Non-repeatable field "[_1]" appears more than once beginning at '
      . 'line [_2]. Please remove all but one.',
        'by',
        7,
    ], 'Should get the correct maketext array';

    # Try repeating a default field not allowed to be repeated.
    $para = $elem->get_element_type->get_field_types('para');
    ok $para->set_quantifier(0), 'Disallow repeating for paragarphs';
    ok $para->save, 'Save paragraph field type';
    eval { $elem->update_from_pod("=para\n\nfoo\n\n=para\n\n", 'para') };
    ok $err = $@, 'Catch non-repeatable default field exception';
    isa_ok $err, 'Bric::Util::Fault::Error::Invalid';
    is $err->error,
        'Non-repeatable field "para" appears more than once beginning at '
      . 'line 5. Please remove all but one.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'Non-repeatable field "[_1]" appears more than once beginning at '
      . 'line [_2]. Please remove all but one.',
        'para',
        5,
    ], 'Should get the correct maketext array';

    # Allow repeatable paragraphs again.
    ok $para->set_quantifier(1), 'Aallow repeating for paragarphs again';
    ok $para->save, 'Save paragraph field type';

    # Try a bad tag.
    eval { $elem->update_from_pod("=para\n\nfoo\n\n=foo bar\n\n") };
    ok $err = $@, 'Catch bad tag field exception';
    isa_ok $err, 'Bric::Util::Fault::Error::Invalid';
    is $err->error,
        'Unknown tag "=foo bar" at line 5.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'Unknown tag "[_1]" at line [_2].',
        '=foo bar',
        5,
    ], 'Should get the correct maketext array';

    # Try without a related story.
    (my $strip_rel = $self->pod_output) =~ s/^=related_story_uuid\s+\S+\n\n//;
    ok $elem->update_from_pod($strip_rel), 'Parse POD without a related story';
    is $elem->get_related_story_id, undef, 'Related ID should be undef';

    # Try without a related media.
    $strip_rel =~ s/^=related_media_uuid\s+\S+\n\n//;
    ok $elem->update_from_pod($strip_rel), 'Parse POD without a related media';
    is $elem->get_related_media_id, undef, 'Related ID should be undef';

    # Try with a related_story_id.
    ok $elem->update_from_pod("=related_story_id $rel_story_id\n\n$strip_rel"),
        'Parse POD with related_story_id';
    is $elem->get_related_story_id, $rel_story_id,
        'Related story ID should be set again';

    # Try with a related_media_id.
    ok $elem->update_from_pod("=related_media_id $rel_media_id\n\n$strip_rel"),
        'Parse POD with related_media_id';
    is $elem->get_related_media_id, $rel_media_id,
        'Related media ID should be set again';

    # Try with related_story_uri.
    ok $elem->update_from_pod("=related_story_uri $rel_story_uri\n\n$strip_rel"),
        'Parse POD with related_story_uri';
    is $elem->get_related_story_id, $rel_story_id,
        'Related story ID should be correct';

    # Try with related_media_uri.
    ok $elem->update_from_pod("=related_media_uri $rel_media_uri\n\n$strip_rel"),
        'Parse POD with related_media_uri';
    is $elem->get_related_media_id, $rel_media_id,
        'Related media ID should be correct';

    # Try with related_story_url.
    my $rel_story_url = "http://www.example.com$rel_story_uri";
    ok $elem->update_from_pod("=related_story_url $rel_story_url\n\n$strip_rel"),
        'Parse POD with related_story_url';
    is $elem->get_related_story_id, $rel_story_id,
        'Related story ID should be correct';

    # Try with related_media_url.
    my $rel_media_url = "http://www.example.com$rel_media_uri";
    ok $elem->update_from_pod("=related_media_url $rel_media_url\n\n$strip_rel"),
        'Parse POD with related_media_url';
    is $elem->get_related_media_id, $rel_media_id,
        'Related media ID should be correct';

    # Try a bogus story site.
    $rel_story_url = "http://www.nosuchexample.com$rel_story_uri";
    eval {
        $elem->update_from_pod("=related_story_url $rel_story_url\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid site exception';
    is $err->error,
        'No such site "www.nosuchexample.com" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No such site "[_1]" at line [_2].',
        'www.nosuchexample.com',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus media site.
    $rel_media_url = "http://www.nosuchexample.com$rel_media_uri";
    eval {
        $elem->update_from_pod("=related_media_url $rel_media_url\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid site exception';
    is $err->error,
        'No such site "www.nosuchexample.com" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No such site "[_1]" at line [_2].',
        'www.nosuchexample.com',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus story URL.
    $rel_story_url = 'http://www.example.com/foo/bar/bat/';
    eval {
        $elem->update_from_pod("=related_story_url $rel_story_url\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid site URI exception';
    is $err->error,
        'No such URI "/foo/bar/bat/" in site "www.example.com" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No such URI "[_1]" in site "[_2]" at line [_3].',
        '/foo/bar/bat/',
        'www.example.com',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus media URL.
    $rel_media_url = 'http://www.example.com/foo/bar/bat.txt';
    eval {
        $elem->update_from_pod("=related_media_url $rel_media_url\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid site URI exception';
    is $err->error,
        'No such URI "/foo/bar/bat.txt" in site "www.example.com" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No such URI "[_1]" in site "[_2]" at line [_3].',
        '/foo/bar/bat.txt',
        'www.example.com',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus story ID.
    eval {
        $elem->update_from_pod("=related_story_id -1\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid ID exception';
    is $err->error,
        'No story document found for ID "-1" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No story document found for ID "[_1]" at line [_2].',
        '-1',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus media ID.
    eval {
        $elem->update_from_pod("=related_media_id -1\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid ID exception';
    is $err->error,
        'No media document found for ID "-1" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No media document found for ID "[_1]" at line [_2].',
        '-1',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus story UUID.
    eval {
        $elem->update_from_pod("=related_story_uuid -1\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid UUID exception';
    is $err->error,
        'No story document found for UUID "-1" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No story document found for UUID "[_1]" at line [_2].',
        '-1',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus media UUID.
    eval {
        $elem->update_from_pod("=related_media_uuid -1\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid UUID exception';
    is $err->error,
        'No media document found for UUID "-1" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No media document found for UUID "[_1]" at line [_2].',
        '-1',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus story URI.
    eval {
        $elem->update_from_pod("=related_story_uri /foo/\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid URI exception';
    is $err->error,
        'No story document found for URI "/foo/" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No story document found for URI "[_1]" at line [_2].',
        '/foo/',
        1,
    ], 'Should get the correct maketext array';

    # Try a bogus media URI.
    eval {
        $elem->update_from_pod("=related_media_uri /foo/\n\n$strip_rel");
    };
    ok $err = $@, 'Catch invalid URI exception';
    is $err->error,
        'No media document found for URI "/foo/" at line 1.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'No media document found for URI "[_1]" at line [_2].',
        '/foo/',
        1,
    ], 'Should get the correct maketext array';

    # Try a related story in a non-related element.
    eval {
        $elem->update_from_pod("=begin _page_\n\n=related_story_id 100\n\n");
    };
    ok $err = $@, 'Catch non-related element exception';
    is $err->error,
        'Element "_page_" cannot have a related story.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'Element "[_1]" cannot have a related story.',
        '_page_',
    ], 'Should get the correct maketext array';

    # Try a related media in a non-related element.
    eval {
        $elem->update_from_pod("=begin _page_\n\n=related_media_id 100\n\n");
    };
    ok $err = $@, 'Catch non-related element exception';
    is $err->error,
        'Element "_page_" cannot have a related media.',
        'Should get the correct exception message';
    is_deeply $err->maketext, [
        'Element "[_1]" cannot have a related media.',
        '_page_',
    ], 'Should get the correct maketext array';

}

sub pod_output {
    return qq{=related_story_uuid $rel_story_uuid

=related_media_uuid $rel_media_uuid

=para

This is a paragraph

=para

Second paragraph

=header

And then...

=para

Third paragraph

=begin _pull_quote_

    =para

    Ask not what your country can do for you.
    \\=Ask what you can do for your country.

    =by

    John F. Kennedy

    =date

    1961-01-20 00:00:00

=end _pull_quote_

=para

圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年

=para

橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱

=para

뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐

=begin _pull_quote_

    =para

    So, first of all, let me assert my firm belief that the only

    \\=thing we have to fear is fear itself -- nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.

    =by

    Franklin D. Roosevelt

    =date

    1933-03-04 00:00:00

=end _pull_quote_

}
}

sub pod_output_plus_pq {
    return shift->pod_output . q{=begin _pull_quote_

    =para

    That's one small step for man, one giant leap for mankind

    =by

    Neil Armstrong

    =date

    1970-07-20 00:00:00

=end _pull_quote_

}
}

sub pod_output_plus_page {
    return shift->pod_output . q{=begin _page_

    =para

    This is the first paragraph from page one.
    It isn't a long paragraph.
    But it'll do.

    =begin _pull_quote_
  
          =para
  
          Granted, Opera has been available for a while, but it remains the province of a devoted few -- the Amiga of Web browsers.
  
          =by
  
          Chad Dickerson
  
          =date
  
          2004-12-03 00:00:00
  
    =end _pull_quote

=end _page_

}
}
1;

__DATA__
This will be used for the test media file.
