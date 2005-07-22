package Bric::Util::Burner::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Burner;
use Bric::Biz::Asset::Formatting;
use Bric::Util::Trans::FS;
use Bric::Biz::Category;
use Bric::Biz::Asset::Formatting::DevTest;
use Bric::Config qw(:temp :prev);
use File::Basename;
use Test::MockModule;
use Test::File::Contents;

sub table { 'alert_type' }

my $fs = Bric::Util::Trans::FS->new;

sub test_deploy : Test(28) {
    my $self = shift;

    my $name = 'foodoo';
    my $oc_id = 1;
    my $oc_dir  = 'oc_' . $oc_id;
    # Create a template to deploy.
    ok( my $tmpl = Bric::Biz::Asset::Formatting::DevTest->construct
        (  data => '% print "hello world\n"',
           name => $name ),
        "Create template" );

    ok( $tmpl->save, "Save template" );
    $self->add_del_ids($tmpl->get_id, 'formatting');

    # Create a burner.
    ok( my $burner = Bric::Util::Burner->new
        ({ comp_dir => $fs->cat_dir(TEMP_DIR, 'comp') }),
        "Create burner" );

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

    # Mark the published version number again, for completeness.
    ok( $tmpl->set_published_version($tmpl->get_current_version),
        "Set published version number again" );
    ok( $tmpl->save, "Save with published version number again" );
}

sub test_mason : Test(75) {
    my $self = shift;
    $self->test_burn('Mason', 'mc', Bric::Biz::AssetType::BURNER_MASON);
}

