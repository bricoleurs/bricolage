package Bric::App::Callback::Profile::Action;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass(class_key => 'action');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $disp_name = get_disp_name(CLASS_KEY);
my $class = get_package_name(CLASS_KEY)
my $dest_class = get_package_name('dest');


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $act = $self->obj;

    if (!defined $param->{action_id}) {
        # This is a new action. Set the type and return.
        $act->set_type($param->{type});
        $act->set_server_type_id($param->{dest_id});
        $act->set_ord($param->{ord});
        $act->save;
        return $act if $act->has_more;
    }

    # Set the redirection.
    set_redirect("/admin/profile/dest?id=$param->{dest_id}");
    my $name = '&quot;' . $act->get_name . '&quot;';

    if ($param->{delete}) {
        # Delete it.
        $act->del;
        $act->save;
        log_event('action_del', $act);
        add_msg("$disp_name profile $name deleted.");
        return;
    }

    # Roll in the changes. Assume it's active.
    foreach my $meth ($act->my_meths(1)) {
        next if $meth->{name} eq 'type';
        $meth->{set_meth}->($act, @{$meth->{set_args}}, $param->{$meth->{name}})
          if defined $meth->{set_meth};
    }
    $act->save;
    log_event('action_' . (defined $param->{action_id} ? 'save' : 'new'), $act);
    add_msg("$disp_name profile $name saved.");
}


# strictly speaking, this is a Manager (not a Profile) callback

sub delete : Callback {
    my $self = shift;

    my $dest = $dest_class->lookup({ 'id' => $param->{'dest_id'} });
    chk_authz($dest, EDIT);
    foreach my $id (@{ mk_aref($self->value) }) {
        my $act = $class->lookup({ 'id' => $id }) || next;
        $act->del();
        $act->save();
        log_event(CLASS_KEY . '_del', $act);
    }
}



1;
