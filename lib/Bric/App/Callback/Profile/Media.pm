package Bric::App::Callback::Profile::Media;

use base qw(Bric::App::Callback);     # not subclassing Profile
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'media_prof';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Callback::Desk;
use Bric::App::Callback::Util::OutputChannel qw(update_output_channels);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:history :aref clear_msg);
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::ElementType;
use Bric::Biz::Keyword;
use Bric::Biz::OutputChannel;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Config qw(:media :mod_perl);
use Bric::Util::ApacheConst qw(HTTP_OK);
use Bric::Util::DBI qw(:trans);
use Bric::Util::Fault qw(throw_forbidden);
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::MediaType;
use Bric::Util::Trans::FS;
use Bric::App::Callback::Search;

my $SEARCH_URL = '/workflow/manager/media/';
my $ACTIVE_URL = '/workflow/active/media/';
my $DESK_URL   = '/workflow/profile/desk/';

my ($save_category, $handle_delete);

sub update : Callback(priority => 1) {
    my $self = shift;
    my $widget = $self->class_key;
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);
    my $param = $self->params;

    # Make sure it's active.
    $media->activate;

    # set the source
    $media->set_source__id($param->{"$widget|source__id"})
      if $param->{"$widget|source__id"};

    $media->set_category__id($param->{"$widget|category__id"})
      if defined $param->{"$widget|category__id"}
      && $media->get_category__id ne $param->{"$widget|category__id"};

    # set the name
    $media->set_title($param->{title})
      if exists $param->{title};

    # set the description
    $media->set_description($param->{description})
      if exists $param->{description};

    $media->set_priority($param->{priority})
      if exists $param->{priority};

    update_output_channels($self, $media, $param);

    # Delete old keywords.
    my $old;
    my $keywords = { map { $_ => 1 } @{ mk_aref($param->{keyword_id}) } };
    foreach ($media->get_keywords) {
        push @$old, $_ unless $keywords->{$_->get_id};
    }
    $media->del_keywords(@$old) if $old;

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
            }
            else {
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
    $media->add_keywords(@$new) if $new;

    $self->_handle_contributors($media, $param, $widget);

    # Set the dates.
    $media->set_cover_date($param->{cover_date})
      if exists $param->{cover_date};
    $media->set_expire_date($param->{expire_date})
      if exists $param->{expire_date};

    # Check for file
    $self->handle_upload($media) if $param->{"$widget|file"};
    set_state_data($widget, 'media', $media);
}

sub delete_media : Callback {
    my $self = shift;

    my $widget = $self->class_key;
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);

    # Make sure it's active.
    $media->activate;

    $media->delete_file($media);

    log_event('media_del_file', $media);

    set_state_data($widget, 'media', $media);
}

################################################################################

sub view : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $media = get_state_data($widget, 'media');
    my $version = $self->params->{"$widget|version"};
    my $id = $media->get_id();
    $self->set_redirect("/workflow/profile/media/$id/?version=$version");
}

##############################################################################

sub diff : Callback {
    my $self   = shift;
    my $widget = $self->class_key;
    my $params = $self->params;
    my $media  = get_state_data($widget, 'media');
    my $id     = $media->get_id;

    # Find the from and to version numbers.
    my $from = $params->{"$widget|from_version"} || $params->{"$widget|version"};
    my $to   = $params->{"$widget|to_version"}   || $media->get_version;

    # Send it on home.
    $self->set_redirect(
        "/workflow/profile/media/$id/?diff=1"
        . "&from_version=$from&to_version=$to"
    );
}

################################################################################

sub revert : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;
    my $media = get_state_data($widget, 'media');
    my $version = $self->params->{"$widget|version"};
    $media->revert($version);
    $media->save;
    $self->add_message('Media "[_1]" reverted to V.[_2]', $media->get_title, $version);
    $self->params->{checkout} = 1; # Reload checked-out media.
    $self->clear_my_state;
}

################################################################################

