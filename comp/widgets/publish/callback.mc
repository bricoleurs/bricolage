<%args>
$widget
$field
$param
$story_id => undef
$media_id => undef
</%args>
<%once>;
my $fs = PREVIEW_LOCAL ? Bric::Util::Trans::FS->new : undef;
my $send_msg = sub { $m->comp('/lib/util/status_msg.mc', @_) };
my $comp_root = $m->interp->comp_root->[0][1];
</%once>

<%init>;
# Hunt the wumpus
$field = 'publish' if $field eq "$widget|publish_cb";
return unless $field eq 'preview' or $field eq "publish";

# Grab the story and media IDs from the session.
my ($story_pub_ids, $media_pub_ids);
if (my $d = get_state_data($widget)) {
    ($story_pub_ids, $media_pub_ids) = @{$d}{qw(story media)};
    clear_state($widget);
} elsif (! defined $story_id && ! defined $media_id ) { return }

if ($field eq 'preview') {
    # Instantiate the Burner object.
    my $b = Bric::Util::Burner->new({ out_dir => PREVIEW_ROOT });
    if (defined $media_id) {
	my $m = get_state_data('media_prof', 'media');
	unless ($m && defined $media_id && $m->get_id == $media_id) {
	    $m = Bric::Biz::Asset::Business::Media->lookup({ id => $media_id });
	}

	# Move out the story and then redirect to preview.
	my $url = &$publish($m, $b, 'media', $param, $field);
	&$send_msg("Redirecting to preview.");
	redirect_onload($url);
    } else {
	my $s = get_state_data('story_prof', 'story');
	unless ($s && defined $story_id && $s->get_id == $story_id) {
	    $s = Bric::Biz::Asset::Business::Story->lookup({ id => $story_id });
	}

	# Get all the related media to be previewed as well
	foreach my $r ($s->get_related_objects) {
	    next if (ref $r eq 'Bric::Biz::Asset::Business::Story');

	    # Make sure this media object isn't checked out.
	    if ($r->get_checked_out) {
		add_msg('Cannot auto-publish related media &quot;'.
			$r->get_title.'&quot; because it is checked out');
		next;
	    }
	    &$publish($r, $b, 'media', $param, $field);
	}
	# Move out the story and then redirect to preview.
	my $url = &$publish($s, $b, 'story', $param, $field);
	&$send_msg("Redirecting to preview.");
	redirect_onload($url);
    }
} else {
    # Instantiate the Burner object.
    my $b = Bric::Util::Burner->new({ out_dir => STAGE_ROOT });
    my $stories = mk_aref($story_pub_ids);
    my $media = mk_aref($media_pub_ids);

    # Iterate through each story and media object to be published.
    foreach my $sid (@$stories) {
	# Instantiate the story.
	my $s = Bric::Biz::Asset::Business::Story->lookup({ id => $sid });
	&$publish($s, $b, 'story', $param, $field);
    }

    foreach my $mid (@$media) {
	# Instantiate the media.
	my $m = Bric::Biz::Asset::Business::Media->lookup({ id => $mid });
	&$publish($m, $b, 'media', $param, $field);
    }

    redirect_onload(last_page());
}
</%init>

