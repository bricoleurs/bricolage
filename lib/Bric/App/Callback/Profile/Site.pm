package Bric::App::Callback::Profile::Site;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'site';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Util::Fault qw(rethrow_exception isa_bric_exception);
use Bric::Util::Grp;

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $site = $self->obj;

    if ($param->{delete}) {
        # Deactivate it.
        $site->deactivate;
        $site->save;
        $self->cache->set_lmu_time;
        $self->cache->set('__SITES__', 0);
        $self->cache->set('__WORKFLOWS__' . $site->get_id, 0);
        log_event("${type}_deact", $site);
        set_redirect('/admin/manager/site');
        add_msg("$disp_name profile &quot;[_1]&quot; deleted.",
                $param->{name});
        return;
    }

    # Set the main attributes.
    $site->set_description($param->{description});
    $site->set_name($param->{name});
    $site->set_domain_name($param->{domain_name});
    $site->save;
    $self->cache->set('__SITES__', 0);
    $self->cache->set('__WORKFLOWS__' . $site->get_id, 0);
    add_msg("$disp_name profile [_1] saved.", $param->{name});
    log_event($type . '_save', $site);

    # Take care of group managment.
    if ($param->{add_grp} or $param->{rem_grp}) {
        my @add_grps = map { Bric::Util::Grp->lookup({ id => $_ }) }
          @{mk_aref($param->{add_grp})};
        my @del_grps = map { Bric::Util::Grp->lookup({ id => $_ }) }
          @{mk_aref($param->{rem_grp})};

        # Assemble the new member information.
        foreach my $grp (@add_grps) {
            # Add the user to the group.
            $grp->add_members([{ obj => $site }]);
            $grp->save;
            log_event('grp_save', $grp);
        }

        foreach my $grp (@del_grps) {
            # Deactivate the user's group membership.
            foreach my $mem ($grp->has_member({ obj => $site })) {
                $mem->deactivate;
                $mem->save;
            }
            $grp->save;
            log_event('grp_save', $grp);
        }
    }

    $param->{obj} = $site;
    set_redirect('/admin/manager/site');
    return;
}


# strictly speaking, this is a Manager (not a Profile) callback

sub delete : Callback {
    my $self = shift;
    my $c = $self->cache;

    my $flag;
    foreach my $id (@{ mk_aref($self->value) }) {
        my $site = $class->lookup({'id' => $id}) || next;
        if (chk_authz($site, EDIT, 1)) {
            $site->deactivate();
            $site->save();
            $c->set_lmu_time();
            log_event("${type}_deact", $site);
            $flag = 1;
        } else {
            add_msg('Permission to delete "[_1]" denied.', $site->get_name);
        }
    }
    if ($flag) {
        $c->set('__SITES__', 0);
        $c->set('__WORK_FLOWS__', 0);
    }
}


1;
