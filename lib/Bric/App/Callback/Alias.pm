package Bric::App::Callback::Alias;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'alias';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Session qw(:state :user);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
use Bric::Biz::Asset;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Category;
use Bric::Biz::Site;
use Bric::Biz::Workflow;
use Bric::Util::Fault qw(:all);
use Bric::Util::Priv::Parts::Const qw(READ CREATE);

my %classes = (
    story => 'Bric::Biz::Asset::Business::Story',
    media => 'Bric::Biz::Asset::Business::Media',
);

my %dispmap = (
    story => 'Story',
    media => 'Media',
);

my ($get_dynamic, $work_it, $handle_asset);


sub make_alias : Callback {
    my $self = shift;
    my ($class_key, $wf_id, $wf, $gid, $site_id, $site) = $get_dynamic->($self);

    my $aliased_id = $self->value;
    my $aliased = $classes{$class_key}->lookup({ id => $aliased_id });

    # Check permissions. Users must have READ permission to the asset to be
    # aliased and CREATE permission to create the alias asset.
    chk_authz($aliased, READ);
    chk_authz($classes{$class_key}, CREATE, 0, $site_id, $gid);

    # If we got here, we'll let 'em create the alias. But first, let's see if
    # there are any related assets that they might want to alias, as well.
    set_state_data($self->class_key, 'aliased_id', $aliased_id);
    $self->set_redirect("/workflow/profile/alias/pick_cats.html");
    return;
}

sub pick_cats : Callback {
    my $self = shift;
    my $param = $self->params;
    my ($class_key, $wf_id, $wf, $gid, $site_id, $site) = $get_dynamic->($self);

    # Grab the asset to be aliased.
    my $aliased_id = get_state_data($self->class_key, 'aliased_id');
    my $aliased = $classes{$class_key}->lookup({ id => $aliased_id });

    # Alias it.
    my $ba = $classes{$class_key}->new({ site_id  => $site_id,
                                         alias_id => $aliased_id,
                                         user__id => get_user_id(),
                                       });
    # Set up the category.
    my $cat_ids = mk_aref($param->{'category_id'});
    my $cid = shift @$cat_ids;
    my $cat;
    if ($class_key eq 'story') {
        $ba->delete_categories(scalar $ba->get_categories);
        $ba->add_categories([$cid]);
        $ba->set_primary_category($cid);
        $cat = Bric::Biz::Category->lookup({ id => $cid });
    } else {
        $ba->set_category__id($cid);
    }

    # Save it and move it into workflow.
    $ba->save();
    $work_it->($class_key, $site, $ba, $wf_id, $wf, $aliased, $cat, $self);

    # Add it to the profile's session.
    set_state_name("$class_key\_prof", 'edit');
    set_state_data("$class_key\_prof", $class_key, $ba);

    # Prepare to head for the main edit screen.
    $self->set_redirect("/workflow/profile/$class_key/");

    $handle_asset->('story', $param, $cat_ids, $site_id, $self, $site, $wf_id, $wf);
    $handle_asset->('media', $param, $cat_ids, $site_id, $self, $site, $wf_id, $wf);
}


$get_dynamic = sub {
    my $self = shift;
    my $class_key = get_state_data($self->class_key, 'class_key');
    my $wf_id = get_state_data($self->class_key, 'wf_id');
    my $wf = Bric::Biz::Workflow->lookup({ id => $wf_id });
    my $gid = $wf->get_all_desk_grp_id();
    my $site_id = $wf->get_site_id();
    my $site = Bric::Biz::Site->lookup({ id => $site_id });
    return ($class_key, $wf_id, $wf, $gid, $site_id, $site);
};

$work_it = sub {
    my ($class_key, $site, $ba, $wf_id, $wf, $aliased, $cat, $self) = @_;

    # Move it into workflow.
    $ba->set_workflow_id($wf_id);
    my $start_desk = $wf->get_start_desk();
    $start_desk->accept({ 'asset' => $ba });
    $start_desk->save();

    # Log that we've created this new alias and moved it into workflow.
    my $origin_site = Bric::Biz::Site->lookup({ id => $aliased->get_site_id() });
    log_event("$class_key\_alias_new", $ba,
              { 'From Site' => $origin_site->get_name() });
    log_event("story_add_category", $ba, { 'Category' => $cat->get_name() })
      if $class_key eq 'story';
    log_event("$class_key\_add_workflow", $ba, { 'Workflow' => $wf->get_name() });
    log_event("$class_key\_moved", $ba, { 'Desk' => $start_desk->get_name() });
    log_event("$class_key\_save", $ba);

    # Log that the original asset was aliased.
    log_event("$class_key\_aliased", $aliased, { 'To Site' => $site->get_name() });

    # Let 'em know what we've done.
    $self->add_message('Alias to "[_1]" created and saved.', $ba->get_title);
};

$handle_asset = sub {
    my ($type, $param, $cat_ids, $site_id, $self, $site, $wf_id, $wf) = @_;
    my $cat = '';

    foreach my $id (@{ mk_aref($param->{"$type\_id"}) }) {
        # Get the category ID. If there isn't one, they don't want to
        # create an alias for this related story/media.
        my $cid = shift @$cat_ids or next;

        # Look up the story/media to be aliased and alias it.
        my $a = $classes{$type}->lookup({ 'id' => $id });
        my $ba = $classes{$type}->new({
            'site_id'  => $site_id,
            'alias_id' => $id,
            'user__id' => get_user_id(),
        });

        # Set up the category.
        if ($type eq 'story') {
            $ba->delete_categories(scalar $ba->get_categories());
            $ba->add_categories([$cid]);
            $ba->set_primary_category($cid);
            $cat = Bric::Biz::Category->lookup({ 'id' => $cid });
        } elsif ($type eq 'media') {
            $ba->set_category__id($cid);
        } else {
            throw_ap('error' => 'Unknown asset type');
        }

        # Save it and move it into workflow.
        $ba->save();
        $work_it->($type, $site, $ba, $wf_id, $wf, $a, $cat, $self);
    }
};

1;
