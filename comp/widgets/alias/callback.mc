<%once>;
my %classes = ( story => get_package_name('story'),
                media => get_package_name('media'),
              );

my %dispmap = ( story => get_disp_name('story'),
                media => get_disp_name('media')
              );
</%once>
<%args>
$widget
$field
$param
</%args>
<%init>;
# Pull it together.
my $class_key = get_state_data($widget, 'class_key');
my $wf_id = get_state_data($widget, 'wf_id');
my $wf = Bric::Biz::Workflow->lookup({ id => $wf_id });
my $gid = $wf->get_all_desk_grp_id;
my $site_id = $wf->get_site_id;
my $site = Bric::Biz::Site->lookup({ id => $site_id });
if ($field eq "$widget|make_alias_cb") {
    my $aliased_id = $param->{$field};
    my $aliased = $classes{$class_key}->lookup({ id => $aliased_id });

    # Check permissions. Users must have READ permission to the asset to be
    # aliased and CREATE permission to create the alias asset.
    chk_authz($aliased, READ);
    chk_authz($classes{$class_key}, CREATE, 0, $site_id, $gid);

    # Make sure they're not try to create an alias to an asset in the same
    # site.
    if ($aliased->get_site_id == $site_id) {
        add_msg($lang->maketext("Cannot create an alias to a " .
                                "$dispmap{$class_key} in the same site"));
        return;
    }

    # If we got here, we'll let 'em create the alias. But first, let's see if
    # there are any related assets that they might want to alias, as well.
    set_state_data($widget, 'aliased_id', $aliased_id);
    set_redirect("/workflow/profile/alias/pick_cats.html");
    return;
} elsif ($field eq "$widget|pick_cats_cb") {
    my $aliased_id = get_state_data($widget, 'aliased_id');
    my $aliased = $classes{$class_key}->lookup({ id => $aliased_id });

    my $cat_ids = mk_aref($param->{category_id});
    my $ba = $classes{$class_key}->new({ site_id  => $site_id,
                                         alias_id => $aliased_id,
                                         user__id => get_user_id
                                       });

    # Set up the category.
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
    $ba->save;

    # Move it into workflow.
    $ba->set_workflow_id($wf_id);
    my $start_desk = $wf->get_start_desk;
    $start_desk->accept({ asset => $ba });
    $start_desk->save;

    # Log that we've created this new alias and moved it into workflow.
    my $origin_site = Bric::Biz::Site->lookup({ id => $ba->get_site_id });
    log_event("$class_key\_alias_new", $ba, { 'From Site' => $origin_site->get_name });
    log_event("story_add_category", $ba, { Category => $cat->get_name })
      if $class_key eq 'story';
    log_event("$class_key\_add_workflow", $ba, { Workflow => $wf->get_name });
    log_event("$class_key\_moved", $ba, { Desk => $start_desk->get_name });
    log_event("$class_key\_save", $ba);

    # Log that the original asset was aliased.
    log_event("$class_key\_aliased", $aliased, { 'To Site' => $site->get_name });

    # Let 'em know what we've done.
    add_msg($lang->maketext("$dispmap{$class_key} [_1] created and saved.",
                            "&quot;" . $ba->get_title . "&quot;"));

    # Add it to the profile's session.
    set_state_name("$class_key\_prof", 'edit');
    set_state_data("$class_key\_prof", $class_key, $ba);

    # Head for the main edit screen.
    set_redirect("/workflow/profile/$class_key/");
}
</%init>
