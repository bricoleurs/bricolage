<%args>
$widget
$field
$param
</%args>

<%init>;

if ($field eq "$widget|save_cb") {
    $save_object->($widget, $param);

    my $fa = get_state_data($widget, 'fa');

    if ($param->{"$widget|delete"}) {
	# Delete the fa.
	$delete_fa->($fa);
    } else {
        # Check syntax.
        return unless $check_syntax->($widget);
	# Make sure the fa is activated and then save it.
	$fa->activate;
	$fa->save;
	log_event('formatting_save', $fa);
	add_msg("Template &quot;" . $fa->get_name . "&quot; saved.");
    }

    my $return = get_state_data($widget, 'return') || '';

    # Clear out our application state and send 'em home.
    clear_state($widget);

    if ($return eq 'search') {
	my $workflow_id = $fa->get_workflow_id();
	my $url = $SEARCH_URL . $workflow_id . '/';
	set_redirect($url);
    } elsif ($return eq 'active') {
	my $workflow_id = $fa->get_workflow_id();
	my $url = $ACTIVE_URL . $workflow_id;
	set_redirect($url);
    } elsif ($return =~ /\d+/) {
	my $workflow_id = $fa->get_workflow_id();
	my $url = $DESK_URL . $workflow_id . '/' . $return . '/';
	set_redirect($url);
    } else {
	set_redirect("/");
    }
}

elsif ($field eq "$widget|checkin_cb") {
    return unless $check_syntax->($widget);
    $checkin->($widget, $param);
}

elsif ($field eq "$widget|checkin_deploy_cb") {
    my $fa = $checkin->($widget, $param);
    $param->{'desk|formatting_pub_ids'} = $fa->get_id;

    # Call the deploy callback in the desk widget.
    $m->comp('/widgets/desk/callback.mc',
	     widget => 'desk',
	     field  => 'desk|deploy_cb',
	     param  => $param);
}

elsif ($field eq "$widget|save_and_stay_cb") {
    $save_object->($widget, $param);
    my $fa = get_state_data($widget, 'fa');

    if ($param->{"$widget|delete"}) {
	# Delete the template.
	$delete_fa->($fa);
	# Get out of here, since we've blow it away!
	set_redirect("/");
	pop_page();
	clear_state($widget);
    } else {
        # Check syntax.
        return unless $check_syntax->($widget);
	# Make sure the template is activated and then save it.
	$fa->activate;
	$fa->save;
	log_event('formatting_save', $fa);
	add_msg("Template &quot;" . $fa->get_name . "&quot; saved.");
    }
}

elsif ($field eq "$widget|revert_cb") {
    my $fa      = get_state_data($widget, 'fa');
    my $version = $param->{"$widget|version"};
    $fa->revert($version);
    $fa->save();
    clear_state($widget);
}

elsif ($field eq "$widget|view_cb") {
    my $fa      = get_state_data($widget, 'fa');
    my $version = $param->{"$widget|version"};
    my $id      = $fa->get_id();
    set_redirect("/workflow/profile/templates/$id/?version=$version");
}

elsif ($field eq "$widget|cancel_cb") {
    my $fa = get_state_data($widget, 'fa');
    $fa->cancel_checkout();
    $fa->save();
    log_event('formatting_cancel_checkout', $fa);
    clear_state($widget);
    set_redirect("/");
    add_msg("Template &quot;" . $fa->get_name . "&quot; check out canceled.");
}

elsif ($field eq "$widget|notes_cb") {
    my $action = $param->{$widget.'|notes_cb'};

    # Save the metadata we've collected on this request.
    my $fa = get_state_data($widget, 'fa');
    my $id = $fa->get_id;

    # Save the data if we are in edit mode.
    &$save_meta($param, $widget, $fa) if $action eq 'edit';

    # Set a redirection to the code page to be enacted later.
    set_redirect("/workflow/profile/templates/${action}_notes.html?id=$id");
}

elsif ($field eq "$widget|trail_cb") {
    # Save the metadata we've collected on this request.
    my $fa  = get_state_data($widget, 'fa');
    &$save_meta($param, $widget, $fa);
    my $id = $fa->get_id;

    # Set a redirection to the code page to be enacted later.
    set_redirect("/workflow/trail/formatting/$id");
}

