<%args>
$widget
$field
$param
</%args>

<%perl>

print STDERR "Handling field $field.\n";
#print STDERR "ARGS = ", Data::Dumper::Dumper(\%ARGS), "\n\n";

my ($section, $mode, $type) = $m->comp("/lib/util/parseUri.mc");

# What class is this object?
my $class = "Bric::Biz::AssetType";

# Instantiate the object.
my $obj;
if ($param->{id} ne "add" && $param->{id} ne '') {
	$obj = $class->lookup({ id => $param->{id} })
} else {
	$obj = get_state_data('admin_container_profile', 'cur_obj');
	print STDERR "obj = ", Data::Dumper::Dumper(\$obj), "\n\n";
	if (!$obj) {	
		$obj = $class->new();
	}
}

# take actions based on callback...
if ($field eq "$widget:save_form_builder_cb" ) {

	# create new data object on current asset type
	# set data object name = name field from form builder
	
	print STDERR "Saving or modifying attribute ... \n";
	
	my $dataObj = $obj->get_data( $param->{name} );
	
	if (!$dataObj) {
		print STDERR "new data\n";
		$dataObj = $obj->new_data({ name => $param->{name} });
	} else {
		print STDERR "modifying existing data point";
		#$obj->del_data( $dataObj );
		#$dataObj = $obj->new_data({ name => $param->{name} });
	}

	# add new attr to data object
	$dataObj->set_attr($param->{name}, $param->{name});
	print STDERR "done setting attr as $param->{name} \n";
	print STDERR "$widget:$field \n";
	# set meta data on the html_info attribute
	foreach my $k (keys %$param) {
		next if ($k eq 'name' || $k eq $field) ;
		$dataObj->set_meta( $param->{name}, $k, $param->{$k} );
		print STDERR "new meta key: $k value: " . $param->{$k} . "\n";
	}
	
} 


if ($field eq "$widget:add_attr_cb" || $field eq "$widget:save_cb") {

	# save name and description 
	print STDERR "$field ... saving... name and description\n";
	$obj->set_name($param->{name});
	$obj->set_description($param->{description});
	# TODO: save mods to any data fields
}

# save it to db and session
$obj->save;
set_state_data('admin_container_profile', 'cur_obj', $obj);
	
# now that that's over, set the id
$param->{id} = $obj->get_id;
print STDERR $obj->get_attr($param->{name});
# set widget state
if ($field eq "$widget:save_cb" ) { # save returns to manager, so clear the profile state
	$obj->activate;
	set_state_data('admin_container_profile', 'cur_state', 'edit');
	set_state_data('admin_container_profile', 'cur_obj', '');
	# uhh, redirect....
} elsif ($field eq "$widget:add_attr_cb" && !$param->{cancelField}) {
	set_state_data('admin_container_profile', 'cur_state', 'form_builder');
} else {
	set_state_data('admin_container_profile', 'cur_state', 'edit');
}
</%perl>

