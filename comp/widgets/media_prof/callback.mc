<%args>
$widget
$field
$param
</%args>

<%once>
######################
## Constants        ##
######################
my $SEARCH_URL = '/workflow/manager/media/';
my $ACTIVE_URL = '/workflow/active/media/';
my $DESK_URL = '/workflow/profile/desk/';



#######################
## Callback Handlers ##
#######################

my $handle_update = sub {
    my ($widget, $field, $param, $WORK_ID) = @_;
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);

    # set the source
    $media->set_source__id($param->{"$widget|source__id"})
      if $param->{"$widget|source__id"};

	$media->set_category__id($param->{"$widget|category__id"})
		if $param->{"$widget|category__id"};

    # set the name
    $media->set_title($param->{title})
      if $param->{title};

    # set the description
    $media->set_description($param->{description})
      if $param->{description};

    $media->set_priority($param->{priority})
      if $param->{priority};

    # Set the dates.
    $media->set_cover_date($param->{cover_date})
      if $param->{cover_date};
    $media->set_expire_date($param->{expire_date})
      if $param->{expire_date};

    # check for file
    if ($param->{"$widget|file"} ) {
	my $upload = $r->upload();
	my $fh = $upload->fh();
	my $filename = Bric::Util::Trans::FS->base_name($upload->filename(),
	  $m->comp('/widgets/util/detectAgent.mc')->{os});
	$media->upload_file($fh, $filename);
	$media->set_size($upload->size);

	my $type          = $upload->type;
	my $media_type    = Bric::Util::MediaType->lookup({'name' => $type});
	my $media_type_id = $media_type ? $media_type->get_id : 0;

	$media->set_media_type_id($media_type_id);

	log_event('media_upload', $media);
    }
    set_state_data($widget, 'media', $media);
};

################################################################################

my $handle_delete = sub {
    my $media = shift;
    my $desk = $media->get_current_desk;
    $desk->checkin($media);
    $desk->remove_asset($media);
    $desk->save;
    log_event("media_rem_workflow", $media);
    $media->deactivate;
    $media->save;
    log_event("media_deact", $media);
    add_msg("Media &quot;" . $media->get_title . "&quot; deleted.");
};

################################################################################

my $handle_view = sub {
    my ($widget, $field, $param, $WORK_ID, $media) = @_;
    $media ||= get_state_data($widget, 'media');
    my $version = $param->{"$widget|version"};
    my $id = $media->get_id();
    set_redirect("/workflow/profile/media/$id/?version=$version");
};

################################################################################

my $handle_revert = sub {
    my ($widget, $field, $param, $WORK_ID, $media) = @_;
    $media ||= get_state_data($widget, 'media');
    my $version = $param->{"$widget|version"};
    $media->revert($version);
    $media->save();
    add_msg("Media &quot;" . $media->get_title . "&quot; reverted to V.$version.");
    clear_state($widget);
};

################################################################################

my $handle_save = sub {
    my ($widget, $field, $param, $WORK_ID, $media) = @_;
    $media ||= get_state_data($widget, 'media');
    chk_authz($media, EDIT);
    my $work_id = get_state_data($widget, 'work_id');

    if ($work_id) {
	$media->set_workflow_id($work_id);

	# Figure out what desk this story should be in.
	my $wf = Bric::Biz::Workflow->lookup({'id' => $work_id});
	log_event('media_add_workflow', $media, { Workflow => $wf->get_name });

	my $start_desk = $wf->get_start_desk;

	# Send this story to the first desk.
	$start_desk->accept({'asset' => $media});
	$start_desk->save;
	log_event('media_moved', $media, { Desk => $start_desk->get_name });
    }

    if ($param->{"$widget|delete"}) {
	# Delete the media.
	$handle_delete->($media);
    } else {
	# Make sure the media is activated and then save it.
	$media->activate();
	$media->save();
	log_event('media_save', $media);
	add_msg("Media &quot;" . $media->get_title . "&quot; saved.");
    }

    my $return = get_state_data($widget, 'return') || '';

    # Clear the state and send 'em home.
    clear_state($widget);

	if ($return eq 'search') {
        my $workflow_id = $media->get_workflow_id();
        my $url = $SEARCH_URL . $workflow_id . '/';
        set_redirect($url);
    } elsif ($return eq 'active') {
        my $workflow_id = $media->get_workflow_id();
        my $url = $ACTIVE_URL . $workflow_id;
        set_redirect($url);
    } elsif ($return =~ /\d+/) {
        my $workflow_id = $media->get_workflow_id();
        my $url = $DESK_URL . $workflow_id . '/' . $return . '/';
        set_redirect($url);
    } else {
        set_redirect("/");
    }

};

