package Bric::App::Callback::Profile::Story;

use base qw(Bric::App::Callback);   # not subclassing Profile
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'story_prof';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Callback::Desk;
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:all);
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Category;
use Bric::Biz::Keyword;
use Bric::Biz::OutputChannel;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Config qw(ISO_8601_FORMAT);
use Bric::Util::DBI;
use Bric::Util::Fault qw(:all);
use Bric::Util::Grp::Parts::Member::Contrib;

my $SEARCH_URL = '/workflow/manager/story/';
my $ACTIVE_URL = '/workflow/active/story/';
my $DESK_URL = '/workflow/profile/desk/';

my ($save_contrib, $unique_msgs, $save_data, $handle_delete);


sub view : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');
    # Abort this save if there were any errors.
    return unless &$save_data($self, $self->request_args, $widget, $story);
    my $version = $self->request_args->{"$widget|version"};
    my $id = $story->get_id();
    set_redirect("/workflow/profile/story/$id/?version=$version");
}

sub revert : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');
    my $version = $self->request_args->{"$widget|version"};
    $story->revert($version);
    $story->save();
    my $msg = "Story [_1] reverted to V.[_2].";
    my @args = ('&quot;' . $story->get_title . '&quot;', $version);
    add_msg($self->lang->maketext($msg, @args));
    clear_state($widget);
}

sub save : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');
    my $param = $self->request_args;
    # Just return if there was a problem with the update callback.
    return if delete $param->{__data_errors__};

    my $workflow_id = $story->get_workflow_id;
    if ($param->{"$widget|delete"}) {
        # Delete the story.
        $handle_delete->($story, $self);
    } else {
        # Save the story.
        $story->save;
        log_event('story_save', $story);
        my $arg = '&quot;' . $story->get_title . '&quot;';
        add_msg($self->lang->maketext("Story [_1] saved.", $arg));
    }

    my $return = get_state_data($widget, 'return') || '';

    # Clear the state and send 'em home.
    clear_state($widget);

    if ($return eq 'search') {
        my $url = $SEARCH_URL . $workflow_id . '/';
        set_redirect($url);
    } elsif ($return eq 'active') {
        my $url = $ACTIVE_URL . $workflow_id;
        set_redirect($url);
    } elsif ($return =~ /\d+/) {
        my $url = $DESK_URL . $workflow_id . '/' . $return . '/';
        set_redirect($url);
    } else {
        set_redirect("/");
    }
}

sub checkin : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');
    my $param = $self->request_args;
    # Abort this save if there were any errors.
    return unless &$save_data($self, $param, $widget, $story);

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
        log_event('story_checkin', $story);
        log_event("story_rem_workflow", $story);
        my $arg = '&quot;' . $story->get_title . '&quot;';
        add_msg($self->lang->maketext("Story [_1] saved and shelved.", $arg));
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
            $wf ||= Bric::Biz::Workflow->lookup
              ({ id => $story->get_workflow_id });
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
        log_event('story_checkin', $story);
        my $dname = $pub_desk->get_name;
        log_event('story_moved', $story, { Desk => $dname })
          unless $no_log;
        my $msg = "Story [_1] saved and checked in to [_2].";
        my @args = ('&quot;' . $story->get_title . '&quot;',
                    "&quot;$dname&quot;");
        add_msg($self->lang->maketext($msg, @args));

        # HACK: Commit this checkin WHY?? Because Postgres does NOT like
        # it when you insert and delete a record within the same
        # transaction. This will be fixed in PostgreSQL 7.3. Be sure to
        # start a new transaction!
        Bric::Util::DBI::commit(1);
        Bric::Util::DBI::begin(1);

        # Use the desk callback to save on code duplication.
        my $pub = Bric::App::Callback::Desk->new
          ( ah           => $self->ah,
            apache_req   => $self->apache_req,
            request_args => { story_pub => { $story->get_id => $story } },
          );
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
        log_event('story_checkin', $story);
        my $dname = $desk->get_name;
        log_event('story_moved', $story, { Desk => $dname }) unless $no_log;
        my $msg = "Story [_1] saved and moved to [_2].";
        my @args = ('&quot;' . $story->get_title . '&quot;',
                    "&quot;$dname&quot;");
        add_msg($self->lang->maketext($msg, @args));
    }

    # Clear the state out and set redirect.
    clear_state($widget);
    set_redirect("/");
}

