<%args>
$widget
$field
$param
</%args>

<%once>
###############
## Constants ##
my $SEARCH_URL = '/workflow/manager/story/';
my $ACTIVE_URL = '/workflow/active/story/';
my $DESK_URL = '/workflow/profile/desk/';

####################
## Misc Functions ##

my $save_data = sub {
    my ($param, $widget, $story) = @_;
    my $data_errors = 0;

    $story ||= get_state_data($widget, 'story');
    chk_authz($story, EDIT);

    if ($param->{'slug'}) {
	# check the form of the slug
	if ($param->{'slug'} =~ m/\W/) {
	    add_msg('Slug must conform to URI character rules.');
	    $data_errors = 1;
	} else {
	    $story->set_slug($param->{slug});
	}
    }

    $story->set_title($param->{title})
      if exists $param->{title};
    $story->set_description($param->{description})
      if exists $param->{description};
    $story->set_source__id($param->{"$widget|source_id"})
      if exists $param->{"$widget|source_id"};
    $story->set_priority($param->{priority})
      if exists $param->{priority};
    $story->set_cover_date($param->{cover_date})
      if exists $param->{cover_date};

    if ($param->{'cover_date-partial'}) {
	add_msg('Cover Date incomplete.');
	$data_errors = 1;
    }

    $story->set_expire_date($param->{expire_date})
      if exists $param->{expire_date};

    if ($param->{'expire_date-partial'}) {
	add_msg('Expire Date incomplete.');
	$data_errors = 1;
    }

    $story->set_primary_category($param->{"$widget|primary_cat"})
      if defined $param->{"$widget|primary_cat"};

    return not $data_errors;
};

#######################
## Callback Handlers ##

my $handle_delete = sub {
    my $story = shift;
    my $desk = $story->get_current_desk();
    $desk->checkin($story);
    $desk->remove_asset($story);
    $desk->save;
    log_event("story_rem_workflow", $story);
    $story->deactivate;
    $story->save;
    log_event("story_deact", $story);
    add_msg("Story &quot;" . $story->get_title . "&quot; deleted.");
};

################################################################################

my $handle_view = sub {
	my ($widget, $field, $param, $story, $new) = @_;

	$story ||= get_state_data($widget, 'story');

	# Abort this save if there were any errors.
	return unless &$save_data($param, $widget, $story);

	my $version = $param->{"$widget|version"};
	my $id = $story->get_id();

	set_redirect("/workflow/profile/story/$id/?version=$version");
};

################################################################################

my $handle_revert = sub {
	my ($widget, $field, $param, $story, $new) = @_;

	$story ||= get_state_data($widget, 'story');

	my $version = $param->{"$widget|version"};

	$story->revert($version);

	$story->save();
+	add_msg("Story &quot;" . $story->get_title . "&quot; reverted to V.$version.");

	clear_state($widget);

};

################################################################################

my $handle_save = sub {
    my ($widget, $field, $param, $story, $new) = @_;
    $story ||= get_state_data($widget, 'story');

    # Abort this save if there were any errors.
    return unless &$save_data($param, $widget, $story);

    my $work_id = get_state_data($widget, 'work_id');

    if ($work_id) {
	# Set the workflow this story should be in.
	$story->set_workflow_id($work_id);
	$story->activate;

#	$story->checkin();
#	$story->save();
#	$story->checkout( { user__id => get_user_id });

	# Figure out what desk this story should be in.
	my $wf = Bric::Biz::Workflow->lookup({'id' => $work_id});
	log_event('story_add_workflow', $story, { Workflow => $wf->get_name });

	# Send this story to the first desk.
	my $start_desk = $wf->get_start_desk;
	$start_desk->accept({'asset' => $story});
	$start_desk->save;
	log_event('story_moved', $story, { Desk => $start_desk->get_name });
    }

    if ($param->{"$widget|delete"}) {
	# Delete the story.
	$handle_delete->($story);
    } else {
	# Make sure the story is activated and then save it.
	$story->activate;
	$story->save;
	log_event(($new ? 'story_create' : 'story_save'), $story);
	add_msg("Story &quot;" . $story->get_title . "&quot; saved.");
    }

    my $return = get_state_data($widget, 'return') || '';

    # Clear the state and send 'em home.
    clear_state($widget);

	if ($return eq 'search') {
		my $workflow_id = $story->get_workflow_id();
		my $url = $SEARCH_URL . $workflow_id . '/';
		set_redirect($url);
	} elsif ($return eq 'active') {
		my $workflow_id = $story->get_workflow_id();
		my $url = $ACTIVE_URL . $workflow_id;
		set_redirect($url);
	} elsif ($return =~ /\d+/) {
		my $workflow_id = $story->get_workflow_id();
		my $url = $DESK_URL . $workflow_id . '/' . $return . '/';
		set_redirect($url);
	} else {
    	set_redirect("/");
	}
};

