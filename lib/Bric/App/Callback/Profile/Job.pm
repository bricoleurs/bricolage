package Bric::App::Callback::Profile::Job;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass('class_key' => 'job');
use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $job = $self->obj;

    my $name = "&quot;$param->{name}&quot;";

    if ($param->{delete}) {
        # Deactivate it.
        $job->cancel;
        log_event('job_cancel', $job);
        $job->save;
        add_msg("$disp_name profile $name deleted.");
    } else {
        $job->set_name($param->{name});
        $job->set_sched_time($param->{sched_time});
        $job->set_type($param->{type});
        $job->save;
        log_event('job_save', $job);
        add_msg("$disp_name profile $name saved.");
    }
    set_redirect('/admin/manager/job');
}


1;