sub save : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);

    # Just return if there was a problem with the update callback.
    return if delete $self->params->{__data_errors__};

    my $workflow_id = $media->get_workflow_id;
    if ($self->params->{"$widget|delete"}) {
        # Delete the media.
        $handle_delete->($media, $self);
    } else {
        # Make sure the media is activated and then save it.
        $media->activate();
        $media->save;
        log_event('media_save', $media);
        $self->add_message('Media "[_1]" saved.', $media->get_title);
    }

    my $return = get_state_data($widget, 'return') || '';

    # Clear the state and send 'em home.
    $self->clear_my_state;

    if (my $prev = get_state_data('_profile_return')) {
        $self->return_to_other($prev);
    } elsif ($return eq 'search') {
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

################################################################################

sub checkin : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;
    my $media = get_state_data($widget, 'media');
    my $param = $self->params;

    # Just return if there was a problem with the update callback.
    return if delete $param->{__data_errors__};

    my $work_id = get_state_data($widget, 'work_id');
    my $wf;
    if ($work_id) {
        # Set the workflow this media asset should be in.
        $media->set_workflow_id($work_id);
        $wf = Bric::Biz::Workflow->lookup( { id => $work_id });
        log_event('media_add_workflow', $media,
                  { Workflow => $wf->get_name });
        $media->checkout({ user__id => get_user_id() })
          unless $media->get_checked_out;
    }

    $media->checkin;

    # Get the desk information.
    my $desk_id = $param->{"$widget|desk"};
    my $cur_desk = $media->get_current_desk;

    # See if this media asset needs to be removed from workflow or published.
    if ($desk_id eq 'remove') {
        # Remove from the current desk and from the workflow.
        $cur_desk->remove_asset($media)->save if $cur_desk;
        $media->set_workflow_id(undef);
        $media->save;
        log_event('media_save', $media);
        log_event('media_checkout', $media) if $work_id;
        log_event('media_checkin', $media, { Version => $media->get_version });
        log_event("media_rem_workflow", $media);
        $self->add_message('Media "[_1]" saved and shelved.', $media->get_title);
    } elsif ($desk_id eq 'publish') {
        # Publish the media asset and remove it from workflow.
        my ($pub_desk, $no_log);
        # Find a publish desk.
        if ($cur_desk and $cur_desk->can_publish) {
            # We've already got one.
            $pub_desk = $cur_desk;
            $no_log = 1;
        } else {
            # Find one in this workflow.
            $wf ||= Bric::Biz::Workflow->lookup
              ({ id => $media->get_workflow_id });
            foreach my $d ($wf->allowed_desks) {
                $pub_desk = $d and last if $d->can_publish;
            }
            # Transfer the media to the publish desk.
            if ($cur_desk) {
                $cur_desk->transfer({ to    => $pub_desk,
                                      asset => $media });
                $cur_desk->save;
            } else {
                $pub_desk->accept({ asset => $media });
            }
            $pub_desk->save;
        }

        $media->save;

        # Log it!
        log_event('media_save', $media);
        log_event('media_checkin', $media, { Version => $media->get_version });
        my $dname = $pub_desk->get_name;
        log_event('media_moved', $media, { Desk => $dname })
          unless $no_log;
        $self->add_message(
            'Media "[_1]" saved and checked in to "[_2]".',
            $media->get_title,
            $dname
        );

        # Prevent loss of data due to publish failure.
        commit(1);
        begin(1);

        # Use the desk callback to save on code duplication.
        clear_authz_cache( $media );
        my $pub = Bric::App::Callback::Desk->new(
            cb_request => $self->cb_request,
            apache_req => $self->apache_req,
            params     => { media_pub => { $media->get_version_id => $media } },
        );

        # Clear the state out, set redirect, and publish.
        $self->clear_my_state;
        $pub->publish;
        if (my $prev = get_state_data('_profile_return')) {
            $self->return_to_other($prev);
        } else {
            $self->set_redirect('/');
        }


    } else {
        # Look up the selected desk.
        my $desk = Bric::Biz::Workflow::Parts::Desk->lookup
          ({ id => $desk_id });
        my $no_log;
        if ($cur_desk) {
            if ($cur_desk->get_id == $desk_id) {
                $no_log = 1;
            } else {
                # Transfer the media asset to the new desk.
                $cur_desk->transfer({ to    => $desk,
                                      asset => $media });
                $cur_desk->save;
            }
        } else {
            # Send this media to the selected desk.
            $desk->accept({ asset => $media });
        }

        $desk->save;
        $media->save;
        log_event('media_save', $media);
        log_event('media_checkin', $media, { Version => $media->get_version });
        my $dname = $desk->get_name;
        log_event('media_moved', $media, { Desk => $dname }) unless $no_log;
        $self->add_message(
            'Media "[_1]" saved and moved to "[_2]".',
            $media->get_title,
            $dname,
        );

        # Clear the state out and set redirect.
        $self->clear_my_state;
        if (my $prev = get_state_data('_profile_return')) {
            $self->return_to_other($prev);
        } else {
            $self->set_redirect('/');
        }
    }
}

