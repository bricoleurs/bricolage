<%args>
$widget
$field
$param
</%args>

<%init>
if ($field eq "$widget|delete_cb") {
#    my $id  = ref $param->{$field} ? $param->{$field} : [$param->{$field}];
    my $id  = mk_aref($param->{$field});
    my $pkg = get_state_data($widget, 'pkg_name');
    my $obj_key = get_state_data($widget, 'object');

    foreach (@$id) {
        my $obj = $pkg->lookup({'id' => $_});
	if (chk_authz($obj, EDIT, 1)) {
	    $obj->delete;
	    $obj->save;
	    log_event($obj_key.'_del', $obj);
	} else {
	    my $name = defined($obj->get_name) ?
	      '&quot;' . $obj->get_name . '&quot' : 'Object';
	    add_msg("Permission to delete $name denied.");
	}
    }
} elsif ($field eq "$widget|deactivate_cb") {
    my $id  = mk_aref($param->{$field});
    my $pkg     = get_state_data($widget, 'pkg_name');
    my $obj_key = get_state_data($widget, 'object');

    foreach (@$id) {
        my $obj = $pkg->lookup({'id' => $_});
	if (chk_authz($obj, EDIT, 1)) {
	    $obj->deactivate;
	    $obj->save;
	    log_event($obj_key.'_deact', $obj);
	} else {
	    my $name = defined($obj->get_name) ?
	      '&quot;' . $obj->get_name . '&quot' : 'Object';
	    add_msg("Permission to delete $name denied.");
	}
    }
#} elsif ($field eq "$widget|add_cb") {

} elsif ($field eq "$widget|sortBy_cb") {
    set_state_data('listManager', 'sortBy', $param->{$field});
} elsif ( $field eq "$widget|start_page_cb" ) {
    # ensure paging is turned on
    set_state_data( $widget, 'multiple_pages', 1 );

    # set the page of results to be displayed to the passed value
    set_state_data( $widget, 'start_page', $param->{ $field } );
}
# Try to match a custom select action.
elsif ($field =~ /$widget\|select-(.+)_cb/) {
    my $method = $1;
    my $id      = ref $param->{$field} ? $param->{$field} : [$param->{$field}];
    my $pkg = get_state_data($widget, 'pkg_name');

    foreach (@$id) {
        my $obj = $pkg->lookup({'id' => $_});
	if (chk_authz($obj, EDIT, 1)) {
	    $obj->$method;
	    $obj->save;
	} else {
	    my $name = defined($obj->get_name) ?
	      '&quot;' . $obj->get_name . '&quot' : 'Object';
	    add_msg("Permission to $method $name denied.");
	}
    }
} elsif( $field eq "$widget|show_all_listings_cb" ) {
    # turn off paging
    set_state_data( $widget, 'multiple_pages', 0 );
}

</%init>
