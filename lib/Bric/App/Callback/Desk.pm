package Bric::App::Callback::Desk;

use base qw(Bric::App::Callback);
# Note special name 'desk_asset' so it doesn't conflict
# with 'desk' in Profile/Desk.pm
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'desk_asset';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Session qw(:state :user);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:msg :pkg :aref);
use Bric::App::Callback::Publish;
use Bric::App::Callback::Workspace;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Formatting;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Config qw(:ui :pub);
use Bric::Util::Burner;
use Bric::Util::Time qw(strfdate);

my $pkgs = {
    story => 'Bric::Biz::Asset::Business::Story',
    media => 'Bric::Biz::Asset::Business::Media',
    formatting => 'Bric::Biz::Asset::Formatting',
};
my $keys = [ keys %$pkgs ];

my $type = 'formatting';
my $disp_name = 'Template';

sub checkin : Callback {
    my $self = shift;

    my $a_id    = $self->value;
    my $a_class = $self->params->{$self->class_key.'|asset_class'};
    my $pkg     = get_package_name($a_class);
    my $a_obj   = $pkg->lookup({'id' => $a_id, checkout => 1});
    my $d       = $a_obj->get_current_desk;

    $d->checkin($a_obj);
    $d->save;

    if ($a_class eq 'formatting') {
        my $sb = Bric::Util::Burner->new({user_id => get_user_id()});
           $sb->undeploy($a_obj);
    }

    log_event("${a_class}_checkin", $a_obj, { Version => $a_obj->get_version });
}

sub checkout : Callback {
    my $self = shift;

    my $a_id    = $self->value;
    my $a_class = $self->params->{$self->class_key.'|asset_class'};
    my $pkg     = get_package_name($a_class);
    my $a_obj   = $pkg->lookup({'id' => $a_id});
    my $d       = $a_obj->get_current_desk;

    $d->checkout($a_obj, get_user_id());
    $d->save;
    $a_obj->save;
    log_event("${a_class}_checkout", $a_obj);

    $a_id = $a_obj->get_id;

    my $profile;
    if ($a_class eq 'formatting') {
        my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
        $sb->deploy($a_obj);

        $profile = '/workflow/profile/templates';
    } elsif ($a_class eq 'media') {
        $profile = '/workflow/profile/media';
    } else {
        $profile = '/workflow/profile/story';
    }

    $self->set_redirect("$profile/$a_id/?checkout=1");
}

sub move : Callback {
    my $self = shift;

    # Accept one or more assets to be moved to another desk.
    my $next_desk = $self->params->{$self->class_key.'|next_desk'};
    my $assets    = ref $next_desk ? $next_desk : [$next_desk];

    my ($a_id, $a_class, $d_id, $pkg, %wfs);
    foreach my $a (@$assets) {
        my ($a_id, $from_id, $to_id, $a_class, $wfid) = split('-', $a);

        # Do not move assets where the user has not chosen a next desk.
        # And where the desk ID is the same.
        next unless $to_id and $to_id != $from_id;

        my $pkg   = get_package_name($a_class);
        my $a_obj = $pkg->lookup({'id' => $a_id});

        unless ($a_obj->is_current) {
            add_msg('Cannot move [_1] asset "[_2]" while it is checked out.',
                    $a_class, $a_obj->get_name);
            next;
        }

        my $dpkg = 'Bric::Biz::Workflow::Parts::Desk';

        # Get the current desk and the next desk.
        my $d    = $dpkg->lookup({'id' => $from_id});
        my $next = $dpkg->lookup({'id' => $to_id});

        # Transfer from the current to the next.
        $d->transfer({'to'    => $next,
                      'asset' => $a_obj});

        # Save both desks.
        $d->save;
        $next->save;

        if (ALLOW_WORKFLOW_TRANSFER) {
            if ($wfid != $a_obj->get_workflow_id) {
                # Transfer workflows.
                $a_obj->set_workflow_id($wfid);
                $a_obj->save;
                my $wf = $wfs{$wfid} ||=
                  Bric::Biz::Workflow->lookup({ id => $wfid });
                log_event("${a_class}_add_workflow", $a_obj,
                          { Workflow => $wf->get_name });
            }
        }

        # Log an event
        log_event("${a_class}_moved", $a_obj, { Desk => $next->get_name });
    }
}

