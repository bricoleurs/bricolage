package Bric::App::Callback::AlertType;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'alert_type');
use strict;
use Bric::App::Authz;
use Bric::App::Event;
use Bric::App::Session;
use Bric::App::Util;
use Bric::Util::Language;
use Bric::Util::Priv::Parts::Const qw(EDIT);

my $disp_name = get_disp_name(CLASS_KEY);
my $class = get_package_name(CLASS_KEY);

sub delete : Callback {
    my $self = shift;
    my ($param, $field) = @{ $self->request_args }['param', 'field'];

    foreach my $id (@{ mk_aref($param->{$field}) }) {
        my $at = $class->lookup({ id => $id }) || next;
        if (chk_authz($at, EDIT, 1)) {
            $at->remove();
            $at->save();
            log_event(CLASS_KEY . '_del', $at);
        } else {
            my $lang = Bric::Util::Language->get_handle(LANGUAGE);
            my $name = '&quot;' . $at->get_name() . '&quot';
            add_msg($lang->maketext("Permission to delete [_1] denied.", $name));
        }
    }
}


1;
