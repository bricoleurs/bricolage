<%doc>
###############################################################################

=head1 NAME

/widgets/job/callback.mc - Job Callback to Cancel Jobs.

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:09 $

=head1 SYNOPSIS

  $m->comp('/widgets/job/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Job Manager, where one or more
jobs have been marked for cancellation.

=head1 REVISION HISTORY

$Log: callback.mc,v $
Revision 1.1  2001-09-06 21:52:09  wheeler
Initial revision

</%doc>

<%once>;
my $type = 'job';
my $class = get_package_name($type);
</%once>

<%args>
$widget
$field
$param
</%args>

<%init>;
return unless $field eq "$widget|cancel_cb";
foreach my $id (@{ mk_aref($param->{$field}) }) {
    my $job = $class->lookup({ id => $id }) || next;
    if (chk_authz($job, EDIT)) {
	if ($job->is_pending) {
	    # It's executing right now. Don't cancel it.
	    add_msg("Cannot cancel &quot;" . $job->get_name . "&quot; because"
		    . " it is currently executing.");
	} else {
	    # Cancel it.
	    $job->cancel;
	    $job->save;
	    log_event('job_cancel', $job);
	}
    } else {
	add_msg("Permission to delete &quot;" . $job->get_name . "&quot; denied");
    }
}
return;
</%init>
