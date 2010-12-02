package Bric::Util::Burner::DevTest;

use strict;
use warnings;
use utf8;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Burner;
use Bric::Biz::Asset::Template;
use Bric::Util::Trans::FS;
use Bric::Biz::Category;
use Bric::Biz::Asset::Template::DevTest;
use Bric::Biz::Asset::Business::Story::DevTest;
use Bric::Biz::Asset::Business::Media::DevTest;
use Bric::Config qw(:temp :prev);
use Bric::Biz::OutputChannel;
use File::Basename;
use Test::MockModule;
use Test::File;
use Test::File::Contents;

sub table { 'alert_type' }

my $fs = Bric::Util::Trans::FS->new;

##############################################################################
sub test_deploy : Test(31) {
    my $self = shift;

    my $name = 'foodoo';
    my $oc_id = 1;
    my $oc_dir  = 'oc_' . $oc_id;
    # Create a template to deploy.
    ok( my $tmpl = Bric::Biz::Asset::Template::DevTest->construct
        (  data => '% print "hello world\n"',
           name => $name ),
        "Create template" );

    ok( $tmpl->save, "Save template" );
    $self->add_del_ids($tmpl->get_id, 'template');

    # Create a burner.
    ok( my $burner = Bric::Util::Burner->new({
        comp_dir => $fs->cat_dir(TEMP_DIR, 'comp')
    }), "Create burner" );

    # Figure out the complete file name and make sure it doesn't
    # yet exist.
    ok( my $fn = $fs->cat_dir($burner->get_comp_dir, $oc_dir,
                              $tmpl->get_file_name),
        "Construct file name" );
    ok( !-f $fn, "Check that the file doesn't exist" );

    # Check in an deploy the template and make sure it exists.
    ok( $tmpl->checkin, "Check in the template" );
    ok( $tmpl->save, "Save the template again" );
    ok( $burner->deploy($tmpl), "Deploy the template" );
    ok( -f $fn, "Check that the file exists" );

    # Mark the published version number.
    ok( $tmpl->set_published_version($tmpl->get_current_version),
        "Set published version number" );
    ok( $tmpl->save, "Save with published version number" );

    # Okay, now alter the template so that it gets deployed to a
    # different location. Start by creating a new category.
    ok( my $cat = Bric::Biz::Category->new({ name      => 'TmplTest',
                                             parent_id => 1,
                                             site_id   => 100,
                                             directory => 'ttest',
                                           }),
      "Create new category" );
    ok( $cat->save, "Save category" );
    ok( my $cat_id = $cat->get_id, "Get category ID" );
    $self->add_del_ids($cat_id, 'category');

    # Look up and check out the template.
    ok( $tmpl = $tmpl->lookup({ id => $tmpl->get_id }), "Look up template" );
    ok( $tmpl->checkout({ user__id => $self->user_id }),
        "Checkout the template" );

    # Set the template to use the new category.
    ok( $tmpl->set_category_id($cat_id),
        "Set template category to '$cat_id'" );

    # Save it.
    ok( $tmpl->save, "Save the template yet again" );

    # Save it and check it in again.
    ok( $tmpl->checkin, "Check in the template again" );
    ok( $tmpl->save, "Save the template one last time" );

    # Figure out the complete file name and make sure it doesn't
    # yet exist.
    ok( my $new_fn = $fs->cat_dir($burner->get_comp_dir, $oc_dir,
                                  $tmpl->get_file_name),
        "Construct new file name" );
    ok( $new_fn ne $fn, "Make sure file names are different" );
    ok( !-f $new_fn, "Check that the new file doesn't exist" );

    # Deploy the template and make sure it exists and that the old file
    # name doesn't exist.
    ok( $burner->deploy($tmpl), "Deploy the template again" );
    ok( -f $new_fn, "Check that the new file exists" );
    ok( !-f $fn, "Check that the old file is gone" );

    # Now undeploy it.
    ok( $burner->undeploy($tmpl), "Undeploy the template" );
    ok( !-f $new_fn, "Check that the new file is gone" );
    ok( !-f $fn, "Check that the old file is still gone" );

    # Mark the published version number again, for completeness.
    ok( $tmpl->set_published_version($tmpl->get_current_version),
        "Set published version number again" );
    ok( $tmpl->save, "Save with published version number again" );
}

