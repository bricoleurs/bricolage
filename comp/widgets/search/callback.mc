<%args>
$widget
$field
$param
</%args>

<%init>

use Bric::Config qw(:search);

# Set the uri for use in expiring the search criteria.
set_state_data($widget, 'crit_set_uri', $r->uri);

if( Bric::Util::Pref->lookup_val( 'Search Results / Page' ) ) {
    set_state_data( 'listManager', 'pages', '1' )
      unless( get_state_data( 'listManager', 'pages' ) );
    set_state_data( 'listManager', 'start_page', 'x' );
}

if ($field eq "$widget|substr_cb") {
    my $val_fld = $widget.'|value';
    my $crit = $param->{$val_fld} ? (FULL_SEARCH ? '%' : '') .$param->{$val_fld}.'%' : '%';

    # Set the search criterion and append a '%' to do a prefix search.
    set_state_data($widget, 'criterion', $crit);

    # Set the value that will repopulate the search box and clear the alpha
    set_state_data($widget, 'crit_field', $param->{$val_fld});
    set_state_data($widget, 'crit_letter', '');

}
elsif ($field eq "$widget|alpha_cb") {
    my $crit = $param->{$field} ? $param->{$field}.'%' : '';

    # Add a '%' to create a prefix search by first letter.
    set_state_data($widget, 'criterion', $crit);

    # Clear the substr search box and set the letter selector
    set_state_data($widget, 'crit_letter', $param->{$field});
    set_state_data($widget, 'crit_field', '');
}
elsif ($field eq "$widget|story_cb") {
    my (@field, @crit);

    $build_fields->($widget, $param, \@field, \@crit, 
		    [qw(simple title primary_uri keyword)]);

    $build_date_fields->($widget, $param, \@field, \@crit, 
			 [qw(cover_date publish_date expire_date)]);

    # Default to displaying everything if the leave all fields blank
    unless (@field) {
	push @field, 'name';
	push @crit,  '%';
    }

    set_state_data($widget, 'criterion', \@crit);
    set_state_data($widget, 'field', \@field);
}
elsif ($field eq "$widget|media_cb") {
    my (@field, @crit);

    $build_fields->($widget, $param, \@field, \@crit, 
		    [qw(simple name uri)]);

    $build_date_fields->($widget, $param, \@field, \@crit, 
			 [qw(cover_date publish_date expire_date)]);

    # Default to displaying everything if the leave all fields blank
    unless (@field) {
	push @field, 'name';
	push @crit,  '%';
    }

    set_state_data($widget, 'criterion', \@crit);
    set_state_data($widget, 'field', \@field);
}
elsif ($field eq "$widget|formatting_cb") {
    my (@field, @crit);
    
    $build_fields->($widget, $param, \@field, \@crit, 
		    [qw(simple name file_name)]);
    
    $build_date_fields->($widget, $param, \@field, \@crit, 
			 [qw(cover_date publish_date expire_date)]);

    # Default to displaying everything if the leave all fields blank
    unless (@field) {
	push @field, 'name';
	push @crit,  '%';
    }

    set_state_data($widget, 'criterion', \@crit);
    set_state_data($widget, 'field', \@field);
}
elsif ($field eq "$widget|generic_cb") {
    # Callback in 'leech' mode.  Any old page can send search criteria here

    # A '+' separated list of object field names
    my $flist  = $param->{"$widget|generic_fields"};

    # A '+' separated list of form field names who's values are the criteria for
    # the object field names in $flist above
    my $clist  = $param->{"$widget|generic_criteria"};

    # A '+' separated list of object fields that are meant to be substring 
    # searches and thus should be wrapped in '%'
    my $substr = $param->{"$widget|generic_set_substr"};

    my $fields = [split('\+', $flist)];
    my $crit   = [map { $param->{$_} } split('\+', $clist)];

    my %sub = map { $_ => 1 } split('\+', $substr);

    my $i = $#{$fields};
    while ($i >= 0) {
	# Remove any criteria from the list who's value is the null string or
	# the string '_all'.
    	if (($crit->[$i] eq '_all') or ($crit->[$i] eq '')) {
	    splice @$fields, $i, 1;
	    splice @$crit,   $i, 1;
        }
	
	# Check for searches that should be substring searches.
	if ($sub{$fields->[$i]}) {
	    $crit->[$i] = '%'.$crit->[$i].'%';
	}
        $i--;
    }

    set_state_data($widget, 'criterion', $crit);
    set_state_data($widget, 'field', $fields);
}

elsif ($field eq "$widget|clear_cb") {
    clear_state($widget);
}

elsif ($field eq "$widget|set_advanced_cb") {
    set_state_data($widget, 'advanced_search', 1);
}

elsif ($field eq "$widget|unset_advanced_cb") {
    set_state_data($widget, 'advanced_search', 0);
}

</%init>

<%once>

use Bric::Config qw(:search);

my $build_fields = sub {
    my ($widget, $param, $field, $crit, $add) = @_;
    
    foreach my $f (@$add) {
	my $v = $param->{$widget."|$f"};
	
	# Save the value so we can repopulate the form.
	set_state_data($widget, $f, $v);
	
	# Skip it if its blank
	next unless $v;

	push @$field, $f;
	push @$crit, (FULL_SEARCH ? '%' : '').$v.'%';
    }
};

my $build_date_fields = sub {
    my ($widget, $param, $field, $crit, $add) = @_;

    foreach my $f (@$add) {
	my $v_start = $param->{$widget."|${f}_start"};
	my $v_end   = $param->{$widget."|${f}_end"};

	# Save the value so we can repopulate the form.
	set_state_data($widget, $f.'_start', $v_start);
	set_state_data($widget, $f.'_end', $v_end);

	if ($v_start) {
	    push @$field, $f.'_start';
	    push @$crit,  $v_start;
	}

	if ($v_end) {
	    push @$field, $f.'_end';
	    push @$crit,  $v_end;
	}
    }
};

</%once>