elsif ($field eq "$widget|create_cb") {
    my $at_id = $param->{$widget.'|at_id'};
    my $oc_id = $param->{$widget.'|oc_id'};
    my $cat_id = $param->{$widget.'|cat_id'};
    my $file_type = $param->{file_type};

    my ($at, $name);
    unless ($param->{$widget.'|no_at'}) {
	# Associate it with an Element.
	$at    = Bric::Biz::AssetType->lookup({'id' => $at_id});
	$name  = $at->get_name();
    } # Otherwise, it'll default to an autohandler.

    # Check permissions.
    my $work_id = get_state_data($widget, 'work_id');
    my $gid = Bric::Biz::Workflow->lookup({ id => $work_id })->get_all_desk_grp_id;
    chk_authz('Bric::Biz::Asset::Formatting', CREATE, 0, $gid);

    # Create a new formatting asset.
    my $fa = Bric::Biz::Asset::Formatting->new(
			    {'element'     		=> $at,
			     'file_type'                => $file_type,
			     'output_channel__id' 	=> $oc_id,
			     'category_id'        	=> $cat_id,
			     'priority'           	=> $param->{priority},
			     'name'               	=> $name,
			     'user__id'           	=> get_user_id});


    # check that there isn't already an active template with the same
    # output channel and file_name (which is composed of category,
    # file_type and element name).
    my $found_dup = 0;
    my $file_name  = $fa->get_file_name;
    my @list = Bric::Biz::Asset::Formatting->list_ids(
			  { output_channel__id => $oc_id,
			    file_name => $file_name      });
    if (@list) {
	$found_dup = 1;
    } else {
	# Arrgh.  This is the only way to search all checked out
	# formatting assets.  According to Garth this isn't a
	# problem...  I'd like to show him this code sometime and see
	# if he still thinks so!
	my @user_ids = Bric::Biz::Person::User->list_ids({});
	foreach my $user_id (@user_ids) {
	    @list = Bric::Biz::Asset::Formatting->list_ids(
			  { output_channel__id => $oc_id,
			    file_name          => $file_name,
			    user__id           => $user_id   });
	    if (@list) {
		$found_dup = 1;
		last;
	    }
	}
    }

    if ($found_dup) {
	set_redirect("/");
	add_msg("An active template already exists for the selected output channel, category, element and burner you selected.  You must delete the existing template before you can add a new one.");
	return;
    }

    # Keep the formatting asset deactivated until the user clicks save.
    $fa->deactivate;
    $fa->save;

    # Log that a new media has been created.
    log_event('formatting_new', $fa);

    set_state_data($widget, 'fa', $fa);

    # Head for the main edit screen.
    set_redirect("/workflow/profile/templates/?checkout=1");

    # As far as history is concerned, this page should be part of the template
    # profile stuff.
    pop_page;
}