################################################################################

my $handle_checkin = sub {
    my ($widget, $field, $param, $WORK_ID, $media) = @_;
    $media ||= get_state_data($widget, 'media');

    my $work_id = get_state_data($widget, 'work_id');

    if ($work_id) {
	$media->set_workflow_id($work_id);

	my $wf = Bric::Biz::Workflow->lookup( { id => $work_id });
	log_event('media_add_workflow', $media, { Workflow => $wf->get_name });
    }

    $media->checkin();
    my $desk_id = $param->{"$widget|desk"};
    my $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ id => $desk_id });
    my $cur_desk = $media->get_current_desk();

	my $no_log;
    if ($cur_desk) {
		if ($cur_desk->get_id() == $desk_id) {
            $no_log = 1;
        } else {
			$cur_desk->transfer({
			     to    => $desk,
			     asset => $media
			    });
			$cur_desk->save();
		}
    } else {
	$desk->accept({'asset' => $media});
    }
    $desk->save;
    my $dname = $desk->get_name;
    log_event('media_moved', $media, { Desk => $dname }) unless $no_log;

    # make sure that the media is active
    $media->activate();
    $media->save();

    log_event('media_checkin', $media);

    # Clear the state out.
    clear_state($widget);
    add_msg("Media &quot;" . $media->get_title . "&quot; saved and moved to"
	    . " &quot;$dname&quot;.");

    # Set the redirect to the page we were at before here.
    set_redirect("/");

    # Remove this page from history.
    pop_page;
};

################################################################################

my $handle_save_stay = sub {
    my ($widget, $field, $param, $WORK_ID, $media) = @_;

    $media ||= get_state_data($widget, 'media');
    chk_authz($media, EDIT);
    my $work_id = get_state_data($widget, 'work_id');

    $media->activate();
    $media->save();

    if ($work_id) {
	$media->set_workflow_id($work_id);

	# Figure out what desk this story should be in.
	my $wf = Bric::Biz::Workflow->lookup({'id' => $work_id});
	log_event('media_add_workflow', $media, { Workflow => $wf->get_name });

	my $start_desk = $wf->get_start_desk;

	# Send this story to the first desk.
	$start_desk->accept({'asset' => $media});
	$start_desk->save;
	log_event('media_moved', $media, { Desk => $start_desk->get_name });
	set_state_data($widget, 'work_id', '');
    }

    if ($param->{"$widget|delete"}) {
	# Delete the media.
	$handle_delete->($media);
	# Get out of here, since we've blow it away!
	set_redirect("/");
	pop_page();
	clear_state($widget);
    } else {
	# Make sure the media is activated and then save it.
	$media->activate;
	$media->save;
	log_event('media_save', $media);
	add_msg("Media &quot;" . $media->get_title . "&quot; saved.");
	set_state_data($widget, 'work_id', '');
    }

    # Set the state.
    set_state_data($widget, 'media', $media);
};

################################################################################

my $handle_cancel = sub {
    my ($widget, $field, $param) = @_;
    my $media = get_state_data($widget, 'media');
    $media->cancel_checkout();
    $media->save();
    log_event('media_cancel_checkout', $media);
    clear_state($widget);
    set_redirect("/");
    add_msg("Media &quot;" . $media->get_name . "&quot; check out canceled.");
};

################################################################################

