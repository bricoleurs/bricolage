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
use Bric::App::Util qw(:pkg :aref);
use Bric::App::Callback::Publish;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Template;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Config qw(:ui :pub);
use Bric::Util::Burner;
use Bric::Util::DBI qw(:junction);
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::Time qw(strfdate);
use Bric::Util::Fault qw(throw_error);

my $pkgs = {
    story    => 'Bric::Biz::Asset::Business::Story',
    media    => 'Bric::Biz::Asset::Business::Media',
    template => 'Bric::Biz::Asset::Template',
    desk     => 'Bric::Biz::Workflow::Parts::Desk'
};

sub checkin : Callback {
    my $self = shift;

    my ($class, $id) = split /_/, $self->value;
    my $obj  = $pkgs->{$class}->lookup({'id' => $id, checkout => 1});
    my $desk = $obj->get_current_desk;

    $desk->checkin($obj);
    log_event("${class}_checkin", $obj, { Version => $obj->get_version });

    # If the same asset is cached in the session, remove it.
    if (my $cached = get_state_data("$class\_prof" => $class)) {
        if ($cached->get_id == $obj->get_id) {
            clear_state("$class\_prof");
            clear_state('container_prof');
        }
    }

    my ($next_desk_id, $next_workflow_id) =
        split /-/, $self->params->{"desk_asset|next_desk"};

    if ($next_desk_id eq 'shelve') {
        $desk->remove_asset($obj)->save;
        $obj->set_workflow_id(undef);
        $obj->save;
        log_event("${class}_rem_workflow", $obj);
    } elsif ($next_desk_id eq 'publish') {
        $self->_move_to_publish_desk($obj);
        $self->params->{"${class}_pub"} = { $obj->get_version_id => $obj };
        $self->publish;
    } elsif ($next_desk_id eq 'deploy') {
        if ($class eq 'template') {
            $self->_move_to_publish_desk($obj);
            $self->params->{"desk_asset|template_pub_ids"} = [ $obj->get_version_id ];
            $self->deploy;
        }
    } elsif ($next_desk_id) {
        if ($desk->get_id != $next_desk_id) {
            my $next = $pkgs->{desk}->lookup({ id => $next_desk_id });
            $desk->transfer({
                to    => $next,
                asset => $obj
            });
            log_event("${class}_moved", $obj, { Desk => $next->get_name });
            $next->save;
        }
        $desk->save;
    } else {
        $desk->save;
    }

    if ($class eq 'template') {
        my $sandbox = Bric::Util::Burner->new({user_id => get_user_id()});
        $sandbox->undeploy($obj);
    }
}

sub checkout : Callback {
    my $self = shift;

    my ($class, $id) = split(/_/, $self->value);
    my $pkg  = get_package_name($class);
    my $obj  = $pkg->lookup({'id' => $id});

    unless ($obj->get_checked_out) {
        my $desk = $obj->get_current_desk;
        $desk->checkout($obj, get_user_id());
        $desk->save;
        $obj->save;
        log_event("${class}_checkout", $obj);

        if ($class eq 'template') {
            my $sandbox = Bric::Util::Burner->new({user_id => get_user_id() });
            $sandbox->deploy($obj);
        }
    }

    # Clear the profile state of stale data and redirect to the profile.
    clear_state("$class\_prof");
    clear_state('container_prof');
    $self->set_redirect("/workflow/profile/$class/$id/?checkout=1");
}