##############################################################################
sub test_page : Test(37) {
    my $self = shift;
    my $out_path = $fs->cat_dir('', 'output');
    ok my $burner = Bric::Util::Burner->new({
        base_uri    => '/foo/bar',
        output_path => $out_path,
        page        => 3,
    }), "Create a new burner";
    my $out_file = $fs->cat_file($out_path, 'index');
    ok $burner->set_output_filename('index'), "Set the file name";
    ok $burner->set_output_ext('html'), "Set the file extension";
    is_deeply [$burner->get_page_extensions], [''],
      "We should start with a single empty string extension";
    is $burner->page_file(1), 'index.html',
      "The first page should have no extension";
    is $burner->page_file(2), 'index1.html',
      "The second page should have an extension of '1'";
    is $burner->page_uri(1), '/foo/bar/index.html',
      "The first uri should have no extension";
    is $burner->page_uri(2), '/foo/bar/index1.html',
      "The second uri should have an extension of '1'";
    is $burner->page_filepath(1), "$out_file.html",
      "The first file should have no extension";
    is $burner->page_filepath(2), "${out_file}1.html",
      "The second file should have an extension of '1'";
    is $burner->prev_page_file, $burner->page_file(3),
      "Previos page should be page_file(3)";
    is $burner->prev_page_uri, $burner->page_uri(3),
      "Previos URI should be page_uri(3)";
    is $burner->next_page_file, undef, "Next page should still undef";
    is $burner->next_page_uri, undef, "Next URI should still be undef";
    ok $burner->set_burn_again(1), "Set burn_again to true";
    is $burner->next_page_file, $burner->page_file(3 + 2),
      "Next page should be page_file(3 + 2)";
    is $burner->next_page_uri, $burner->page_uri(3 + 2),
      "Next URI should be page_uri(3 + 2)";
    ok $burner->set_burn_again(0), "Set burn_again to false";

    ok $burner->set_page_extensions('foo', 'bar'),
      "Set a couple of extensions";
    is_deeply [$burner->get_page_extensions], ['foo', 'bar'],
      "We should get back the extensions";
    is $burner->page_file(1), 'indexfoo.html',
      "The first page should have the first extension";
    is $burner->page_file(2), 'indexbar.html',
      "The second page should have the second extension";
    is $burner->page_file(3), 'index1.html',
      "The third page should have an extension of '1'";
    is $burner->page_uri(1), '/foo/bar/indexfoo.html',
      "The first page should have the first extension";
    is $burner->page_uri(2), '/foo/bar/indexbar.html',
      "The second page should have the second extension";
    is $burner->page_uri(3), '/foo/bar/index1.html',
      "The third page should have an extension of '1'";
    is $burner->page_filepath(1), "${out_file}foo.html",
      "The first page should have the first extension";
    is $burner->page_filepath(2), "${out_file}bar.html",
      "The second page should have the second extension";
    is $burner->page_filepath(3), "${out_file}1.html",
      "The third page should have an extension of '1'";
    is $burner->prev_page_file, $burner->page_file(3),
      "Previos page should still be page_file(3)";
    is $burner->prev_page_uri, $burner->page_uri(3),
      "Previos URI should still be page_uri(3)";
    is $burner->next_page_file, undef, "Next page should still undef";
    is $burner->next_page_uri, undef, "Next URI should still be undef";
    ok $burner->set_burn_again(1), "Set burn_again to true";
    is $burner->next_page_file, $burner->page_file(3 + 2),
      "Next page should still be page_file(3 + 2)";
    is $burner->next_page_uri, $burner->page_uri(3 + 2),
      "Next URI should still be page_uri(3 + 2)";
    ok $burner->set_burn_again(0), "Set burn_again to false";
}

##############################################################################
sub test_notes : Test(7) {
    my $self = shift;
    ok my $burner = Bric::Util::Burner->new, "Create a new burner";
    is_deeply $burner->notes, {}, "Notes should start out empty";
    ok $burner->notes(foo => 'bar'), "Set 'foo' to 'bar'";
    is_deeply $burner->notes, {foo => 'bar'},
      "Notes should have new value";
    is $burner->notes('foo'), 'bar', "'foo' should return 'bar'";
    ok $burner->clear_notes, "Clear the notes";
    is_deeply $burner->notes, {}, "Notes should be empty again";

}

##############################################################################
sub test_best_uri : Test(4) {
    my $self = shift;

    # Mock stuff in burner class.
    my $oc = Bric::Biz::OutputChannel->new({
        site_id  => 100,
        protocol => 'http://',
    });
    my $bc = Test::MockModule->new('Bric::Util::Burner');
    $bc->mock(get_oc => $oc);

    # Mock stuff in Story class.
    my $sc = Test::MockModule->new('Bric::Biz::Asset::Business::Story');
    $sc->mock(new => sub { my $pkg = shift; bless {@_}, $pkg; });
    $sc->mock(get_site_id => 100);
    $sc->mock(get_output_channels => [$oc]);
    $sc->mock(get_primary_oc => $oc);
    $sc->mock(get_uri => sub { shift->{uri} });
    my $story = Bric::Biz::Asset::Business::Story->new( uri => '/foo/bar' );

    # Test with a story in the same site.
    ok my $burner = Bric::Util::Burner->new, "Create a new burner";
    is $burner->best_uri($story), '/foo/bar',
      "We should get a simple URI for a story in the same site";

    # Now try with a story in a different site, but an alias in the current
    # site.
    my $alias = Bric::Biz::Asset::Business::Story->new( uri => '/my/alias' );
    $sc->mock(lookup => $alias);
    $sc->mock(get_site_id => 1212);
    is $burner->best_uri($story), '/my/alias',
      "We should get a simple URI for an alias in the same site";

    # Now have no alias, so we have to use the original story with a full
    # URL.
    my $site = Bric::Biz::Site->new({ domain_name => 'www.example.org'});
    my $sitec = Test::MockModule->new('Bric::Biz::Site');
    $sitec->mock(lookup => $site);
    $sc->mock(lookup => undef);
    is $burner->best_uri($story), 'http://www.example.org/foo/bar',
      "We should get a full URL";
}

