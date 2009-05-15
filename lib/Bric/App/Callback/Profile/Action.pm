package Bric::App::Callback::Profile::Action;

=head1 Name

Bric::App::Callback::Profile::Action - Action callback class.

=head1 Synopsis

  use Bric::App::Callback::Profile::Action;

=head1 Description

This class contains the callbacks for the distribution action profile in the
Bricolage UI.

=cut

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'action';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
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

    my $name = $act->get_name;

    if ($param->{delete}) {
        # Delete it.
        $act->del;
        $act->save;
        log_event('action_del', $act);
        $self->add_message("$disp_name profile \"[_1]\" deleted.", $name);
        $self->set_redirect("/admin/profile/dest/?id=$param->{dest_id}");
        return;
    }

    # Roll in the changes. Assume it's active.
    $param->{obj} = $act;
    foreach my $meth ($act->my_meths(1)) {
        next if $meth->{name} eq 'type' || ! defined $param->{$meth->{name}};
        $meth->{set_meth}->($act, @{$meth->{set_args}}, $param->{$meth->{name}})
          if defined $meth->{set_meth};
    }
    $act->save;
    log_event('action_' . (defined $param->{action_id} ? 'save' : 'new'), $act);
    $self->add_message("$disp_name profile $name saved.");
    $self->set_redirect("/admin/profile/dest/?id=$param->{dest_id}");

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
__END__

=head1 Author

Scott Lanning <lannings@who.int>

=head1 See Also

=over 4

=item L<Bric::App::Callback::Profile|Bric::App::Callback::Profile>

The Bricolage profile callback base class, from which
Bric::App::Callback::Profile::Action inherits.

=item L<Bric::App::Callback|Bric::App::Callback>

The Bricolage base callback class, from which Bric::App::Callback::Profile
inherits.

=back

=head1 Copyright and License

Copyright (c) 2003-2004 World Health Organization and Kineticode, Inc. See
L<Bric::License|Bric::License> for complete license terms and conditions.

=cut
