<%args>
$widget
$field
$param
</%args>

<%perl>

my ($section, $mode, $type) = $m->comp("/lib/util/parseUri.mc");

# What class is this object?
my $class = "Bric::Biz::ATType";

# Instantiate the object.
my $obj;
if ($param->{id} ne "add" && $param->{id} ne '') {
    $obj = $class->lookup({ id => $param->{id} })
} else {
    $obj = $class->new();
}

if ( $field eq "$widget:save_and_exit_cb" || $field eq "$widget:save_and_return_cb" ) {

    # save name and description 
    $obj->set_name($param->{name}) if ($param->{name});
    $obj->set_description( $param->{description} ) if ($param->{description});
    $obj->set_top_level( ($param->{top_level}) ? 1 : 0);
    $obj->set_paginated( ($param->{paginated}) ? 1 : 0);
    ($param->{delete}) ? $obj->deactivate : $obj->activate;
    $obj->save;
    $param->{id} = $obj->get_id;
    if ($field eq "$widget:save_and_exit_cb") {
	set_redirect('/admin/manager/container_type');
    }
}
</%perl>