sub move : Callback {
    my $self = shift;

    my ($class, $id) = split /_/, $self->value;
    my $obj  = $pkgs->{$class}->lookup({ 'id' => $id });
    my $desk = $obj->get_current_desk;
    my $curr_desk_id = $desk->get_id;

    my ($next_desk_id, $next_workflow_id) =
        split /-/, $self->params->{"desk_asset|next_desk"};

    # Do not move assets where the user has not chosen a next desk,
    # or the desk ID is the same.
    return unless $next_desk_id and $next_desk_id != $curr_desk_id;

    unless ($obj->get_version > 0 && $obj->is_current) {
        $self->raise_conflict(
            'Cannot move [_1] asset "[_2]" while it is checked out.',
            $class,
            $obj->get_name
        );
        return;
    }

    if ($next_desk_id eq 'shelve') {
        if ($obj->get_checked_out) {
            $desk->checkin($obj);
            log_event("${class}_checkin", $obj, {
                Version => $obj->get_version
            });
        }
        $desk->remove_asset($obj)->save;
        $obj->set_workflow_id(undef);
        $obj->save;
        log_event("${class}_rem_workflow", $obj);
        return;
    } elsif ($next_desk_id eq 'publish') {
        $self->_move_to_publish_desk($obj);
        $self->params->{"${class}_pub"} = { $obj->get_version_id => $obj };
        $self->publish;
        return;
    } elsif ($next_desk_id eq 'deploy') {
        if ($class eq 'template') {
            $self->_move_to_publish_desk($obj);
            $self->params->{"desk_asset|template_pub_ids"} = [ $obj->get_version_id ];
            $self->deploy;
        }
        return;
    }

    # Get the next desk.
    my $next = $pkgs->{desk}->lookup({'id' => $next_desk_id});

    # Transfer from the current to the next.
    $desk->transfer({'to'    => $next,
                     'asset' => $obj});

    # Save both desks.
    $desk->save;
    $next->save;

    if (ALLOW_WORKFLOW_TRANSFER) {
        if ($next_workflow_id != $obj->get_workflow_id) {
            # Transfer workflows.
            $obj->set_workflow_id($next_workflow_id);
            $obj->save;
            my $wf = Bric::Biz::Workflow->lookup({ id => $next_workflow_id });
            log_event("${class}_add_workflow", $obj,
                      { Workflow => $wf->get_name });
        }
    }

    # Log an event
    log_event("${class}_moved", $obj, { Desk => $next->get_name });
}

