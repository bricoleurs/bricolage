<%doc>
###############################################################################

=head1 NAME

/widgets/profile/actions.mc - Processes submits from Action Profile.

=head1 VERSION

$Revision: 1.6 $

=head1 DATE

$Date: 2003-07-10 09:27:46 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/actions.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Actions Profile page.

=cut

</%doc>

<%args>
$widget
$param
$field
$obj
</%args>
<%once>;
my $type = 'action';
my $disp_name = get_disp_name($type);
</%once>
<%init>;
return unless $field eq "$widget|save_cb";
# Grab the action object.
my $act = $obj;

my $ret = eval {
    if (!defined $param->{action_id}) {
        # This is a new action. Set the type and return.
        $act->set_type($param->{type});
        $act->set_server_type_id($param->{dest_id});
        $act->set_ord($param->{ord});
        return $act unless $param->{save_it} or not $act->has_more;
    }

    # Set the redirection.
    my $name = '&quot;' . $act->get_name . '&quot;';

    if ($param->{delete}) {
        # Delete it.
        $act->del;
        $act->save;
        log_event('action_del', $act);
        add_msg("$disp_name profile $name deleted.");
        set_redirect("/admin/profile/dest?id=$param->{dest_id}");
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
    set_redirect("/admin/profile/dest?id=$param->{dest_id}");
};

my $err = $@ or return $ret;
# Catch Error exctpions and turn them into error messages.
die $err unless isa_bric_exception($err, 'Error');
add_msg($lang->maketext($err->maketext));
return $act;

</%init>