################################################################################

my $handle_checkin = sub {
	my ($widget, $field, $param, $story, $new) = @_;

	$story ||= get_state_data($widget, 'story');

	# Abort this save if there were any errors.
	return unless &$save_data($param, $widget, $story);

	my $work_id = get_state_data($widget, 'work_id');

	if ($work_id) {
		# Set the workflow this story should be in.
		$story->set_workflow_id($work_id);
		my $wf = Bric::Biz::Workflow->lookup( { id => $work_id });
		log_event('story_add_workflow', $story, { Workflow => $wf->get_name });
	}

	$story->checkin();

	# figure out the desk this should go to
	my $desk_id = $param->{"$widget|desk"};

	my $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ id => $desk_id });

	my $cur_desk = $story->get_current_desk();

	my $no_log;
	if ($cur_desk) {
		if ($cur_desk->get_id() == $desk_id) {
			$no_log = 1;
		} else {
			$cur_desk->transfer( { 
				to 		=> $desk,
				asset	=> $story
			});
			$cur_desk->save();
		}
	} else {
		# Send this story to the first desk.
		$desk->accept({'asset' => $story});
	}
	$desk->save;
	my $dname = $desk->get_name;
	log_event('story_moved', $story, { Desk => $dname }) unless $no_log;

	# make sure that the story is active
	$story->save();

	log_event(($new ? 'story_create' : 'story_save'), $story);
	log_event('story_checkin', $story);

	# Clear the state out.
	clear_state($widget);

	# Set the redirect to the page we were at before here.
	set_redirect("/");

	add_msg("Story &quot;" . $story->get_title . "&quot; saved and moved to"
	        . " &quot;$dname&quot;.");
};

################################################################################

my $handle_save_stay = sub {
    my ($widget, $field, $param, $story, $new) = @_;

    $story ||= get_state_data($widget, 'story');

    # Abort this save if there were any errors.
    return unless &$save_data($param, $widget, $story);

    my $work_id = get_state_data($widget, 'work_id');

    if ($work_id) {
        # Set the workflow this story should be in.
        $story->set_workflow_id($work_id);

        $story->checkin();
        $story->save();
        $story->checkout( { user__id => get_user_id });

        # Figure out what desk this story should be in.
        my $wf = Bric::Biz::Workflow->lookup({'id' => $work_id});
        log_event('story_add_workflow', $story, { Workflow => $wf->get_name });

        # Send this story to the first desk.
        my $start_desk = $wf->get_start_desk;
        $start_desk->accept({'asset' => $story});
        $start_desk->save;
        log_event('story_moved', $story, { Desk => $start_desk->get_name });
    }

    if ($param->{"$widget|delete"}) {
	# Delete the story.
	$handle_delete->($story);
	# Get out of here, since we've blow it away!
	set_redirect("/");
	clear_state($widget);
    } else {
	# Make sure the story is activated and then save it.
	$story->activate;
	$story->save;
	log_event(($new ? 'story_create' : 'story_save'), $story);
	add_msg("Story &quot;" . $story->get_title . "&quot; saved.");
	set_state_data($widget, 'work_id', '');
    }
};