sub publish : Callback {
    my $self = shift;
    my $param = $self->params;
    my $story_pub = $param->{'story_pub'};
    my $media_pub = $param->{'media_pub'};

    my $mpkg = 'Bric::Biz::Asset::Business::Media';
    my $spkg = 'Bric::Biz::Asset::Business::Story';
    my $story = mk_aref($param->{$self->class_key.'|story_pub_ids'});
    my $media = mk_aref($param->{$self->class_key.'|media_pub_ids'});
    my (@rel_story, @rel_media);

    # start with the objects checked for publish
    my @stories = ((map { $spkg->lookup({id => $_}) } @$story),
                   values %$story_pub);
    my @media = ((map { $mpkg->lookup({id => $_}) } @$media),
                   values %$media_pub);

    my (@sids, @mids);

    if (PUBLISH_RELATED_ASSETS) {
        my %seen;
        for ([story => \@stories, $story_pub],
             [media => \@media, $media_pub]) {
            my ($key, $objs, $pub_ids) = @$_;
            # iterate through objects looking for related and stories
            while (@$objs) {
                my $a = shift @$objs or next;

                # haven't I seen you someplace before?
                my $id = $a->get_id;
                next if exists $seen{"$key$id"};
                $seen{"$key$id"} = 1;

                if ($a->get_checked_out) {
                    my $a_disp_name = lc get_disp_name($key);
                    add_msg("Cannot publish $a_disp_name \"[_1]\" because it is"
                            . " checked out.", $a->get_name);
                    delete $pub_ids->{$id};
                    next;
                }

                # Hang on to your hat!
                if ($key eq 'story') {
                    push @sids, $id;
                } else {
                    push @mids, $id;
                }

                # Examine all the related objects.
                foreach my $r ($a->get_related_objects) {
                    # Skip assets whose current version has already been published.
                    next unless $r->needs_publish;
                    # Skip deactivated documents.
                    next unless $r->is_active;

                    # haven't I seen you someplace before?
                    my $rid = $r->get_id;
                    my $rkey = $r->key_name;
                    next if exists $seen{"$rkey$rid"};
                    $seen{"$rkey$rid"} = 1;

                    if ($r->get_checked_out) {
                        my $r_disp_name = lc(get_disp_name($r->key_name));
                        add_msg("Cannot auto-publish related $r_disp_name \"[_1]\""
                                . " because it is checked out.", $r->get_name);
                        next;
                    }

                    # push onto the appropriate list
                    if ($rkey eq 'story') {
                        push @rel_story, $r->get_id;
                        push @sids, $rid if $pub_ids->{$id};
                        push(@stories, $r); # recurse through related stories
                    } else {
                        push @rel_media, $r->get_id;
                        push @mids, $rid if $pub_ids->{$id};
                    }
                }
            }
        }
    }

    # Make sure we have the IDs for any assets passed in explicitly.
#    push @$story, keys %$story_pub;
#    push @$media, keys %$media_pub;

    # For publishing from a desk, I added two new 'publish'
    # state data: 'rel_story', 'rel_media'. This is to be
    # able to distinguish between related assets and the
    # original stories to be published.
    set_state_data('publish', { story => \@sids,
                                media => \@mids,
                                story_pub => $story_pub,
                                media_pub => $media_pub,
                                (@rel_story ? (rel_story => \@rel_story) : ()),
                                (@rel_media ? (rel_media => \@rel_media) : ())
                            });

    if (%$story_pub or %$media_pub) {
        # Instant publish!
        my $pub = Bric::App::Callback::Publish->new
          ( cb_request   => $self->cb_request,
            pkg_key      => 'publish',
            apache_req   => $self->apache_req,
            params       => { instant => 1,
                              pub_date => strfdate(),
                            },
          );
        $pub->publish();
    } else {
        $self->set_redirect('/workflow/profile/publish');
    }
}

sub deploy : Callback {
    my $self = shift;

    if (my $a_ids = $self->params->{$self->class_key.'|formatting_pub_ids'}) {
        my $b = Bric::Util::Burner->new;

        $a_ids = ref $a_ids ? $a_ids : [$a_ids];

        my $c = @$a_ids;
        foreach (@$a_ids) {
            my $fa = Bric::Biz::Asset::Formatting->lookup({ id => $_ });
            my $action = $fa->get_deploy_status ? 'formatting_redeploy'
              : 'formatting_deploy';
            $b->deploy($fa);
            $fa->set_deploy_date(strfdate());
            $fa->set_deploy_status(1);
            $fa->set_published_version($fa->get_current_version);
            $fa->save;
            log_event($action, $fa);

            # Get the current desk and remove the asset from it.
            my $d = $fa->get_current_desk;
            $d->remove_asset($fa);
            $d->save;

            # Clear the workflow ID.
            $fa->set_workflow_id(undef);
            $fa->save;
            log_event("formatting_rem_workflow", $fa);
        }
        # Let 'em know we've done it!
        if ($c == 1) {
            add_msg('Template "[_1]" deployed.', $disp_name);
        } else {
            add_msg("[quant,_1,$disp_name] deployed.", $c);
        }
    }

    # If there are stories or media to be published, publish them!
    if ($self->params->{$self->class_key.'|story_pub_ids'}
          || $self->params->{$self->class_key.'|media_pub_ids'}) {
        $self->publish;
    }

}

