package Bric::App::Callback::Profile::Dest;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'dest';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
use Bric::Biz::OutputChannel;
use Bric::Dist::ServerType;

my $type = CLASS_KEY;
my $disp_name = 'Destination';
my $class = 'Bric::Dist::ServerType';


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $dest = $self->obj;

    my $name = $param->{name};

    if ($param->{delete}) {
        # Dissociate output channels.
        $dest->del_output_channels;
        # Deactivate the destination.
        $dest->deactivate;
        $dest->save;
        log_event('dest_deact', $dest);
        $self->add_message("$disp_name profile \"[_1]\" deleted.", $name);
        # Set the redirection.
        $self->set_redirect("/admin/manager/dest");
        return;
    }
    my $dest_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my $used;
    my @dests = $class->list_ids({ name    => $param->{name},
                                   site_id => $param->{site_id}
                                              || $dest->get_site_id });
    if (@dests > 1) {
        $used = 1;
    } elsif (@dests == 1 && !defined $dest_id) {
        $used = 1;
    } elsif (@dests == 1 && defined $dest_id
       && $dests[0] != $dest_id) {
        $used = 1;
    }
    $self->raise_conflict(
        qq{The name "[_1]" is already used by another $disp_name.},
        $name,
    ) if $used;

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
        $param->{'obj'} = $dest;
        return;
    } else {
        # Save it!
        $dest->save;
        if (defined $dest_id) {
            log_event('dest_' . (defined $param->{dest_id} ? 'save' : 'new'), $dest);
            # Send a message to the browser.
            $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
            # Set the redirection.
            $self->set_redirect("/admin/manager/dest");
        } else {
            # It's a new destination. Let them add Actions and Servers.
            $param->{'obj'} = $dest;
            return;
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
            $self->raise_forbidden(
                'Permission to delete "[_1]" denied.',
                $dest->get_name,
            );
        }
    }
}


1;
