package Bric::App::Callback::Workflow;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'workflow');
use strict;

my $type = 'workflow';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);


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
	my $name = '&quot;' . $wf->get_name . '&quot';
        add_msg($lang->maketext("Permission to delete [_1] denied.",$name));
    }
}
if ($flag) {
    $c->set('__SITES__', 0);
    $c->set('__WORK_FLOWS__', 0);
}


1;
