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
use Bric::Config qw(:temp);

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
    ok( my $cat = Bric::Biz::Category->new({ name => 'TmplTest',
                                             parent_id => 0,
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

1;
__END__
