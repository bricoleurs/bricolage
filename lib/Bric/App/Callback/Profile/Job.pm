package Bric::App::Callback::Profile::Job;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'job';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $job = $self->obj;

    my $name = $param->{name};

    if ($param->{delete}) {
        # Deactivate it.
        $job->cancel;
        log_event('job_cancel', $job);
        $job->save;
        add_msg("$disp_name profile \"[_1]\" deleted.", $name);
    } else {
        $job->set_name($param->{name});
        $job->set_sched_time($param->{sched_time});
        $job->set_type($param->{type});
        $job->save;
        log_event('job_save', $job);
        add_msg("$disp_name profile \"[_1]\" saved.", $name);
    }
    set_redirect('/admin/manager/job');
}


# strictly speaking, this is a Manager (not a Profile) callback

sub cancel : Callback {
    my $self = shift;

    foreach my $id (@{ mk_aref($self->value) }) {
        my $job = $class->lookup({'id' => $id}) || next;
        if (chk_authz($job, EDIT)) {
            if ($job->is_pending) {
                # It's executing right now. Don't cancel it.
                add_msg('Cannot cancel "[_1]" because it is currently executing.', $job->get_name);
            } else {
                # Cancel it.
                $job->cancel();
                $job->save();
                log_event('job_cancel', $job);
            }
        } else {
            add_msg('Permission to delete "[_1]" denied.', $job->get_name);
        }
    }
}


1;
