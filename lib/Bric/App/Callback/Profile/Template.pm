package Bric::App::Callback::Profile::Template;

use base qw(Bric::App::Callback);    # not subclassing Profile
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'tmpl_prof';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:all);
use Bric::Biz::Asset::Formatting;
use Bric::Biz::AssetType;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Util::Burner;
use Bric::Util::Fault qw(rethrow_exception);

my $DESK_URL = '/workflow/profile/desk/';
my $SEARCH_URL = '/workflow/manager/templates/';
my $ACTIVE_URL = '/workflow/active/templates/';

my ($save_meta, $save_code, $save_object, $checkin, $check_syntax,
    $delete_fa, $create_fa);


sub save : Callback {
    my $self = shift;
    my $widget = $self->class_key;

    $save_object->($widget, $self->params);
    my $fa = get_state_data($widget, 'fa');

    my $workflow_id = $fa->get_workflow_id;
    if ($self->params->{"$widget|delete"}) {
        # Delete the fa.
        $delete_fa->($self, $fa);
    } else {
        # Check syntax.
        return unless $check_syntax->($self, $widget, $fa);
        # Save it.
        $fa->save;
        log_event('formatting_save', $fa);
        add_msg('Template "[_1]" saved.', $fa->get_name);
    }

    my $return = get_state_data($widget, 'return') || '';

    # Clear out our application state and send 'em home.
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

    my $fa = get_state_data($widget, 'fa');
    $save_meta->($self->params, $widget, $fa);
    return unless $check_syntax->($self, $widget, $fa);
    $checkin->($self, $widget, $self->params, $fa);
}

sub save_and_stay : Callback {
    my $self = shift;
    my $widget = $self->class_key;

    $save_object->($widget, $self->params);
    my $fa = get_state_data($widget, 'fa');

    if ($self->params->{"$widget|delete"}) {
        # Delete the template.
        $delete_fa->($self, $fa);
        # Get out of here, since we've blow it away!
        set_redirect("/");
        pop_page();
        clear_state($widget);
    } else {
        # Check syntax.
        return unless $check_syntax->($self, $widget, $fa);
        # Save the template.
        $fa->save;
        log_event('formatting_save', $fa);
        add_msg('Template "[_1]" saved.', $fa->get_name);
    }
}

sub revert : Callback {
    my $self = shift;
    my $widget = $self->class_key;

    my $fa      = get_state_data($widget, 'fa');
    my $version = $self->params->{"$widget|version"};
    $fa->revert($version);
    $fa->save;
    clear_state($widget);
}

sub view : Callback {
    my $self = shift;
    my $widget = $self->class_key;

    my $fa      = get_state_data($widget, 'fa');
    my $version = $self->params->{"$widget|version"};
    my $id      = $fa->get_id;
    set_redirect("/workflow/profile/templates/$id/?version=$version");
}

sub cancel : Callback {
    my $self = shift;

    my $fa = get_state_data($self->class_key, 'fa');
    $fa->cancel_checkout;
    $fa->save;
    log_event('formatting_cancel_checkout', $fa);
    clear_state($self->class_key);
    set_redirect("/");
    add_msg('Template "[_1]" check out canceled.', $fa->get_name);
}

sub notes : Callback {
    my $self = shift;
    my $widget = $self->class_key;

    my $action = $self->params->{$widget.'|notes_cb'};

    # Save the metadata we've collected on this request.
    my $fa = get_state_data($widget, 'fa');
    my $id = $fa->get_id;

    # Save the data if we are in edit mode.
    &$save_meta($self->params, $widget, $fa) if $action eq 'edit';

    # Set a redirection to the code page to be enacted later.
    set_redirect("/workflow/profile/templates/${action}_notes.html?id=$id");
}

sub trail : Callback {
    my $self = shift;

    # Save the metadata we've collected on this request.
    my $fa  = get_state_data($self->class_key, 'fa');
    &$save_meta($self->params, $self->class_key, $fa);
    my $id = $fa->get_id;

    # Set a redirection to the code page to be enacted later.
    set_redirect("/workflow/trail/formatting/$id");
}