my $handle_return = sub {
    my ($widget, $field, $param) = @_;
    my $version_view = get_state_data($widget, 'version_view');

	my $media = get_state_data($widget, 'media');

    if ($version_view) {
	my $media_id = $media->get_id();
	clear_state($widget);
	set_redirect("/workflow/profile/media/$media_id/?checkout=1");
    } else {
	my $state = get_state_name($widget);
	my $url;
	my $return = get_state_data($widget, 'return') || '';
	my $wid = $media->get_workflow_id;

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
    my ($widget, $field, $param, $WORK_ID) = @_;

    # Check permissions.
    my $gid = Bric::Biz::Workflow->lookup({ id => $WORK_ID })->get_all_desk_grp_id;
    chk_authz('Bric::Biz::Asset::Business::Media', CREATE, 0, $gid);

    # get the asset type
    my $at_id = $param->{"$widget|at_id"};
    my $element = Bric::Biz::AssetType->lookup({ id => $at_id });

    # determine the package to which this belongs
    my $pkg = $element->get_biz_class();

    my $init = {
		element => $element,
		source__id => $param->{"$widget|source__id"},
		priority   => $param->{priority},
		cover_date => $param->{cover_date},
		title       => $param->{title},
		user__id   => get_user_id,
		category__id	=> $param->{"$widget|category__id"}
	       };

    # bless a new object into this package
    my $media = $pkg->new($init);

    # Keep this object deactivated until they actually save it.
    $media->deactivate;

    # Save the media object.
    $media->save;

    # Log that a new media has been created.
    log_event('media_new', $media);

    # store the state to use it in a bit
    set_state_data($widget, 'media', $media);

    # Head for the main edit screen.
    set_redirect('/workflow/profile/media/'.$media->get_id.'/');

    # As far as history is concerned, this page should be part of the story
    # profile stuff.
    pop_page;
};

################################################################################

my $handle_contributors = sub {
    my ($widget, $field, $param) = @_;

    set_redirect("/workflow/profile/media/contributors.html");
};

################################################################################

my $handle_assoc_contrib = sub {
    my ($widget, $field, $param, $WORK_ID) = @_;
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);
    my $contrib_id = $param->{$field};
    my $contrib =
      Bric::Util::Grp::Parts::Member::Contrib->lookup({'id' => $contrib_id});
    my $roles = $contrib->get_roles;
    if (scalar(@$roles)) {
	set_state_data($widget, 'contrib', $contrib);
	set_redirect("/workflow/profile/media/contributor_role.html");
    } else {
	$media->add_contributor($contrib);
	log_event('media_add_contrib', $media, { Name => $contrib->get_name });
#	add_msg("Contributor &quot;" . $contrib->get_name . "&quot; associated.");
    }
};

################################################################################

my $handle_assoc_contrib_role = sub {
    my ($widget, $field, $param) = @_;
    my $media   = get_state_data($widget, 'media');
    chk_authz($media, EDIT);
    my $contrib = get_state_data($widget, 'contrib');
    my $role    = $param->{$widget.'|role'};
    # Add the contributor
    $media->add_contributor($contrib, $role);
    log_event('media_add_contrib', $media, { Name => $contrib->get_name });
#    add_msg("Contributor &quot;" . $contrib->get_name . "&quot; associated.");
    # Go back to the main contributor pick screen.
    set_redirect(last_page);
    # Remove this page from the stack.
    pop_page;
};


################################################################################

my $handle_unassoc_contrib = sub {
    my ($widget, $field, $param) = @_;
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);
    my $contrib_id = $param->{$field};
    $media->delete_contributors([$contrib_id]);
    my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup({'id' => $contrib_id});
    log_event('media_del_contrib', $media, { Name => $contrib->get_name });
#    add_msg("Contributor &quot;" . $contrib->get_name . "&quot; disassociated.");
};

################################################################################

my $save_contrib = sub {
	my ($widget, $param) = @_;

	# get the contribs to delete
	my $media = get_state_data($widget, 'media');

	my $existing;
	foreach ($media->get_contributors) {
		my $id = $_->get_id();
		$existing->{$id} = 1;
	}

	chk_authz($media, EDIT);
	my $contrib_id = $param->{$widget.'|delete_id'};
	my $msg;
	if ($contrib_id) {
		if (ref $contrib_id) {
			$msg = 'Contributors ';
			$media->delete_contributors($contrib_id);
			foreach (@$contrib_id) {
				my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup(
					{ id => $_ });
				$msg .= "&quot;" . $contrib->get_name . "&quot;";
				delete $existing->{$_};
			}
			$msg .= ' disassociated.';
		} else {
			$media->delete_contributors([$contrib_id]);
			my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup(
				{ id => $contrib_id });
			delete $existing->{$contrib_id};
			$msg = 'Contributor &quot;' . $contrib->get_name .
			"&quot; disassociated.";
		}
	}
	add_msg($msg) if $msg;

	# get the remaining
	# and reorder
	foreach (keys %$existing) {
		my $key = $widget . '|reorder_' . $_;
		my $place = $param->{$key};
		$existing->{$_} = $place;
	}

	my @no;
	@no = sort { $existing->{$a} <=> $existing->{$b} } keys %$existing;
	$media->reorder_contributors(@no);

	# and that's that
};

