<%doc>
###############################################################################

=head1 NAME

/widgets/workflow/callback.mc - Workflow Callback to delete Workflows.

=head1 VERSION

$Revision$

=head1 DATE

$Date$

=head1 SYNOPSIS

  $m->comp('/widgets/workflow/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Workflow Manager, where one or more
Workflows have been marked for deletion.

=cut

</%doc>

<%once>;
my $type = 'workflow';
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
my $flag;
foreach my $id (@{ mk_aref($param->{$field}) }) {
    my $wf = $class->lookup({ id => $id }) || next;
    if (chk_authz($wf, EDIT, 1)) {
	$wf->deactivate;
	$wf->save;
	log_event("${type}_deact", $wf);
	$flag = 1;
    } else {
	my $name = '&quot;' . $wf->get_name . '&quot;';
        add_msg($lang->maketext("Permission to delete [_1] denied.",$name));
    }
}
if ($flag) {
    $c->set('__SITES__', 0);
    $c->set('__WORK_FLOWS__', 0);
}
return;
</%init>
