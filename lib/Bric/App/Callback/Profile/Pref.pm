package Bric::App::Callback::Profile::Pref;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass(class_key => 'pref');
use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $disp_name = get_disp_name(CLASS_KEY);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $pref = $self->obj;

    my $name = $pref->get_name;
    $pref->set_value($param->{value});
    $pref->save;
    log_event('pref_save', $pref);
    add_msg($self->lang->maketext("$disp_name [_1] updated.","&quot;$name&quot;"));
    set_redirect('/admin/manager/pref');
}


1;
