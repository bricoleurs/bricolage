package Bric::App::Callback::Search;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'search');
use strict;
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);
use Bric::Config qw(FULL_SEARCH);


sub substr : Callback {
    my $self = shift;
    $init_state->($self);
    my $param = $self->param;

    my $val_fld = CLASS_KEY.'|value';
    my $crit = $param->{$val_fld} ? (FULL_SEARCH ? '%' : '')
      . $param->{$val_fld} . '%' : '%';

    # Set the search criterion and append a '%' to do a prefix search.
    set_state_data(CLASS_KEY, 'criterion', $crit);

    # Set the value that will repopulate the search box and clear the alpha
    set_state_data(CLASS_KEY, 'crit_field', $param->{$val_fld});
    set_state_data(CLASS_KEY, 'crit_letter', '');

}

sub alpha : Callback {
    my $self = shift;
    $init_state->($self);

    my $crit = $self->value ? $self->value.'%' : '';

    # Add a '%' to create a prefix search by first letter.
    set_state_data(CLASS_KEY, 'criterion', $crit);

    # Clear the substr search box and set the letter selector
    set_state_data(CLASS_KEY, 'crit_letter', $self->value);
    set_state_data(CLASS_KEY, 'crit_field', '');
}

sub story : Callback {
    my $self = shift;
    $init_state->($self);

    my (@field, @crit);

    $build_fields->(CLASS_KEY, $self->param, \@field, \@crit,
		    [qw(simple title primary_uri category_uri keyword)]);

    $build_date_fields->(CLASS_KEY, $self->param, \@field, \@crit,
			 [qw(cover_date publish_date expire_date)]);

    # Default to displaying everything if the leave all fields blank
    unless (@field) {
	push @field, 'name';
	push @crit,  '%';
    }

    set_state_data(CLASS_KEY, 'criterion', \@crit);
    set_state_data(CLASS_KEY, 'field', \@field);
}

sub media : Callback {
    my $self = shift;
    $init_state->($self);

    my (@field, @crit);

    $build_fields->(CLASS_KEY, $self->param, \@field, \@crit,
		    [qw(simple name uri)]);

    $build_date_fields->(CLASS_KEY, $self->param, \@field, \@crit,
			 [qw(cover_date publish_date expire_date)]);

    # Default to displaying everything if the leave all fields blank
    unless (@field) {
	push @field, 'name';
	push @crit,  '%';
    }

    set_state_data(CLASS_KEY, 'criterion', \@crit);
    set_state_data(CLASS_KEY, 'field', \@field);
}

sub formatting : Callback {
    my $self = shift;
    $init_state->($self);

    my (@field, @crit);

    $build_fields->(CLASS_KEY, $self->param, \@field, \@crit,
		    [qw(simple name file_name)]);

    $build_date_fields->(CLASS_KEY, $self->param, \@field, \@crit, 
			 [qw(cover_date publish_date expire_date)]);

    # Default to displaying everything if the leave all fields blank
    unless (@field) {
	push @field, 'name';
	push @crit,  '%';
    }

    set_state_data(CLASS_KEY, 'criterion', \@crit);
    set_state_data(CLASS_KEY, 'field', \@field);
}

sub generic : Callback {
    my $self = shift;
    $init_state->($self);
    my $param = $self->param;

    # Callback in 'leech' mode.  Any old page can send search criteria here

    # A '+' separated list of object field names
    my $flist  = $param->{CLASS_KEY . "|generic_fields"};

    # A '+' separated list of form field names who's values are the criteria for
    # the object field names in $flist above
    my $clist  = $param->{CLASS_KEY . "|generic_criteria"};

    # A '+' separated list of object fields that are meant to be substring
    # searches and thus should be wrapped in '%'
    my $substr = $param->{CLASS_KEY . "|generic_set_substr"};

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

    set_state_data(CLASS_KEY, 'criterion', $crit);
    set_state_data(CLASS_KEY, 'field', $fields);
}

sub clear : Callback {
    my $self = shift;
    $init_state->($self);

    clear_state(CLASS_KEY);
}

sub set_advanced : Callback {
    my $self = shift;
    $init_state->($self);

    set_state_data(CLASS_KEY, 'advanced_search', 1);
}

sub unset_advanced : Callback {
    my $self = shift;
    $init_state->($self);

    set_state_data(CLASS_KEY, 'advanced_search', 0);
}

###

my $build_fields = sub {
    my ($widget, $param, $field, $crit, $add) = @_;

    foreach my $f (@$add) {
	my $v = $param->{CLASS_KEY."|$f"};

	# Save the value so we can repopulate the form.
	set_state_data(CLASS_KEY, $f, $v);

	# Skip it if its blank
	next unless $v;

	push @$field, $f;
	push @$crit, (FULL_SEARCH ? '%' : '') . $v . '%';
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

my $init_state {
    my $r = $_[0]->apache_req;

    # Set the uri for use in expiring the search criteria.
    set_state_data(CLASS_KEY, 'crit_set_uri', $r->uri);

    # reset search paging offset to start at the first record
    set_state_data('listManager', 'offset', 0);
}

1;