##############################################################################
# To be called by the subclasses to run burn tests.
sub subclass_burn_test {
    my ($self, $dir, $suffix, $burner_type) = @_;
    $self->{delete_resources} = 1;

    # Add a couple of categories.
    ok my $cat = Bric::Biz::Category->new({
        name        => 'Testing',
        site_id     => 100,
        description => 'Description',
        parent_id   => 1,
        directory   => 'testing',
    }), "Create a subcategory";
    ok $cat->save, "Save the subcategory";
    $self->add_del_ids($cat->get_id, 'category');

    ok my $subcat = Bric::Biz::Category->new({
        name        => 'SubTesting',
        site_id     => 100,
        description => 'Description',
        parent_id   => $cat->get_id,
        directory   => 'sub',
    }), "Create a sub-subcategory";
    ok $subcat->save, "Save the sub-subcategory";
    $self->add_del_ids($subcat->get_id, 'category');

    # Create some output channels.
    ok my $suboc = Bric::Biz::OutputChannel->new({
        name    => 'Sub XHTML',
        burner  => $burner_type,
        site_id => 100,
    }), "Create another output channel";
    ok $suboc->save, "Save the other output channel";
    $self->add_del_ids($suboc->get_id, 'output_channel');

    ok my $oc = Bric::Biz::OutputChannel->new({
        name    => 'Test XHTML',
        burner  => $burner_type,
        site_id => 100,
    }), "Create an output channel";
    ok $oc->save, "Save the new output channel";
    $self->add_del_ids($oc->get_id, 'output_channel');
    ok $oc->add_includes($suboc), "Add an include OC";
    ok $oc->save, "Save the new output channel with its includes";

    # Create a story type.
    ok my $story_type = Bric::Biz::ElementType->new({
        key_name  => '_testing_',
        name      => 'Testing',
        top_level => 1,
        reference => 0, # No idea what this is.
    }), "Create story type";
    ok $story_type->add_site(100), "Add the site ID";
    ok $story_type->add_output_channels([$oc]), "Add the output channel";
    ok $story_type->set_primary_oc_id($oc->get_id, 100),
      "Set it as the primary OC";;
    ok $story_type->save, "Save the test story type";
    $self->add_del_ids($story_type->get_id, 'element_type');

    # Give it a header field.
    ok my $head = $story_type->new_field_type({
        key_name    => 'header',
        name        => 'Header',
        required    => 0,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 1,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a paragraph field.
    ok my $para = $story_type->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 0,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 2,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Save the story type with its fields.
    ok $story_type->save, "Save element with the fields";
    $self->add_del_ids($head->get_id, 'field_type');
    $self->add_del_ids($para->get_id, 'field_type');

    # Create a subelement.
    ok my $pull_quote = Bric::Biz::ElementType->new({
        key_name  => '_pull_quote_',
        name      => 'Pull Quote',
        reference => 0, # No idea what this is.
    }), "Create a subelement element";

    ok $pull_quote->save, "Save the subelement element";
    $self->add_del_ids($pull_quote->get_id, 'element_type');

    # Give it a paragraph field.
    ok my $pq_para = $pull_quote->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 1,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a by field.
    ok my $by = $pull_quote->new_field_type({
        key_name    => 'by',
        name        => 'By',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 2,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a date field.
    ok my $date = $pull_quote->new_field_type({
        key_name    => 'date',
        name        => 'Date',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'date',
        place       => 3,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Save the pull quote with its fields.
    ok $pull_quote->save, "Save subelement with the fields";
    $self->add_del_ids($pq_para->get_id, 'field_type');
    $self->add_del_ids($by->get_id, 'field_type');
    $self->add_del_ids($date->get_id, 'field_type');

    # Create a page subelement.
    ok my $page = Bric::Biz::ElementType->new({
        key_name  => '_page_',
        name      => 'Page',
        paginated => 1,
        reference => 0, # No idea what this is.
    }), "Create a page subelement element";

    # Give it a paragraph field.
    ok my $page_para = $page->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 0,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 1,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Save it.
    ok $page->save, "Save the page subelement element";
    $self->add_del_ids($page->get_id, 'element_type');

    # Add the subelements to the story type element.
    ok $story_type->add_containers([$pull_quote->get_id, $page->get_id]),
      "Add the subelements";

    # Now let's create some templates for these bad boys! Start with the
    # story template.
    my $file = $fs->cat_file(dirname(__FILE__), $dir, "story.$suffix");
    open my $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $story_tmpl = Bric::Biz::Asset::Template->new({
        output_channel => $oc,
        user__id       => $self->user_id,
        category_id    => 1,
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Template::ELEMENT_TEMPLATE,
        element_type   => $story_type,
        file_type      => $suffix,
        data           => join('', <$fh>),
    }), "Create a story template";

    ok( $story_tmpl->save, "Save template" );
    $self->add_del_ids($story_tmpl->get_id, 'template');
    close $fh;

    # Now the subelement template.
    $file = $fs->cat_file(dirname(__FILE__), $dir, "pull_quote.$suffix");
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $pq_tmpl = Bric::Biz::Asset::Template->new({
        output_channel => $suboc, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => $cat->get_id, # Put it in a subcategory
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Template::ELEMENT_TEMPLATE,
        element_type   => $pull_quote,
        file_type      => $suffix,
        data           => join('', <$fh>),
    }), "Create a pull quote template";
    ok( $pq_tmpl->save, "Save pull quote template" );
    $self->add_del_ids($pq_tmpl->get_id, 'template');
    close $fh;

    # Page template.
    $file = $fs->cat_file(dirname(__FILE__), $dir, "page.$suffix");
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $page_tmpl = Bric::Biz::Asset::Template->new({
        output_channel => $oc,
        user__id       => $self->user_id,
        category_id    => 1,
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Template::ELEMENT_TEMPLATE,
        element_type   => $page,
        data           => join('', <$fh>),
        file_type      => $suffix,
    }), "Create a page template";
    ok( $page_tmpl->save, "Save page template" );
    $self->add_del_ids($page_tmpl->get_id, 'template');
    close $fh;

    # And how about a category template?
    my $cat_tmpl_fn = Bric::Util::Burner->cat_fn_for_ext($suffix);
    $cat_tmpl_fn .= ".$suffix"
      if Bric::Util::Burner->cat_fn_has_ext($cat_tmpl_fn);
    $file = $fs->cat_file(dirname(__FILE__), $dir, $cat_tmpl_fn);
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $cat_tmpl = Bric::Biz::Asset::Template->new({
        output_channel => $suboc, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => 1,
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Template::CATEGORY_TEMPLATE,
        file_type      => $suffix,
        data           => join('', <$fh>),
    }), "Create a category template";
    ok( $cat_tmpl->save, "Save category template" );
    $self->add_del_ids($cat_tmpl->get_id, 'template');
    close $fh;

    # And also a subcategory template.
    my $subcat_tmpl_fn = Bric::Util::Burner->cat_fn_for_ext($suffix);
    $subcat_tmpl_fn .= ".$suffix"
      if Bric::Util::Burner->cat_fn_has_ext($subcat_tmpl_fn);
    $subcat_tmpl_fn = 'sub_' . $subcat_tmpl_fn;
    $file = $fs->cat_file(dirname(__FILE__), $dir, $subcat_tmpl_fn);
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $subcat_tmpl = Bric::Biz::Asset::Template->new({
        output_channel => $suboc, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => $subcat->get_id, # This is the important bit.
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Template::CATEGORY_TEMPLATE,
        file_type      => $suffix,
        data           => join('', <$fh>),
    }), "Create a subcategory template";
    ok( $subcat_tmpl->save, "Save subcategory template" );
    $self->add_del_ids($subcat_tmpl->get_id, 'template');
    close $fh;

    # And I think a utility template might be handy.
    $file = $fs->cat_file(dirname(__FILE__), $dir, "util.$suffix");
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $util_tmpl = Bric::Biz::Asset::Template->new({
        output_channel => $suboc, # Put it in the contained OC.
        user__id       => $self->user_id,
        name           => "util.$suffix",
        category_id    => $subcat->get_id, # Bury it!
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Template::UTILITY_TEMPLATE,
        file_type      => $suffix,
        data           => join('', <$fh>),
    }), "Create a utility template";
    ok( $util_tmpl->save, "Save utility template" );
    $self->add_del_ids($util_tmpl->get_id, 'template');
    close $fh;

    # Now, create a burner, check the syntax, and deploy these templates.
    ok my $burner = Bric::Util::Burner->new({
        comp_dir  => $fs->cat_dir(TEMP_DIR, 'comp'),
        base_path => $fs->cat_dir(TEMP_DIR, 'base'),
    }), "Create burner";

    for my $tmpl ($story_tmpl, $pq_tmpl, $cat_tmpl, $page_tmpl, $util_tmpl,
                  $subcat_tmpl, $self->extra_templates({
                      story_type => $story_type,
                      pull_quote => $pull_quote,
                      oc         => $oc,
                      suboc      => $suboc,
                      cat        => $cat,
                      subcat     => $subcat
                  }))
    {
        my $name = $tmpl->get_file_name;
        ok $tmpl->checkin, "Check in the $name template";
        ok $tmpl->save, "Save the $name template again";
        my $err;
        ok $burner->chk_syntax($tmpl, \$err), "Check the syntax of $name";
        diag $err if $err;
        ok $burner->deploy($tmpl), "Deploy $name";
    }

    # Now it's time to create a story!
    ok my $story = Bric::Biz::Asset::Business::Story->new({
        user__id        => $self->user_id,
        site_id         => 100,
        element_type_id => $story_type->get_id,
        source__id      => 1,
        title           => 'This is a Test',
        slug            => 'test_burn',
    }), "Create test story";

    ok $story->add_categories([$subcat->get_id]), "Add it to the subcategory";
    ok $story->set_primary_category($subcat->get_id),
      "Make the subcategory the primary category";
    ok $story->set_cover_date('2005-03-22 21:07:56'), "Set the cover date";
    ok $story->checkin, "Check in the story";
    ok $story->save, "Save the story";
    $self->add_del_ids($story->get_id, 'story');

    # Add some content to it.
    ok my $elem = $story->get_element, "Get the story element";
    ok $elem->add_data($para, 'This is a paragraph'), "Add a paragraph";
    ok $elem->add_data($para, 'Second paragraph'), "Add another paragraph";
    ok $elem->add_data($head, "And then..."), "Add a header";
    ok $elem->add_data($para, 'Third paragraph'), "Add a third paragraph";

    # Add a pull quote.
    ok my $pq = $elem->add_container($pull_quote), "Add a pull quote";
    ok $pq->get_field('para')->set_data(
        'Ask not what your country can do for you. '
          . 'Ask what you can do for your country.'
    ), "Add a paragraph to the pull quote";
    ok $pq->get_field('by')->set_data("John F. Kennedy"),
      "Add a By to the pull quote";
    ok $pq->get_field('date')->set_data('1961-01-20 00:00:00'),
      "Add a date to the pull quote";

    # Add some Unicode content.
    ok $elem->add_data(
        $para,
        '圳地在圭圬圯圩夙多夷夸妄奸妃好她如妁字存宇守宅安寺尖屹州帆并年'
    ), "Add a Chinese paragraph";
    ok $elem->add_data(
        $para,
        '橿梶鰍潟割喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱'
    ), "Add a Japanese paragraph";
    ok $elem->add_data(
        $para,
        '뼈뼉뼘뼙뼛뼜뼝뽀뽁뽄뽈뽐뽑뽕뾔뾰뿅뿌뿍뿐뿔뿜뿟뿡쀼쁑쁘쁜쁠쁨쁩삐'
    ), "Add a Korean paragraph";

    # Add another pull quote.
    ok $pq = $elem->add_container($pull_quote), "Add another pull quote";
    ok $pq->get_field('para')->set_data(
        'So, first of all, let me assert my firm belief that the only '
        . 'thing we have to fear is fear itself -- nameless, unreasoning, '
        . 'unjustified terror which paralyzes needed efforts to convert '
        . 'retreat into advance.'
    ), "Add a paragraph to the pull quote";
    ok $pq->get_field('by')->set_data("Franklin D. Roosevelt"),
      "Add a By to the pull quote";
    ok $pq->get_field('date')->set_data('1933-03-04 00:00:00'),
      "Add a date to the pull quote";

    # Make it so!
    ok $elem->save, "Save the story element";

    # Allow localization by creating a language object.
    isa_ok(Bric::Util::Language->get_handle('en-us'),
           'Bric::Util::Language::en_us');
    $self->trap_stderr;

    # Set up the component root for the preview.
    $self->{comp_root} = Bric::Util::Burner::MASON_COMP_ROOT->[0][1];
    Bric::Util::Burner::MASON_COMP_ROOT->[0][1] = TEMP_DIR;

    # Make sure that the files don't already exist.
    $file = $fs->cat_dir(
        TEMP_DIR,
        'base',
        $fs->uri_to_dir($story->get_primary_uri),
        '',
        $oc->get_filename . '.' . $oc->get_file_ext
    );
    (my $file1 = $file) =~ s/index/index1/;
    ok !-e $file, 'File should not yet exist';
    ok !-e $file1, 'File1 should not yet exist';

    # Now burn it!
    ok my ($res) = $burner->burn_one($story, $oc, $subcat), "Burn the story";
    is $res->get_path, $file, "Check the file location";

    # Now we should have a file!
    ok -e $file, 'File should now exist' or return "Failed to create $file!";
    unless ($burner_type == Bric::Biz::OutputChannel::BURNER_TEMPLATE) {
        ok -e $file1, 'Second file should now exist'
            or return "Failed to create $file!";
    }

    # So now let's take a look at that bad boy.
    file_contents_is($file, $self->story_output, "Check the file contents");
    # Clean up our mess.
    unlink $file;
    unlink $file1;

    # Now we'll try a preview, just for the heck of it.
    my $prev_root = $fs->cat_dir(TEMP_DIR, 'comp');
    Bric::Util::Burner::MASON_COMP_ROOT->[0][1] = $prev_root;

    my $prev_file = $fs->cat_file(
        $prev_root,
        PREVIEW_LOCAL,
        $fs->uri_to_dir($story->get_primary_uri), '',
        $oc->get_filename . '.' . $oc->get_file_ext
    );
    (my $prev_file1 = $prev_file) =~ s/index/index1/;
    ok !-e $prev_file, 'The preview file should not yet exist';
    ok !-e $prev_file1, 'The second preview file should not yet exist';

    # Set up to listen in to the status messages.
    $self->trap_stderr;

    # Make it so!
    ok $burner->preview($story, 'story', $self->user_id, $oc->get_id),
      "Preview story";

    # The job starts a new transaction, so let's commit it so that objects can
    # be properly deleted from the database during cleanpup.
    Bric::Util::DBI::commit();

    is $self->read_stderr,
      'Writing files to "Test XHTML" Output Channel.Distributing files.',
      "The status message should be correct";

    ok -e $prev_file, 'Preview file should now exist'
        or return "Failed to create $prev_file!";
    unless ($burner_type == Bric::Biz::OutputChannel::BURNER_TEMPLATE) {
        ok -e $prev_file1, 'Second preview file should now exist'
            or return "Failed to create $prev_file!";
    }

    file_contents_is($prev_file, $self->story_output,
                     "Check the preview file contents");

    # Okay, cool. Let's just stick to burning and try adding a couple of
    # pages.
    ok my $pg = $elem->add_container($page), "Add a page";
    ok $pg->add_data($page_para, 'Wee, page one paragraph'),
      "Add a paragraph to the page";
    ok $pg->add_data($page_para, 'Another page one paragraph'),
      "Add another paragraph to the page";
    ok $pg = $elem->add_container($page), "Add a second page";
    ok $pg->add_data($page_para, 'Wee, page two paragraph'),
      "Add a paragraph to the second page";
    ok $pg->add_data($page_para, 'Another page two paragraph'),
      "Add another paragraph to the second page";
    ok $pg = $elem->add_container($page), "Add another page";
    ok $elem->save, "Save the story element";

    # Now that we've done a preview, the OC will be a part of the path,
    # so re-create the file path variable.
    $file = $fs->cat_file(TEMP_DIR, 'burn', 'stage', 'oc_' . $oc->get_id,
                          $fs->uri_to_dir($story->get_primary_uri), '',
                          $oc->get_filename . '.' . $oc->get_file_ext);
    ($file1 = $file) =~ s/index/index1/;
    (my $file2 = $file) =~ s/index/index2/;
    ok !-e $file2, 'Third page file should not yet exist';

    # Now burn it with pages.
    ok my @reses = $burner->burn_one($story, $oc, $subcat),
      "Burn the paginated story";
    is @reses, 3, "We should have two resources";
    is $reses[0]->get_path, $file, "Check the first file location";
    is $reses[1]->get_path, $file1, "Check the second file location";
    is $reses[2]->get_path, $file2, "Check the third file location";
    ok -e $file, 'First page file should still exist';
    ok -e $file1, 'Second page file should still exist';
    ok -e $file2, 'Third page file should now exist, too';

    # Check their contents.
    file_contents_is($file, $self->story_page1, 'Check page 1 contents');
    file_contents_is($file1, $self->story_page2, 'Check page 2 contents');

    # Clean up our mess.
    unlink $file, $file1, $file2, $prev_file, $prev_file1;
}

##############################################################################
sub test_story_publish {
    my $self = shift;

    # Where we at?
    my $stage_dir   = $fs->cat_dir($ENV{BRIC_TEMP_DIR}, 'stage');
    my $preview_dir = $fs->cat_dir($ENV{BRIC_TEMP_DIR}, 'preview');
    my $dest_root   = $fs->cat_dir($ENV{BRIC_TEMP_DIR}, 'prod');
    my $prev_root   = $fs->cat_dir($ENV{BRIC_TEMP_DIR}, 'previewed');

    # Create a story.
    ok my $story = Bric::Biz::Asset::Business::Story::DevTest->construct(
        name => 'Flubber',
        slug => 'hugo',
    ), 'Create a story';
    ok $story->checkin, 'Check in the story';
    ok $story->save, 'Save the story';
    $self->add_del_ids($story->get_id, 'story');
    my $oc = $story->get_primary_oc;

    # We need to know where files will end up.
    my $stage_path = $fs->cat_file(
        $stage_dir,
        'oc_' . $oc->get_id,
        $story->get_uri,
        $oc->get_filename . '.' . $oc->get_file_ext
    );
    my $preview_path = $fs->cat_file(
        $preview_dir,
        'oc_' . $oc->get_id,
        $story->get_uri,
        $oc->get_filename . '.' . $oc->get_file_ext
    );

    # Set up a destination and a server.
    $self->make_dest($dest_root, $oc, $prev_root);

    # Set up the component root for the preview.
    $self->{comp_root} = Bric::Util::Burner::MASON_COMP_ROOT->[0][1];
    Bric::Util::Burner::MASON_COMP_ROOT->[0][1] = TEMP_DIR;

    # We'll need a burner.
    ok my $burner = Bric::Util::Burner->new({
        out_dir   => $preview_dir,
        comp_dir  => $fs->cat_dir(TEMP_DIR, 'comp'),
        base_path => $fs->cat_dir(TEMP_DIR, 'base'),
        _output_preview_msgs => 0,
    }), "Create burner";

    # Find the template for the story.
    ok my $tmpl = Bric::Biz::Asset::Template->lookup({
        id => 512, # Story template ID.
    }), 'Find the story template';

    ok $burner->deploy($tmpl), 'Deploy it';

    # First, preview the story.
    ok $burner->preview( $story, 'story', $self->user_id ), 'Preview the story';

    # Now, find the resource that was distributed.
    ok my $res = Bric::Dist::Resource->lookup({ path => $preview_path }),
        'Look up the previewed resource';
    $self->add_del_ids($res->get_id, 'resource');
    my $prev_file = $fs->cat_dir($prev_root, $res->get_uri);

    # Make sure the file was distributed!
    file_exists_ok $prev_file, 'The preview should have been distributed';

    # Now publish the story.
    $burner->set_out_dir( $stage_dir );
    ok $burner->publish( $story, 'story', $self->user_id), 'Publish the story';

    # Now, find the resource that was distributed.
    ok my $res2 = Bric::Dist::Resource->lookup({ path => $stage_path }),
        'Look up the published resource';
    $self->add_del_ids($res2->get_id, 'resource');
    my $pub_file = $fs->cat_dir($dest_root, $res2->get_uri);

    # Make sure the file was distributed!
    file_exists_ok $pub_file, 'The publish should have been distributed';
    file_exists_ok $prev_file, 'The preview file should still exist';
}

##############################################################################
sub test_media_publish : Test(60) {
    my $self = shift;

    # Where we at?
    my $media_root = $fs->cat_dir($ENV{BRIC_TEMP_DIR}, '_media');
    my $dest_root  = $fs->cat_dir($ENV{BRIC_TEMP_DIR}, 'prod');

    # Create a media object.
    ok my $media = Bric::Biz::Asset::Business::Media::DevTest->construct(
        name      => 'Flubberman',
        file_name => 'fun.foo',
    ), 'Create a new media object';

    # Upload a file before saving the media.
    ok open my $fh, '<', __FILE__ or die 'Cannot open ' . __FILE__ . ": $!";
    ok $media->upload_file($fh, 'foo.png'), 'Upload a media file';

    # Now checkin and save the media and grab the path info.
    ok $media->checkin, 'Check in the media document';
    ok $media->save, 'Save the media document';
    $self->add_del_ids($media->get_id, 'media');
    ok my $path = $media->get_path, 'Grab the path';
    ok my $uri  = $media->get_uri;

    # Set up a destination and a server.
    $self->make_dest($dest_root, $media->get_primary_oc);

    ok my $burner = Bric::Util::Burner->new({
        comp_dir => $fs->cat_dir(TEMP_DIR, 'comp')
    }), 'Create a burner';


    # First, make the publish fail.
    ok !$media->get_publish_status, 'Publish status should be false';
    is $media->get_publish_date, undef, 'Publish date should be undef';
    is $media->get_first_publish_date, undef, 'First publish date should be undef';

    # Prevent the publish by having no server types.
    my $stmock = Test::MockModule->new('Bric::Dist::ServerType');
    $stmock->mock(list => sub {[]});

    my $msg = 'Cannot publish asset "Flubberman" to "Web" because there are no Destinations associated with this output channel.';
    my $bmock = Test::MockModule->new('Bric::Util::Burner');
    $bmock->mock(add_msg => sub { is shift, $msg, 'Failure message should be correct' });
    ok !$burner->publish($media, 'media', $self->user_id),
        'Try to publish the media document';

    # Publish status and dates should be unchanged.
    ok !$media->get_publish_status, 'Publish status should still be false';
    is $media->get_publish_date, undef, 'Publish date should still be undef';
    is $media->get_first_publish_date, undef, 'First publish date should still be undef';

    # Okay, let it go now.
    $stmock->unmock_all;
    $bmock->unmock_all;
    ok $burner->publish($media, 'media', $self->user_id),
        'Publish the media document';

    ok $media->get_publish_status, 'Publish status should now be true';
    isnt $media->get_publish_date, undef, 'Publish date should not be undef';
    isnt $media->get_first_publish_date, undef, 'First publish date should not be undef';

    # Now, find the resource that was distributed.
    ok my $res = Bric::Dist::Resource->lookup({ path => $path }),
        'Look up the distributed resource';
    $self->add_del_ids($res->get_id, 'resource');
    my $file = $fs->cat_dir($dest_root, $res->get_uri);

    # Make sure the file was distributed!
    file_exists_ok $file, 'The file should have been distributed';

    # Make the publish fail again.
    $stmock->mock(list => sub {[]});
    $bmock->mock(add_msg => sub { is shift, $msg, 'Failure message should be correct' });
    my $date = '2010-12-02 19:29:00';
    $media->set_publish_date($date);
    $media->set_first_publish_date($date);
    $media->save;
    ok !$burner->publish($media, 'media', $self->user_id),
        'Fail to publish the media document again';
    ok $media->get_publish_status, 'Publish status should still be true';
    is $media->get_publish_date, $date, 'Publish date should not be updated';
    is $media->get_first_publish_date, $date, 'First publish date should not be updated';

    # Now create a new version of the media document, with a new file.
    $stmock->unmock_all;
    $bmock->unmock_all;
    ok $media->checkout({ user__id => $self->user_id }), 'Check out the media';
    ok $media->checkin, 'Check it in';
    ok $media->checkout({ user__id => $self->user_id }), 'Check it out again';

    ok open $fh, '<', __FILE__ or die 'Cannot open ' . __FILE__ . ": $!";
    # Must use the same file name here.
    ok $media->upload_file($fh, 'foo.png'), 'Upload the media file again';
    ok $media->checkin, 'Check it in yet again';
    ok $media->save, 'Save the media document again';
    isnt $media->get_path, $path, 'It should have a new path';
    is $media->get_uri, $uri, 'But its URI should be the same';

    ok $burner->publish($media, 'media', $self->user_id),
        'Publish the media document again';

    # Find the new resource.
    ok my $res2 = Bric::Dist::Resource->lookup({ path => $media->get_path }),
        'Look up the newly distributed resource';
    $self->add_del_ids($res2->get_id, 'resource');
    isnt $res2->get_id, $res->get_id, 'It should be a different resource';

    file_exists_ok $file, 'The distributed file should still exist';

    # Okay, now we'll try uploading a file with a new file name.
    ok $media->checkout({ user__id => $self->user_id }), 'Check it out again';
    ok open $fh, '<', __FILE__ or die 'Cannot open ' . __FILE__ . ": $!";
    # Must use the same file name here.
    ok $media->upload_file($fh, 'bar.png'), 'Upload with a new file name';
    ok $media->checkin, 'Check it in one last time';
    ok $media->save, 'Save the media document again';
    isnt $media->get_path, $path, 'It should have a new path';
    isnt $media->get_uri, $uri, 'And its URI should be different';

    ok $burner->publish($media, 'media', $self->user_id),
        'Publish the media document one last time';

    # Find the new resource.
    ok my $res3 = Bric::Dist::Resource->lookup({ path => $media->get_path }),
        'Look up the last distributed resource';
    $self->add_del_ids($res3->get_id, 'resource');
    isnt $res3->get_id, $res->get_id, 'It should be different than the first res';
    isnt $res3->get_id, $res2->get_id, 'And from the previoius res';

    file_not_exists_ok $file, 'And the original file should be expired!';
    $file = $fs->cat_dir($dest_root, $res3->get_uri);
    file_exists_ok $file, 'But the new file should be distributed';
}

##############################################################################
# Creates a destination to test publishing. Used by test_story_publish() and
# test_media_publish().
sub make_dest {
    my ($self, $dest_root, $oc, $preview_root) = @_;
    # Set up a destination and a server.
    ok my $dest = Bric::Dist::ServerType->new({
        name        => 'Prod',
        site_id     => 100,
        move_method => 'File System',
        publish     => 1,
    }), 'Create a destination';

    # Associate the output channel and save it.
    ok $dest->add_output_channels($oc), 'Add OC';
    ok $dest->save, 'Save the destination';
    $self->add_del_ids($dest->get_id, 'server_type');

    # Add a move action.
    ok $dest->new_action({ type => 'Move' }), 'Create new action';
    ok $dest->save, 'Save new action';

    # Create a server for the destination.
    ok my $server = Bric::Dist::Server->new({
        host_name      => 'www.example.org',
        os             => 'Unix',
        doc_root       => $dest_root,
        server_type_id => $dest->get_id,
    }), 'Create a new server';
    ok $server->save, 'Save the server';
    $self->add_del_ids($server->get_id, 'server');

    return $self unless $preview_root;

    ok $dest = Bric::Dist::ServerType->new({
        name        => 'Preview',
        site_id     => 100,
        move_method => 'File System',
    }), 'Create a preview destination';

    $dest->on_preview(1);
    $dest->no_publish(0);
    # Associate the output channel and save it.
    ok $dest->add_output_channels($oc), 'Add OC';
    ok $dest->save, 'Save the preview destination';
    $self->add_del_ids($dest->get_id, 'server_type');

    # Add a move action.
    ok $dest->new_action({ type => 'Move' }), 'Create preview action';
    ok $dest->save, 'Save preview action';

    # Create a server for the destination.
    ok $server = Bric::Dist::Server->new({
        host_name      => 'www.example.org',
        os             => 'Unix',
        doc_root       => $preview_root,
        server_type_id => $dest->get_id,
    }), 'Create a new preview server';
    ok $server->save, 'Save the preview server';
    $self->add_del_ids($server->get_id, 'server');

    return $self;
}

##############################################################################
sub burn_cleanup : Test(teardown) {
    my $self = shift;
    Bric::Util::Burner::MASON_COMP_ROOT->[0][1] = delete $self->{comp_root}
      if exists $self->{comp_root};

    # Clean up our mess.
    Bric::Util::DBI::prepare(qq{
        DELETE FROM resource
        WHERE  id > 1023
    })->execute if delete $self->{delete_resources};
}

sub extra_templates {}

1;
__END__
