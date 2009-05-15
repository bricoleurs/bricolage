package Bric::App::Callback::Profile::Job;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'job';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);

my $type = CLASS_KEY;
my $disp_name = 'Job';
my $class = 'Bric::Util::Job';

sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $job = $self->obj;

    my $name = $param->{name};

    if (exists $param->{delete}) {
        $self->add_message(qq{$disp_name profile "[_1]" deleted.}, $name)
            if $self->_cancel($job);
    } else {
        $job->set_name($param->{name});
        $job->set_sched_time($param->{sched_time});
        $job->set_priority($param->{priority});
        if ($param->{reset}) {
            # Reset the job. The "delete" checkbox has been perverted for this
            # purpose.
            $job->reset;
            log_event(job_reset => $job);
            $self->add_message(qq{$disp_name "[_1]" has been reset.}, $name);
        }
        $job->save;
        log_event('job_save', $job);
        $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
    }
    $self->set_redirect('/admin/manager/job');
}


# strictly speaking, this is a Manager (not a Profile) callback

sub cancel : Callback {
    my $self = shift;

    foreach my $id (@{ mk_aref($self->value) }) {
        my $job = $class->lookup({ id => $id }) || next;
        if (chk_authz($job, EDIT)) {
            $self->_cancel($job);
        } else {
            $self->raise_forbidden(
                'Permission to delete "[_1]" denied.',
                $job->get_name
            );
        }
    }
}

sub _cancel {
    my ($self, $job) = @_;
    if ($job->is_executing) {
        # It's executing right now. Don't cancel it.
        $self->raise_conflict(
            'Cannot cancel "[_1]" because it is currently executing.',
            $job->get_name,
        );
        return;
    }

    # Cancel it.
    $job->cancel;
    $job->save;
    log_event('job_cancel', $job);
    return $self;
}


1;
