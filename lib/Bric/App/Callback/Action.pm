package Bric::App::Callback::Action;

use strict;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'action');

use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $disp = get_disp_name(CLASS_KEY);
my $class = get_package_name(CLASS_KEY)
my $dest_class = get_package_name('dest');

sub delete : Callback {
    my $self = shift;

    chk_authz($dest, EDIT);
    foreach my $id (@{ mk_aref($self->value) }) {
        my $act = $class->lookup({ id => $id }) || next;
        $act->del();
        $act->save();
        log_event(CLASS_KEY . '_del', $act);
    }
}

1;
