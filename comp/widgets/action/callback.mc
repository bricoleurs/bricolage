<%doc>
###############################################################################

=head1 NAME

/widgets/action/callback.mc - Action Callback to delete Actions.

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2001-11-20 00:04:05 $

=head1 SYNOPSIS

  $m->comp('/widgets/action/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Distribution Profile, where one or
more actions have been marked for deletion.

</%doc>

<%once>;
my $type = 'action';
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
    my $act = $class->lookup({ id => $id }) || next;
    $act->del;
    $act->save;
    log_event('action_del', $act);
}
return;
</%init>