sub clone : Callback {
    my $self = shift;
    my $aid = $self->value;
    my $param = $self->params;

    # Lookup the story and log that it has been cloned.
    my $story = Bric::Biz::Asset::Business::Story->lookup({ id => $aid });
    log_event('story_clone', $story);

    # Look it up again to avoid the event above being logged on the clone
    # instead of the original story.
    $story = Bric::Biz::Asset::Business::Story->lookup({ id => $aid });

    # Get the current desk.
    my $desk = $story->get_current_desk;

    # Clone the story.
    $story->clone;

    # Merge changes into story
    $self->_merge_properties($story) or return;

    # Save changes
    $story->save;

    # Put the cloned story on the desk.
    $desk->accept({ asset => $story });
    $desk->save;

    # Log events and redirect.
    my $wf = $story->get_workflow_object;
    log_event('story_clone_create', $story);
    log_event('story_add_workflow', $story, { Workflow => $wf->get_name });
    log_event('story_moved', $story, { Desk => $desk->get_name });
    log_event('story_checkout', $story);
    $self->set_redirect('/workflow/profile/story/' . $story->get_id
                        . '/?checkout=1');
}

# This is quite similar to Workspace::delete
sub delete : Callback {
    my $self = shift;
    my $burn = Bric::Util::Burner->new;

    # Deleting assets.
    foreach my $key (@$keys) {
        foreach my $aid (@{ mk_aref($self->params->{"${key}_delete_ids"}) }) {
	    my $a = $pkgs->{$key}->lookup({ id => $aid });
	    if (chk_authz($a, EDIT, 1)) {
		my $d = $a->get_current_desk;
		$d->remove_asset($a);
		$d->save;
		log_event("${key}_rem_workflow", $a);
                $a->set_workflow_id(undef);
		$a->deactivate;
		$a->save;

                if($key eq 'formatting') {
                    $burn->undeploy($a);
                    my $sb = Bric::Util::Burner->new({user_id => get_user_id()});
                    $sb->undeploy($a);
                }
		log_event("${key}_deact", $a);
	    } else {
                add_msg('Permission to delete "[_1]" denied.', $a->get_name);
	    }
	}
    }
}


### PRIVATE ###

sub _merge_properties {
    my ($self, $story) = @_;
    my $param = $self->params;
    my $widget = $self->class_key;

    my $err = 0;

    # Title
    $story->set_title($param->{title});

    # Slug - account for sluglessness
    $param->{slug} = '' unless exists($param->{slug}) && defined($param->{slug});
    unless (ALLOW_SLUGLESS_NONFIXED || $story->is_fixed || $param->{slug} =~ /\S/) {
        add_msg('Slug required for non-fixed (non-cover) story type.');
        $err++;
    } else {
        $story->set_slug($param->{slug});
    }

    # Category
    my $cid = $param->{"$widget|new_category_id"};
    unless (defined $cid && $cid ne '') {
        add_msg('Please select a primary category.');
        $err++;
    } else {
        # Delete all the current categories first,
        # then add the new category and make it primary.
        # It's a little more complicated to avoid
        # deleting the new category if it's already there.
        my %todelete_cats = map { $_->get_id => $_ } $story->get_categories;

        my $was_there = delete($todelete_cats{$cid}) || 0;
        $story->add_categories([$cid]) unless $was_there;
        $story->delete_categories([ values(%todelete_cats) ]) if %todelete_cats;
        $story->set_primary_category($cid);
    }

    # Cover date
    if ($param->{'cover_date-partial'}) {
        add_msg('Cover Date incomplete.');
        $err++;
    } else {
        $story->set_cover_date($param->{cover_date});
    }

    # Output Channel
    my $ocid = $param->{"$widget|new_oc_id"};
    unless (defined $ocid && $ocid ne '') {
        add_msg('Please select a primary output channel.');
        $err++;
    } else {
        # Delete all the current output channels first,
        # then add the new output channel and make it primary.
        # It's a little more complicated to avoid
        # deleting the new output channel if it's already there.

        # Note the current output channels.
        my %todelete_ocs =  map { $_->get_id => $_ }
          $story->get_output_channels;

        unless (delete $todelete_ocs{$ocid}) {
            $story->add_output_channels(
                Bric::Biz::OutputChannel->lookup({ id => $ocid })
            );
        }
        $story->set_primary_oc_id($ocid);
        $story->del_output_channels(values %todelete_ocs) if %todelete_ocs;
    }

    return 1 unless $err;
    return;
}

1;
