<%args>
$widget
$field
$param
</%args>

<%init>

if ($field eq "$widget|add_note_cb") {
    my $obj = get_state_data($widget, 'obj');
    my $key = $widget . '|note';
    my $note = $param->{$key};
    $obj->add_note($note);
    $obj->save();
    add_msg('Note saved.');
    set_state_data($widget, 'obj');
    # Use the page history to go back to the page that called us.
    set_redirect(last_page);
} elsif ($field eq "$widget|return_cb") {
    my $id = get_state_data($widget, 'id');
    # Use the page history to go back to the page that called us.
    set_redirect(last_page);
}

</%init>