sub create_next : Callback {
    my $self = shift;

    my $ttype = $self->params->{tplate_type};

    # Just create it if CATEGORY template was selected.
    $create_fa->($self, $self->class_key, $self->params)
      if $ttype == Bric::Biz::Asset::Formatting::CATEGORY_TEMPLATE;
}

sub create : Callback {
    my $self = shift;
    $create_fa->($self, $self->class_key, $self->params);
}

sub return : Callback {
    my $self = shift;
    my $widget = $self->class_key;

    my $state        = get_state_name($widget);
    my $version_view = get_state_data($widget, 'version_view');
    my $fa = get_state_data($widget, 'fa');

    if ($version_view) {
        my $fa_id = $fa->get_id;
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
    pop_page();
}

# Pull a template back from the dead and on to the workflow.
sub recall : Callback {
    my $self = shift;

    my $ids = $self->params->{$self->class_key.'|recall_cb'};
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
            $start_desk->checkout($fa, get_user_id());
            $start_desk->save;
            log_event('formatting_moved', $fa, { Desk => $start_desk->get_name });
            log_event('formatting_checkout', $fa);
        } else {
            add_msg('Permission to checkout "[_1]" denied.', $fa->get_name);
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

sub checkout : Callback {
    my $self = shift;

    my $ids = $self->value;
    $ids = ref $ids ? $ids : [$ids];

    foreach my $t_id (@$ids) {
        my $t_obj = Bric::Biz::Asset::Formatting->lookup({'id' => $t_id});
        if (chk_authz($t_obj, EDIT, 1)) {
            $t_obj->checkout({ user__id => get_user_id() });
            $t_obj->save;
            log_event("formatting_checkout", $t_obj);
        } else {
            add_msg('Permission to checkout "[_1]" denied.', $t_obj->get_file_name);
        }
    }

    if (@$ids > 1) {
        # Go to 'my workspace'
        set_redirect("/");
    } else {
        # Go to the profile screen
        set_redirect('/workflow/profile/templates/' . $ids->[0] . '?checkout=1');
    }
}


###

$save_meta = sub {
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

$save_code = sub {
    my ($param, $widget, $fa) = @_;
    $fa ||= get_state_data($widget, 'fa');
    chk_authz($fa, EDIT);
    $fa->set_data($param->{"$widget|code"});
    return set_state_data($widget, 'fa', $fa);
};

$save_object = sub{
    my ($widget, $param) = @_;
    my $fa = get_state_data($widget, 'fa');
    $save_meta->($param, $widget, $fa);
};

$checkin = sub {
    my ($self, $widget, $param, $fa) = @_;
    my $new = defined $fa->get_id ? 0 : 1;
    $save_meta->($param, $widget, $fa);

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
        log_event(($new ? 'formatting_create' : 'formatting_save'), $fa);
        log_event('formatting_checkin', $fa, { Version => $fa->get_version });
        log_event("formatting_rem_workflow", $fa);
        add_msg('Template "[_1]" saved and shelved.', $fa->get_name);
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
        log_event(($new ? 'formatting_create' : 'formatting_save'), $fa);
        log_event('formatting_checkin', $fa, { Version => $fa->get_version });
        my $dname = $pub_desk->get_name;
        log_event('formatting_moved', $fa, { Desk => $dname })
          unless $no_log;
        add_msg('Template "[_1]" saved and checked in to "[_2]".', $fa->get_name, $dname);
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
        log_event(($new ? 'formatting_create' : 'formatting_save'), $fa);
        log_event('formatting_checkin', $fa, { Version => $fa->get_version });
        my $dname = $desk->get_name;
        log_event('formatting_moved', $fa, { Desk => $dname }) unless $no_log;
        add_msg('Template "[_1]" saved and moved to "[_2]".', $fa->get_name, $dname);
    }

    # Deploy the template, if necessary.
    if ($desk_id eq 'deploy') {
        my $class_key = 'desk_asset';

        $param->{"$class_key|formatting_pub_ids"} = $fa->get_id;

        # Call the deploy callback in the desk widget.
        my $cb = Bric::App::Callback::Desk->new
          ( cb_request => $self->cb_request,
            apache_req => $self->apache_req,
            params     => $param,
            pkg_key    => $class_key,
        );
        $cb->deploy;
    }

    # Clear the state out, set redirect, and return.
    clear_state($widget);
    set_redirect("/");
    return $fa;
};

$check_syntax = sub {
    my ($self, $widget, $fa) = @_;
    my $burner = Bric::Util::Burner->new;
    my $err;
    # Return success if the syntax checks out.
    return 1 if $burner->chk_syntax($fa, \$err);
    # Otherwise, add a message and return false.
    add_msg("Template compile failed: [_1]", $err);
    return 0
};

$delete_fa = sub {
    my ($self, $fa) = @_;
    my $desk = $fa->get_current_desk;
    $desk->checkin($fa);
    $desk->remove_asset($fa);
    $desk->save;
    log_event("formatting_rem_workflow", $fa);
    my $burn = Bric::Util::Burner->new;
    $burn->undeploy($fa);
    $fa->set_workflow_id(undef);
    $fa->deactivate;
    $fa->save;
    log_event("formatting_deact", $fa);
    add_msg('Template "[_1]" deleted.', $fa->get_name);
};

$create_fa = sub {
    my ($self, $widget, $param) = @_;
    my $at_id = $param->{$widget.'|at_id'};
    my $oc_id = $param->{$widget.'|oc_id'};
    my $cat_id = $param->{$widget.'|cat_id'};
    my $file_type = $param->{file_type};
    my $tplate_type = $param->{tplate_type};

    my $site_id = Bric::Biz::Workflow->lookup
      ({ id => get_state_data($widget, 'work_id')})->
        get_site_id;

    my ($at, $name);
    if ($tplate_type == Bric::Biz::Asset::Formatting::ELEMENT_TEMPLATE) {
        unless ($param->{$widget.'|no_at'}) {
            unless (defined $at_id && $at_id ne '') {
                # It's no good.
                add_msg("You must select an Element.");
                return;
            }
            # Associate it with an Element.
            $at    = Bric::Biz::AssetType->lookup({'id' => $at_id});
            $name  = $at->get_name();
        }
    } elsif ($tplate_type == Bric::Biz::Asset::Formatting::UTILITY_TEMPLATE) {
        $name = $param->{"$widget|name"};
    } # Otherwise, it'll default to a category template.

    # Check permissions.
    my $work_id = get_state_data($widget, 'work_id');
    my $wf = Bric::Biz::Workflow->lookup({ id => $work_id });
    my $start_desk = $wf->get_start_desk;
    my $gid = $start_desk->get_asset_grp;
    chk_authz('Bric::Biz::Asset::Formatting', CREATE, 0, $gid);

    # Create a new formatting asset.
    my $fa;
    eval {
        $fa = Bric::Biz::Asset::Formatting->new({
            'element'            => $at,
            'file_type'          => $file_type,
            'output_channel__id' => $oc_id,
            'category_id'        => $cat_id,
            'priority'           => $param->{priority},
            'name'               => $name,
            'user__id'           => get_user_id(),
            'site_id'            => $site_id,
        });
    };

    if (my $err = $@) {
        unless ($err->error =~ /already exists/) {
            rethrow_exception($err);
        } else {
            add_msg("A template already exists for the selected output channel, category, element and burner you selected.  You must delete the existing template before you can add a new one.");
            return;
        }
    }

    # Set the workflow this template should be in.
    $fa->set_workflow_id($work_id);

    # Save the template.
    $fa->save;

    # Send this template to the first desk.
    $start_desk->accept({ asset => $fa });
    $start_desk->save;

    # Log that a new media has been created.
    log_event('formatting_new', $fa);
    log_event('formatting_add_workflow', $fa, { Workflow => $wf->get_name });
    log_event('formatting_moved', $fa, { Desk => $start_desk->get_name });
    log_event('formatting_save', $fa);
    add_msg('Template "[_1]" saved.', $fa->get_name);

    # Put the template into the session and clear the workflow ID.
    set_state_data($widget, 'fa', $fa);
    set_state_data($widget, 'work_id', '');

    # Head for the main edit screen.
    set_redirect("/workflow/profile/templates/?checkout=1");

    # As far as history is concerned, this page should be part of the template
    # profile stuff.
    pop_page();
};


1;
