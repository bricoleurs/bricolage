package Bric::App::Callback::Profile::Template;

use base qw(Bric::App::Callback);    # not subclassing Profile
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'tmpl_prof';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:history);
use Bric::Biz::Asset::Template;
use Bric::Biz::ElementType;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Config qw(ENCODE_OK);
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::Burner;
use Bric::Util::Fault qw(rethrow_exception);
use Bric::Config qw(:mod_perl);

my $DESK_URL   = '/workflow/profile/desk/';
my $SEARCH_URL = '/workflow/manager/template/';
my $ACTIVE_URL = '/workflow/active/template/';

my ( $save_meta, $save_code, $save_object, $checkin, $check_syntax, $delete_fa,
    $create_fa, $handle_upload );

sub save : Callback(priority => 6) {
    my $self   = shift;
    my $widget = $self->class_key;

    $save_object->( $self, $self->params );
    my $fa = get_state_data( $widget, 'template' );

    my $workflow_id = $fa->get_workflow_id;
    if ( $self->params->{"$widget|delete"} ) {

        # Delete the fa.
        $delete_fa->( $self, $fa );
    }
    else {

        # Check syntax.
        return unless $check_syntax->( $self, $widget, $fa );

        # Save it.
        $fa->save;

        my $sb = Bric::Util::Burner->new( { user_id => get_user_id() } );
        $sb->deploy($fa);

        log_event( 'template_save', $fa );
        $self->add_message( 'Template "[_1]" saved.', $fa->get_file_name );
    }

    my $return = get_state_data( $widget, 'return' ) || '';

    # Clear out our application state and send 'em home.
    clear_state($widget);

    if ( $return eq 'search' ) {
        my $url = $SEARCH_URL . $workflow_id . '/';
        $self->set_redirect($url);
    }
    elsif ( $return eq 'active' ) {
        my $url = $ACTIVE_URL . $workflow_id;
        $self->set_redirect($url);
    }
    elsif ( $return =~ /\d+/ ) {
        my $url = $DESK_URL . $workflow_id . '/' . $return . '/';
        $self->set_redirect($url);
    }
    else {
        $self->set_redirect("/");
    }
}

sub checkin : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;

    my $fa = get_state_data($widget, 'template');
    $save_meta->($self, $widget, $fa);
    return unless $check_syntax->($self, $widget, $fa);
    $checkin->($self, $widget, $self->params, $fa);
}

sub save_and_stay : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;

    $save_object->($self, $self->params);
    my $fa = get_state_data($widget, 'template');

    if ($self->params->{"$widget|delete"}) {
        # Delete the template.
        $delete_fa->($self, $fa);
        # Get out of here, since we've blow it away!
        $self->set_redirect("/");
        pop_page();
        clear_state($widget);
    } else {
        # Check syntax.
        return unless $check_syntax->($self, $widget, $fa);

        # Deploy the template to the user's sandbox.
        my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
        $sb->deploy($fa);

        # Save the template.
        $fa->save;
        log_event('template_save', $fa);
        $self->add_message('Template "[_1]" saved.', $fa->get_file_name);
    }
}

sub revert : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;

    my $fa      = get_state_data($widget, 'template');
    my $version = $self->params->{"$widget|version"};
    $fa->revert($version);
    $fa->save;

    # Deploy the template to the user's sandbox.
    my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
    $sb->deploy($fa);
    $self->params->{checkout} = 1; # Reload checked-out template.
    clear_state($widget);
}

sub view : Callback {
    my $self = shift;
    my $widget = $self->class_key;

    my $id      = get_state_data($widget, 'template')->get_id;
    my $version = $self->params->{"$widget|version"};
    set_state_data($widget, version_view => 1);
    $self->set_redirect("/workflow/profile/template/$id/?version=$version");
}

sub diff : Callback {
    my $self   = shift;
    my $widget = $self->class_key;
    my $params = $self->params;
    my $tmpl   = get_state_data($widget, 'template');
    my $id     = $tmpl->get_id;

    # Save any changes to the template to the session.
    $save_object->($self, $self->params)
        if get_state_name($widget) eq 'edit'
        && $tmpl->get_checked_out
        && $tmpl->get_user__id == get_user_id;

    # Find the from and to version numbers.
    my $from = $params->{"$widget|from_version"}
             || $params->{"$widget|version"};
    my $to   = $params->{"$widget|to_version"}
             || $tmpl->get_version;

    # Send it on home.
    $self->set_redirect(
        "/workflow/profile/template/$id/?diff=1"
        . "&from_version=$from&to_version=$to"
    );
}

