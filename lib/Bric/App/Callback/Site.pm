package Bric::App::Callback::Site;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'site');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $type = 'site';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);


sub delete : Callback {
    my $self = shift;
    my $c = $self->cache;

    my $flag;
    foreach my $id (@{ mk_aref($self->value) }) {
        my $site = $class->lookup({ id => $id }) || next;
        if (chk_authz($site, EDIT, 1)) {
            $site->deactivate;
            $site->save;
            $c->set_lmu_time;
            log_event("${type}_deact", $site);
            $flag = 1;
        } else {
            my $name = '&quot;' . $site->get_name . '&quot';
            my $msg = "Permission to delete [_1] denied.";
            add_msg($self->lang->maketext($msg, $name));
        }
    }
    if ($flag) {
        $c->set('__SITES__', 0);
        $c->set('__WORK_FLOWS__', 0);
    }
}


1;