################################################################################

my $handle_cancel = sub {
    my ($widget, $field, $param) = @_;
    my $story = get_state_data($widget, 'story');
    $story->cancel_checkout();
    $story->save();
    log_event('story_cancel_checkout', $story);
    clear_state($widget);
    set_redirect("/");
    add_msg("Story &quot;" . $story->get_title . "&quot; check out canceled.");
};

################################################################################

my $handle_workspace_return = sub {
    my ($widget, $field, $param) = @_;
    my $version_view = get_state_data($widget, 'version_view');

	my $story = get_state_data($widget, 'story');

    if ($version_view) {
	my $story_id = $story->get_id();
	clear_state($widget);
	set_redirect("/workflow/profile/story/$story_id/?checkout=1");
    } else {
	my $url;
	my $return = get_state_data($widget, 'return') || '';
	my $wid = $story->get_workflow_id;

	if ($return eq 'search') {
	    $wid = get_state_data('workflow', 'work_id') || $wid;
	    $url = $SEARCH_URL . $wid . '/';
	} elsif ($return eq 'active') {
	    $url = $ACTIVE_URL . $wid;
	} elsif ($return =~ /\d+/) {
	    $url = $DESK_URL . $wid . '/' . $return . '/';
	} else {
	    $url = '/';
	}

    	# Clear the state and send 'em home.
    	clear_state($widget);
    	set_redirect($url);
    }
};

################################################################################

my $handle_create = sub {
    my ($widget, $field, $param) = @_;

    # Check permissions.
    my $work_id = get_state_data($widget, 'work_id');
    my $gid = Bric::Biz::Workflow->lookup({ id => $work_id })->get_all_desk_grp_id;
    chk_authz('Bric::Biz::Asset::Business::Story', CREATE, 0, $gid);

    my $init = {element__id => $param->{"$widget|at_id"},
		source__id  => $param->{"$widget|source__id"},
		user__id    => get_user_id };

    if ($param->{'slug'}) {
        # check the form of the slug
        if ($param->{'slug'} =~ m/\W/) {
            add_msg('Slug must conform to URI character rules.');
	    return;
	}
    }

    # Create a new story with the initial values given.
    my $story = Bric::Biz::Asset::Business::Story->new($init);

    # Set the primary category
    my $cid = $param->{"$widget|new_category_id"};
    my $cat_event;
    if (defined $cid) {
	$story->add_categories([$cid]);
	$story->set_primary_category($cid);
	my $cat = Bric::Biz::Category->lookup({ id => $cid });
	$cat_event = sub {
	    log_event('story_add_category', $story,
		      { Category => $cat->get_name })
	};
    }

    # Save everything else unless there were data errors
    return unless &$save_data($param, $widget, $story);

    # Keep the story deactivated until they hit save.
    $story->deactivate;
    $story->save;

    # Log that a new story has been created and a category added.
    log_event('story_new', $story);
    &$cat_event() if $cat_event;

    set_state_data($widget, 'story', $story);

    # Head for the main edit screen.
    set_redirect("/workflow/profile/story/");

    # As far as history is concerned, this page should be part of the story
    # profile stuff.
    pop_page;
};

################################################################################

my $handle_notes = sub {
    my ($widget, $field, $param) = @_;

    # Return if there were data errors.
    return unless &$save_data($param, $widget);

    my $story = get_state_data($widget, 'story');
    my $id    = $story->get_id();
    my $action = $param->{$widget.'|notes_cb'};
    set_redirect("/workflow/profile/story/${action}_notes.html?id=$id");
};

################################################################################

my $handle_delete_cat = sub {
    my ($widget, $field, $param) = @_;
    my $cat_ids = mk_aref($param->{"$widget|delete_cat"});
    my $story = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    $story->delete_categories($cat_ids);
    $story->save;

    # Log events.
    foreach my $cid (@$cat_ids) {
	my $cat = Bric::Biz::Category->lookup({ id => $cid });
	log_event('story_del_category', $story, { Category => $cat->get_name });
	add_msg("Category &quot;" . $cat->get_name . "&quot; disassociated.");
    }
    set_state_data($widget, 'story', $story);
};

