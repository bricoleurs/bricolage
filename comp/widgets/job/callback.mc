<%doc>
###############################################################################

=head1 NAME

/widgets/job/callback.mc - Job Callback to Cancel Jobs.

=head1 VERSION

$Revision: 1.6 $

=head1 DATE

$Date: 2003/02/12 15:53:19 $

=head1 SYNOPSIS

  $m->comp('/widgets/job/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Job Manager, where one or more
jobs have been marked for cancellation.

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
            add_msg($lang->maketext("Cannot cancel [_1] because it is currently executing.","&quot;" . $job->get_name . "&quot;"));
	} else {
	    # Cancel it.
	    $job->cancel;
	    $job->save;
	    log_event('job_cancel', $job);
	}
    } else {
        add_msg($lang->maketext("Permission to delete [_1] denied.", "&quot;" . $job->get_name . "&quot;"));
    }
}
return;
</%init>
