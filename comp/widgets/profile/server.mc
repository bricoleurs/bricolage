<%doc>
###############################################################################

=head1 NAME

/widgets/profile/servers.mc - Processes submits from Server Profile.

=head1 VERSION

$Revision: 1.6 $

=head1 DATE

$Date: 2003/02/12 15:53:36 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/servers.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Servers Profile page.

</%doc>

<%args>
$widget
$param
$field
$obj
</%args>
<%once>;
my $type = 'server';
my $disp_name = get_disp_name($type);
my $dest_name = get_disp_name('dest');
my $class = get_package_name($type);
</%once>
<%init>;
return unless $field eq "$widget|save_cb";
# Instantiate the server object and grab its name.
my $s = $obj;
my $name = "&quot;$param->{host_name}&quot;";

if ($param->{delete}) {
    # Delete it.
    $s->del;
    $s->save;
    log_event('server_del', $s);
    add_msg($lang->maketext("$disp_name profile [_1] deleted.",$name));
    # Set the redirection.
    set_redirect("/admin/profile/dest/$param->{dest_id}");
    return;
}

my $dest_id = $param->{"${type}_id"};
# Make sure the name isn't already in use.
my $used;
my @dests = $class->list_ids({ host_name => $param->{host_name},
			       server_type_id => $param->{dest_id} });
if (@dests > 1) { $used = 1 }
elsif (@dests == 1 && !defined $dest_id) { $used = 1 }
elsif (@dests == 1 && defined $dest_id
       && $dests[0] != $dest_id) { $used = 1 }
add_msg($lang->maketext("The name [_1] is already used by another $disp_name in this"
	. " $dest_name."),$name) if $used;

# Roll in the changes.
if (exists $param->{active}) {
    unless ($s->is_active) {
        $s->activate;
        log_event('server_act', $s);
    }
} else {
    $s->deactivate;
    log_event('server_deact', $s);
}

$s->set_server_type_id($param->{dest_id});
$s->set_os($param->{os});
$s->set_doc_root($param->{doc_root});
$s->set_login($param->{login});
$s->set_password($param->{password}) if $param->{password};
$s->set_cookie($param->{cookie});
if ($used) {
    return $s;
} else {
    $s->set_host_name($param->{host_name});
    $s->save;
    log_event($type . (defined $param->{server_id} ? '_save' : '_new'), $s);
    add_msg($lang->maketext("$disp_name profile [_1] saved.",$name));
    # Set the redirection.
    set_redirect("/admin/profile/dest/$param->{dest_id}");
}
</%init>
