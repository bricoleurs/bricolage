package Bric::App::Callback::MediaProf;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'media_prof');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Callback::Desk;
use Bric::App::Callback::Util qw(detect_agent);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:all);
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::AssetType;
use Bric::Biz::Keyword;
use Bric::Biz::OutputChannel;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Util::DBI;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::MediaType;
use Bric::Util::Trans::FS;

my $SEARCH_URL = '/workflow/manager/media/';
my $ACTIVE_URL = '/workflow/active/media/';
my $DESK_URL = '/workflow/profile/desk/';


sub update : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);
    my $param = $self->request_args;

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

    # Delete output channels.
    if ($param->{rem_oc}) {
        my $del_oc_ids = mk_aref($param->{rem_oc});
        foreach my $delid (@$del_oc_ids) {
            if ($delid == $param->{primary_oc_id}) {
                add_msg("Cannot both delete and make primary a single " .
                            "output channel.");
                $param->{__data_errors__} = 1;
            } else {
                my ($oc) = $media->get_output_channels($delid);
                $media->del_output_channels($delid);
                log_event('media_del_oc', $media,
                          { 'Output Channel' => $oc->get_name });
            }
        }
    }

    # Set primary output channel.
    $media->set_primary_oc_id($param->{primary_oc_id})
      if exists $param->{primary_oc_id};

    # Set the dates.
    $media->set_cover_date($param->{cover_date})
      if exists $param->{cover_date};
    $media->set_expire_date($param->{expire_date})
      if exists $param->{expire_date};

    # Check for file
    if ($param->{"$widget|file"}) {
        my $upload = $self->apache_req->upload;
        my $fh = $upload->fh;
        my $ua = detect_agent();
        my $filename = Bric::Util::Trans::FS->base_name($upload->filename, $ua->{'os'});
        $media->upload_file($fh, $filename);
        $media->set_size($upload->size);

        if (my ($mid) = Bric::Util::MediaType->list_ids({name => $upload->type})) {
            # Apache gave us a valid type.
            $media->set_media_type_id($mid);
        } elsif ($mid = Bric::Util::MediaType->get_id_by_ext($filename)) {
            # We figured out the type by the filename extension.
            $media->set_media_type_id($mid);
        } else {
            # We have no idea what the type is. :-(
            $media->set_media_type_id(0);
        }

        log_event('media_upload', $media);
    }
    set_state_data($widget, 'media', $media);
}

################################################################################

sub view : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    my $media = get_state_data($widget, 'media');
    my $version = $self->request_args->{"$widget|version"};
    my $id = $media->get_id();
    set_redirect("/workflow/profile/media/$id/?version=$version");
}

################################################################################

sub revert : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    my $media = get_state_data($widget, 'media');
    my $version = $self->request_args->{"$widget|version"};
    $media->revert($version);
    $media->save();
    my $msg = "Media [_1] reverted to V.[_2]";
    my $arg1 = '&quot;' . $media->get_title . '&quot;';
    add_msg($self->lang->maketext($msg, $arg1, $version));
    clear_state($widget);
}

################################################################################

sub save : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    my $media = get_state_data($widget, 'media');
    chk_authz($media, EDIT);

    if (my $msg = $media->check_uri(get_user_id())) {
        my $langmsg = "The URI of this media conflicts with that of [_1]. "
          . "Please change the category or file name.";
        add_msg($self->lang->maketext($langmsg, '&quot;' . $msg . '&quot;'));
        return;
    }

    # Just return if there was a problem with the update callback.
    return if delete $self->request_args->{__data_errors__};

    if ($self->request_args->{"$widget|delete"}) {
        # Delete the media.
        $handle_delete->($media);
    } else {
        # Make sure the media is activated and then save it.
        $media->activate();
        $media->save();
        log_event('media_save', $media);
        my $arg = '&quot;' . $media->get_title . '&quot;';
        add_msg($self->lang->maketext("Media [_1] saved.", $arg));
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

}

################################################################################