################################################################################

sub save_and_stay : Callback(priority => 6) {
    my ($self, $no_log) = @_; # $no_log passed by Callback::ContainerProf.
    my $widget = $self->class_key;
    my $media = get_state_data($widget, 'media');

    chk_authz($media, EDIT);
    my $work_id = get_state_data($widget, 'work_id');

    # Just return if there was a problem with the update callback.
    return if delete $self->params->{__data_errors__};

    if ($self->params->{"$widget|delete"}) {
        # Delete the media.
        $handle_delete->($media, $self);
        # Get out of here, since we've blown it away!
        $self->set_redirect("/");
        pop_page();
        $self->clear_my_state;
    } else {
        # Make sure the media is activated and then save it.
        $media->activate;
        $media->save;
        log_event('media_save', $media);
        $self->add_message('Media "[_1]" saved.', $media->get_title) unless $no_log;
    }

    # Set the state.
    set_state_data($widget, 'media', $media);
}

################################################################################

sub cancel : Callback(priority => 6) {
    my $self = shift;
    my $media = get_state_data($self->class_key, 'media');

    if ($media->get_version == 0) {
        # If the version number is 0, the media was never checked in to a
        # desk. So just delete it.
        return unless $handle_delete->($media, $self);
    } else {
        # Cancel the checkout.
        $media->cancel_checkout;
        log_event('media_cancel_checkout', $media);

        # If the media was last recalled from the library, then remove it
        # from the desk and workflow. We can tell this because there will
        # only be one media_moved event and one media_checkout event
        # since the last media_add_workflow event.
        my @events = Bric::Util::Event->list({
            class => 'Bric::Biz::Asset::Business::Media',
            obj_id => $media->get_id
        });
        my ($desks, $cos) = (0, 0);
        while (@events && $events[0]->get_key_name ne 'media_add_workflow') {
            my $kn = shift(@events)->get_key_name;
            if ($kn eq 'media_moved') {
                $desks++;
            } elsif ($kn eq 'media_checkout') {
                $cos++
            }
        }

        # If one move to desk, and one checkout, and this isn't the first
        # time the media has been in workflow since it was created...
        # XXX Two events upon creation: media_create and media_moved.
        if ($desks == 1 && $cos == 1 && @events > 2) {
            # It was just recalled from the library. So remove it from the
            # desk and from workflow.
            my $desk = $media->get_current_desk;
            $desk->remove_asset($media);
            $media->set_workflow_id(undef);
            $desk->save;
            $media->save;
            log_event("media_rem_workflow", $media);
        } else {
            # Just save the cancelled checkout. It will be left in workflow for
            # others to find.
            $media->save;
        }
        $self->add_message('Media "[_1]" check out canceled.', $media->get_title);
    }
    $self->clear_my_state;
    if (my $prev = get_state_data('_profile_return')) {
        $self->return_to_other($prev);
    } else {
        $self->set_redirect('/');
    }
}

################################################################################

sub return : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;
    my $version_view = get_state_data($widget, 'version_view');
    my $media = get_state_data($widget, 'media');

    # note: $self->value =~ /^\d+$/ is for IE which sends the .x or .y position
    # of the mouse for <input type="image"> buttons
    if ($version_view || $self->value eq 'diff' || $self->value =~ /^\d+$/) {
        my $media_id = $media->get_id;
        $self->clear_my_state if $version_view;
        $self->set_redirect("/workflow/profile/media/$media_id/?checkout=1");
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
        $self->clear_my_state;
        if (my $prev = get_state_data('_profile_return')) {
            $self->return_to_other($prev);
        } else {
            $self->set_redirect($url);
        }
    }
}