sub cancel : Callback(priority => 6) {
    my $self = shift;

    my $fa = get_state_data($self->class_key, 'template');
    if ($fa->get_version == 0) {
        # If the version number is 0, the template was never checked in to a
        # desk. So just delete it.
        $delete_fa->($self, $fa);
    } else {
        # Cancel the checkout and undeploy the template from the user's
        # sand box.
        $fa->cancel_checkout;
        log_event('template_cancel_checkout', $fa);
        my $sb = Bric::Util::Burner->new({user_id => get_user_id()});
        $sb->undeploy($fa);

        # If the template was last recalled from the library, then remove it
        # from the desk and workflow. We can tell this because there will
        # only be one template_moved event and one template_checkout event
        # since the last template_add_workflow event.
        my @events = Bric::Util::Event->list({
            class => ref $fa,
            obj_id => $fa->get_id
        });
        my ($desks, $cos) = (0, 0);
        while (@events && $events[0]->get_key_name ne 'template_add_workflow') {
            my $kn = shift(@events)->get_key_name;
            if ($kn eq 'template_moved') {
                $desks++;
            } elsif ($kn eq 'template_checkout') {
                $cos++
            }
        }

        # If one move to desk, and one checkout, and this isn't the first
        # time the template has been in workflow since it was created...
        if ($desks == 1 && $cos == 1 && @events > 2) {
            # It was just recalled from the library. So remove it from the
            # desk and from workflow.
            my $desk = $fa->get_current_desk;
            $desk->remove_asset($fa);
            $fa->set_workflow_id(undef);
            $desk->save;
            $fa->save;
            log_event("template_rem_workflow", $fa);
        } else {
            # Just save the cancelled checkout. It will be left in workflow for
            # others to find.
            $fa->save;
        }
        $self->add_message('Template "[_1]" check out canceled.', $fa->get_file_name);
    }
    clear_state($self->class_key);

    # Remove the template from the user's sandbox.
    my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
    $sb->undeploy($fa);

    $self->set_redirect("/");
}

sub notes : Callback {
    my $self = shift;
    my $widget = $self->class_key;

    my $action = $self->params->{$widget.'|notes_cb'};

    # Save the metadata we've collected on this request.
    my $fa = get_state_data($widget, 'template');
    my $id = $fa->get_id;

    # Save the data if we are in edit mode.
    &$save_meta($self, $widget, $fa) if $action eq 'edit';

    # Set a redirection to the code page to be enacted later.
    $self->set_redirect("/workflow/profile/template/${action}_notes.html?id=$id");
}

sub trail : Callback {
    my $self = shift;
    my $widget = $self->class_key;
    my $action = $self->params->{$widget.'|trail_cb'};

    # Save the metadata we've collected on this request.
    my $fa = get_state_data($widget, 'template');
    my $id = $fa->get_id;

    &$save_meta($self->params, $widget, $fa) if $action eq 'edit';

    $save_meta->($self, $widget, $fa) if $action eq 'edit';

    # Set a redirection to the code page to be enacted later.
    $self->set_redirect("/workflow/events/template/$id?filter_by=template_moved");
}

sub create_next : Callback {
    my $self = shift;

    my $ttype = $self->params->{tplate_type};

    # Just create it if CATEGORY template was selected.
    $create_fa->($self, $self->class_key, $self->params)
      if $ttype == Bric::Biz::Asset::Template::CATEGORY_TEMPLATE;
}

sub create : Callback {
    my $self = shift;
    $create_fa->($self, $self->class_key, $self->params);
}

sub return : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;

    my $state        = get_state_name($widget);
    my $version_view = get_state_data($widget, 'version_view');
    my $fa = get_state_data($widget, 'template');

    # note: $self->value =~ /^\d+$/ is for IE which sends the .x or .y position
    # of the mouse for <input type="image"> buttons
    if ($version_view || $self->value eq 'diff' || $self->value =~ /^\d+$/) {
        my $fa_id = $fa->get_id;
        clear_state($widget) if $version_view;
        $self->set_redirect("/workflow/profile/template/$fa_id/?checkout=1");
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
        $self->set_redirect($url);
    }

    # Remove this page from the stack.
    pop_page();
}

sub cancel_return : Callback(priority => 6) {
    my $self = shift;
    my $widget = $self->class_key;

    my $state        = get_state_name($widget);
    my $version_view = get_state_data($widget, 'version_view');
    my $fa = get_state_data($widget, 'template');

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
    $self->set_redirect($url);

    # Remove this page from the stack.
    pop_page();
}