<%shared>;
my ($ats, $oc_sts, $uid) = ({}, {}, get_user_id());
my $publish = sub {
    my ($ba, $b, $key, $param, $field) = @_;
    # Check for EDIT permission for publish or READ permission for preview.
    if (chk_authz($ba, EDIT, 1) || (chk_authz($ba, READ, 1)
				    && $field eq 'preview')) {
	# Send a status message.
	&$send_msg('Preparing to format &quot;' . $ba->get_name . '&quot;');
    } else {
	# No permission. Send a message.
	my $msg = "Permission to publish &quot;" . $ba->get_name
	  . "&quot; denied";
	$field eq 'preview' ? &$send_msg($msg) : add_msg($msg);
	next;
    }

    if ($field ne 'preview' and $ba->get_checked_out) {
	add_msg("Cannot publish ".lc(get_disp_name($ba->key_name))." '".
		$ba->get_name."' because it is checked out");

	return;
    }

    $ba->set_publish_date($param->{pub_date});
    # Create a job for moving this asset.
    my $job = Bric::Dist::Job->new( { sched_time => $param->{pub_date},
				    user_id => $uid,
				    name => ucfirst($field) . " &quot;" .
				            $ba->get_name . "&quot;" });

    my $exp_job;
    my $repub;
    if ($field eq 'publish' && !$ba->get_publish_status) {
	# This puppy hasn't been published before. Mark it.
	$ba->set_publish_status(1);
	$repub = 1;
	if (my $exp_date = $ba->get_expire_date) {
	    # We'll need to expire it.
	    $exp_job = Bric::Dist::Job->new( { sched_time => $exp_date,
					     user_id => $uid,
					     type => 1 });
	    $exp_job->set_name("Expire &quot;" . $ba->get_name . "&quot;");
	}
    }

    # Get a list of the relevant categories.
    my @cats = $key eq 'story' ? $ba->get_categories : ();
    # Grab the asset type.
    my $at = $ats->{$ba->get_element__id} ||= $ba->_get_element_object;
    my $bats = {};
    my $res = [];
    my $ocs = $field eq 'preview'
      ? [ Bric::Biz::OutputChannel->lookup({ id => $at->get_primary_oc_id }) ]
	: $at->get_output_channels;

    # Iterate through each output channel.
    foreach my $oc (@$ocs) {
	&$send_msg("Writing files to &quot;" . $oc->get_name
		   . '&quot; Output Channel.');
	my $ocid = $oc->get_id;
	# Get a list of server types this categroy applies to.
	my $bat = $oc_sts->{$ocid} ||=
	  Bric::Dist::ServerType->list({ "can_$field" => 1,
					 active => 1,
					 output_channel_id => $ocid });
	# Make sure we have some destinations.
	unless (@$bat || ($field eq 'preview' && PREVIEW_LOCAL)) {
	    add_msg("Cannot publish asset &quot;" . $ba->get_name . "&quot; "
		    . "because there are no Destinations associated with its "
		    . "output channels.");
	    next;
	}
	# Force the list of server types into a hash so that they're unique
	# (they can repeat between asset channels).
	grep { $bats->{ $_->get_id } = $_ } @$bat;

	# Burn, baby, burn!
	if ($key eq 'story') {
	    foreach my $cat (@cats) { push @$res, $b->burn_one($ba, $oc, $cat) }
	} else {
	    my $path = $ba->get_path;
	    my $uri = $ba->get_uri;
	    if ($path && $uri) {
		my $r = Bric::Dist::Resource->lookup({ path => $path })
		  || Bric::Dist::Resource->new({ path => $path,
						 media_type => Bric::Util::MediaType->get_name_by_ext($uri)
					       });
		$r->set_uri($uri);
		$r->add_media_ids($ba->get_id);
		$r->save;
		push @$res, $r;
	    }
	}
    }
    # Turn the hash of server types into an array.
    $bats = [ values %$bats ];

    # Save the delivery job.
    $job->add_server_types(@$bats);
    $job->add_resources(@$res);
    $job->save;
    log_event('job_new', $job);

    # Save the expiration job, if there is one.
    if ($exp_job) {
	# Add the server types to the job.
	$exp_job->add_server_types(@$bats);
	$exp_job->add_resources(@$res);
	$exp_job->save;
	log_event('job_new', $exp_job);
    }

    # Now log that we've published and get it out of workflow.
    if ($field eq 'publish') {
	log_event($key . ($repub ? '_republish' : '_publish'), $ba);
	my $d = $ba->get_current_desk;
	$d->remove_asset($ba);
	$d->save;

	# Remove this asset from the workflow by setting is workflow ID to undef
	$ba->set_workflow_id(undef);
	$ba->save;

	log_event("${key}_rem_workflow", $ba);
    } else {
	# Execute the job and redirect.
	&$send_msg("Distributing files.");
	# We don't need to exeucte the job if it has already been executed.
	$job->execute_me unless ENABLE_DIST;
	if (PREVIEW_LOCAL) {
	    # Copy the files for previewing locally.
	    foreach my $rsrc (@$res) {
		$fs->copy($rsrc->get_path,
			  $fs->cat_dir($comp_root, PREVIEW_LOCAL,
				       $rsrc->get_uri));
	    }
	    # Return the redirection URL.
	    return $fs->cat_uri('/', PREVIEW_LOCAL, $res->[0]->get_uri);
	} else {
	    # Return the redirection URL.
	    return 'http://' . ($bats->[0]->get_servers)[0]->get_host_name
	      . $ba->get_uri;
	}
    }
};
</%shared>