sub save_and_stay : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $param = $self->request_args;
    # Just return if there was a problem with the update callback.
    return if delete $param->{__data_errors__};

    my $story = get_state_data($widget, 'story');

    if ($param->{"$widget|delete"}) {
        # Delete the story.
        $handle_delete->($story, $self);
        # Get out of here, since we've blow it away!
        set_redirect("/");
        clear_state($widget);
    } else {
        # Make sure the story is activated and then save it.
        $story->activate;
        $story->save;
        log_event('story_save', $story);
        my $arg = '&quot;' . $story->get_title . '&quot;';
        add_msg($self->lang->maketext("Story [_1] saved.", $arg));
    }
}

sub cancel : Callback {
    my $self = shift;

    my $story = get_state_data($self->class_key, 'story');
    $story->cancel_checkout();
    $story->save();
    log_event('story_cancel_checkout', $story);
    clear_state($self->class_key);
    set_redirect("/");
    my $msg = "Story [_1] check out canceled.";
    my $arg = '&quot;' . $story->get_title . '&quot;';
    add_msg($self->lang->maketext($msg, $arg));
}

sub return : Callback {
    my $self = shift;
    my $widget = $self->class_key;
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
}

sub create : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $param = $self->request_args;

    # Check permissions.
    my $work_id = get_state_data($widget, 'work_id');
    my $wf = Bric::Biz::Workflow->lookup({ id => $work_id });
    my $start_desk = $wf->get_start_desk;
    my $gid = $start_desk->get_asset_grp;
    chk_authz('Bric::Biz::Asset::Business::Story', CREATE, 0, $gid);

    # Make sure we have the required data. Check the story type.
    my $ret;
    unless (defined $param->{"$widget|at_id"}
            && $param->{"$widget|at_id"} ne '')
    {
        add_msg("Please select a story type.");
        $ret = 1;
    }

    # Check the category ID.
    my $cid = $param->{"$widget|new_category_id"};
    unless (defined $cid && $cid ne '') {
        add_msg("Please select a primary category.");
        $ret = 1;
    }

    # Check the slug.
    if ($param->{'slug'}) {
        # check the form of the slug
        if ($param->{'slug'} =~ m/\W/) {
            add_msg('Slug must conform to URI character rules.');
            $ret = 1;
        }
    }

    # Return if there are problems.
    return if $ret;

    # Create a new story with the initial values given.
    my $init = { element__id => $param->{"$widget|at_id"},
                 source__id  => $param->{"$widget|source__id"},
                 site_id     => $wf->get_site_id,
                 user__id    => get_user_id() };

    my $story = Bric::Biz::Asset::Business::Story->new($init);

    # Set the primary category
    $story->add_categories([$cid]);
    $story->set_primary_category($cid);
    my $cat = Bric::Biz::Category->lookup({ id => $cid });

    # Save everything else unless there were data errors
    return unless &$save_data($self, $param, $widget, $story);

    # Set the workflow this story should be in.
    $story->set_workflow_id($work_id);

    # Save the story.
    $story->save;

    # Send this story to the first desk.
    $start_desk->accept({ asset => $story });
    $start_desk->save;
    $story->save;

    # Log that a new story has been created and generally handled.
    log_event('story_new', $story);
    log_event('story_add_category', $story, { Category => $cat->get_name });
    log_event('story_add_workflow', $story, { Workflow => $wf->get_name });
    log_event('story_moved', $story, { Desk => $start_desk->get_name });
    log_event('story_save', $story);
    my $arg = '&quot;' . $story->get_title . '&quot;';
    add_msg($self->lang->maketext("Story [_1] created and saved.", $arg));

    # Put the story into the session and clear the workflow ID.
    set_state_data($widget, 'story', $story);
    set_state_data($widget, 'work_id', '');

    # Head for the main edit screen.
    set_redirect("/workflow/profile/story/");

    # As far as history is concerned, this page should be part of the story
    # profile stuff.
    pop_page();
}

sub notes : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $param = $self->request_args;
    # Return if there were data errors.
    return unless &$save_data($self, $param, $widget);

    my $story = get_state_data($widget, 'story');
    my $id    = $story->get_id();
    my $action = $param->{$widget.'|notes_cb'};
    set_redirect("/workflow/profile/story/${action}_notes.html?id=$id");
}

sub delete_cat : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $cat_ids = mk_aref($self->request_args->{"$widget|delete_cat"});
    my $story = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    $story->delete_categories($cat_ids);
    $story->save;

    # Log events.
    foreach my $cid (@$cat_ids) {
        my $cat = Bric::Biz::Category->lookup({ id => $cid });
        log_event('story_del_category', $story, { Category => $cat->get_name });
        my $arg = '&quot;' . $cat->get_name . '&quot;';
        add_msg($self->lang->maketext("Category [_1] disassociated.", $arg));
    }
    set_state_data($widget, 'story', $story);
}