sub cancel_return : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;
    my $version_view = get_state_data($widget, 'version_view');
    my $media = get_state_data($widget, 'media');

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
    $self->clear_my_state;
    if (my $prev = get_state_data('_profile_return')) {
        $self->return_to_other($prev);
    } else {
        $self->set_redirect($url);
    }
}

################################################################################

sub create : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    # Get the workflow ID to use in redirects.
    my $WORK_ID = get_state_data($widget, 'work_id');
    my $param   = $self->params;

    # Check permissions.
    my $wf = Bric::Biz::Workflow->lookup({ id => $WORK_ID });
    my $start_desk = $wf->get_start_desk;
    my $gid = $start_desk->get_asset_grp;
    chk_authz('Bric::Biz::Asset::Business::Media', CREATE, 0, $gid);

    my $site_id = $wf->get_site_id;

    # get the asset type
    my $at_id = $param->{"$widget|at_id"};
    my $element = Bric::Biz::ElementType->lookup({ id => $at_id });

    # determine the package to which this belongs
    my $pkg = $element->get_biz_class;

    my $init = { element => $element,
                 source__id   => $param->{"$widget|source__id"},
                 priority     => $param->{priority},
                 cover_date   => $param->{cover_date},
                 title        => $param->{title},
                 user__id     => get_user_id(),
                 category__id => $param->{"$widget|category__id"},
                 site_id      => $site_id,
               };

    # Create the media object.
    my $media = $pkg->new($init);

    # Set the workflow this media should be in.
    $media->set_workflow_id($WORK_ID);

    # Save the media object.
    $media->save;

    # Send this media to the first desk.
    $start_desk->accept({ asset => $media });
    $start_desk->save;

    # Handle a file upload.
    $self->handle_upload($media) if $param->{"$widget|file"};

    # Log that a new media has been created and generally handled.
    log_event('media_new', $media);
    log_event('media_add_workflow', $media, { Workflow => $wf->get_name });
    log_event('media_moved', $media, { Desk => $start_desk->get_name });
    log_event('media_save', $media);
    $self->add_message('Media "[_1]" created and saved.', $media->get_title);

    # Put the media asset into the session and clear the workflow ID.
    set_state_data($widget, 'media', $media);
    set_state_data($widget, 'work_id', '');

    # Head for the main edit screen.
    $self->set_redirect('/workflow/profile/media/'.$media->get_id.'/');

    # As far as history is concerned, this page should be part of the media
    # profile stuff.
    pop_page();
}

################################################################################

sub notes : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $media = get_state_data($widget, 'media');
    my $id    = $media->get_id();
    my $action = $self->params->{"$widget|notes_cb"};
    $self->set_redirect("/workflow/profile/media/${action}_notes.html?id=$id");
}

################################################################################

sub trail : Callback {
    my $self = shift;
    my $media = get_state_data($self->class_key, 'media');
    my $id = $media->get_id();
    $self->set_redirect("/workflow/events/media/$id?filter_by=media_moved");
}

################################################################################

