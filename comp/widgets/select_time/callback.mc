<%args>
$widget
$field
$param
</%args>

<%once>
my $is_clear_state = sub {
    my ($param) = @_;
    my $trigger = $param->{'select_time|clear_cb'} || return;
    return $param->{$trigger};
};
my $defs = { min  => '00',
	     hour => '00',
	     day  => '01'
	   };
</%once>

<%init>

if (($field eq "$widget|refresh_p0") and (not $is_clear_state->($param))) {
    # There might be many time widgets on this page.
    my $base = mk_aref($param->{$field});

    foreach  my $b (@$base) {
	# Keep this widget with this base name distict from others on the page.
	my $sub_widget = "$widget.$b";
	my @vals;
	my $incomplete = 0;
	# This is compliments $incomplete.  It tells whether *any* time fields
	# were set.  This way we know if they started to add time fields, but
	# then stopped.
	my $has_data   = 0;

	foreach my $unit (qw(year mon day hour min)) {
	    my $f = $b.'_'.$unit;
	    my $v = $param->{$f};

	    # Set the incomplete flag and stop if we get an unset date value.
	    if ($v eq '-1') {
		$defs->{$unit} ? (push @vals, $defs->{$unit}) : ($incomplete = 1);
 	    } else {
		$has_data = 1;

		# Collect the values.
		push @vals, ($v || '0');
	    }

	    # Update all the time values.
	    set_state_data($sub_widget, $unit, $v) if defined $v;
	}

	if ($incomplete) {
	    # Clear state if this is incomplete
	    #clear_state($sub_widget);

	    # If some fields were set, flag it
	    $param->{$b.'-partial'} = 1 if $has_data;
	} else {
	    my $date = sprintf("%04d-%02d-%02d %02d:%02d:00", @vals);
	    # Write the date to the parameters.
	    $param->{$b} = $date;
	}
    }
}
elsif ($field eq $widget.'|clear_cb') {
    # If the trigger field was submitted with a true value then, clear state!
    if ($is_clear_state->($param)) {
	my $s = \%HTML::Mason::Commands::session;

	# Find all the select_time widget information
	my @sel = grep(substr($_,0,11) eq 'select_time', keys %$s);

	# Clear out all the state data.
	foreach my $sub_widget (@sel) {
	    set_state_data($sub_widget, {});
	}
    }
}

</%init>
