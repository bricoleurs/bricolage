package Bric::App::Callback::Profile::Server;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass(class_key => 'server');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Dist::Server;
use Bric::Dist::ServerType;

my $type = CLASS_KEY;
my $dest_type = 'dest';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
my $dest_name = get_disp_name($dest_type);
my $dest_class = get_package_name($dest_type);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $s = $self->obj;

    my $name = "&quot;$param->{host_name}&quot;";

    if ($param->{delete}) {
        # Delete it.
        $s->del;
        $s->save;
        log_event('server_del', $s);
        add_msg($self->lang->maketext("$disp_name profile [_1] deleted.",$name));
        # Set the redirection.
        set_redirect("/admin/profile/dest/$param->{dest_id}");
        return;
    }

    my $dest_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my $used;
    my @dests = $class->list_ids({ host_name => $param->{host_name},
                                   server_type_id => $param->{dest_id} });
    if (@dests > 1) {
        $used = 1;
    } elsif (@dests == 1 && !defined $dest_id) {
        $used = 1;
    } elsif (@dests == 1 && defined $dest_id
       && $dests[0] != $dest_id) {
        $used = 1;
    }
    add_msg($self->lang->maketext("The name [_1] is already used by another $disp_name in this"
                              . " $dest_name."),$name) if $used;

    # Roll in the changes.
    if (exists $param->{active}) {
        unless ($s->is_active) {
            $s->activate;
            log_event('server_act', $s);
        }
    } else {
        $s->deactivate;
        log_event('server_deact', $s);
    }

    $s->set_server_type_id($param->{dest_id});
    $s->set_os($param->{os});
    $s->set_doc_root($param->{doc_root});
    $s->set_login($param->{login});
    $s->set_password($param->{password}) if $param->{password};
    $s->set_cookie($param->{cookie});
    if ($used) {
        return $s;
    } else {
        $s->set_host_name($param->{host_name});
        $s->save;
        log_event($type . (defined $param->{server_id} ? '_save' : '_new'), $s);
        add_msg($self->lang->maketext("$disp_name profile [_1] saved.",$name));
        # Set the redirection.
        set_redirect("/admin/profile/dest/$param->{dest_id}");
    }
}


# strictly speaking, this is a Manager (not a Profile) callback

sub delete : Callback {
    my $self = shift;

    my $dest = $dest_class->lookup({ 'id' => $self->request_args->{dest_id} });
    chk_authz($dest, EDIT);
    foreach my $id (@{ mk_aref($self->value) }) {
        my $s = $class->lookup({'id' => $id}) || next;
        $s->del();
        $s->save();
        log_event('server_del', $s);
    }
}


1;