sub test_burn {
    my ($self, $dir, $suffix, $burner_type) = @_;

    # First, we'll need a story element type.
    ok my $story_et = Bric::Biz::ATType->new({
        name => 'Testing',
        top_level => 1,
    }), "Create a story element type";
    ok $story_et-> save, "Save story element type";
    $self->add_del_ids($story_et->get_id, 'at_type');

    # Next, a subelement.
    ok my $sub_et = Bric::Biz::ATType->new({
        name => 'Subby',
        top_level => 0,
    }), "Create a subelement element type";
    ok $sub_et-> save, "Save subelement element type";
    $self->add_del_ids($sub_et->get_id, 'at_type');

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
        site_id => 100,
    }), "Create another output channel";
    ok $suboc->save, "Save the other output channel";
    $self->add_del_ids($suboc->get_id, 'output_channel');

    ok my $oc = Bric::Biz::OutputChannel->new({
        name    => 'Test XHTML',
        site_id => 100,
    }), "Create an output channel";
    ok $oc->save, "Save the new output channel";
    $self->add_del_ids($oc->get_id, 'output_channel');
    ok $oc->add_includes($suboc), "Add an include OC";
    ok $oc->save, "Save the new output channel with its includes";

    # Create a story type.
    ok my $story_type = Bric::Biz::AssetType->new({
        key_name  => '_testing_',
        name      => 'Testing',
        burner    => $burner_type,
        type__id  => $story_et->get_id,
        reference => 0, # No idea what this is.
    }), "Create story type";
    ok $story_type->add_site(100), "Add the site ID";
    ok $story_type->add_output_channels([$oc]), "Add the output channel";
    ok $story_type->set_primary_oc_id($oc->get_id, 100),
      "Set it as the primary OC";;
    ok $story_type->save, "Save the test story type";
    $self->add_del_ids($story_type->get_id, 'element');

    # Give it a header field.
    ok my $head = $story_type->new_data({
        key_name    => 'header',
        required    => 0,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 1,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a paragraph field.
    ok my $para = $story_type->new_data({
        key_name    => 'para',
        required    => 0,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 2,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Save the story type with its fields.
    ok $story_type->save, "Save element with the fields";
    $self->add_del_ids($head->get_id, 'at_data');
    $self->add_del_ids($para->get_id, 'at_data');

    # Create a subelement.
    ok my $pull_quote = Bric::Biz::AssetType->new({
        key_name  => '_pull_quote_',
        name      => 'Pull Quote',
        burner    => $burner_type,
        type__id  => $sub_et->get_id,
        reference => 0, # No idea what this is.
    }), "Create a subelement element";

    ok $pull_quote->save, "Save the subelement element";
    $self->add_del_ids($pull_quote->get_id, 'element');

    # Give it a paragraph field.
    ok my $pq_para = $pull_quote->new_data({
        key_name    => 'para',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 1,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a by field.
    ok my $by = $pull_quote->new_data({
        key_name    => 'by',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 2,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a date field.
    ok my $date = $pull_quote->new_data({
        key_name    => 'date',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'date',
        place       => 3,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Save the pull quote with its fields.
    ok $pull_quote->save, "Save subelement with the fields";
    $self->add_del_ids($pq_para->get_id, 'at_data');
    $self->add_del_ids($by->get_id, 'at_data');
    $self->add_del_ids($date->get_id, 'at_data');

    # Add the subelement.
    ok $story_type->add_containers([$pull_quote->get_id]),
      "Add the subelement";

    # Now let's create some templates for these bad boys! Start with the
    # story template.
    my $file = $fs->cat_file(dirname(__FILE__), $dir, "story.$suffix");
    open my $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $story_tmpl = Bric::Biz::Asset::Formatting->new({
        output_channel => $oc,
        user__id       => $self->user_id,
        category_id    => 1,
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Formatting::ELEMENT_TEMPLATE,
        element        => $story_type,
        data           => join('', <$fh>),
    }), "Create a story template";

    ok( $story_tmpl->save, "Save template" );
    $self->add_del_ids($story_tmpl->get_id, 'formatting');
    close $fh;

    # Now the subelement template.
    $file = $fs->cat_file(dirname(__FILE__), $dir, "pull_quote.$suffix");
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $pq_tmpl = Bric::Biz::Asset::Formatting->new({
        output_channel => $suboc, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => $cat->get_id, # Put it in a subcategory
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Formatting::ELEMENT_TEMPLATE,
        element        => $pull_quote,
        data           => join('', <$fh>),
    }), "Create a pull quote template";
    ok( $pq_tmpl->save, "Save pull quote template" );
    $self->add_del_ids($pq_tmpl->get_id, 'formatting');
    close $fh;

    # And how about a category template?
    my $cat_tmpl_fn = Bric::Util::Burner->cat_fn_for_ext($suffix);
    $cat_tmpl_fn .= ".$suffix" if  Bric::Util::Burner->cat_fn_has_ext($suffix);
    $file = $fs->cat_file(dirname(__FILE__), $dir, $cat_tmpl_fn);
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $cat_tmpl = Bric::Biz::Asset::Formatting->new({
        output_channel => $suboc, # Put it in the contained OC.
        user__id       => $self->user_id,
        category_id    => 1,
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Formatting::CATEGORY_TEMPLATE,
        data           => join('', <$fh>),
    }), "Create a category template";
    ok( $cat_tmpl->save, "Save category template" );
    $self->add_del_ids($cat_tmpl->get_id, 'formatting');
    close $fh;

    # And I think a utility template might be handy.
    $file = $fs->cat_file(dirname(__FILE__), $dir, "util.$suffix");
    open $fh, '<', $file or die "Cannot open '$file': $!\n";
    ok my $util_tmpl = Bric::Biz::Asset::Formatting->new({
        output_channel => $suboc, # Put it in the contained OC.
        user__id       => $self->user_id,
        name           => "util.$suffix",
        category_id    => $subcat->get_id, # Bury it!
        site_id        => 100,
        tplate_type    => Bric::Biz::Asset::Formatting::UTILITY_TEMPLATE,
        data           => join('', <$fh>),
    }), "Create a utility template";
    ok( $util_tmpl->save, "Save utility template" );
    $self->add_del_ids($util_tmpl->get_id, 'formatting');
    close $fh;

    # Now, create a burner, check the syntax, and deploy these templates.
    ok my $burner = Bric::Util::Burner->new({
        comp_dir  => $fs->cat_dir(TEMP_DIR, 'comp'),
        base_path => $fs->cat_dir(TEMP_DIR, 'base'),
    }), "Create burner";

    for my $tmpl ($story_tmpl, $pq_tmpl, $cat_tmpl, $util_tmpl) {
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
        user__id    => $self->user_id,
        site_id     => 100,
        element__id => $story_type->get_id,
        source__id  => 1,
        title       => 'This is a Test',
        slug        => 'test_burn',
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
    ok $elem->add_data($para, 'Third paragraph'), "Add a third paragraph";

    # Add a pull quote.
    ok my $pq = $elem->add_container($pull_quote), "Add a pull quote";
    ok $pq->get_data_element('para')->set_data(
        'Ask not what your country can do for you. '
          . 'Ask what you can do for your country.'
    ), "Add a paragraph to the pull quote";
    ok $pq->get_data_element('by')->set_data("John F. Kennedy"),
      "Add a By to the pull quote";
    ok $pq->get_data_element('date')->set_data('1961-01-20 00:00:00'),
      "Add a date to the pull quote";

    # Make it so!
    ok $elem->save, "Save the story element";
    # Allow localization by creating a language object.
    isa_ok(Bric::Util::Language->get_handle('en-us'),
           'Bric::Util::Language::en_us');
    $self->trap_stderr;

    # Mock the user so that event logging works properly.
    my $event = Test::MockModule->new('Bric::App::Event');
    my $user = Bric::Biz::Person::User->lookup({ id => $self->user_id });
    $event->mock(get_user_object => $user);

    # Set up the component root for the preview.
    $self->{comp_root} = Bric::Util::Burner::MASON_COMP_ROOT->[0][1];
      Bric::Util::Burner::MASON_COMP_ROOT->[0][1] = TEMP_DIR;

    # Make sure that the file doesn't already exist.
    $file = $fs->cat_file(TEMP_DIR, 'base',
                          $fs->uri_to_dir($story->get_primary_uri), '',
                          $oc->get_filename . '.' . $oc->get_file_ext);
    ok !-e $file, "File should not yet exist";

    # Now burn it!
    ok my ($res) = $burner->burn_one($story, $oc, $subcat), "Burn the story";
    is $res->get_path, $file, "Check te file location";

    # Now we should have a file!
    ok -e $file, "File should now exist" or return "Failed to create $file!";

    # So now let's take a look at that bad boy.
    file_contents_is($file, $self->story_output, "Check the file contents");
}

sub restore_comp_root : Test(teardown) {
    my $self = shift;
    Bric::Util::Burner::MASON_COMP_ROOT->[0][1] = delete $self->{comp_root}
      if exists $self->{comp_root};
}

sub story_output {
    return q{<html><head>
<title>This is a Test</title>
</head><body>
<h1>This is a Test</h1>
<p>This is a paragraph</p>
<p>Second paragraph</p>
<p>Third paragraph</p>
<blockquote>
<p>Ask not what your country can do for you. Ask what you can do for your country.</p>
<p>--John F. Kennedy, 1961.01.20</p>
</blockquote>
<div>Licensed under the BSD license</div>
</body></html>
}
}

1;
__END__