sub checkin : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    my $media = get_state_data($widget, 'media');
    my $param = $self->request_args;

    if (my $msg = $media->check_uri(get_user_id())) {
        my $langmsg = "The URI of this media conflicts with that of [_1]. "
          . "Please change the category, file name, or slug.";
        add_msg($self->lang->maketext($langmsg, "'$msg'"));
        return;
    }

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
        log_event('media_checkin', $media);
        log_event("media_rem_workflow", $media);
        my $msg = 'Media [_1] saved and shelved.';
        my $arg = '&quot;' . $media->get_title . '&quot;';
        add_msg($self->lang->maketext($msg, $arg));
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
        log_event('media_checkin', $media);
        my $dname = $pub_desk->get_name;
        log_event('media_moved', $media, { Desk => $dname })
          unless $no_log;
        my $msg = "Media [_1] saved and checked in to [_2].";
        my @args = ('&quot;' . $media->get_title . '&quot;',
                    "&quot;$dname&quot;");
        add_msg($self->lang->maketext($msg, @args));
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
        log_event('media_checkin', $media);
        my $dname = $desk->get_name;
        log_event('media_moved', $media, { Desk => $dname }) unless $no_log;
        my $msg = "Media [_1] saved and moved to [_2].";
        my @args = ('&quot;' . $media->get_title . '&quot;',
                    "&quot;$dname&quot;");
        add_msg($self->lang->maketext($msg, @args));
    }

    # Publish the media asset, if necessary.
    if ($desk_id eq 'publish') {
        # HACK: Commit this checkin WHY?? Because Postgres does NOT like
        # it when you insert and delete a record within the same
        # transaction. This will be fixed in PostgreSQL 7.3. Be sure to
        # start a new transaction!
        Bric::Util::DBI::commit(1);
        Bric::Util::DBI::begin(1);

        # Use the desk callback to save on code duplication.
        my $pub = Bric::App::Callback::Desk->new(
            'ah' => $self->ah,
            'apache_req' => $self->apache_req,
            'request_args' => {
                'media_pub' => { $media->get_id => $media },
            },
        );
        $pub->publish();
    }
    # Clear the state out and set redirect.
    clear_state($widget);
    set_redirect("/");
}

################################################################################

sub save_stay : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    my $media = get_state_data($widget, 'media');

    chk_authz($media, EDIT);
    my $work_id = get_state_data($widget, 'work_id');

    $media->activate();
    $media->save();

    if (my $msg = $media->check_uri(get_user_id())) {
        my $langmsg = "The URI of this media conflicts with that of [_1]. "
          . "Please change the category, file name, or slug.";
        add_msg($self->lang->maketext($langmsg, "'$msg'"));
        return;
    }

    # Just return if there was a problem with the update callback.
    return if delete $self->request_args->{__data_errors__};

    if ($self->request_args->{"$widget|delete"}) {
        # Delete the media.
        $handle_delete->($media);
        # Get out of here, since we've blown it away!
        set_redirect("/");
        pop_page();
        clear_state($widget);
    } else {
        # Make sure the media is activated and then save it.
        $media->activate;
        $media->save;
        log_event('media_save', $media);
        my $msg = "Media [_1] saved.";
        my $arg = '&quot;' . $media->get_title . '&quot;';
        add_msg($self->lang->maketext($msg, $arg));
    }

    # Set the state.
    set_state_data($widget, 'media', $media);
}

################################################################################

sub cancel : Callback {
    my $self = shift;
    my $media = get_state_data(CLASS_KEY, 'media');
    $media->cancel_checkout();
    $media->save();
    log_event('media_cancel_checkout', $media);
    clear_state(CLASS_KEY);
    set_redirect("/");
    my $msg = "Media [_1] check out canceled.";
    my $arg = '&quot;' . $media->get_name . '&quot;';
    add_msg($self->lang->maketext($msg, $arg));
}

################################################################################

sub return : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
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
}

################################################################################

sub create : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    # Get the workflow ID to use in redirects.
    my $WORK_ID = get_state_data($widget, 'work_id');
    my $param = $self->request_args;

    # Check permissions.
    my $wf = Bric::Biz::Workflow->lookup({ id => $WORK_ID });
    my $start_desk = $wf->get_start_desk;
    my $gid = $start_desk->get_asset_grp;
    chk_authz('Bric::Biz::Asset::Business::Media', CREATE, 0, $gid);

    my $site_id = $wf->get_site_id;

    # get the asset type
    my $at_id = $param->{"$widget|at_id"};
    my $element = Bric::Biz::AssetType->lookup({ id => $at_id });

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

    # Log that a new media has been created and generally handled.
    log_event('media_new', $media);
    log_event('media_add_workflow', $media, { Workflow => $wf->get_name });
    log_event('media_moved', $media, { Desk => $start_desk->get_name });
    log_event('media_save', $media);
    my $msg = 'Media [_1] created and saved.';
    my $arg = '&quot;' . $media->get_title . '&quot;';
    add_msg($self->lang->maketext($msg, $arg));

    # Put the media asset into the session and clear the workflow ID.
    set_state_data($widget, 'media', $media);
    set_state_data($widget, 'work_id', '');

    # Head for the main edit screen.
    set_redirect('/workflow/profile/media/'.$media->get_id.'/');

    # As far as history is concerned, this page should be part of the media
    # profile stuff.
    pop_page();
}

