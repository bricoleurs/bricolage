<%args>
$widget
$field
$param
$obj
</%args>

%#-- Once Section --#
<%once>;
my $type = 'job';
my $disp_name = get_disp_name($type);
</%once>

<%init>;
return unless $field eq "$widget|save_cb";
# Instantiate the job object and grab its name.
my $job = $obj;
my $name = "&quot;$param->{name}&quot;";

if ($param->{delete}) {
    # Deactivate it.
    $job->cancel;
    log_event('job_cancel', $job);
    $job->save;
    add_msg("$disp_name profile $name deleted.");
} else {
    $job->set_name($param->{name});
    $job->set_sched_time($param->{sched_time});
    $job->set_type($param->{type});
    $job->save;
    log_event('job_save', $job);
    add_msg("$disp_name profile $name saved.");
}
set_redirect('/admin/manager/job');
</%init>
