<%args>
$widget
$field
$param
$obj
</%args>

%#-- Once Section --#
<%once>;
my $type = 'output_channel';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
</%once>

<%init>;
return unless $field eq "$widget|save_cb";
# Instantiate the output channel object and grab its name.
my $oc = $obj;
my $name = "&quot;$param->{name}&quot;";
my $used;

if ($param->{delete}) {
    # Deactivate it.
    $oc->deactivate;
    log_event('output_channel_deact', $oc);
    add_msg("$disp_name profile $name deleted.");
    $oc->save;
} else {
    my $oc_id = $param->{"${type}_id"};
    # Make sure the name isn't already in use.
    my @ocs = $class->list_ids({ name => $param->{name} });
    if (@ocs > 1) { $used = 1 }
    elsif (@ocs == 1 && !defined $oc_id) { $used = 1 }
    elsif (@ocs == 1 && defined $oc_id
	   && $ocs[0] != $oc_id) { $used = 1 }
    add_msg("The name $name is already used by another $disp_name.") if $used;

    $oc->set_description( $param->{description} );
    $oc->set_pre_path( $param->{pre_path} );
    $oc->set_post_path( $param->{post_path});
    $oc->set_filename( $param->{filename});
    $oc->set_file_ext( $param->{file_ext});
    $oc->activate;
    unless ($used) {
	$oc->set_name($param->{name});
	log_event('output_channel_' .
		  ( defined $param->{output_channel_id} ? 'save' : 'new'), $oc);
	add_msg("$disp_name profile $name saved.");
	$oc->save;
    }
}
$used ? return $oc : set_redirect('/admin/manager/output_channel');
</%init>
