package Bric::App::Callback::Profile::Action;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'action';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref :msg);
use Bric::Util::Fault qw(rethrow_exception);

my $disp_name = 'Action';
my $class = 'Bric::Dist::Action';
my $dest_class = 'Bric::Dist::ServerType';


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $act = $self->obj;

    if (!defined $param->{action_id}) {
        # This is a new action. Set the type and return.
        $act->set_type($param->{type});
        $act->set_server_type_id($param->{dest_id});
        $act->set_ord($param->{ord});

        unless ($param->{save_it} or not $act->has_more) {
            $param->{'obj'} = $act;
            return;
        }
    }

    # Set the redirection.
    my $name = $act->get_name;

    if ($param->{delete}) {
        # Delete it.
        $act->del;
        $act->save;
        log_event('action_del', $act);
        add_msg("$disp_name profile \"[_1]\" deleted.", $name);
        $self->set_redirect("/admin/profile/dest?id=$param->{dest_id}");
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
    $self->set_redirect("/admin/profile/dest?id=$param->{dest_id}");

    $param->{'obj'} = $act;
    return;
}


# strictly speaking, this is a Manager (not a Profile) callback

sub delete : Callback {
    my $self = shift;
    my $param = $self->params;

    my $dest = $dest_class->lookup({ 'id' => $param->{'dest_id'} });
    chk_authz($dest, EDIT);
    foreach my $id (@{ mk_aref($self->value) }) {
        my $act = $class->lookup({ 'id' => $id }) || next;
        $act->del();
        $act->save();
        log_event($self->class_key . '_del', $act);
    }
}



1;
