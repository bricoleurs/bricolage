package Bric::App::Callback::Job;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'job');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $type = 'job';
my $class = get_package_name($type);


sub cancel : Callback {
    my $self = shift;

    foreach my $id (@{ mk_aref($self->param_value) }) {
        my $job = $class->lookup({ id => $id }) || next;
        if (chk_authz($job, EDIT)) {
            if ($job->is_pending) {
                # It's executing right now. Don't cancel it.
                my $msg = "Cannot cancel [_1] because it is currently executing.";
                add_msg($self->lang->maketext($msg, '&quot;' . $job->get_name . '&quot;'));
            } else {
                # Cancel it.
                $job->cancel;
                $job->save;
                log_event('job_cancel', $job);
            }
        } else {
            my $msg = "Permission to delete [_1] denied.";
            add_msg($self->lang->maketext($msg, '&quot;' . $job->get_name . '&quot;'));
        }
    }

}


1;
