package Bric::App::Callback::Profile::Story;

use base qw(Bric::App::Callback);   # not subclassing Profile
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'story_prof';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Callback::Desk;
use Bric::App::Callback::Util::OutputChannel qw(update_output_channels);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:history :aref next_msg);
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Category;
use Bric::Biz::Keyword;
use Bric::Biz::OutputChannel;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Config qw(:ui ISO_8601_FORMAT);
use Bric::Util::DBI qw(:trans);
use Bric::Util::Fault qw(:all);
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::App::Callback::Search;

my $SEARCH_URL = '/workflow/manager/story/';
my $ACTIVE_URL = '/workflow/active/story/';
my $DESK_URL   = '/workflow/profile/desk/';

my ($save_category, $unique_msgs);

sub view : Callback {
    my $self = shift;
    my $params = $self->params;

    # Abort this save if there were any errors in the update callback.
    return if delete $params->{__data_errors__};

    my $widget = $self->class_key;
    my $story  = get_state_data($widget => 'story');
    my $version = $params->{"$widget|version"};
    my $id = $story->get_id;
    $self->set_redirect("/workflow/profile/story/$id/?version=$version");
}

sub diff : Callback {
    my $self   = shift;
    my $widget = $self->class_key;
    my $params = $self->params;
    my $story  = get_state_data($widget, 'story');
    my $id     = $story->get_id;

    # Find the from and to version numbers.
    my $from = $params->{"$widget|from_version"} || $params->{"$widget|version"};
    my $to   = $params->{"$widget|to_version"}   || $story->get_version;

    # Send it on home.
    $self->set_redirect(
        "/workflow/profile/story/$id/?diff=1"
        . "&from_version=$from&to_version=$to"
    );
}

sub revert : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');
    my $version = $self->params->{"$widget|version"};
    $story->revert($version);
    $story->save;
    $self->add_message(
        'Story "[_1]" reverted to V.[_2].',
        '<span class="l10n">' . $story->get_title . '</span>',
        $version,
    );
    $self->params->{checkout} = 1; # Reload checked-out story.
    set_state_data($widget, 'story');
}

sub save : Callback(priority => 6) {
    my $self = shift;
    my $param = $self->params;
    # Just return if there was a problem with the update callback.
    return if delete $param->{__data_errors__};

    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');

    my $workflow_id = $story->get_workflow_id;
    if ($param->{"$widget|delete"}) {
        # Delete the story.
        return unless $self->_handle_delete($story);
    } else {
        # Save the story.
        $story->save;
        log_event('story_save', $story);
        $self->add_message(
            'Story "[_1]" saved.',
            '<span class="l10n">' . $story->get_title . '</span>'
        );

    }

    my $return = get_state_data($widget, 'return') || '';

    # Clear the state and send 'em home.
    $self->clear_my_state;

    if ($return eq 'search') {
        my $url = $SEARCH_URL . $workflow_id . '/';
        $self->set_redirect($url);
    } elsif ($return eq 'active') {
        my $url = $ACTIVE_URL . $workflow_id;
        $self->set_redirect($url);
    } elsif ($return =~ /\d+/) {
        my $url = $DESK_URL . $workflow_id . '/' . $return . '/';
        $self->set_redirect($url);
    } else {
        $self->set_redirect("/");
    }
}