################################################################################

sub contributors : Callback {
    my $self = shift;
    set_redirect("/workflow/profile/media/contributors.html");
}

##############################################################################

sub add_oc : Callback {
    my $self = shift;
    my $media = get_state_data(CLASS_KEY, 'media');
    chk_authz($media, EDIT);
    my $oc = Bric::Biz::OutputChannel->lookup({ id => $self->value });
    $media->add_output_channels($oc);
    log_event('media_add_oc', $media, { 'Output Channel' => $oc->get_name });
    $media->save;
}

################################################################################

sub assoc_contrib : Callback {
    my $self = shift;
    my $media = get_state_data(CLASS_KEY, 'media');
    chk_authz($media, EDIT);
    my $contrib_id = $self->value;
    my $contrib =
      Bric::Util::Grp::Parts::Member::Contrib->lookup({'id' => $contrib_id});
    my $roles = $contrib->get_roles;
    if (scalar(@$roles)) {
        set_state_data(CLASS_KEY, 'contrib', $contrib);
        set_redirect("/workflow/profile/media/contributor_role.html");
    } else {
        $media->add_contributor($contrib);
        log_event('media_add_contrib', $media, { Name => $contrib->get_name });
    }
}

################################################################################

sub assoc_contrib_role : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    my $media   = get_state_data($widget, 'media');
    chk_authz($media, EDIT);
    my $contrib = get_state_data($widget, 'contrib');
    my $role    = $param->{"$widget|role"};
    # Add the contributor
    $media->add_contributor($contrib, $role);
    log_event('media_add_contrib', $media, { Name => $contrib->get_name });
    # Go back to the main contributor pick screen.
    set_redirect(last_page);
    # Remove this page from the stack.
    pop_page;
}


################################################################################

sub unassoc_contrib : Callback {
    my $self = shift;
    my $media = get_state_data(CLASS_KEY, 'media');
    chk_authz($media, EDIT);
    my $contrib_id = $self->value;
    $media->delete_contributors([$contrib_id]);
    my $contrib =
      Bric::Util::Grp::Parts::Member::Contrib->lookup({'id' => $contrib_id});
    log_event('media_del_contrib', $media, { Name => $contrib->get_name });
}

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
    my $contrib_id = $param->{$widget . '|delete_id'};
    my $contrib_number;
    my $contrib_string;
    if ($contrib_id) {
        if (ref $contrib_id) {
            $media->delete_contributors($contrib_id);
            foreach (@$contrib_id) {
                my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup
                  ({ id => $_ });
                $contrib_string .= '&quot;' . $contrib->get_name . '&quot;';
                $contrib_number++;
                delete $existing->{$_};
            }
        } else {
            $media->delete_contributors([$contrib_id]);
            my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup
              ({ id => $contrib_id });
            delete $existing->{$contrib_id};
            $contrib_string = '&quot;' . $contrib->get_name . '&quot;';
            $contrib_number++;
        }
    }
    my $msg = '[quant,_1,Contributor] [_2] associated.';
    add_msg($self->lang->maketext($msg, $contrib_number, $contrib_string))
      if $contrib_number;

    # get the remaining
    # and reorder
    foreach (keys %$existing) {
        my $key = $widget . '|reorder_' . $_;
        my $place = $param->{$key};
        $existing->{$_} = $place;
    }

    my @no = sort { $existing->{$a} <=> $existing->{$b} } keys %$existing;
    $media->reorder_contributors(@no);
}

################################################################################

sub save_contrib : Callback {
    my $self = shift;
    $save_contrib->(CLASS_KEY, $self->request_args);
    # Set a redirect for the previous page.
    set_redirect(last_page);
    # Pop this page off the stack.
    pop_page();
}

##############################################################################i

sub save_and_stay_contrib : Callback {
    my $self = shift;
    $save_contrib->(CLASS_KEY, $self->request_args);
}

###############################################################################

sub leave_contrib : Callback {
    my $self = shift;
    # Set a redirect for the previous page.
    set_redirect(last_page);
    # Pop this page off the stack.
    pop_page();
}

################################################################################

