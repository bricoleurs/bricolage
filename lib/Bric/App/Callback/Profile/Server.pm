package Bric::App::Callback::Profile::Server;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'server';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
use Bric::Dist::Server;
use Bric::Dist::ServerType;

my $type = CLASS_KEY;
my $disp_name = 'Server';
my $class = 'Bric::Dist::Server';
my $dest_type = 'dest';
my $dest_name = 'Destination';
my $dest_class = 'Bric::Dist::ServerType';


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $s = $self->obj;

    my $name = $param->{host_name};

    if ($param->{delete}) {
        # Delete it.
        $s->del;
        $s->save;
        log_event('server_del', $s);
        $self->add_message("$disp_name profile \"[_1]\" deleted.", $name);
        # Set the redirection.
        $self->set_redirect("/admin/profile/dest/$param->{dest_id}");
        return;
    }

    my $dest_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my $used;
    my @dests = $class->list_ids({
        host_name      => $param->{host_name},
        server_type_id => $param->{dest_id}
    });
    if (@dests > 1) {
        $used = 1;
    } elsif (@dests == 1 && !defined $dest_id) {
        $used = 1;
    } elsif (@dests == 1 && defined $dest_id
       && $dests[0] != $dest_id) {
        $used = 1;
    }
    $self->add_message("The name \"[_1]\" is already used by another $disp_name in this $dest_name.", $name) if $used;

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
        $param->{'obj'} = $s;
        return;
    } else {
        $s->set_host_name($param->{host_name});
        $s->save;
        log_event($type . (defined $param->{server_id} ? '_save' : '_new'), $s);
        $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
        # Set the redirection.
        $self->set_redirect("/admin/profile/dest/$param->{dest_id}");
    }
}


# strictly speaking, this is a Manager (not a Profile) callback

sub delete : Callback {
    my $self = shift;

    my $dest = $dest_class->lookup({ 'id' => $self->params->{dest_id} });
    chk_authz($dest, EDIT);
    foreach my $id (@{ mk_aref($self->value) }) {
        my $s = $class->lookup({'id' => $id}) || next;
        $s->del();
        $s->save();
        log_event('server_del', $s);
    }
}


1;