sub checkin : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');
    my $param = $self->params;
    # Abort this save if there were any errors.
    return unless $self->_save_data($param, $widget, $story);

    my $work_id = get_state_data($widget, 'work_id');
    my $wf;
    if ($work_id) {
        # Set the workflow this story should be in.
        $story->set_workflow_id($work_id);
        $wf = Bric::Biz::Workflow->lookup( { id => $work_id });
        log_event('story_add_workflow', $story,
                  { Workflow => $wf->get_name });
        $story->checkout({ user__id => get_user_id() })
          unless $story->get_checked_out;
    }

    $story->checkin;

    # Get the desk information.
    my $desk_id = $param->{"$widget|desk"};
    my $cur_desk = $story->get_current_desk;

    # See if this story needs to be removed from workflow or published.
    if ($desk_id eq 'remove') {
        # Remove from the current desk and from the workflow.
        $cur_desk->remove_asset($story)->save if $cur_desk;
        $story->set_workflow_id(undef);
        $story->save;
        log_event('story_save', $story);
        log_event('story_checkout', $story) if $work_id;
        log_event('story_checkin', $story, { Version => $story->get_version });
        log_event("story_rem_workflow", $story);
        $self->add_message(
            'Story "[_1]" saved and shelved.',
            '<span class="l10n">' . $story->get_title . '</span>',
        );
        # Clear the state out and set redirect.
        $self->clear_my_state;
        $self->set_redirect('/');
    } elsif ($desk_id eq 'publish') {
        # Publish the story and remove it from workflow.
        my ($pub_desk, $no_log);
        # Find a publish desk.
        if ($cur_desk and $cur_desk->can_publish) {
            # We've already got one.
            $pub_desk = $cur_desk;
            $no_log = 1;
        } else {
            # Find one in this workflow.
            $wf ||= $story->get_workflow_object;
            foreach my $d ($wf->allowed_desks) {
                $pub_desk = $d and last if $d->can_publish;
            }
            # Transfer the story to the publish desk.
            if ($cur_desk) {
                $cur_desk->transfer({ to    => $pub_desk,
                                      asset => $story });
                $cur_desk->save;
            } else {
                $pub_desk->accept({ asset => $story });
            }
            $pub_desk->save;
        }

        $story->save;

        # Log it!
        log_event('story_save', $story);
        log_event('story_checkin', $story, { Version => $story->get_version });
        my $dname = $pub_desk->get_name;
        log_event('story_moved', $story, { Desk => $dname })
          unless $no_log;
        $self->add_message(
            'Story "[_1]" saved and checked in to "[_2]".',
            '<span class="l10n">' . $story->get_title . '</span>',
            $dname,
        );

        # Prevent loss of data due to publish failure.
        commit(1);
        begin(1);
        # Use the desk callback to save on code duplication.
        clear_authz_cache( $story );
        my $pub = Bric::App::Callback::Desk->new(
            cb_request   => $self->cb_request,
            apache_req   => $self->apache_req,
            params       => { story_pub => { $story->get_version_id => $story } },
        );

        # Clear the state out, set redirect, and publish.
        $self->clear_my_state;
        $self->set_redirect('/');
        $pub->publish;

    } else {
        # Look up the selected desk.
        my $desk = Bric::Biz::Workflow::Parts::Desk->lookup
          ({ id => $desk_id });
        my $no_log;
        if ($cur_desk) {
            if ($cur_desk->get_id == $desk_id) {
                $no_log = 1;
            } else {
                # Transfer the story to the new desk.
                $cur_desk->transfer({ to    => $desk,
                                      asset => $story });
                $cur_desk->save;
            }
        } else {
            # Send this story to the selected desk.
            $desk->accept({ asset => $story });
        }

        $desk->save;
        $story->save;
        log_event('story_save', $story);
        log_event('story_checkin', $story, { Version => $story->get_version });
        my $dname = $desk->get_name;
        log_event('story_moved', $story, { Desk => $dname }) unless $no_log;
        $self->add_message(
            'Story "[_1]" saved and moved to "[_2]".',
            '<span class="l10n">' . $story->get_title . '</span>',
            $dname,
        );

        # Clear the state out and set redirect.
        $self->clear_my_state;
        $self->set_redirect('/');
    }
}

sub save_and_stay : Callback(priority => 6) {
    my $self = shift;
    my $param = $self->params;
    # Just return if there was a problem with the update callback.
    return if delete $param->{__data_errors__};

    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');

    if ($param->{"$widget|delete"}) {
        # Delete the story.
        return unless $self->_handle_delete($story);
        # Get out of here, since we've blow it away!
        $self->set_redirect("/");
        $self->clear_my_state;
    } else {
        # Make sure the story is activated and then save it.
        $story->activate;
        $story->save;
        log_event('story_save', $story);
        $self->add_message(
            'Story "[_1]" saved.',
            '<span class="l10n">' . $story->get_title . '</span>',
        );
    }
}

