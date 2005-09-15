package Bric::Biz::Asset::Business::Parts::Tile::DevTest;
################################################################################

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Asset::Business::Story;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Business::Parts::Tile' }

################################################################################
# A sample story to use

sub get_story {
   my $self = shift;
   my $story_pkg = 'Bric::Biz::Asset::Business::Story';

   my $story = $story_pkg->new({
       name       => 'Fruits',
       slug       => 'Cranberry',
       element    => $self->get_elem,
       user__id   => $self->user_id,
       source__id => 1,
       site_id    => 100,
       @_,
   });
   $story->add_categories([1]);
   $story->set_primary_category(1);
   $story->set_cover_date('2005-03-22 21:07:56');
   $story->save;
   $self->add_del_ids([$story->get_id], $story->key_name);
   return $story;
}

##############################################################################
# The element object we'll use throughout. Override in subclass if necessary.
my $elem;
sub get_elem {
    $elem ||= Bric::Biz::AssetType->lookup({ id => 1 });
    $elem;
}

sub create_element_types {
    my $self = shift;

    # First, we'll need a story element type.
    ok my $story_et = Bric::Biz::ATType->new({
        name          => 'Testing',
        top_level     => 1,
        related_story => 1,
        related_media => 1,
    }), "Create a story element type";
    ok $story_et-> save, "Save story element type";
    $self->add_del_ids($story_et->get_id, 'at_type');
    $self->{story_et} = $story_et;

    # Next, a subelement.
    ok my $sub_et = Bric::Biz::ATType->new({
        name      => 'Subby',
        top_level => 0,
    }), "Create a subelement element type";
    ok $sub_et-> save, "Save subelement element type";
    $self->add_del_ids($sub_et->get_id, 'at_type');
    $self->{sub_et} = $sub_et;

    # And finally, a page subelement.
    ok my $page_et = Bric::Biz::ATType->new({
        name      => 'Pagey',
        top_level => 0,
        paginated => 1,
    }), "Create a page element type";
    ok $page_et-> save, "Save page element type";
    $self->add_del_ids($page_et->get_id, 'at_type');
    $self->{page_et} = $page_et;

    # We also need a media element type type.
    ok my $media_et = Bric::Biz::ATType->new({
        name          => 'Media',
        top_level     => 1,
        media         => 1,
    }), "Create a media element type type";
    ok $media_et-> save, "Save media element type type";
    $self->add_del_ids($media_et->get_id, 'at_type');
    $self->{media_et} = $media_et;

    # Create a media type.
    ok my $media_type = Bric::Biz::AssetType->new({
        key_name  => '_media_',
        name      => 'Media Testing',
        burner    => Bric::Biz::AssetType::BURNER_MASON,
        type__id  => $media_et->get_id,
        reference => 0, # No idea what this is.
    }), "Create media type";
    ok $media_type->add_site(100), "Add the site ID";
    ok $media_type->add_output_channels([1]), "Add the output channel";
    ok $media_type->set_primary_oc_id(1, 100),
      "Set it as the primary OC";;
    ok $media_type->save, "Save the test media type";
    $self->add_del_ids($media_type->get_id, 'element');
    $self->{media_type} = $media_type;

    # Create a story type.
    ok my $story_type = Bric::Biz::AssetType->new({
        key_name  => '_testing_',
        name      => 'Testing',
        burner    => Bric::Biz::AssetType::BURNER_MASON,
        type__id  => $story_et->get_id,
        reference => 0, # No idea what this is.
    }), "Create story type";
    ok $story_type->add_site(100), "Add the site ID";
    ok $story_type->add_output_channels([1]), "Add the output channel";
    ok $story_type->set_primary_oc_id(1, 100),
      "Set it as the primary OC";;
    ok $story_type->save, "Save the test story type";
    $self->add_del_ids($story_type->get_id, 'element');
    $self->{story_type} = $story_type;

    # Give it a header field.
    ok my $head = $story_type->new_data({
        key_name    => 'header',
        name        => 'Header',
        required    => 0,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 1,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";
    $self->{head} = $head;

    # Give it a paragraph field.
    ok my $para = $story_type->new_data({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 0,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 2,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";
    $self->{para} = $para;

    # Save the story type with its fields.
    ok $story_type->save, "Save element with the fields";
    $self->add_del_ids($head->get_id, 'at_data');
    $self->add_del_ids($para->get_id, 'at_data');

    # Create a subelement.
    ok my $pull_quote = Bric::Biz::AssetType->new({
        key_name  => '_pull_quote_',
        name      => 'Pull Quote',
        burner    => Bric::Biz::AssetType::BURNER_MASON,
        type__id  => $sub_et->get_id,
        reference => 0, # No idea what this is.
    }), "Create a subelement element";
    $self->{pull_quote} = $pull_quote;

    ok $pull_quote->save, "Save the subelement element";
    $self->add_del_ids($pull_quote->get_id, 'element');

    # Give it a paragraph field.
    ok my $pq_para = $pull_quote->new_data({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 1,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 1,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";
    $self->{pq_para} = $pq_para;

    # Give it a by field.
    ok my $by = $pull_quote->new_data({
        key_name    => 'by',
        name        => 'By',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 2,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";
    $self->{by} = $by;

    # Give it a date field.
    ok my $date = $pull_quote->new_data({
        key_name    => 'date',
        name        => 'Date',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'date',
        place       => 3,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";
    $self->{date} = $date;

    # Save the pull quote with its fields.
    ok $pull_quote->save, "Save subelement with the fields";
    $self->add_del_ids($pq_para->get_id, 'at_data');
    $self->add_del_ids($by->get_id, 'at_data');
    $self->add_del_ids($date->get_id, 'at_data');

    # Create a page subelement.
    ok my $page = Bric::Biz::AssetType->new({
        key_name  => '_page_',
        name      => 'Page',
        burner    => Bric::Biz::AssetType::BURNER_MASON,
        type__id  => $page_et->get_id,
        reference => 0, # No idea what this is.
    }), "Create a page subelement element";
    $self->{page} = $page;

    # Give it a paragraph field.
    ok my $page_para = $page->new_data({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 0,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 1,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";
    $self->{page_para} = $page_para;

    # Save it.
    ok $page->add_containers([$pull_quote->get_id]), 'Add pull quote to page';
    ok $page->save, "Save the page subelement element";
    $self->add_del_ids($page->get_id, 'element');

    # Add the subelements to the story type element.
    ok $story_type->add_containers([$pull_quote->get_id, $page->get_id]),
        "Add the subelements";
    ok $story_type->save, 'Save the story type with the subelements';
    return $self;
}

1;

__END__