elsif ($field eq "$widget|return_cb") {
    my $state        = get_state_name($widget);
    my $version_view = get_state_data($widget, 'version_view');

	my $fa = get_state_data($widget, 'fa');

    if ($version_view) {
		my $fa_id = $fa->get_id();

		clear_state($widget);
		set_redirect("/workflow/profile/templates/$fa_id/?checkout=1");
    } else {
	my $url;
	my $return = get_state_data($widget, 'return') || '';
	my $wid = $fa->get_workflow_id;
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

    # Remove this page from the stack.
    pop_page;
}

# Pull a template back from the dead and on to the workflow.
elsif ($field eq "$widget|recall_cb") {
    my $ids = $param->{$widget.'|recall_cb'};
    my %wfs;
    $ids = ref $ids ? $ids : [$ids];

    foreach (@$ids) {
	my ($o_id, $w_id) = split('\|', $_);
	my $fa = Bric::Biz::Asset::Formatting->lookup({'id' => $o_id});
	if (chk_authz($fa, EDIT, 1)) {
	    my $wf = $wfs{$w_id} ||= Bric::Biz::Workflow->lookup({'id' => $w_id});

	    # Put this formatting asset into the current workflow
	    $fa->set_workflow_id($w_id);
	    log_event('formatting_add_workflow', $fa, { Workflow => $wf->get_name });

	    # Get the start desk for this workflow.
	    my $start_desk = $wf->get_start_desk;

	    # Put this formatting asset on to the start desk.
	    $start_desk->accept({'asset' => $fa});
	    $start_desk->checkout($fa, get_user_id);
	    $start_desk->save;
	    log_event('formatting_moved', $fa, { Desk => $start_desk->get_name });
	} else {
	    add_msg("Permission to checkout &quot;" . $fa->get_name
		    . "&quot; denied");
	}
    }

    if (@$ids > 1) {
	# Go to 'my workspace'
	set_redirect("/");
    } else {
	# Go to the profile screen
        my ($o_id, $w_id) = split('\|', $ids->[0]);
	set_redirect('/workflow/profile/templates/'.$o_id.'?checkout=1');
    }
}

elsif ($field eq "$widget|checkout_cb") {
    my $ids = $param->{$field};

    $ids = ref $ids ? $ids : [$ids];

    foreach my $t_id (@$ids) {
	my $t_obj = Bric::Biz::Asset::Formatting->lookup({'id' => $t_id});
	my $d     = $t_obj->get_current_desk;

	$d->checkout($t_obj, get_user_id);
	$d->save;

	log_event("formatting_checkout", $t_obj);
    }

    if (@$ids > 1) {
	# Go to 'my workspace'
	set_redirect("/");
    } else {
	# Go to the profile screen
	set_redirect('/workflow/profile/templates/'.$ids->[0].'?checkout=1');
    }
}

</%init>

<%once>

#################
## Constants  ###
#################
my $DESK_URL = '/workflow/profile/desk/';
my $SEARCH_URL = '/workflow/manager/templates/';
my $ACTIVE_URL = '/workflow/active/templates/';


my $save_meta = sub {
    my ($param, $widget, $fa) = @_;
    $fa ||= get_state_data($widget, 'fa');
    chk_authz($fa, EDIT);
    $fa->set_priority($param->{priority}) if $param->{priority};
    $fa->set_category_id($param->{category_id}) if exists $param->{category_id};
    $fa->set_description($param->{description}) if $param->{description};
    $fa->set_expire_date($param->{'expire_date'}) if $param->{'expire_date'};
    $fa->set_data($param->{"$widget|code"});

    return set_state_data($widget, 'fa', $fa);
};

my $save_code = sub {
    my ($param, $widget, $fa) = @_;
    $fa ||= get_state_data($widget, 'fa');
    chk_authz($fa, EDIT);
    $fa->set_data($param->{"$widget|code"});
    return set_state_data($widget, 'fa', $fa);
};

my $save_object = sub {
    my ($widget, $param) = @_;
    my $fa = get_state_data($widget, 'fa');
    $save_meta->($param, $widget, $fa);

    my $work_id = get_state_data($widget, 'work_id');

    # Only update the workflow ID if they've just created the template
    if ($work_id) {
        $fa->set_workflow_id($work_id);
	$fa->activate;

        my $wf = Bric::Biz::Workflow->lookup({'id' => $work_id});
        log_event('formatting_add_workflow', $fa, {Workflow => $wf->get_name});
        my $start_desk = $wf->get_start_desk;

        $start_desk->accept({'asset' => $fa});
        $start_desk->save;
        log_event('formatting_moved', $fa, {Desk => $start_desk->get_name});
    }

    # Make sure this formatting asset is active
    $fa->activate;
};


my $checkin = sub {
	my ($widget, $param) = @_;
	my $fa = get_state_data($widget, 'fa');

	$save_meta->($param, $widget, $fa);

	log_event('formatting_checkin', $fa);
	my $work_id = get_state_data($widget, 'work_id');

	if ($work_id) {
	    $fa->set_workflow_id($work_id);
	    my $wf = Bric::Biz::Workflow->lookup( { id => $work_id });
	    log_event('formatting_add_workflow', $fa, { Workflow => $wf->get_name });
	}
	$fa->checkin();
	$fa->activate();
	$fa->save();

	my $desk_id = $param->{"$widget|desk"};
	my $desk    = Bric::Biz::Workflow::Parts::Desk->lookup({id => $desk_id});
	my $cur_desk = $fa->get_current_desk();

	my $no_log;
	if ($cur_desk) {
	    if ($cur_desk->get_id() == $desk_id) {
		$no_log = 1;
	    } else {
		# Send this story to the next desk
		$cur_desk->transfer({
				     to    => $desk,
				     asset => $fa
				    });
		$cur_desk->save();
	    }
	} else {
	    $desk->accept( { 'asset' => $fa });
	}

	$desk->save;
	my $dname = $desk->get_name;
	log_event('formatting_moved', $fa, {Desk => $dname}) unless $no_log;
	add_msg("Template &quot;" . $fa->get_name . "&quot; checked in to &quot;${dname}&quot; desk.");

	# Clear the state out.
	clear_state($widget);

	# Set the redirect to the page we were at before here.
	set_redirect("/");

	# Remove this page from history.
	pop_page;

	return $fa;
};

my $check_syntax = sub {
    my ($widget) = @_;
    my $fa = get_state_data($widget, 'fa');
    my $burner = Bric::Util::Burner->new;
    my $err;
    # Return success if the syntax checks out.
    return 1 if $burner->chk_syntax($fa, \$err);
    # Otherwise, add a message and return false.
    add_msg("Template compile failed: $err");
    return 0
};

my $delete_fa = sub {
    my $fa = shift;
    my $desk = $fa->get_current_desk;
    $desk->checkin($fa);
    $desk->remove_asset($fa);
    $desk->save;
    log_event("formatting_rem_workflow", $fa);
    my $burn = Bric::Util::Burner->new;
    $burn->undeploy($fa);
    $fa->deactivate;
    $fa->save;
    log_event("formatting_deact", $fa);
    add_msg("Template &quot;" . $fa->get_name . "&quot; deleted.");
};

</%once>

%#--- Log History ---#