################################################################################

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

my $handle_notes = sub {
    my ($widget, $field, $param, $WORK_ID) = @_;
    my $media = get_state_data($widget, 'media');
    my $id    = $media->get_id();
    my $action = $param->{$widget.'|notes_cb'};
    set_redirect("/workflow/profile/media/${action}_notes.html?id=$id");
};

################################################################################

my $handle_trail = sub {
	my ($widget, $field, $param, $WORK_ID) = @_;
	my $media = get_state_data($widget, 'media');
	my $id = $media->get_id();
	set_redirect("/workflow/trail/media/$id");
};

################################################################################

my $handle_recall = sub {
    my ($widget, $field, $param) = @_;
    my $ids = $param->{$widget.'|recall_cb'};
    $ids = ref $ids ? $ids : [$ids];
    my %wfs;

    foreach (@$ids) {
	my ($o_id, $w_id) = split('\|', $_);
	my $ba = Bric::Biz::Asset::Business::Media->lookup({'id' => $o_id});
	if (chk_authz($ba, EDIT, 1)) {
	    my $wf = $wfs{$w_id} ||= Bric::Biz::Workflow->lookup({'id' => $w_id});

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
	set_redirect('/workflow/profile/media/'.$o_id.'?checkout=1');
    }
};

################################################################################

my $handle_checkout = sub {
	my ($widget, $field, $param) = @_;
	my $ids = $param->{$field};
	$ids = ref $ids ? $ids : [$ids];

	foreach (@$ids) {
		my $ba = Bric::Biz::Asset::Business::Media->lookup({'id' => $_});
		if (chk_authz($ba, EDIT, 1)) {
			$ba->checkout({'user__id' => get_user_id});
			$ba->save;

			# Log Event.
			log_event('media_checkout', $ba);
		} else {
			add_msg("Permission to checkout &quot;" .
					$ba->get_name . "&quot; denied");
		}
	}
    if (@$ids > 1) {
	# Go to 'my workspace'
	set_redirect("/");
    } else {
	# Go to the profile screen
	set_redirect('/workflow/profile/media/'.$ids->[0].'?checkout=1');
    }
};


##########################
## Callback Definitions ##
##########################

my %cbs = (
	   # create a media asset
	   create_cb             => $handle_create,
	   # redirect to edit notes page
	   notes_cb              => $handle_notes,
	   # called on all updates the fields
	   update_pc             => $handle_update,
	   # final save
	   save_cb               => $handle_save,
	   # Return to the workspace without saving.
	   return_cb             => $handle_return,
	   # downloads the file to the user
	   contributors_cb       => $handle_contributors,
	   assoc_contrib_cb      => $handle_assoc_contrib,
	   assoc_contrib_role_cb => $handle_assoc_contrib_role,
	   unassoc_contrib_cb    => $handle_unassoc_contrib,
	   leave_contrib_cb      => $handle_leave_contrib,
	   trail_cb              => $handle_trail,
	   cancel_cb		 => $handle_cancel,
	   recall_cb             => $handle_recall,
	   checkout_cb		 => $handle_checkout,
	   view_cb		 => $handle_view,
	   revert_cb		 => $handle_revert,
	   save_and_stay_cb	 => $handle_save_stay,
	   checkin_cb		 		=> $handle_checkin,
	   save_contrib_cb 		=> $handle_save_contrib,
	   save_and_stay_contrib_cb => $handle_save_and_stay_contrib

);
</%once>

<%init>;
my ($cb) = substr($field, length($widget)+1);

# Get the workflow ID to use in redirects.
my $WORK_ID = get_state_data($widget, 'work_id');

# Execute the call back if it exists.

if (exists $cbs{$cb}) {
    $cbs{$cb}->($widget, $field, $param, $WORK_ID);
} else {
    die "No callback for $cb\n";
}
</%init>
