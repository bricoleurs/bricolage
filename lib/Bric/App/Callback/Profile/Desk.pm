package Bric::App::Callback::Profile::Desk;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass(class_key => 'desk');
use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;

my $type = 'desk';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);

sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $desk = $self->obj;

    my $name = "&quot;$param->{name}&quot;" if $param->{name};
    if ($param->{delete}) {
        # Deactivate it.
        $desk->deactivate;
        $desk->save;
        $self->cache->set('__WORKFLOWS__', 0);
        log_event("${type}_deact", $desk);
        add_msg($self->lang->maketext("$disp_name profile [_1] deleted from all workflows.",$name));
        set_redirect(defined $param->{workflow_id} ?
                       "/admin/profile/workflow/$param->{workflow_id}"
                         : last_page());
    } else {
        my $desk_id = $param->{"${type}_id"};
        # Make sure the name isn't already in use.
        my $used;
        if ($param->{name}) {
            my @desks = $class->list_ids({ name => $param->{name} });
            if (@desks > 1) {
                $used = 1;
            } elsif (@desks == 1 && !defined $desk_id) {
                $used = 1;
            } elsif (@desks == 1 && defined $desk_id
	       && $desks[0] != $desk_id) {
                $used = 1;
            }
            add_msg($self->lang->maketext("The name [_1] is already used by another [_2].",$name,$disp_name))
              if $used;
        }

        # Roll in the changes.
        $desk->set_name($param->{name}) if exists $param->{name} && !$used;
        $desk->set_description($param->{description}) if exists $param->{description};
        if (exists $param->{name} && exists $param->{publish}) {
            $desk->make_publish_desk;
        } else {
            $desk->make_regular_desk;
        }
        unless ($used) {
            $desk->save;
            $self->cache->set('__WORKFLOWS__', 0);
            log_event($type . (defined $param->{desk_id} ? '_save' : '_new'), $desk);
        } else {
            $param->{new_desk} = 1;
            return $desk;
        }
        if (defined $param->{workflow_id}) {
            # It's a new desk for this profile. Add it.
            my $wf = Bric::Biz::Workflow->lookup({ id => $param->{workflow_id} });
            $wf->add_desk({ allowed => [$desk->get_id] });
            $wf->save;
            $self->cache->set('__WORKFLOWS__', 0);
            log_event('workflow_add_desk', $wf, { Desk => $desk->get_name });
            set_redirect("/admin/profile/workflow/$param->{workflow_id}");
        } else {
            set_redirect(last_page());
        }
    }
}


1;