sub update_primary : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $story   = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    my $primary = $self->request_args->{"$widget|primary_cat"};
    $story->set_primary_category($primary);
    $story->save();
    set_state_data($widget, 'story', $story);
}

sub add_category : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $story = get_state_data($widget, 'story');
    chk_authz($story, EDIT);
    my $cat_id = $self->request_args->{"$widget|new_category_id"};
    if (defined $cat_id) {
        $story->add_categories([ $cat_id ]);
        my $msg = $story->check_uri(get_user_id());
        if ($msg) {
            $story->delete_categories([ $cat_id ]);
            my $langmsg = "The category was not added, "
              . "as it would have caused a URI clash with story [_1].";
            add_msg($self->lang->maketext($langmsg, "'$msg'"));
            $story->save();
            set_state_data($widget, 'story', $story);
            return;
        }
        $story->save();
        my $cat = Bric::Biz::Category->lookup({ id => $cat_id });
        log_event('story_add_category', $story, { Category => $cat->get_name });
        my $arg = '&quot;' . $cat->get_name . '&quot;';
        add_msg($self->lang->maketext("Category [_1] added.", $arg));
    }
    set_state_data($widget, 'story', $story);
}

sub add_oc : Callback {
    my $self = shift;

    my $story = get_state_data($self->class_key, 'story');
    chk_authz($story, EDIT);
    my $oc = Bric::Biz::OutputChannel->lookup({ id => $self->value });
    $story->add_output_channels($oc);
    log_event('story_add_oc', $story, { 'Output Channel' => $oc->get_name });
    $story->save;
    set_state_data($self->class_key, 'story', $story);
}

sub view_notes : Callback {
    my $self = shift;

    my $story = get_state_data($self->class_key, 'story');
    my $id = $story->get_id();
    set_redirect("/workflow/profile/story/comments.html?id=$id");
}

sub trail : Callback {
    my $self = shift;

    # Return if there were data errors
    return unless &$save_data($self, $self->request_args, $self->class_key);

    my $story = get_state_data($self->class_key, 'story');
    my $id = $story->get_id();
    set_redirect("/workflow/trail/story/$id");
}

sub view_trail : Callback {
    my $self = shift;

    my $story = get_state_data($self->class_key, 'story');
    my $id = $story->get_id();
    set_redirect("/workflow/trail/story/$id");
}

sub update : Callback(priority => 1) {
    my $self = shift;

    &$save_data($self, $self->request_args, $self->class_key);
}

sub keywords : Callback {
    my $self = shift;


    # Return if there were data errors
    return unless &$save_data($self, $self->request_args, $self->class_key);

    my $story = get_state_data($self->class_key, 'story');
    my $id = $story->get_id();
    set_redirect("/workflow/profile/story/keywords.html");
}

sub contributors : Callback {
    my $self = shift;


    # Return if there were data errors
    return unless &$save_data($self, $self->request_args, $self->class_key);
    set_redirect("/workflow/profile/story/contributors.html");
}

sub assoc_contrib : Callback {
    my $self = shift;

    my $story = get_state_data($self->class_key, 'story');
    chk_authz($story, EDIT);
    my $contrib_id = $self->value;
    my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup({'id' => $contrib_id});
    my $roles = $contrib->get_roles;
    if (scalar(@$roles)) {
        set_state_data($self->class_key, 'contrib', $contrib);
        set_redirect("/workflow/profile/story/contributor_role.html");
    } else {
        $story->add_contributor($contrib);
        log_event('story_add_contrib', $story, { Name => $contrib->get_name });
    }
}

sub assoc_contrib_role : Callback {
    my $self = shift;

    my $story   = get_state_data($self->class_key, 'story');
    chk_authz($story, EDIT);
    my $contrib = get_state_data($self->class_key, 'contrib');
    my $role    = $self->request_args->{$self->class_key.'|role'};

    # Add the contributor
    $story->add_contributor($contrib, $role);
    log_event('story_add_contrib', $story, { Name => $contrib->get_name });

    # Go back to the main contributor pick screen.
    set_redirect(last_page());

    # Remove this page from the stack.
    pop_page();
}