sub notes : Callback {
    my $self = shift;
    my $widget = CLASS_KEY;
    my $media = get_state_data($widget, 'media');
    my $id    = $media->get_id();
    my $action = $self->request_args->{"$widget|notes_cb"};
    set_redirect("/workflow/profile/media/${action}_notes.html?id=$id");
}

################################################################################

sub trail : Callback {
    my $self = shift;
    my $media = get_state_data(CLASS_KEY, 'media');
    my $id = $media->get_id();
    set_redirect("/workflow/trail/media/$id");
}

################################################################################

sub recall : Callback {
    my $self = shift;
    my $ids = $self->request_args->{CLASS_KEY . '|recall_cb'};
    $ids = ref $ids ? $ids : [$ids];
    my %wfs;

    foreach (@$ids) {
        my ($o_id, $w_id) = split('\|', $_);
        my $ba = Bric::Biz::Asset::Business::Media->lookup({'id' => $o_id});
        if (chk_authz($ba, EDIT, 1)) {
            my $wf = $wfs{$w_id} ||= Bric::Biz::Workflow->lookup({'id' => $w_id});

            # Put this formatting asset into the current workflow and log it.
            $ba->set_workflow_id($w_id);
            log_event('media_add_workflow', $ba, { Workflow => $wf->get_name });

            # Get the start desk for this workflow.
            my $start_desk = $wf->get_start_desk;

            # Put this formatting asset on to the start desk.
            $start_desk->accept({'asset' => $ba});
            $start_desk->checkout($ba, get_user_id());
            $start_desk->save;
            log_event('media_moved', $ba, { Desk => $start_desk->get_name });
            log_event('media_checkout', $ba);
        } else {
            my $msg = 'Permission to checkout [_1] denied';
            my $arg = '&quot;' . $ba->get_name. '&quot;';
            add_msg($self->lang->maketext($msg, $arg));
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
}

################################################################################

sub checkout : Callback {
    my $self = shift;
    my $ids = $self->value;
    $ids = ref $ids ? $ids : [$ids];

    foreach (@$ids) {
        my $ba = Bric::Biz::Asset::Business::Media->lookup({'id' => $_});
        if (chk_authz($ba, EDIT, 1)) {
            $ba->checkout({'user__id' => get_user_id()});
            $ba->save;

            # Log Event.
            log_event('media_checkout', $ba);
        } else {
            my $msg = 'Permission to checkout [_1] denied';
            my $arg = '&quot;' . $ba->get_name. '&quot;';
            add_msg($self->lang->maketext($msg, $arg));
        }
    }

    if (@$ids > 1) {
        # Go to 'my workspace'
        set_redirect("/");
    } else {
        # Go to the profile screen
        set_redirect('/workflow/profile/media/'.$ids->[0].'?checkout=1');
    }
}

################################################################################

sub keywords : Callback {
    my $self = shift;
    my $id = get_state_data(CLASS_KEY, 'media')->get_id;
    set_redirect("/workflow/profile/media/keywords.html");
}

################################################################################

sub add_kw : Callback {
    my $self = shift;
    my $param = $self->request_args;

    # Grab the media.
    my $media = get_state_data(CLASS_KEY, 'media');
    chk_authz($media, EDIT);

    # Add new keywords.
    my $new_kw;
    foreach (@{ mk_aref($param->{keyword}) }) {
        next unless $_;
        my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
        unless ($kw) {
            $kw = Bric::Biz::Keyword->new({ name => $_})->save;
            log_event('keyword_new', $kw);
        }
        push @$new_kw, $kw;
    }
    $media->add_keywords($new_kw) if $new_kw;

    # Delete old keywords.
    $media->delete_keywords(mk_aref($param->{del_keyword}))
      if defined $param->{del_keyword};

    # Save the changes
    set_state_data(CLASS_KEY, 'media', $media);

    set_redirect(last_page());

    add_msg("Keywords saved.");

    # Take this page off the stack.
    pop_page();
}


### end of callbacks ###

my $handle_delete = sub {
    my $media = shift;
    my $desk = $media->get_current_desk;
    $desk->checkin($media);
    $desk->remove_asset($media);
    $desk->save;
    log_event("media_rem_workflow", $media);
    $media->set_workflow_id(undef);
    $media->deactivate;
    $media->save;
    log_event("media_deact", $media);
    my $msg = 'Media [_1] deleted.';
    my $arg = '&quot;' . $media->get_title . '&quot;';
    add_msg($self->lang->maketext($msg, $arg));
};


1;
