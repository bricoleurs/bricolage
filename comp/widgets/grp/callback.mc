<%doc>
###############################################################################

=head1 NAME

/widgets/grp/callback.mc - Grp Callback to delete Groups.

=head1 VERSION

$Revision: 1.4 $

=head1 DATE

$Date: 2001-11-29 00:28:51 $

=head1 SYNOPSIS

  $m->comp('/widgets/grp/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Group Manager, where one or more
groups have been marked for deletion.

</%doc>

<%once>;
my $type = 'grp';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
</%once>

<%args>
$widget
$field
$param
</%args>

<%init>;
return unless $field eq "$widget|deactivate_cb";
foreach my $id (@{ mk_aref($param->{$field}) }) {
    my $grp = $class->lookup({ id => $id }) || next;
        if (chk_authz($grp, EDIT)) {
	    if ($grp->get_permanent) {
		# Dissallow deletion of permanent groups.
		add_msg("$disp_name cannot be deleted");
	    } else {
		# Deactivate it.
		$grp->deactivate;
		$grp->save;
		log_event('grp_deact', $grp);
		# Note that a user has been updated to force all users logged into the system
		# to reload their user objects from the database.
	    $c->set_lmu_time if $grp->isa('Bric::Util::Grp::User');
	    }
	    $grp->save;
	    log_event('grp_deact', $grp);
	} else {
	    add_msg("Permission to delete &quot;" . $grp->get_name . "&quot; denied.");
	}
}
return;
</%init>