sub unassoc_contrib : Callback {
    my $self = shift;

    my $story = get_state_data($self->class_key, 'story');
    chk_authz($story, EDIT);
    my $cids = mk_aref($self->value);
    $story->delete_contributors($cids);

    # Log the dissociations.
    foreach my $cid (@$cids) {
        my $c = Bric::Util::Grp::Parts::Member::Contrib->lookup({'id' => $cid });
        log_event('story_del_contrib', $story, { Name => $c->get_name });
    }
}

sub save_contrib : Callback {
    my $self = shift;

    $save_contrib->($self->class_key, $self->request_args, $self);
    # Set a redirect for the previous page.
    set_redirect(last_page());
    # Pop this page off the stack.
    pop_page();
}

sub save_and_stay_contrib : Callback {
    my $self = shift;

    $save_contrib->($self->class_key, $self->request_args, $self);
}

sub leave_contrib : Callback {
    my $self = shift;

    # Set a redirect for the previous page.
    set_redirect(last_page());
    # Pop this page off the stack.
    pop_page();
}

sub exit : Callback {
    my $self = shift;

    set_state($self->class_key, {});
    # Set the redirect to the page we were at before here.
    set_redirect(last_page() || "/workflow/search/story/");
    # Remove this page from history.
    pop_page();
}

sub add_kw : Callback {
    my $self = shift;
    my $param = $self->request_args;

    # Grab the story.
    my $story = get_state_data($self->class_key, 'story');
    chk_authz($story, EDIT);

    # Add new keywords.
    my $new;
    foreach (@{ mk_aref($param->{keyword}) }) {
        next unless $_;
        my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
        unless ($kw) {
            $kw = Bric::Biz::Keyword->new({ name => $_})->save;
            log_event('keyword_new', $kw);
        }
        push @$new, $kw;
    }
    $story->add_keywords($new) if $new;

    # Delete old keywords.
    $story->del_keywords(mk_aref($param->{del_keyword}))
      if defined $param->{del_keyword};
    $story->save();

    # Save the changes
    set_state_data($self->class_key, 'story', $story);

    set_redirect(last_page());

    add_msg("Keywords saved.");

    # Take this page off the stack.
    pop_page();
}

sub checkout : Callback {
    my $self = shift;

    my $ids = $self->value;
    $ids = ref $ids ? $ids : [$ids];

    foreach (@$ids) {
        my $ba = Bric::Biz::Asset::Business::Story->lookup({'id' => $_});
        if (chk_authz($ba, EDIT, 1)) {
            $ba->checkout({'user__id' => get_user_id()});
            $ba->save;

            # Log Event.
            log_event('story_checkout', $ba);
        } else {
            my $msg = "Permission to checkout [_1] denied";
            my $arg = '&quot;' . $ba->get_name . '&quot;';
            add_msg($self->lang->maketext($msg, $arg));
        }
    }

    if (@$ids > 1) {
        # Go to 'my workspace'
        set_redirect("/");
    } else {
        # Go to the profile screen
        set_redirect('/workflow/profile/story/'.$ids->[0].'?checkout=1');
    }
}

sub recall : Callback {
    my $self = shift;

    my $ids = $self->request_args->{$self->class_key.'|recall_cb'};
    $ids = ref $ids ? $ids : [$ids];
    my %wfs;

    foreach (@$ids) {
        my ($o_id, $w_id) = split('\|', $_);
        my $ba = Bric::Biz::Asset::Business::Story->lookup({'id' => $o_id});
        if (chk_authz($ba, EDIT, 1)) {
            my $wf = $wfs{$w_id} ||= Bric::Biz::Workflow->lookup({'id' => $w_id});

            # Make sure the workflow ID is valid.
            unless ($w_id) {
                throw_dp('error' => "Bad Workflow ID '$w_id'");
            }

            # Put this formatting asset into the current workflow and log it.
            $ba->set_workflow_id($w_id);
            log_event('story_add_workflow', $ba, { Workflow => $wf->get_name });

            # Get the start desk for this workflow.
            my $start_desk = $wf->get_start_desk;

            # Put this formatting asset on to the start desk.
            $start_desk->accept({'asset' => $ba});
            $start_desk->checkout($ba, get_user_id());
            $start_desk->save;
            log_event('story_moved', $ba, { Desk => $start_desk->get_name });
            log_event('story_checkout', $ba);
        } else {
            my $msg = "Permission to checkout [_1] denied";
            my $arg = '&quot;' . $ba->get_name . '&quot;';
            add_msg($self->lang->maketext($msg, $arg));
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
}

sub clone : Callback {
    # empty
}


###

$save_contrib = sub {
    my ($widget, $param, $self) = @_;

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
            my $msg = 'Contributor [_1] disassociated.';
            my $arg = '&quot;' . $contrib->get_name . '&quot;';
            add_msg($self->lang->maketext($msg, $arg));
        }
    }

    # get the remaining and reorder
    foreach (keys %$existing) {
        my $key = $widget . '|reorder_' . $_;
        my $place = $param->{$key};
        $existing->{$_} = $place;
    }
    my @no = sort { $existing->{$a} <=> $existing->{$b} } keys %$existing;
    $story->reorder_contributors(@no);
};

