package Bric::App::Callback::Profile::Workflow;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'workflow';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;

my $type = CLASS_KEY;
my $disp_name = 'Workflow';
my $class = 'Bric::Biz::Workflow';


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $wf = $self->obj;
    my $name = $param->{name};

    if ($param->{delete}) {
        # Deactivate it.
        $wf->deactivate;
        $wf->save;
        $self->cache->set('__WORKFLOWS__' . $wf->get_site_id, 0);
        log_event("${type}_deact", $wf);
        $self->set_redirect('/admin/manager/workflow');
        $self->add_message(qq{$disp_name profile "[_1]" deleted.}, $name);
    } else {
        my $wf_id = $param->{"${type}_id"};
        my $site_id = $param->{site_id} || $wf->get_site_id;

        # Make sure the name isn't already in use.
        my $used;
        my @wfs = ($class->list_ids({ name => $param->{name},
                                      site_id => $site_id }),
                   $class->list_ids({ name => $param->{name},
                                      site_id => $site_id,
                                      active => 0 }) );
        if (@wfs > 1) {
            $used = 1;
        } elsif (@wfs == 1 && !defined $wf_id) {
            $used = 1;
        } elsif (@wfs == 1 && defined $wf_id
       && $wfs[0] != $wf_id) {
            $used = 1;
        }
        $self->add_message(
            qq{The name "[_1]" is already used by another $disp_name.},
            $name,
        ) if $used;

        # Roll in the changes.
        $wf->set_name($param->{name}) unless $used;
        $wf->set_description($param->{description});
        $wf->set_type($param->{type}) if exists $param->{type};
        if (! defined $wf_id) {
            # It's a new workflow. Set the start desk.
            $wf->set_site_id($site_id);

            if ($param->{new_desk_name}) {
                # They're creating a brand new desk.
                my $d = (Bric::Biz::Workflow::Parts::Desk->list({ name => $param->{new_desk_name} }))[0]
                  || Bric::Biz::Workflow::Parts::Desk->new;
                $d->set_name($param->{new_desk_name});
                $d->save;
                my $did = $d->get_id;
                $wf->add_desk({ allowed => [$did] });
                $wf->set_start_desk($did);
            } else {
                # Set the start desk from the menu choice.
                $wf->set_start_desk($param->{first_desk});
                $param->{new_desk_name} =
                  Bric::Biz::Workflow::Parts::Desk->lookup({ id => $param->{first_desk} })->get_name;
            }
            unless ($used) {
                $wf->deactivate;
                $wf->save;
                $param->{id} = $wf->get_id;
                $self->cache->set("__WORKFLOWS__$site_id", 0);
                log_event("${type}_add_desk", $wf, { Desk => $param->{new_desk_name} });
                log_event($type . '_new', $wf);
            }
            $param->{'obj'} = $wf;
            return;
        } else {
            # It's an existing desk. Check to see if we're removing any desks.
            if ($param->{remove_desk}) {
                # Dissociate any desks, as necessary.
                my %desks = map { $_->get_id => $_ } $wf->allowed_desks;
                my $rem_desks = mk_aref($param->{remove_desk});
                foreach my $did (@$rem_desks) {
                    my $d = delete $desks{$did};
                    # Check if we're going to need to set a different desk to be start desk.
                    $param->{start} = -1 if $did == $param->{start};
                    log_event("${type}_del_desk", $wf, { Desk => $d->get_name });
                }
                # Now remove them from the workflow.
                $wf->del_desk($rem_desks);
                # Set the start desk ID if it needs to change.
                $param->{start} = (keys %desks)[0] if $param->{start} == -1;
            }

            # Set the start desk.
            $wf->set_start_desk($param->{start});

            # Save changes and redirect back to the manager.
            if ($used) {
                $param->{'obj'} =  $wf;
                return;
            } else {
                $wf->activate;
                $wf->save;
                $self->cache->set("__WORKFLOWS__$site_id", 0);
                $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
                log_event($type . '_save', $wf);
                $self->set_redirect('/admin/manager/workflow');
            }
        }
    }
}


# strictly speaking, this is a Manager (not a Profile) callback

sub delete : Callback {
    my $self = shift;

    my $flag = 0;
    foreach my $id (@{ mk_aref($self->value) }) {
        my $wf = $class->lookup({'id' => $id}) || next;
        if (chk_authz($wf, EDIT, 1)) {
            $wf->deactivate();
            $wf->save();
            $self->cache->set('__WORKFLOWS__' . $wf->get_site_id, 0);
            log_event("${type}_deact", $wf);
            $flag = 1;
        } else {
            $self->raise_forbidden(
                'Permission to delete "[_1]" denied.',
                $wf->get_name,
            );
        }
    }
    if ($flag) {
        $self->cache->set('__SITES__', 0);
        $self->cache->set('__WORK_FLOWS__', 0);
    }
}


1;
