package Bric::App::Callback::Workflow;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'workflow');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $type = 'workflow';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);


sub delete : Callback {
    my $self = shift;

    my $flag = 0;
    foreach my $id (@{ mk_aref($self->value) }) {
        my $wf = $class->lookup({ id => $id }) || next;
        if (chk_authz($wf, EDIT, 1)) {
            $wf->deactivate;
            $wf->save;
            log_event("${type}_deact", $wf);
            $flag = 1;
        } else {
            my $msg = "Permission to delete [_1] denied.";
            my $name = '&quot;' . $wf->get_name . '&quot';
            add_msg($self->lang->maketext($msg, $name));
        }
    }
    if ($flag) {
        $self->cache->set('__SITES__', 0);
        $self->cache->set('__WORK_FLOWS__', 0);
    }
}


1;