sub publish : Callback {
    my $self = shift;
    my $param = $self->params;
    my $story_pub = $param->{story_pub} || {};
    my $media_pub = $param->{media_pub} || {};

    # If we were passed a string instead of an object, find the object
    for my $pub (\$story_pub, \$media_pub) {
        next if ref $$pub;

        my ($class, $version_id) = split /_/, $$pub;
        my $obj = $pkgs->{$class}->lookup({ version_id => $version_id });
        $$pub = { $obj->get_version_id => $obj };
    }

    my $story = mk_aref($param->{$self->class_key.'|story_pub_ids'});
    my $media = mk_aref($param->{$self->class_key.'|media_pub_ids'});
    my (@rel_story, @rel_media);

    # start with the objects checked for publish
    my @stories = values %$story_pub;
    my @media   = values %$media_pub;
    push @stories, $pkgs->{story}->list({ version_id => ANY(@$story) }) if @$story;
    push @media,   $pkgs->{media}->list({ version_id => ANY(@$media) }) if @$media;

    my %selected = (
        story => { map { $_->get_id => undef } @stories },
        media => { map { $_->get_id => undef } @media   },
    );

    my (@sids, @mids, %desks);

    my (%seen, @messages);

    for ([story => \@stories, $story_pub],
         [media => \@media,   $media_pub]
     ) {
        my ($key, $objs, $pub_ids) = @$_;
        # iterate through objects looking for related and stories
        while (@$objs) {
            my $doc = shift @$objs or next;

            # haven't I seen you someplace before?
            my $vid = $doc->get_version_id;
            my $id =  $doc->get_id;
            next if $seen{"$key$id"};

            unless (chk_authz($doc, PUBLISH, 1)) {
                my $doc_disp_name = lc get_disp_name($key);
                push @messages, [
                    'You do not have permission to publish '
                    . qq{$doc_disp_name "[_1]"},
                    $doc->get_name,
                ];
                next;
            }

            if ($doc->get_checked_out) {
                # Cannot publish checked-out assets.
                my $doc_disp_name = lc get_disp_name($key);
                push @messages,[
                    'Cannot publish $doc_disp_name "[_1]" because it is '
                    . " checked out.",
                    $doc->get_name,
                ];
                delete $pub_ids->{$vid};
                next;
            }

            # Hang on to your hat!
            my $ids = $key eq 'story' ? \@sids : \@mids;
            push @$ids, $vid;

            # Examine all the related objects.
            if (PUBLISH_RELATED_ASSETS) {
                foreach my $rel ($doc->get_related_objects) {
                    # Skip assets that don't need to be published.
                    next unless $rel->needs_publish;
                    # Skip deactivated documents.
                    next unless $rel->is_active;

                    # haven't I seen you someplace before?
                    my $relid  = $rel->get_id;
                    my $relkey = $rel->key_name;
                    next if exists $selected{$relkey}{$relid}
                        || $seen{"$relkey$relid"};
                    my $relvid = $rel->get_version_id;

                    if ($rel->get_checked_out) {
                        # Cannot publish checked-out assets.
                        my $rel_disp_name = lc get_disp_name($rel->key_name);
                        push @messages,[
                            "Cannot auto-publish related $rel_disp_name "
                            . '"[_1]" because it is checked out.',
                            $rel->get_name,
                        ];
                        next;
                    }

                    if ($rel->get_workflow_id) {
                        # It must be on a publish desk.
                        my $did = $rel->get_desk_id;
                        my $desk = $desks{$did}
                            ||= Bric::Biz::Workflow::Parts::Desk->lookup({
                                id => $did,
                            });
                        unless ($desk->can_publish) {
                            my $rel_disp_name = lc get_disp_name($rel->key_name);
                            push @messages,[
                                "Cannot auto-publish related $rel_disp_name "
                                . '"[_1]" because it is not on a publish desk.',
                                $rel->get_name,
                            ];
                            next;
                        }
                    }

                    unless (chk_authz($rel, PUBLISH, 1)) {
                        # Permission denied!
                        my $rel_disp_name = lc get_disp_name($rel->key_name);
                        push @messages,[
                            'You do not have permission to auto-publish '
                            . qq{$rel_disp_name "[_1]"},
                            $rel->get_name,
                        ];
                        next;
                    }

                    # Push onto the appropriate list
                    if ($relkey eq 'story') {
                        push @rel_story, $relvid;
                        push @sids,      $relvid if $pub_ids->{$vid};
                        push @stories,   $rel; # recurse through related stories
                    } else {
                        push @rel_media, $relvid;
                        push @mids,      $relvid if $pub_ids->{$vid};
                    }
                }

                # Publish all aliases, too.
                push @$ids,  map { $_->get_version_id } $doc->list({
                    alias_id          => $doc->get_id,
                    publish_status    => 1,
                    published_version => 1,
                });
            }

            # We've been processed now so make sure we aren't done again
            $seen{"$key$id"}++;
        }

    }

    # By this point we now know if we're going to fail this publish
    # if we set the fail behaviour to fail rather than warn
    if (PUBLISH_RELATED_ASSETS && @messages) {
        if (PUBLISH_RELATED_FAIL_BEHAVIOR eq 'fail') {
            $self->add_message(@$_) for @messages;
            my $msg = 'Publish aborted due to errors above. Please fix the '
                . ' above problems and try again.';
            throw_error error    => $msg,
                        maketext => $msg;
        } else {
            # we are set to warn, should we add a further warning to the msg ?
            $self->raise_conflict(@$_) for @messages,
                'Some of the related assets were not published.';
        }
    } else {
        $self->raise_conflict(@$_) for @messages;
    }

    # For publishing from a desk, I added two new 'publish'
    # state data: 'rel_story', 'rel_media'. This is to be
    # able to distinguish between related assets and the
    # original stories to be published.
    set_state_data('publish', {
        story => \@sids,
        media => \@mids,
        story_pub => $story_pub,
        media_pub => $media_pub,
        (@rel_story ? (rel_story => \@rel_story) : ()),
        (@rel_media ? (rel_media => \@rel_media) : ())
    });

    if (%$story_pub or %$media_pub) {
        # Instant publish!
        my $pub = Bric::App::Callback::Publish->new(
            cb_request   => $self->cb_request,
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
    my $widget = $self->class_key;

    if (my $ids = $self->params->{"$widget|template_pub_ids"}) {
        my $burner = Bric::Util::Burner->new;

        $ids = mk_aref($ids);

        if (my $count = @$ids) {
            for my $template (Bric::Biz::Asset::Template->list({
                version_id => ANY(@$ids)
            })) {
                my $action = $template->get_deploy_status ? 'template_redeploy'
                    : 'template_deploy';
                $burner->deploy($template);
                $template->set_deploy_date(strfdate());
                $template->set_deploy_status(1);
                $template->set_published_version($template->get_current_version);
                $template->save;
                log_event($action, $template);

                # Get the current desk and remove the asset from it.
                my $desk = $template->get_current_desk;
                $desk->remove_asset($template);
                $desk->save;

                # Clear the workflow ID.
                $template->set_workflow_id(undef);
                $template->save;
                log_event("template_rem_workflow", $template);
                $self->add_message('Template "[_1]" deployed.', $template->get_uri)
                    if $count == 1;
            }
            # Sum it up for them
            if ($count > 1) {
                $self->add_message('[quant,_1,template] deployed.', $count);
            }
        }
    }

    # If there are stories or media to be published, publish them!
    if ($self->params->{"$widget|story_pub_ids"}
          || $self->params->{"$widget|media_pub_ids"}) {
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

sub delete : Callback {
    my $self = shift;
    my ($class, $id) = split /_/, $self->value;
    my $obj  = $pkgs->{$class}->lookup({ 'id' => $id });

    if (chk_authz($obj, EDIT, 1)) {
        my $desk = $obj->get_current_desk;
        $desk->checkin($obj) if $obj->get_checked_out;
        $desk->remove_asset($obj);
        $obj->set_workflow_id(undef);
        $obj->deactivate;
        $desk->save;
        $obj->save;
        log_event("${class}_rem_workflow", $obj);

        if ($class eq 'template') {
            my $burn = Bric::Util::Burner->new;
            $burn->undeploy($obj);
            my $sandbox = Bric::Util::Burner->new({user_id => get_user_id()});
            $sandbox->undeploy($obj);
        }
        log_event("${class}_deact", $obj);
    } else {
        $self->raise_forbidden(
            'Permission to delete "[_1]" denied.',
            $obj->get_name
        );
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
    if (ALLOW_SLUGLESS_NONFIXED || $story->is_fixed || $param->{slug} =~ /\S/) {
        $story->set_slug($param->{slug});
    } else {
        $self->raise_conflict('Slug required for non-fixed (non-cover) story type.');
        $err++;
    }

    # Category
    my $cid = $param->{"$widget|new_category_id"};
    unless (defined $cid && $cid ne '') {
        $self->raise_conflict('Please select a primary category.');
        $err++;
    } else {
        # Delete all the current categories first,
        # then add the new category and make it primary.
        # It's a little more complicated to avoid
        # deleting the new category if it's already there.
        my %todelete_cats = map { $_->get_id => $_ } $story->get_categories;

        my $was_there = delete($todelete_cats{$cid}) || 0;
        $story->add_categories([$cid]) unless $was_there;
        if (my $seconds = $param->{"$widget|secondary_category_id"}) {
            # Add secondary categories.
            my @add;
            for my $catid (@{mk_aref($seconds)}) {
                # Leave existing seconary categories and the primary category.
                next if delete $todelete_cats{$catid} || $catid == $cid;
                push @add, Bric::Biz::Category->lookup({ id => $catid });
            }
            $story->add_categories(\@add) if @add;
        }
        $story->delete_categories([ values(%todelete_cats) ]) if %todelete_cats;
        $story->set_primary_category($cid);
    }

    # Cover date
    if ($param->{'cover_date-partial'}) {
        $self->raise_conflict('Cover Date incomplete.');
        $err++;
    } else {
        $story->set_cover_date($param->{cover_date});
    }

    # Output Channel
    my $ocid = $param->{"$widget|new_oc_id"};
    unless (defined $ocid && $ocid ne '') {
        $self->raise_conflict('Please select a primary output channel.');
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

        # Add any secondary output channels.
        my (%seen, @add);
        if (my $ocs2 = $param->{"$widget|secondary_oc_id"}) {
            for my $oc2id (@{mk_aref($ocs2)}) {
                # Leave existing seconary OCs and the primary OC.
                next if delete $todelete_ocs{$oc2id} || $oc2id == $ocid;
                push @add, Bric::Biz::OutputChannel->lookup({ id => $oc2id })
                  unless $seen{$oc2id}++;
            }
        }

        # Add any secondary output channels from an associated OC group.
        if (my $grp_id = $param->{"$widget|oc_grp_id"}) {
            my %allowed = map { $_->get_id => 1 }
              $story->get_element_type->get_output_channels;
            push @add,
              map { $_->[1] }
              grep {
                  $allowed{$_->[0]}
                  && !$seen{$_->[0]}++
                  && ! delete $todelete_ocs{$_->[0]}
              }
              map { [ $_->get_id => $_ ] }
              Bric::Biz::OutputChannel->list({ grp_id => $grp_id });
        }

        # Now add them.
        $story->add_output_channels(@add) if @add;

        # Delete any leftovers.
        $story->del_output_channels(values %todelete_ocs) if %todelete_ocs;
    }

    return 1 unless $err;
    return;
}

sub _move_to_publish_desk {
    my ($self, $obj) = @_;

    my $class = $obj->key_name;
    my $cur_desk = $obj->get_current_desk;

    # Publish the template and remove it from workflow.
    my ($pub_desk, $no_log);
    # Find a publish desk.
    if ($cur_desk->can_publish) {
        # We've already got one.
        $pub_desk = $cur_desk;
        $no_log = 1;
    } else {
        # Find one in this workflow.
        my $workflow = $obj->get_workflow_object;
        foreach my $d ($workflow->allowed_desks) {
            $pub_desk = $d and last if $d->can_publish;
        }
        # Transfer the template to the publish desk.
        $cur_desk->transfer({ to    => $pub_desk,
                              asset => $obj });
        $cur_desk->save;
        $pub_desk->save;
    }

    $obj->save;

    log_event("${class}_moved", $obj, { Desk => $pub_desk->get_name }) unless $no_log;
}

1;
