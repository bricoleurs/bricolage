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
              '&quot;' . $obj->get_name . '&quot;' : 'Object';
            add_msg($lang->maketext("Permission to delete [_1] denied.",$name));
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
              '&quot;' . $obj->get_name . '&quot;' : 'Object';
            add_msg($lang->maketext("Permission to delete [_1] denied.",$name));
        }
    }
#} elsif ($field eq "$widget|add_cb") {

} elsif ($field eq "$widget|sortBy_cb") {
    # Leading '-' means reverse the sort
    if ($param->{$field} =~ s/^-//) {
        set_state_data('listManager', 'sortOrder', 'reverse');
    } else {
        set_state_data('listManager', 'sortOrder', '');
    }
    set_state_data('listManager', 'sortBy', $param->{$field});
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
              '&quot;' . $obj->get_name . '&quot;' : 'Object';
            add_msg($lang->maketext("Permission to delete [_1] denied.","$method $name"));
        }
    }
}
# set offset from beginning record in @sort_objs at which array slice begins
elsif ($field eq "$widget|set_offset_cb") {
    set_state_data($widget,'pagination',1);
    set_state_data( $widget, 'offset', $param->{$field});
}
# call back to display all results
elsif ($field eq "$widget|show_all_records_cb") {
    set_state_data($widget, 'pagination', 0);
    set_state_data($widget, 'show_all', 1);
}
</%init>