sub cancel : Callback(priority => 6) {
    my $self = shift;

    my $story = get_state_data($self->class_key, 'story');
    if ($story->get_version == 0) {
        # If the version number is 0, the story was never checked in. So just
        # delete it.
        return unless $self->_handle_delete($story);
    } else {
        # Cancel the checkout.
        $story->cancel_checkout;
        log_event('story_cancel_checkout', $story);

        # If the story was last recalled from the library, then remove it
        # from the desk and workflow. We can tell this because there will
        # only be one story_moved event and one story_checkout event
        # since the last story_add_workflow event.
        my @events = Bric::Util::Event->list({
            class => ref $story,
            obj_id => $story->get_id
        });
        my ($desks, $cos) = (0, 0);
        while (@events && $events[0]->get_key_name ne 'story_add_workflow') {
            my $kn = shift(@events)->get_key_name;
            if ($kn eq 'story_moved') {
                $desks++;
            } elsif ($kn eq 'story_checkout') {
                $cos++
            }
        }

        # If one move to desk, and one checkout, and this isn't the first
        # time the story has been in workflow since it was created...
        # XXX Three events upon creation: story_create, story_add_category,
        # and story_moved.
        if ($desks == 1 && $cos == 1 && @events > 3) {
            # It was just recalled from the library. So remove it from the
            # desk and from workflow.
            my $desk = $story->get_current_desk;
            $desk->remove_asset($story);
            $story->set_workflow_id(undef);
            $desk->save;
            $story->save;
            log_event("story_rem_workflow", $story);
        } else {
            # Just save the cancelled checkout. It will be left in workflow for
            # others to find.
            $story->save;
        }
        $self->add_message(
            'Story "[_1]" check out canceled.',
            '<span class="l10n">' . $story->get_title . '</span>',
        );
    }
    $self->clear_my_state;
    $self->set_redirect("/");
}

sub return : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;
    my $version_view = get_state_data($widget, 'version_view');

    my $story = get_state_data($widget, 'story');

    # note: $self->value =~ /^\d+$/ is for IE which sends the .x or .y position
    # of the mouse for <input type="image"> buttons
    if ($version_view || $self->value eq 'diff' || $self->value =~ /^\d+$/) {
        my $story_id = $story->get_id;
        $self->clear_my_state if $version_view;
        $self->set_redirect("/workflow/profile/story/$story_id/?checkout=1");
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
        $self->clear_my_state;
        $self->set_redirect($url);
    }
}

sub cancel_return : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;
    my $version_view = get_state_data($widget, 'version_view');

    my $story = get_state_data($widget, 'story');

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
    $self->clear_my_state;
    $self->set_redirect($url);
}