# removes repeated error messages
$unique_msgs = sub {
    my (%seen, @msgs);
    while (my $msg = next_msg()) {
        push @msgs, $msg unless $seen{$msg}++;
    }
    add_msg($_) for @msgs;
};

$save_data = sub {
    my ($self, $param, $widget, $story) = @_;
    my $data_errors = 0;

    $story ||= get_state_data($widget, 'story');
    chk_authz($story, EDIT);

    # Make sure the story is active.
    $story->activate;
    my $uid = get_user_id();

    if (($story->get_slug() || '') ne ($param->{'slug'} || '')) {
        my $old_slug = $story->get_slug();
        # check the form of the slug
        if ($param->{'slug'} =~ m/\W/) {
            add_msg('Slug must conform to URI character rules.');
            $data_errors = 1;
        } else {
            $story->set_slug($param->{slug});
            my $msg = $story->check_uri($uid);
            if ($msg) {
                my $lang = $self->lang;
                if ($old_slug) {
                    my $langmsg = "The slug has been reverted to [_1], as "
                      . "the slug [_2] caused this story to have a URI "
                      . "conflicting with that of story [_3].";
                    my @args = ("'$old_slug'", "'$param->{slug}'", "'$msg'");
                    add_msg($lang->maketext($langmsg, @args));
                    $story->set_slug($old_slug);
                } else {
                    my $langmsg = "The slug, category and cover date you selected "
                      . "would have caused this story to have a URI "
                      . "conflicting with that of story [_1].";
                    add_msg($lang->maketext($langmsg, "'$msg'"));
                }
                $data_errors = 1;
            }
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

    # Delete output channels.
    if ($param->{rem_oc}) {
        my $del_oc_ids = mk_aref($param->{rem_oc});
        foreach my $delid (@$del_oc_ids) {
            if ($delid == $param->{primary_oc_id}) {
                add_msg("Cannot both delete and make primary a single "
                          . "output channel.");
                $param->{__data_errors__} = 1;
            } else {
                my ($oc) = $story->get_output_channels($delid);
                $story->del_output_channels($delid);
                log_event('story_del_oc', $story,
                          { 'Output Channel' => $oc->get_name });
            }
        }
    }

    # Set primary output channel.
    $story->set_primary_oc_id($param->{primary_oc_id})
      if exists $param->{primary_oc_id};

    if (($param->{cover_date} || '') ne ($story->get_cover_date || '')) {
        my $old_date = $story->get_cover_date(ISO_8601_FORMAT);
        my $fold_date = $story->get_cover_date;
        $story->set_cover_date($param->{cover_date});
        my $msg = $story->check_uri($uid);
        if ($msg) {
            if ($old_date) {
                my $langmsg = "The cover date has been reverted to [_1], "
                  . "as it caused this story to have a URI conflicting "
                  . "with that of story '[_2].";
                add_msg($self->lang->maketext($langmsg, $old_date,"'$msg'"));
                $story->set_cover_date($old_date);
            } else {
                my $langmsg = "The slug, category and cover date you selected " .
                         "would have caused this story to have a URI " .
                         "conflicting with that of story [_1].";
                add_msg($self->lang->maketext($langmsg, "'$msg'"));
            }
            $data_errors = 1;
        }
    }

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

    # avoid repeated messages from repeated calls to &$save_data
    &$unique_msgs if $data_errors;

    set_state_data($widget, 'story', $story);

    $param->{__data_errors__} = $data_errors;
    return not $data_errors;
};

$handle_delete = sub {
    my ($story, $self) = @_;
    my $desk = $story->get_current_desk();
    $desk->checkin($story);
    $desk->remove_asset($story);
    $desk->save;
    log_event("story_rem_workflow", $story);
    $story->set_workflow_id(undef);
    $story->deactivate;
    $story->save;
    log_event("story_deact", $story);
    my $arg = '&quot;' . $story->get_title . '&quot;';
    add_msg($self->lang->maketext("Story [_1] deleted.", $arg));
};


1;
