package Bric::App::Callback::Dest;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'dest');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $type = 'dest';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);

sub delete : Callback {
    my $self = shift;

    foreach my $id (@{ mk_aref($self->value) }) {
        my $dest = $class->lookup({ id => $id }) || next;
        if (chk_authz($dest, EDIT, 1)) {
            $dest->del_output_channels;
            $dest->deactivate;
            $dest->save;
            log_event("${type}_deact", $dest);
        } else {
            my $name = '&quot;' . $dest->get_name . '&quot';
            my $msg = "Permission to delete [_1] denied.";
            add_msg($self->lang->maketext($msg, $name));
        }
    }
}


1;