################################################################################

my $handle_update_primary = sub {
    my ($widget, $field, $param) = @_;
    my $story   = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    my $primary = $param->{"$widget|primary_cat"};
    $story->set_primary_category($primary);
    $story->save();
    set_state_data($widget, 'story', $story);
};

################################################################################

my $handle_add_category = sub {
    my ($widget, $field, $param) = @_;
    my $story = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    my $cat_id = $param->{"$widget|new_category_id"};
    if (defined $cat_id) {
	$story->add_categories([ $cat_id ]);
	$story->save();
	my $cat = Bric::Biz::Category->lookup({ id => $cat_id });
	log_event('story_add_category', $story, { Category => $cat->get_name });
	add_msg("Category &quot;" . $cat->get_name . "&quot; added.");
    }
    set_state_data($widget, 'story', $story);
};

################################################################################

my $handle_view_notes = sub {
    my ($widget, $field, $param) = @_;
    my $story = get_state_data($widget, 'story');
    my $id = $story->get_id();
    set_redirect("/workflow/profile/story/comments.html?id=$id");
};

################################################################################

my $handle_trail = sub {
    my ($widget, $field, $param) = @_;

    # Return if there were data errors
    return unless &$save_data($param, $widget);

    my $story = get_state_data($widget, 'story');
    my $id = $story->get_id();
    set_redirect("/workflow/trail/story/$id");
};

################################################################################

my $handle_view_trail = sub {
    my ($widget, $field, $param) = @_;
    my $story = get_state_data($widget, 'story');
    my $id = $story->get_id();
    set_redirect("/workflow/trail/story/$id");
};

################################################################################

my $handle_update = sub {
    my ($widget, $field, $param) = @_;
    &$save_data($param, $widget);
};

################################################################################

my $handle_keywords = sub {
    my ($widget, $field, $param) = @_;

    # Return if there were data errors
    return unless &$save_data($param, $widget);

    my $story = get_state_data($widget, 'story');
    my $id = $story->get_id();
    set_redirect("/workflow/profile/story/keywords.html");
};

################################################################################

my $handle_contributors = sub {
    my ($widget, $field, $param) = @_;

    # Return if there were data errors
    return unless &$save_data($param, $widget);
    set_redirect("/workflow/profile/story/contributors.html");
};

################################################################################

my $handle_assoc_contrib = sub {
    my ($widget, $field, $param) = @_;
    my $story = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    my $contrib_id = $param->{$field};
    my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup({'id' => $contrib_id});
    my $roles = $contrib->get_roles;
    if (scalar(@$roles)) {
	set_state_data($widget, 'contrib', $contrib);
	set_redirect("/workflow/profile/story/contributor_role.html");
    } else {
	$story->add_contributor($contrib);
	log_event('story_add_contrib', $story, { Name => $contrib->get_name });
#	add_msg("Contributor &quot;" . $contrib->get_name . "&quot; associated.");
    }
};

################################################################################

my $handle_assoc_contrib_role = sub {
    my ($widget, $field, $param) = @_;
    my $story   = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    my $contrib = get_state_data($widget, 'contrib');
    my $role    = $param->{$widget.'|role'};

    # Add the contributor
    $story->add_contributor($contrib, $role);
    log_event('story_add_contrib', $story, { Name => $contrib->get_name });

    # Go back to the main contributor pick screen.
    set_redirect(last_page);
#    add_msg("Contributor &quot;" . $contrib->get_name . "&quot; associated.");

    # Remove this page from the stack.
    pop_page;
};

################################################################################

