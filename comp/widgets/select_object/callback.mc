<%args>
$widget
$field
$param
</%args>

<%init>

my ($object) = $field =~ /\|([^-]+)-/;
my $sub_widget = "$widget.$object";

if ($field eq "$widget|$object-selected_id_cb") {
    # Handle auto-repopulation of this form.
    my $name = get_state_data($sub_widget, 'form_name');

    # Save the selected ID if it's a single value.
    set_state_data($sub_widget, 'selected_id', $param->{$name})
      unless ref $param->{$name};
}
elsif ($field eq $widget.'|clear_cb') {
    my $trigger = $param->{$field};

    # If the trigger field was submitted with a true value then, clear state!
    if ($param->{$trigger}) {
	my $s = Bric::App::Session->instance;

	# Find all the select_object widget information
	my @sel = grep(substr($_,0,13) eq 'select_object', keys %$s);

	# Clear out all the state data.
	foreach my $sub_widget (@sel) {
	    set_state_data($sub_widget, {});
	}
    }
}

</%init>