# Pull a template back from the dead and on to the workflow.
sub recall : Callback {
    my $self = shift;

    my $ids = $self->params->{$self->class_key.'|recall_cb'};
    my ($co, %wfs);
    $ids = ref $ids ? $ids : [$ids];

    foreach (@$ids) {
        my ($o_id, $w_id) = split('\|', $_);
        my $fa = Bric::Biz::Asset::Template->lookup({'id' => $o_id});
        if (chk_authz($fa, RECALL, 1)) {
            my $wf = $wfs{$w_id} ||= Bric::Biz::Workflow->lookup({'id' => $w_id});

            # They checked 'Include deleted' and the 'Reactivate' checkbox
            unless ($fa->is_active) {
                $fa->activate();
            }

            # Put this template asset into the current workflow
            $fa->set_workflow_id($w_id);
            log_event('template_add_workflow', $fa, { Workflow => $wf->get_name });

            # Get the start desk for this workflow.
            my $start_desk = $wf->get_start_desk;

            # Put this template asset on to the start desk.
            $start_desk->accept({'asset' => $fa});
            $start_desk->checkout($fa, get_user_id());
            $start_desk->save;
            log_event('template_moved', $fa, { Desk => $start_desk->get_name });
            log_event('template_checkout', $fa);
            $co++;

            # Deploy the template to the user's sandbox.
            my $sb = Bric::Util::Burner->new({user_id => get_user_id()});
            $sb->deploy($fa);

        } else {
            $self->raise_forbidden(
                'Permission to checkout "[_1]" denied.',
                $fa->get_file_name,
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
        my ($o_id, $w_id) = split('\|', $ids->[0]);
        $self->set_redirect('/workflow/profile/template/'.$o_id.'?checkout=1');
    }
}

sub checkout : Callback {
    my $self = shift;

    my $ids = $self->value;
    $ids = ref $ids ? $ids : [$ids];
    my $co;

    foreach my $t_id (@$ids) {
        my $t_obj = Bric::Biz::Asset::Template->lookup({'id' => $t_id});
        if (chk_authz($t_obj, EDIT, 1)) {
            $t_obj->checkout({ user__id => get_user_id() });
            $t_obj->save;
            log_event("template_checkout", $t_obj);
            $co++;

            # Deploy the template to the user's sandbox.
            my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
            $sb->deploy($t_obj);
        } else {
            $self->raise_forbidden(
                'Permission to checkout "[_1]" denied.',
                $t_obj->get_file_name,
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
        $self->set_redirect('/workflow/profile/template/' . $ids->[0] . '?checkout=1');
    }
}

sub download_file : Callback {
    my $self = shift;
    my $fa   = get_state_data($self->class_key, 'template');
    my $req  = $self->apache_req;
    (my $fn  = $fa->get_file_name) =~ s{.*/}{};

    $req->content_type(qq{text/plain; name="$fn"; charset=utf-8});
    $req->headers_out->set(
        'Content-Disposition' => qq{attachment; filename="$fn"}
    );

    $req->send_http_header if MOD_PERL_VERSION < 2;
    $req->print($fa->get_data);
    $self->abort;
}

###

$save_meta = sub {
    my ($self, $widget, $fa) = @_;
    my $param = $self->params;
    $fa ||= get_state_data($widget, 'template');
    chk_authz($fa, EDIT);
    $fa->set_priority($param->{priority}) if $param->{priority};
    $fa->set_description($param->{description}) if $param->{description};
    $fa->set_expire_date($param->{'expire_date'}) if $param->{'expire_date'};
    if ($param->{"$widget|upload_file"}) {
        $handle_upload->($self, $fa);
    } else {
        # Normalize line-endings.
        $param->{"$widget|code"} =~ s/\r\n?/\n/g;
        $fa->set_data($param->{"$widget|code"});
    }
    if (exists $param->{category_id}) {
        # Remove the existing version from the user's sand box.
        my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
        $sb->undeploy($fa);
        # Set the new category.
        $fa->set_category_id($param->{category_id});
    }
    return set_state_data($widget, 'template', $fa);
};

$save_code = sub {
    my ($param, $widget, $fa) = @_;
    $fa ||= get_state_data($widget, 'template');
    chk_authz($fa, EDIT);
    $fa->set_data($param->{"$widget|code"});
    return set_state_data($widget, 'template', $fa);
};

$save_object = sub{
    my ($self, $param) = @_;
    my $widget = $self->class_key;
    my $fa = get_state_data($widget, 'template');
    $save_meta->($self, $widget, $fa);
};

$checkin = sub {
    my ($self, $widget, $param, $fa) = @_;
    my $new = defined $fa->get_id ? 0 : 1;
    $save_meta->($self, $widget, $fa);

    $fa->checkin;

    # Get the desk information.
    my $desk_id = $param->{"$widget|desk"};
    my $cur_desk = $fa->get_current_desk;

    # See if this template needs to be removed from workflow or published.
    if ($desk_id eq 'remove') {
        # Remove from the current desk and from the workflow.
        $cur_desk->remove_asset($fa)->save if $cur_desk;
        $fa->set_workflow_id(undef);
        $fa->save;
        log_event(($new ? 'template_create' : 'template_save'), $fa);
        log_event('template_checkin', $fa, { Version => $fa->get_version });
        log_event("template_rem_workflow", $fa);
        $self->add_message('Template "[_1]" saved and shelved.', $fa->get_file_name);
    } elsif ($desk_id eq 'deploy') {
        # Publish the template and remove it from workflow.
        my ($pub_desk, $no_log);
        # Find a publish desk.
        if ($cur_desk and $cur_desk->can_publish) {
            # We've already got one.
            $pub_desk = $cur_desk;
            $no_log = 1;
        } else {
            # Find one in this workflow.
            my $wf = Bric::Biz::Workflow->lookup
              ({ id => $fa->get_workflow_id });
            foreach my $d ($wf->allowed_desks) {
                $pub_desk = $d and last if $d->can_publish;
            }
            # Transfer the template to the publish desk.
            if ($cur_desk) {
                $cur_desk->transfer({ to    => $pub_desk,
                                      asset => $fa });
                $cur_desk->save;
            } else {
                $pub_desk->accept({ asset => $fa });
            }
            $pub_desk->save;
        }

        $fa->save;
        # Log it!
        log_event(($new ? 'template_create' : 'template_save'), $fa);
        log_event('template_checkin', $fa, { Version => $fa->get_version });
        my $dname = $pub_desk->get_name;
        log_event('template_moved', $fa, { Desk => $dname })
          unless $no_log;
        $self->add_message(
            'Template "[_1]" saved and checked in to "[_2]".',
            $fa->get_file_name,
            $dname,
        );
    } else {
        # Look up the selected desk.
        my $desk = Bric::Biz::Workflow::Parts::Desk->lookup
          ({ id => $desk_id });
        my $no_log;
        if ($cur_desk) {
            if ($cur_desk->get_id == $desk_id) {
                $no_log = 1;
            } else {
                # Transfer the template to the new desk.
                $cur_desk->transfer({ to    => $desk,
                                      asset => $fa });
                $cur_desk->save;
            }
        } else {
            # Send this template to the selected desk.
            $desk->accept({ asset => $fa });
        }

        $desk->save;
        $fa->save;
        log_event(($new ? 'template_create' : 'template_save'), $fa);
        log_event('template_checkin', $fa, { Version => $fa->get_version });
        my $dname = $desk->get_name;
        log_event('template_moved', $fa, { Desk => $dname }) unless $no_log;
        $self->add_message(
            'Template "[_1]" saved and moved to "[_2]".',
            $fa->get_file_name,
            $dname,
        );
    }

    # Deploy the template, if necessary.
    if ($desk_id eq 'deploy') {
        my $class_key = 'desk_asset';

        $param->{"$class_key|template_pub_ids"} = $fa->get_version_id;

        # Call the deploy callback in the desk widget.
        clear_authz_cache( $fa );
        my $cb = Bric::App::Callback::Desk->new
          ( cb_request => $self->cb_request,
            apache_req => $self->apache_req,
            params     => $param,
            pkg_key    => $class_key,
        );
        $cb->deploy;
    }

    my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
    $sb->undeploy($fa);

    # Clear the state out, set redirect, and return.
    clear_state($widget);
    $self->set_redirect("/");
    return $fa;
};

$check_syntax = sub {
    my ($self, $widget, $fa) = @_;
    my $burner = Bric::Util::Burner->new;
    my $err;
    # Return success if the syntax checks out.
    return 1 if $burner->chk_syntax($fa, \$err);
    # Otherwise, add a message and return false.
    $self->add_message('Template compile failed: [_1]', $err);
    return 0
};

$delete_fa = sub {
    my ($self, $fa) = @_;
    my $desk = $fa->get_current_desk;
    $desk->checkin($fa);
    $desk->remove_asset($fa);
    $desk->save;
    log_event("template_rem_workflow", $fa);
    my $burn = Bric::Util::Burner->new;
    $burn->undeploy($fa);
    my $sb = Bric::Util::Burner->new({user_id => get_user_id() });
       $sb->undeploy($fa);
    $fa->set_workflow_id(undef);
    $fa->deactivate;
    $fa->save;
    log_event("template_deact", $fa);
    $self->add_message('Template "[_1]" deleted.', $fa->get_file_name);
};

$create_fa = sub {
    my ($self, $widget, $param) = @_;
    my $at_id = $param->{$widget.'|at_id'};
    my $oc_id = $param->{$widget.'|oc_id'};
    my $cat_id = $param->{$widget.'|cat_id'};
    my $tplate_type = $param->{tplate_type};

    my $site_id = Bric::Biz::Workflow->lookup({
        id => get_state_data($widget => 'work_id')
    })->get_site_id;

    my ($at, $name);
    if ($tplate_type == Bric::Biz::Asset::Template::ELEMENT_TEMPLATE) {
        unless ($param->{$widget.'|no_at'}) {
            unless (defined $at_id && $at_id ne '') {
                # It's no good.
                $self->raise_conflict('You must select an Element.');
                return;
            }
            # Associate it with an Element.
            $at    = Bric::Biz::ElementType->lookup({'id' => $at_id});
            $name  = $at->get_key_name;
        }
    } elsif ($tplate_type == Bric::Biz::Asset::Template::UTILITY_TEMPLATE) {
        $name = $param->{"$widget|name"};
    } # Otherwise, it'll default to a category template.

    # Check permissions.
    my $work_id = get_state_data($widget, 'work_id');
    my $wf = Bric::Biz::Workflow->lookup({ id => $work_id });
    my $start_desk = $wf->get_start_desk;
    my $gid = $start_desk->get_asset_grp;
    chk_authz('Bric::Biz::Asset::Template', CREATE, 0, $gid);

    # Create a new template asset.
    my $fa = eval {
        Bric::Biz::Asset::Template->new({
            element_type            => $at,
            file_type          => $param->{file_type},
            output_channel__id => $oc_id,
            category_id        => $cat_id,
            priority           => $param->{priority},
            name               => $name,
            user__id           => get_user_id(),
            site_id            => $site_id,
        });
    };

    my $was_reactivated = 0;
    if (my $err = $@) {
        if ($err->error !~ /already\s+exists/) {
            rethrow_exception($err);
        } else {
            # XXX: it should never return more than one asset, right?
            ($fa) = Bric::Biz::Asset::Template->list({
                active => 0,
                output_channel_id => $oc_id,
                category_id => $cat_id,
                element_type_id => $at_id,
                site_id => $site_id,
            });
            if (defined $fa) {
                $self->add_message('Deactivated template was reactivated.');
                $fa->activate;
                $was_reactivated = 1;
            } else {
                # XXX: it's redundant to say "element and burner"
                # because a burner is associated uniquely with the element
                # (don't forget to update Locale if this changes)
                $self->raise_conflict(
                    'A template already exists for the selected output channel, category, element and burner you selected.  You must delete the existing template before you can add a new one.'
                );
                return;
            }
        }
    }

    # Set the workflow this template should be in.
    $fa->set_workflow_id($work_id);

    # Save the template.
    $fa->save;

    # Send this template to the first desk.
    $start_desk->accept({ asset => $fa });

    if ($was_reactivated) {
        # Check it out.
        $start_desk->checkout($fa, get_user_id());
        log_event("template_checkout", $fa);
    } else {
        log_event('template_new', $fa);
    }

    $start_desk->save;

    # Log that a new template has been created.
    log_event('template_add_workflow', $fa, { Workflow => $wf->get_name });
    log_event('template_moved', $fa, { Desk => $start_desk->get_name });
    log_event('template_save', $fa);
    $self->add_message('Template "[_1]" saved.', $fa->get_file_name);

    # Put the template into the session and clear the workflow ID.
    set_state_data($widget, 'template', $fa);
    set_state_data($widget, 'work_id', '');

    # Head for the main edit screen.
    $self->set_redirect("/workflow/profile/template/?checkout=1");

    # As far as history is concerned, this page should be part of the template
    # profile stuff.
    pop_page();
};

$handle_upload = sub {
    my ($self, $fa) = @_;
    my $widget = $self->class_key;
    my $upload = $self->apache_req->upload("$widget|upload_file");
    my $fh = $upload->fh;
    binmode $fh, ':utf8' if ENCODE_OK;
    $fa->set_data(do { local $/; <$fh> });
    return $self;
};

1;
