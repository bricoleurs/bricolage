package Bric::App::Callback::Profile::Site;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass('class_key' => 'site');
use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Util::Fault qw(rethrow_exception isa_bric_exception);
use Bric::Util::Grp;

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);


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
        $self->cache->set('__WORKFLOWS__', 0);
        log_event("${type}_deact", $site);
        set_redirect('/admin/manager/site');
        add_msg($self->lang->maketext("$disp_name profile &quot;[_1]&quot; deleted.",
                                $param->{name}));
        return;
    }

    eval {
        # Set the main attributes.
        $site->set_description($param->{description});
        $site->set_name($param->{name});
        $site->set_domain_name($param->{domain_name});
        $site->save;
        $self->cache->set('__SITES__', 0);
        $self->cache->set('__WORKFLOWS__', 0);
        add_msg($self->lang->maketext("$disp_name profile [_1] saved.", $param->{name}));
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
        set_redirect('/admin/manager/site');
    };

    # Return if there are no errors.
    my $err = $@ or return;
    # Catch Error exceptions and turn them into error messages.
    rethrow_exception($err) unless isa_bric_exception($err, 'Error');
    add_msg($self->lang->maketext($err->maketext));
    return $site;
}


1;
