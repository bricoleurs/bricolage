package Bric::App::Callback::Profile::Dest;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass('class_key' => 'dest');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Biz::OutputChannel;
use Bric::Dist::ServerType;

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $dest = $self->obj;

    my $name = "&quot;$param->{name}&quot;";

    if ($param->{delete}) {
        # Dissociate output channels.
        $dest->del_output_channels;
        # Deactivate the destination.
        $dest->deactivate;
        $dest->save;
        log_event('dest_deact', $dest);
        add_msg($self->lang->maketext("$disp_name profile [_1] deleted.",$name));
        # Set the redirection.
        set_redirect("/admin/manager/dest");
        return;
    }
    my $dest_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my $used;
    my @dests = $class->list_ids({ name => $param->{name},
                                   site_id => $dest->get_site_id });
    if (@dests > 1) {
        $used = 1;
    } elsif (@dests == 1 && !defined $dest_id) {
        $used = 1;
    } elsif (@dests == 1 && defined $dest_id
       && $dests[0] != $dest_id) {
        $used = 1;
    }
    add_msg($self->lang->maketext("The name [_1] is already used by another [_2].",
                            $name, $disp_name))
      if $used;

    # If they're editing it, assume it's active.
    $param->{active} = 1;

    # Set booleans to true if they're present
    foreach (qw(publish copy preview)) {
        $param->{$_} = 1 if exists $param->{$_};
    }

    # Roll in the changes.
    foreach my $meth ($dest->my_meths(1)) {
        if ($meth->{name} eq 'name') {
            $meth->{set_meth}->($dest, @{$meth->{set_args}}, $param->{$meth->{name}})
              unless $used
          } else {
              $meth->{set_meth}->($dest, @{$meth->{set_args}}, $param->{$meth->{name}})
                if defined $meth->{set_meth};
          }
    }

    # Add any new output channels.
    if ($param->{add_oc}) {
        my @add = map { Bric::Biz::OutputChannel->lookup({ id => $_ }) }
          @{ mk_aref($param->{add_oc}) };
        $dest->add_output_channels(@add);
    }

    # Remove output channels.
    if ($param->{rem_oc}) {
        my @add = map { Bric::Biz::OutputChannel->lookup({ id => $_ }) }
          @{ mk_aref($param->{rem_oc}) };
        $dest->del_output_channels(@add);
    }

    if ($used) {
        return $dest;
    } else {
        # Save it!
        $dest->save;
        if (defined $dest_id) {
            log_event('dest_' . (defined $param->{dest_id} ? 'save' : 'new'), $dest);
            # Send a message to the browser.
            add_msg($self->lang->maketext("$disp_name profile [_1] saved.",$name));
            # Set the redirection.
            set_redirect("/admin/manager/dest");
        } else {
            # It's a new destination. Let them add Actions and Servers.
            return $dest;
        }
    }
}


# strictly speaking, this is a Manager (not a Profile) callback

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