sub create : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $param = $self->params;

    # Check permissions.
    my $work_id = get_state_data($widget, 'work_id');
    my $wf = Bric::Biz::Workflow->lookup({ id => $work_id });
    my $start_desk = $wf->get_start_desk;
    my $gid = $start_desk->get_asset_grp;
    chk_authz('Bric::Biz::Asset::Business::Story', CREATE, 0, $gid);

    # Make sure we have the required data.
    my $ret;

    if (AUTOGENERATE_SLUG) {
        # Create a slug based on title if there is no slug.
        ($param->{slug} = substr($param->{title}, 0, 32)) =~ y/a-zA-Z0-9/_/cs
          unless defined $param->{slug} && $param->{slug} =~ /\S/;
    }

    # Check the story type.
    if (defined $param->{"$widget|at_id"} && $param->{"$widget|at_id"} ne '') {
        unless (ALLOW_SLUGLESS_NONFIXED) {
            # Make sure a non-Cover uses a slug
            my $at_id = $param->{"$widget|at_id"};
            my $element = Bric::Biz::ElementType->lookup({id => $at_id});
            unless ($element->is_fixed_uri) {
                unless (defined $param->{slug} && $param->{slug} =~ /\S/) {
                    $self->add_message(
                        'Slug required for non-fixed (non-cover) story type.'
                    );
                    $ret = 1;
                }
            }
        }
    } else {
        $self->raise_conflict("Please select a story type.");
        $ret = 1;
    }

    # Check the category ID.
    my $curi = $param->{new_category_autocomplete};
    unless (defined $curi && $curi ne '') {
        $self->raise_conflict("Please select a primary category.");
        $ret = 1;
    }

    # Return if there are problems.
    return if $ret;

    # Create a new story with the initial values given.
    my $init = {
        element_type_id => $param->{"$widget|at_id"},
        source__id      => $param->{"$widget|source__id"},
        site_id         => $wf->get_site_id,
        user__id        => get_user_id,
    };

    my $story = Bric::Biz::Asset::Business::Story->new($init);

    # Set the primary category
    my $cat = Bric::Biz::Category->lookup({
        uri     => $curi,
        site_id => $wf->get_site_id,
    });
    $story->add_categories([$cat]);
    $story->set_primary_category($cat);

    # Set the workflow this story should be in.
    $story->set_workflow_id($work_id);

    # Set the slug and cover date and save the story.
    if ($param->{'cover_date-partial'}) {
        $self->raise_conflict('Cover Date incomplete.');
        return;
    }

    $story->set_slug($param->{slug});
    $story->set_cover_date($param->{cover_date});
    $story->save;

    # Send this story to the first desk.
    $start_desk->accept({ asset => $story });
    $start_desk->save;
    $story->save;

    # Save everything else unless there were data errors
    unless ($self->_save_data($param, $widget, $story)) {
        # Oops, there were data errors. Delete it and return.
        # XXX. Ideally, we wouldn't have to do this, but this is the only
        # way to remove it from workflow, at the moment.
        $self->_handle_delete($story);
        return;
    }

    # Save story again now that data was added...
    $story->save;

    # Log that a new story has been created and generally handled.
    log_event('story_new', $story);
    log_event('story_add_category', $story, { Category => $cat->get_name });
    log_event('story_add_workflow', $story, { Workflow => $wf->get_name });
    log_event('story_moved', $story, { Desk => $start_desk->get_name });
    log_event('story_save', $story);
    $self->add_message(
        'Story "[_1]" created and saved.',
        '<span class="l10n">' . $story->get_title . '</span>',
    );

    # Put the story into the session and clear the workflow ID.
    set_state_data($widget, 'story', $story);
    set_state_data($widget, 'work_id', '');

    # Head for the main edit screen.
    $self->set_redirect("/workflow/profile/story/");

    # As far as history is concerned, this page should be part of the story
    # profile stuff.
    pop_page();
}

sub notes : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $param = $self->params;
    my $story = get_state_data($widget, 'story');
    # Return if there were data errors.
    return unless $self->_save_data($param, $widget, $story);

    my $id    = $story->get_id();
    my $action = $param->{$widget.'|notes_cb'};
    $self->set_redirect("/workflow/profile/story/${action}_notes.html?id=$id");
}

sub trail : Callback {
    my $self = shift;

    # Return if there were data errors
    return unless $self->_save_data();

    my $story = get_state_data($self->class_key, 'story');
    my $id = $story->get_id();
    $self->set_redirect("/workflow/events/story/$id?filter_by=story_moved");
}

sub update : Callback(priority => 1) {
    shift->_save_data();
}

sub exit : Callback {
    my $self = shift;

    set_state($self->class_key, {});
    # Set the redirect to the page we were at before here.
    $self->set_redirect(last_page() || "/workflow/search/story/");
    # Remove this page from history.
    pop_page();
}

sub checkout : Callback {
    my $self = shift;

    my $ids = $self->value;
    $ids = ref $ids ? $ids : [$ids];
    my $co;

    foreach my $id (@$ids) {
        my $ba = Bric::Biz::Asset::Business::Story->lookup({'id' => $id});
        if (chk_authz($ba, EDIT, 1)) {
            $ba->checkout({'user__id' => get_user_id()});
            $ba->save;
            $co++;

            # Log Event.
            log_event('story_checkout', $ba);
        } else {
            $self->raise_forbidden(
                'Permission to checkout "[_1]" denied.',
                '<span class="l10n">' . $ba->get_title . '</span>',
            );
        }
    }

    # Just bail if they don't have the proper permissions.
    return unless $co;

    if ($co > 1) {
        # Go to 'my workspace'
        $self->set_redirect("/");
    } else {
        # Go to the profile screen
        $self->set_redirect('/workflow/profile/story/'.$ids->[0].'?checkout=1');
    }
}

