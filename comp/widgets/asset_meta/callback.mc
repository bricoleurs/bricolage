<%once>;
my %types = ('Bric::Biz::Asset::Formatting' => ['tmpl_prof', 'fa'],
	     'Bric::Biz::Asset::Business::Story' => ['story_prof', 'story'],
	     'Bric::Biz::Asset::Business::Media' => ['media_prof', 'media']);
</%once>
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
#    $obj->save();
    add_msg('Note saved.');
    set_state_data($widget, 'obj');

    # Cache the object in the session if it's the current object.
    my @state_vals = @{ $types{ ref $obj } };
    if ( my $c_obj = get_state_data(@state_vals) ) {
        my $cid = $c_obj->get_id;
        my $id = $obj->get_id;
        set_state_data(@state_vals, $obj)
          if (!defined $cid && ! defined $id) ||
          (defined $cid && defined $id && $id == $cid);
    }
    # Use the page history to go back to the page that called us.
    set_redirect(last_page);
} elsif ($field eq "$widget|return_cb") {
    my $id = get_state_data($widget, 'id');
    # Use the page history to go back to the page that called us.
    set_redirect(last_page);
}

</%init>