my $handle_unassoc_contrib = sub {
    my ($widget, $field, $param) = @_;
    my $story = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    my $cids = mk_aref($param->{$field});
    $story->delete_contributors($cids);

    # Log the dissocitations.
    foreach my $cid (@$cids) {
	my $c = Bric::Util::Grp::Parts::Member::Contrib->lookup({'id' => $cid });
	log_event('story_del_contrib', $story, { Name => $c->get_name });
#	add_msg("Contributor &quot;" . $contrib->get_name . "&quot; disassociated.");
    }
};

################################################################################

my $save_contrib = sub {
    my ($widget, $param) = @_;

    # get the contribs to delete
    my $story = get_state_data($widget, 'story');

    my $existing = { map { $_->get_id => 1 } $story->get_contributors };

    chk_authz($story, EDIT);
    my $contrib_id = $param->{$widget.'|delete_id'};
    my $msg;
    if ($contrib_id) {
        if (ref $contrib_id) {
            $story->delete_contributors($contrib_id);
            foreach (@$contrib_id) {
                my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup(
                    { id => $_ });
		delete $existing->{$_};
		log_event('story_del_contrib', $story,
			  { Name => $contrib->get_name });
            }
            add_msg('Contributors disassociated.');
        } else {
            $story->delete_contributors([$contrib_id]);
            my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup(
                { id => $contrib_id });
	    delete $existing->{$contrib_id};
	    log_event('story_del_contrib', $story,
		      { Name => $contrib->get_name });
            add_msg('Contributor &quot;' . $contrib->get_name .
		    "&quot; disassociated.");
        }
    }

    # get the remaining
    # and reorder
    foreach (keys %$existing) {
	my $key = $widget . '|reorder_' . $_;
	my $place = $param->{$key};
	$existing->{$_} = $place;
    }
    my @no = sort { $existing->{$a} <=> $existing->{$b} } keys %$existing;
    $story->reorder_contributors(@no);

    # and that's that
};

##############################################################################

my $handle_save_contrib = sub {
        my ($widget, $field, $param) = @_;

        $save_contrib->($widget, $param);

        # Set a redirect for the previous page.
    set_redirect(last_page);
    # Pop this page off the stack.
    pop_page;
};

##############################################################################i

my $handle_save_and_stay_contrib = sub {
        my ($widget, $field, $param) = @_;

    $save_contrib->($widget, $param);

};



###############################################################################

my $handle_leave_contrib = sub {
    my ($widget, $field, $param) = @_;
    # Set a redirect for the previous page.
    set_redirect(last_page);
    # Pop this page off the stack.
    pop_page;
};

################################################################################

my $handle_exit = sub {
    my ($widget, $field, $param) = @_;
    set_state($widget, {});
    # Set the redirect to the page we were at before here.
    set_redirect(last_page || "/workflow/search/story/");
    # Remove this page from history.
    pop_page;
};

################################################################################

my $handle_add_kw = sub {
    my ($widget, $field, $param) = @_;

    # Grab the story.
    my $story = get_state_data($widget, 'story');
    chk_authz($story, EDIT);

    # Add new keywords.
    my $new;
    foreach (@{ mk_aref($param->{keyword}) }) {
	next unless $_;
	my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
	$kw ||= Bric::Biz::Keyword->new({ name => $_})->save;
	push @$new, $kw;
    }
    $story->add_keywords($new) if $new;

    # Delete old keywords.
    $story->delete_keywords(mk_aref($param->{del_keyword}))
      if defined $param->{del_keyword};

    # Save the changes
    set_state_data($widget, 'story', $story);

    set_redirect(last_page);

    add_msg("Keywords saved.");

    # Take this page off the stack.
    pop_page;
};

################################################################################

my $handle_checkout = sub {
    my ($widget, $field, $param) = @_;
    my $ids = $param->{$field};
    $ids = ref $ids ? $ids : [$ids];

    foreach (@$ids) {
	my $ba = Bric::Biz::Asset::Business::Story->lookup({'id' => $_});
	if (chk_authz($ba, EDIT, 1)) {
	    $ba->checkout({'user__id' => get_user_id});
	    $ba->save;

	    # Log Event.
	    log_event('story_checkout', $ba);
	} else {
	    add_msg("Permission to checkout &quot;" . $ba->get_name . "&quot; denied");
	}
    }

    if (@$ids > 1) {
	# Go to 'my workspace'
	set_redirect("/");
    } else {
	# Go to the profile screen
	set_redirect('/workflow/profile/story/'.$ids->[0].'?checkout=1');
    }
};