sub recall : Callback {
    my $self = shift;

    my $ids = $self->params->{$self->class_key.'|recall_cb'};
    $ids = ref $ids ? $ids : [$ids];
    my ($co, %wfs);

    foreach my $id (@$ids) {
        my ($o_id, $w_id) = split('\|', $id);
        my $ba = Bric::Biz::Asset::Business::Story->lookup({'id' => $o_id});
        if (chk_authz($ba, RECALL, 1)) {
            my $wf = $wfs{$w_id} ||= Bric::Biz::Workflow->lookup({'id' => $w_id});

            # Make sure the workflow ID is valid. (XXX: why isn't this before the lookup?)
            unless ($w_id) {
                throw_dp('error' => "Bad Workflow ID '$w_id'");
            }

            # They checked 'Include deleted' and the 'Reactivate' checkbox
            # XXX: is this sufficient?
            unless ($ba->is_active) {
                $ba->activate();
            }

            # Put this story into the current workflow and log it.
            $ba->set_workflow_id($w_id);
            log_event('story_add_workflow', $ba, { Workflow => $wf->get_name });

            # Get the start desk for this workflow.
            my $start_desk = $wf->get_start_desk;

            # Put this story on the start desk.
            $start_desk->accept({'asset' => $ba});
            $start_desk->checkout($ba, get_user_id());
            $start_desk->save;
            log_event('story_moved', $ba, { Desk => $start_desk->get_name });
            log_event('story_checkout', $ba);
            $co++;
        } else {
            $self->raise_forbidden(
                'Permission to checkout "[_1]" denied.',
                '<span class="l10n">' . $ba->get_title . '</span>',
            );
        }
    }

    # Just bail if they don't have the proper permissions.
    return unless $co;

    if ($co > 1) {
        # Go to 'my workspace'
        $self->set_redirect("/");
    } else {
        my ($o_id, $w_id) = split('\|', $ids->[0]);
        # Go to the profile screen
        $self->set_redirect('/workflow/profile/story/'.$o_id.'?checkout=1');
    }
}

sub categories : Callback {
    my $self = shift;
    # Return if there were data errors
    return unless $self->_save_data();
    $self->set_redirect("/workflow/profile/story/categories.html");
}

sub assoc_category : Callback {
    my $self = shift;

    my $story = get_state_data($self->class_key, 'story');
    chk_authz($story, EDIT);

    my $cat_id = $self->value;
    my $cat = Bric::Biz::Category->lookup({ id => $cat_id });
    $story->add_categories([$cat]);
    eval { $story->save; };
    if (my $err = $@) {
        $story->delete_categories([ $cat_id ]);
        die $err;
    }
    log_event('story_add_category', $story, { Name => $cat->get_name });
    # Avoid unnecessary empty searches.
    Bric::App::Callback::Search->no_new_search;
}

sub save_category : Callback {
    my $self = shift;

    $save_category->($self->class_key, $self->params, $self);
    # Set a redirect for the previous page.
    $self->set_redirect(last_page());
    # Pop this page off the stack.
    pop_page();
}

sub save_and_stay_category : Callback {
    my $self = shift;
    $save_category->($self->class_key, $self->params, $self);
}

sub leave_category : Callback {
    my $self = shift;

    # Set a redirect for the previous page.
    $self->set_redirect(last_page());
    # Pop this page off the stack.
    pop_page();
}

### end of callbacks

sub clear_my_state {
    my $self = shift;
    clear_state($self->class_key);
    clear_state('container_prof');
}

##############################################################################

$save_category = sub {
    my ($widget, $param, $self) = @_;

    # get the categories to delete
    my $story = get_state_data($widget, 'story');

    my $existing = { map { $_->get_id => 1 } $story->get_categories };
    chk_authz($story, EDIT);
    my $cat_id = mk_aref($param->{$widget.'|delete_id'});
    my $msg;
    my @to_delete;
    my $primary_cid = $story->get_primary_category->get_id;

    foreach my $id (@$cat_id) {
        if ($id == $primary_cid) {
            $self->raise_conflict('The primary category cannot be deleted.');
            next;
        }
        delete $existing->{$id};
        push @to_delete, $id;
        my $cat = Bric::Biz::Category->lookup({ id => $id });
        log_event('story_del_category', $story, { Name => $cat->get_name });
    }

    if (@to_delete) {
        $self->add_message('Categories disassociated.');
        $story->delete_categories(\@to_delete);
    }

    # Change the primary category?
    my $new_prime = $param->{"$widget|set_primary_category"};
    if ($new_prime != $primary_cid && exists $existing->{$new_prime}) {
        my $primary_cat = Bric::Biz::Category->lookup({ id => $new_prime });
        $story->set_primary_category($primary_cat);
    }

    # Avoid unnecessary empty searches.
    Bric::App::Callback::Search->no_new_search;
};

