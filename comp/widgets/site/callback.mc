<%doc>
###############################################################################

=head1 NAME

/widgets/site/callback.mc - Site Callback to delete Sites.

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2003-03-12 08:59:53 $

=head1 SYNOPSIS

  $m->comp('/widgets/site/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Site Manager, where one or more
Sites have been marked for deletion.

=cut

</%doc>

<%once>;
my $type = 'site';
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
    my $site = $class->lookup({ id => $id }) || next;
    if (chk_authz($site, EDIT, 1)) {
	$site->deactivate;
	$site->save;
        $c->set_lmu_time;
	log_event("${type}_deact", $site);
	$flag = 1;
    } else {
	my $name = '&quot;' . $site->get_name . '&quot';
        add_msg($lang->maketext("Permission to delete [_1] denied.", $name));
    }
}
if ($flag) {
    $c->set('__SITES__', 0);
    $c->set('__WORK_FLOWS__', 0);
}
return;
</%init>
