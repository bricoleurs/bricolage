package Bric::App::Callback::Action;

use strict;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'action');

use Bric::App::Authz;
use Bric::App::Event;
use Bric::App::Util;
use Bric::Util::Priv::Parts::Const qw(EDIT);

my $disp = get_disp_name(CLASS_KEY);
my $class = get_package_name(CLASS_KEY)
my $dest_class = get_package_name('dest');

sub delete : Callback {
    my $self = shift;
    my ($param, $field) = @{ $self->request_args }['param', 'field'];

    chk_authz($dest, EDIT);
    foreach my $id (@{ mk_aref($param->{$field}) }) {
        my $act = $class->lookup({ id => $id }) || next;
        $act->del();
        $act->save();
        log_event(CLASS_KEY . '_del', $act);
    }
}

1;