sub recall : Callback {
    my $self = shift;
    my $ids = $self->params->{$self->class_key . '|recall_cb'};
    $ids = ref $ids ? $ids : [$ids];
    my ($co, %wfs);

    foreach my $id (@$ids) {
        my ($o_id, $w_id) = split('\|', $id);
        my $ba = Bric::Biz::Asset::Business::Media->lookup({'id' => $o_id});
        if (chk_authz($ba, RECALL, 1)) {
            # XXX: why don't we check if $w_id is valid?
            my $wf = $wfs{$w_id} ||= Bric::Biz::Workflow->lookup({'id' => $w_id});

            # They checked 'Include deleted' and the 'Reactivate' checkbox
            # XXX: is this sufficient?
            unless ($ba->is_active) {
                $ba->activate();
            }

            # Put this media into the current workflow and log it.
            $ba->set_workflow_id($w_id);
            log_event('media_add_workflow', $ba, { Workflow => $wf->get_name });

            # Get the start desk for this workflow.
            my $start_desk = $wf->get_start_desk;

            # Put this media on the start desk.
            $start_desk->accept({'asset' => $ba});
            $start_desk->checkout($ba, get_user_id());
            $start_desk->save;
            log_event('media_moved', $ba, { Desk => $start_desk->get_name });
            log_event('media_checkout', $ba);
            $co++;
        } else {
            $self->raise_forbidden(
                'Permission to checkout "[_1]" denied.',
                $ba->get_name,
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
        $self->set_redirect('/workflow/profile/media/'.$o_id.'?checkout=1');
    }
}

################################################################################

sub checkout : Callback {
    my $self = shift;
    my $ids = $self->value;
    $ids = ref $ids ? $ids : [$ids];
    my $co;

    foreach my $id (@$ids) {
        my $ba = Bric::Biz::Asset::Business::Media->lookup({'id' => $id});
        if (chk_authz($ba, EDIT, 1)) {
            $ba->checkout({'user__id' => get_user_id()});
            $ba->save;
            $co++;

            # Log Event.
            log_event('media_checkout', $ba);
        } else {
            $self->raise_forbidden(
                'Permission to checkout "[_1]" denied.',
                $ba->get_name,
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
        $self->set_redirect('/workflow/profile/media/'.$ids->[0].'?checkout=1');
    }
}

################################################################################

sub category : Callback {
    my $self = shift;
    my $id = get_state_data($self->class_key, 'media')->get_id;
    $self->set_redirect("/workflow/profile/media/category.html");
}

################################################################################

sub save_category : Callback {
    my $self = shift;
    $save_category->($self->class_key, $self->params, $self);
    # Set a redirect for the previous page.
    $self->set_redirect(last_page);
    # Pop this page off the stack.
    pop_page();
}

##############################################################################i

sub save_and_stay_category : Callback {
    my $self = shift;
    $save_category->($self->class_key, $self->params, $self);
}

###############################################################################

sub leave_category : Callback {
    my $self = shift;
    # Set a redirect for the previous page.
    $self->set_redirect(last_page);
    # Pop this page off the stack.
    pop_page();
}

###############################################################################

sub assoc_category : Callback {
    my $self = shift;
    my $media = get_state_data($self->class_key, 'media');
    chk_authz($media, EDIT);
    my $cat_id = $self->value;

    $media->set_category__id($cat_id);
    # XXX: should probably be a media_assoc_category event or something
    # but it doesn't exist (and I'm lazy (programmer virtue?))

    # Avoid unnecessary empty searches.
    Bric::App::Callback::Search->no_new_search;
}

sub save_related : Callback {
    my $self   = shift;
    my $media  = get_state_data($self->class_key => 'media');
    my $desk   = $media->get_current_desk;
    my $params = $self->params;
    my $widget = $self->class_key;

    # Roll in any changes.
    $media->set_title(        $params->{title}                  );
    $media->set_source__id(   $params->{"$widget|source__id"}   );
    $media->set_category__id( $params->{"$widget|category__id"} );
    $media->set_cover_date(   $params->{cover_date}             );
    $media->set_priority(     $params->{priority}               );
    $media->save;

    # Check the media document into a desk.
    my $desk_cb = Bric::App::Callback::Desk->new(
        cb_request => $self->cb_request,
        pkg_key    => 'desk_asset',
        apache_req => $self->apache_req,
        value      => $media->get_id,
        params     => { 'desk_asset|asset_class' => $media->key_name },
    );

    $desk_cb->checkin;
    $self->add_message(
        'Media "[_1]" saved and checked in to "[_2]".',
        $media->get_title,
        $desk->get_name,
    );

    if (my $prev = get_state_data('_profile_return')) {
        $self->return_to_other($prev);
    }
}

### end of callbacks ##########################################################

sub clear_my_state {
    my $self = shift;
    clear_state($self->class_key);
    clear_state('container_prof');
}

sub return_to_other {
    my ($self, $prev) = @_;
    # $prev has state information for a story or media profile that created
    # the media profile we've just finished with. So restore that state.
    clear_state('_profile_return');
    clear_msg();
    set_state(container_prof => @{$prev->{state}});
    set_state(
        "$prev->{type}\_prof" => $prev->{type_state},
        { $prev->{type} => $prev->{prof} }
    );

    my $r = $self->apache_req;
    my $widget = $self->class_key;
    $r->send_http_header if MOD_PERL_VERSION < 2;
    $r->print(
        '<html><head>',
        qq{<script type="text/javascript" src="/media/js/prototype.js"></script>\n},
        qq{<script type="text/javascript" src="/media/js/scriptaculous.js"></script>\n},
        qq{<script type="text/javascript" src="/media/js/lib.js"></script>},
        qq{<script type="text/javascript">Container.update('media', '$widget', '$prev->{elem_id}', true);</script>},
        '</head><body></body></html>',
    );
    $self->abort;
}

sub handle_upload {
    my ($self, $media) = @_;
    my $param  = $self->params;
    my $widget = $self->class_key;
    my $upload = $self->apache_req->upload(
        $param->{file_field_name} || "$widget|file"
    );

    # Prevent big media uploads
    if (MEDIA_UPLOAD_LIMIT && $upload->size > MEDIA_UPLOAD_LIMIT * 1024) {
        my $msg = 'File "[_1]" too large to upload (more than [_2] KB)';
        $self->raise_conflict($msg, $upload->filename, MEDIA_UPLOAD_LIMIT);
        return;
    }

    my $fh = $upload->fh;
    my $agent = $ENV{HTTP_USER_AGENT};
    my $filename = $agent =~ /windows/i && $agent =~ /msie/i
        ? Bric::Util::Trans::FS->base_name($upload->filename, 'win32')
        : $upload->filename;
    $media->upload_file($fh, $filename, undef, $upload->size);
    log_event('media_upload', $media);
    return $self;
}

sub _handle_contributors {
    my ($self, $media, $param, $widget) = @_;

    my $existing = { map { $_->get_id => $_ } $media->get_contributors };

    my $order = {};
    foreach my $contrib_id (@{ mk_aref($param->{'contrib_id'}) }) {
        if (defined $existing->{$contrib_id}) {
            if ($existing->{$contrib_id}->{role} ne $param->{"$widget|contrib_role_$contrib_id"}) {
                # Update role (add_contributor updates if $contrib_id already exists)
                $media->add_contributor($contrib_id, $param->{"$widget|contrib_role_$contrib_id"});
            }
            delete $existing->{$contrib_id};
        } else {
            # Contributor did not previously exist, so add it
            $media->add_contributor($contrib_id, $param->{"$widget|role_$contrib_id"});
        }
        $order->{$contrib_id} = $param->{$widget . '|contrib_order_' . $contrib_id};
    }

    if (my @to_delete = keys %$existing) {
        $media->delete_contributors(\@to_delete);

        my $contrib;
        foreach my $id (@to_delete) {
            $contrib = $existing->{$id}->{obj};
            delete $existing->{$id};
            log_event('media_del_contrib', $media, { Name => $contrib->get_name });
        }
        if (@to_delete > 1) {
            $self->add_message('Contributors disassociated.'); }
        else {
            $self->add_message(
                'Contributor "[_1]" disassociated.',
                $contrib->get_name,
            );
        }
    }

    $media->reorder_contributors(sort { $order->{$a} <=> $order->{$b} } keys %$order);

    # Avoid unnecessary empty searches.
    Bric::App::Callback::Search->no_new_search;
}

##############################################################################

$handle_delete = sub {
    my ($media, $self) = @_;
    my $desk = $media->get_current_desk;
    $desk->checkin($media);
    $desk->remove_asset($media);
    $media->set_workflow_id(undef);
    $media->deactivate;
    $desk->save;
    $media->save;
    log_event("media_rem_workflow", $media);
    log_event("media_deact", $media);
    $self->add_message('Media "[_1]" deleted.', $media->get_title);
};

$save_category = sub {
    my ($widget, $param, $self) = @_;
    # get the contribs to delete
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);

    my $cat_id = $param->{category_id};
    $media->set_category__id($cat_id);

    my $cat = Bric::Biz::Category->lookup({id => $cat_id});
    $self->add_message("Category \"[_1]\" associated.", $cat->get_name);

    # Avoid unnecessary empty searches.
    Bric::App::Callback::Search->no_new_search;
};

1;
