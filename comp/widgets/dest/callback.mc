<%doc>
###############################################################################

=head1 NAME

/widgets/dest/callback.mc - Destination Callback to delete Destinations.

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2003-07-25 04:39:15 $

=head1 SYNOPSIS

  $m->comp('/widgets/dest/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Destination Manager, where one or more
Destinations have been marked for deletion.

</%doc>

<%once>;
my $type = 'dest';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
</%once>

<%args>
$widget
$field
$param
</%args>

<%init>;
return unless $field eq "$widget|delete_cb";
foreach my $id (@{ mk_aref($param->{$field}) }) {
    my $dest = $class->lookup({ id => $id }) || next;
    if (chk_authz($dest, EDIT, 1)) {
        $dest->del_output_channels;
	$dest->deactivate;
	$dest->save;
	log_event("${type}_deact", $dest);
    } else {
	my $name = '&quot;' . $dest->get_name . '&quot;';
        add_msg($lang->maketext("Permission to delete [_1] denied.",$name));
    }
}
return;
</%init>
