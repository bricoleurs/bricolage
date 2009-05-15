package Bric::App::Callback::Profile::Desk;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'desk';

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:history);
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;

my $type = 'desk';
my $disp_name = 'Desk';
my $class = 'Bric::Biz::Workflow::Parts::Desk';

my ($expire_wf_cache);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $desk = $self->obj;

    my $name = $param->{name} if $param->{name};
    if ($param->{delete}) {
        # Deactivate it.
        $desk->deactivate;
        $desk->save;
        $self->$expire_wf_cache($param->{"${type}_id"});
        log_event("${type}_deact", $desk);
        $self->add_message(
            "$disp_name profile \"[_1]\" deleted from all workflows.",
            $name,
        );
        $self->set_redirect(defined $param->{workflow_id} ?
                       "/admin/profile/workflow/$param->{workflow_id}"
                         : last_page());
    } else {
        my $desk_id = $param->{"${type}_id"};
        # Make sure the name isn't already in use.
        my $used;
        if ($param->{name}) {
            my @desks = $class->list_ids({
                name   => $param->{name},
                active => undef,
            });
            if (@desks > 1) {
                $used = 1;
            } elsif (@desks == 1 && !defined $desk_id) {
                $used = 1;
            } elsif (@desks == 1 && defined $desk_id
           && $desks[0] != $desk_id) {
                $used = 1;
            }
            $self->raise_conflict(
                "The name \"[_1]\" is already used by another $disp_name.",
                $name,
            ) if $used;
        }

        # Roll in the changes.
        $desk->set_description($param->{description}) if exists $param->{description};
        if (exists $param->{name}) {
            $desk->set_name($param->{name}) unless $used;
            if (exists $param->{publish}) {
                $desk->make_publish_desk;
            } else {
                $desk->make_regular_desk;
            }
        }
        unless ($used) {
            $desk->save;
            $self->$expire_wf_cache($desk_id);
            log_event($type . (defined $param->{desk_id} ? '_save' : '_new'), $desk);
        } else {
            $param->{new_desk} = 1;
            $param->{'obj'} = $desk;
            return;
        }
        if (defined $param->{workflow_id}) {
            # It's a new desk for this profile. Add it.
            my $wf = Bric::Biz::Workflow->lookup({ id => $param->{workflow_id} });
            $wf->add_desk({ allowed => [$desk->get_id] });
            $wf->save;
            $self->cache->set('__WORKFLOWS__' . $wf->get_site_id => 0);
            log_event('workflow_add_desk', $wf, { Desk => $desk->get_name });
            $self->set_redirect("/admin/profile/workflow/$param->{workflow_id}");
        } else {
            $self->set_redirect(last_page());
        }
    }
}

###

$expire_wf_cache = sub {
    my ($self, $did) = @_;
    # Expire the cache for all workflows that contain this desk.
    foreach my $wf (Bric::Biz::Workflow->list({ desk_id => $did })) {
        $self->cache->set('__WORKFLOWS__' . $wf->get_site_id, 0);
    }
};


1;