################################################################################

my $handle_recall = sub {
    my ($widget, $field, $param) = @_;
    my $ids = $param->{$widget.'|recall_cb'};
    $ids = ref $ids ? $ids : [$ids];
    my %wfs;

    foreach (@$ids) {
	my ($o_id, $w_id) = split('\|', $_);
	my $ba = Bric::Biz::Asset::Business::Story->lookup({'id' => $o_id});
	if (chk_authz($ba, EDIT, 1)) {
	    my $wf = $wfs{$w_id} ||= Bric::Biz::Workflow->lookup({'id' => $w_id});

	    # Make sure the workflow ID is valid.
	    unless ($w_id) {
		my $msg = "Bad Workflow ID '$w_id'";
		die Bric::Util::Fault::Exception::DP->new({'msg' => $msg});
	    }

	    # Put this formatting asset into the current workflow and log it.
	    $ba->set_workflow_id($w_id);
	    log_event('story_add_workflow', $ba, { Workflow => $wf->get_name });

	    # Get the start desk for this workflow.
	    my $start_desk = $wf->get_start_desk;

	    # Put this formatting asset on to the start desk.
	    $start_desk->accept({'asset' => $ba});
	    $start_desk->checkout($ba, get_user_id);
	    $start_desk->save;
	    log_event('story_moved', $ba, { Desk => $start_desk->get_name });
	} else {
	    add_msg("Permission to checkout &quot;" . $ba->get_name
		    . "&quot; denied");
	}
    }

    if (@$ids > 1) {
	# Go to 'my workspace'
	set_redirect("/");
    } else {
	my ($o_id, $w_id) = split('\|', $ids->[0]);
	# Go to the profile screen
	set_redirect('/workflow/profile/story/'.$o_id.'?checkout=1');
    }
};


###########################
## Callbacks Definitions ##

my %cbs = (
	   create_cb                => $handle_create,
	   workspace_return_cb      => $handle_workspace_return,
	   notes_cb                 => $handle_notes,
	   delete_cat_cb            => $handle_delete_cat,
	   update_primary_cb        => $handle_update_primary,
	   add_category_cb          => $handle_add_category,
	   view_notes_cb            => $handle_view_notes,
	   trail_cb                 => $handle_trail,
	   view_trail_cb            => $handle_view_trail,
	   update_pc                => $handle_update,
	   keywords_cb              => $handle_keywords,
	   contributors_cb          => $handle_contributors,
	   assoc_contrib_cb         => $handle_assoc_contrib,
	   assoc_contrib_role_cb    => $handle_assoc_contrib_role,
	   unassoc_contrib_cb       => $handle_unassoc_contrib,
	   leave_contrib_cb         => $handle_leave_contrib,
	   save_cb                  => $handle_save,
	   exit_cb                  => $handle_exit,
	   add_kw_cb                => $handle_add_kw,
	   checkout_cb              => $handle_checkout,
	   recall_cb                => $handle_recall,
	   cancel_cb		    => $handle_cancel,
	   view_cb		    => $handle_view,
	   revert_cb		    => $handle_revert,
	   save_and_stay_cb	    => $handle_save_stay,
	   return_cb		    => $handle_workspace_return,
	   checkin_cb		    => $handle_checkin,
	   save_contrib_cb          => $handle_save_contrib,
	   save_and_stay_contrib_cb => $handle_save_and_stay_contrib,
	  );
</%once>

<%init>;
my ($cb) = substr($field, length($widget)+1);
# Execute the call back if it exists.
if (exists $cbs{$cb}) {
    $cbs{$cb}->($widget, $field, $param);
} else {
    die "No callback for $cb\n";
}
</%init>
