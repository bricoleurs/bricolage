package Bric::App::Callback::Profile::Site;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'site';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
use Bric::Util::Fault qw(rethrow_exception isa_bric_exception);
use Bric::Util::Grp;

my $type = CLASS_KEY;
my $disp_name = 'Site';
my $class = 'Bric::Biz::Site';
my $site_cache_key = '__SITES__';
my $wf_cache_key = '__WORKFLOWS__';

sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $site = $self->obj;

    if ($param->{delete}) {
        # Deactivate it.
        $site->deactivate;
        $site->save;
        $self->cache->set_lmu_time;
        $self->cache->set($site_cache_key, 0);
        $self->cache->set($wf_cache_key . $site->get_id, 0);
        log_event("${type}_deact", $site);
        $self->set_redirect('/admin/manager/site');
        $self->add_message(
            qq{$disp_name profile "[_1]" deleted.},
            $param->{name},
        );
        return;
    }

    # Set the main attributes.
    $site->set_description($param->{description});
    $site->set_name($param->{name});
    $site->set_domain_name($param->{domain_name});
    $site->save;
    $self->cache->set_lmu_time;
    $self->cache->set($site_cache_key, 0);
    $self->cache->set($wf_cache_key . $site->get_id, 0);
    $self->add_message(qq{$disp_name profile "[_1]" saved.}, $param->{name});
    log_event($type . '_save', $site);

    $param->{obj} = $site;
    $self->set_redirect('/admin/manager/site');
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
            $self->raise_forbidden(
                'Permission to delete "[_1]" denied.',
                $site->get_name,
            );
        }
    }
    if ($flag) {
        $c->set($site_cache_key, 0);
        $c->set($wf_cache_key, 0);
    }
}


1;
