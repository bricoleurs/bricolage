package Bric::App::Callback::Grp;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'grp');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Cache;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);


my $type = 'grp';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
my $c = Bric::App::Cache->new();   # singleton


sub deactivate : Callback {
    my $self = shift;

    foreach my $id (@{ mk_aref($self->param_value) }) {
        my $grp = $class->lookup({ id => $id }) || next;
        if (chk_authz($grp, EDIT)) {
            if ($grp->get_permanent) {
                # Disallow deletion of permanent groups.
                add_msg($self->lang->maketext("[_1] cannot be deleted", $disp_name));
            } else {
                # Deactivate it.
                $grp->deactivate;
                $grp->save;
                log_event('grp_deact', $grp);
                # Note that a user has been updated to force all
                # users logged into the system to reload their
                # user objects from the database.
                $c->set_lmu_time if $grp->isa('Bric::Util::Grp::User');
            }
            $grp->save;
            log_event('grp_deact', $grp);
        } else {
            my $msg = 'Permission to delete [_1] denied.';
            add_msg($self->lang->maketext($msg, '&quot;' . $grp->get_name . '&quot;'));
        }
    }
}

1;