# removes repeated error messages
$unique_msgs = sub {
    my $self = shift;
    my (%seen, @msgs);
    while (my $msg = next_msg) {
        push @msgs, $msg unless $seen{$msg}++;
    }
    $self->add_message($_) for @msgs;
};

sub _save_data {
    my ($self, $param, $widget, $story) = @_;
    my $data_errors = 0;

    $param  ||= $self->params;
    $widget ||= $self->class_key;
    $story  ||= get_state_data($widget, 'story');
    chk_authz($story, EDIT);

    # Make sure the story is active.
    $story->activate;
    my $uid = get_user_id();

    unless (ALLOW_SLUGLESS_NONFIXED) {
        # Make sure a non-Cover has a slug
        my $at_id = $story->get_element_type_id;
        my $element = Bric::Biz::ElementType->lookup({id => $at_id});
        unless ($element->is_fixed_uri) {
            unless (defined $param->{slug} && $param->{slug} =~ /\S/) {
                $self->raise_conflict(
                    'Slug required for non-fixed (non-cover) story type.'
                );
                $data_errors = 1;
            }
        }
    }
    unless ($data_errors) {
        eval { $story->set_slug($param->{slug}) };
        if (my $err = $@) {
            rethrow_exception($err) unless isa_bric_exception($err, 'Error');
            $self->raise_conflict($err->maketext);
            $data_errors = 1;
        }
    }

    $story->set_title($param->{title})
      if exists $param->{title};
    $story->set_description($param->{description})
      if exists $param->{description};
    $story->set_source__id($param->{"$widget|source__id"})
      if exists $param->{"$widget|source__id"};
    $story->set_priority($param->{priority})
      if exists $param->{priority};

    if ($param->{'cover_date-partial'}) {
        $self->raise_conflict('Cover Date incomplete.');
        $data_errors = 1;
    } elsif (exists $param->{cover_date}) {
        $story->set_cover_date($param->{cover_date});
    }

    if ($param->{'expire_date-partial'}) {
        $self->raise_conflict('Expire Date incomplete.');
        $data_errors = 1;
    } elsif (exists $param->{expire_date}) {
        $story->set_expire_date($param->{expire_date});
    }

    update_output_channels($self, $story, $param);

    $self->_handle_categories($story, $param, $widget);

    $self->_handle_keywords($story, $param);

    $self->_handle_contributors($story, $param, $widget);

    # avoid repeated messages from repeated calls to _save_data
    $unique_msgs->($self) if $data_errors;

    set_state_data($widget, 'story', $story);

    $param->{__data_errors__} = $data_errors;
    return not $data_errors;
};

sub _handle_categories {
    my ($self, $story, $param, $widget) = @_;

    my ($cat_ids, @to_add, @to_delete, %checked_cats);
    my %existing_cats = map { $_->get_id => $_ } $story->get_categories;

    $cat_ids = mk_aref($param->{"category_id"});

    # Bail unless there are categories submitted via the UI. Otherwise we end
    # up deleting categories added during create().  This should also prevent
    # us from ever somehow deleting all categories on a story, which really
    # screws things up (the error is not (currently) fixable through the UI!)
    return unless @$cat_ids;

    foreach my $cat_id (@$cat_ids) {
        # Mark this category as seen so we don't delete it later
        $checked_cats{$cat_id} = 1;

        # If the category already exists, don't add it again
        if (defined $existing_cats{$cat_id}) {
            next;
        }

        # Since the category doesn't exist, we need to add it
        my $cat = Bric::Biz::Category->lookup({ id => $cat_id });
        push @to_add, $cat;
        log_event('story_add_category', $story, { Category => $cat->get_name });
    }

    $story->add_categories(\@to_add);

    $story->set_primary_category($param->{"primary_category_id"})
        if defined $param->{"primary_category_id"};

    my $primary = $param->{"primary_category_id"} || $story->get_primary_category->get_id;
    for my $cat_id (keys %existing_cats) {
        my $cat = $existing_cats{$cat_id};
        # If the category isn't still in the list of categories, delete it
        if (!(defined $checked_cats{$cat_id})) {
            if ($cat_id == $primary) {
                $self->add_message(
                    'Category "[_1]" cannot be dissociated because it is the primary category',
                    $cat->get_name,
                );
                next;
            }

            push @to_delete, $cat;
            log_event('story_del_category', $story, { Category => $cat->get_name });
        }
    }

    $story->delete_categories(\@to_delete);

    set_state_data($widget, 'story', $story);
};

