<%doc>
###############################################################################

=head1 NAME

/widgets/server/callback.mc - Server Callback to delete Servers.

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2001/12/04 18:17:41 $

=head1 SYNOPSIS

  $m->comp('/widgets/servers/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Distribution Profile, where one or
more servers have been marked for deletion.

</%doc>

<%once>;
my $type = 'server';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
my $dest_class = get_package_name('dest');
</%once>

<%args>
$widget
$field
$param
</%args>

<%init>;
return unless $field eq "$widget|delete_cb";
my $dest = $dest_class->lookup({ id => $param->{dest_id} });
chk_authz($dest, EDIT);
foreach my $id (@{ mk_aref($param->{$field}) }) {
    my $s = $class->lookup({ id => $id }) || next;
    $s->del;
    $s->save;
    log_event('server_del', $s);
}
return;
</%init>