sub _handle_keywords {
    my ($self, $story, $param) = @_;

    # Delete old keywords.
    my $old;
    my $keywords = { map { $_ => 1 } @{ mk_aref($param->{keyword_id}) } };
    foreach ($story->get_keywords) {
        push @$old, $_ unless $keywords->{$_->get_id};
    }
    $story->del_keywords(@$old) if $old;

    # Add new keywords.
    my $new;
    foreach (@{ mk_aref($param->{new_keyword}) }) {
        next unless $_;
        my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
        if ($kw) {
            chk_authz($kw, READ);
        } else {
            if (chk_authz('Bric::Biz::Keyword', CREATE, 1)) {
                $kw = Bric::Biz::Keyword->new({ name => $_ })->save;
                log_event('keyword_new', $kw);
            } else {
                throw_forbidden(
                    maketext => [
                        'Could not create keyword, "[_1]", as you have not been granted permission to create new keywords.',
                        $_,
                    ],
                );
            }
        }
        push @$new, $kw;
    }
    $story->add_keywords(@$new) if $new;
};

sub _handle_contributors {
    my ($self, $story, $param, $widget) = @_;

    my $existing = { map { $_->get_id => $_ } $story->get_contributors };

    my $order = {};
    foreach my $contrib_id (@{ mk_aref($param->{'contrib_id'}) }) {
        if (defined $existing->{$contrib_id}) {
            if ($existing->{$contrib_id}->{role} ne $param->{"$widget|contrib_role_$contrib_id"}) {
                # Update role (add_contributor updates if $contrib_id already exists)
                $story->add_contributor($contrib_id, $param->{"$widget|contrib_role_$contrib_id"});
            }
            delete $existing->{$contrib_id};
        } else {
            # Contributor did not previously exist, so add it
            $story->add_contributor($contrib_id, $param->{"$widget|role_$contrib_id"});
        }
        $order->{$contrib_id} = $param->{$widget . '|contrib_order_' . $contrib_id};
    }

    if (my @to_delete = keys %$existing) {
        $story->delete_contributors(\@to_delete);

        my $contrib;
        foreach my $id (@to_delete) {
            $contrib = $existing->{$id}->{obj};
            delete $existing->{$id};
            log_event('story_del_contrib', $story,
                      { Name => $contrib->get_name });
        }
        if (scalar @to_delete > 1) {
            $self->add_message('Contributors disassociated.');
        } else {
            $self->add_message(
                'Contributor "[_1]" disassociated.',
                $contrib->get_name,
            );
        }
    }

    $story->reorder_contributors(sort { $order->{$a} <=> $order->{$b} } keys %$order);

    # Avoid unnecessary empty searches.
    Bric::App::Callback::Search->no_new_search;
}

sub _handle_delete {
    my ($self, $story) = @_;
    my $desk = $story->get_current_desk();
    $desk->checkin($story) if $story->get_checked_out;
    $desk->remove_asset($story);
    $story->set_workflow_id(undef);
    $story->deactivate;
    $desk->save;
    $story->save;
    log_event("story_rem_workflow", $story);
    log_event("story_deact", $story);
    $self->add_message(
        'Story "[_1]" deleted.',
        '<span class="l10n">' . $story->get_title . '</span>',
    );
    return 1;
};

1;
__END__
