<%doc>

=head1 NAME

listManager.mc - display a list of objects.

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2001-10-09 20:54:38 $

=head1 SYNOPSIS

<& '/widgets/listManager/listManager.mc' object => $object, sortBy => $sortBy &>

=head1 DESCRIPTION

Display a list of objects in a table, with links to sort by any column header.

Required arguments to this widget:

=over 4

=item *

object

A short name for the object type to display,  eg 'Person' translates to the
package name 'Bric::Biz::Person'.   This mapping is maintained in the 'class'
table, where the short name is the 'disp_name' column and the package name is 
in the 'pkg_name' column.

=back

Optional arguments to this widget:

=over 4

=item *

objs

An anonymous array of objects. If you pass these in, listManager won't bother to
call list() to look them up.

=item *

style

As with other widgets the 'style' argument provides the ability to display 
itself in a variety of ways.  Currently the only style available is 'full_list'
which produces a non-scrolling list of all the elements.  Possible styles that
could be developed are paged_list, scrolled_list, etc.  This widget will 
default to 'full_list'.

=item *

title

This gives the display title for this list.  The string may contain substituted
values.  They are:

%n - The plural name of the object being listed.

The default value for this argument is:

'Existing %n'

=item *

sortBy

Provide the a default column by which to sort all the elements of the list.  If
this argument is not passed the listManager will display the elements in the
order they were returned by the objects 'list' function.

=item *

userSort

A flag controlling whether the user is allowed to resort the list based on the 
column headings.  The default is 1 (true) or that the user can resort the list.

=item *

profile

A 'profile' is a generic term for any action that applies to one and only on
object in the list.  It is a labeled link that typically points to an edit page.
This argument takes an array ref of a label, URL and query value.  The default 
is:

['Edit', '', "id=$o_id"]

Which means the label is 'Edit', with a null link and the id parameter set to 
the current objects ID.  Only the label argurment needs to be filled in.  In 
the 'full_list' style this link is followed via a GET request.  If the value is 
a list of lists, then multiple profile links will be displayed:

[['Edit', ''], ['Update', '']]

will display two links labeled 'Edit' and 'Update'.

This can also take a code reference that will return the apropriate array ref
when called.  It will be passed the object ref on each row.

=item *

select

A 'select' is a generic term for any action that applies to one or many objects
in the list.  In the 'full_list' style it is represented as a checkbox next to
each object.  This argument takes an array ref of a label and callback.  The
default is:

['Delete', '', $o_id]

Which means the label is 'Delete', the callback is null and the callback value
is the current objects ID.  Only the label argument is required.

The listManager widget has two built in callbacks that can be used as actions
for the select.  These are 'listManager|delete_cb' and
'listManager|deactivate_cb'.  These will automatically call the delete or
deactivate method, respectively, on the object they represent. 

If the value is a list of lists, then multiple profile links will be displayed:

[['Edit', ''], ['Update', '']]

will display two checkboxes labeled 'Edit' and 'Update'.

This can also take a code reference that will return the appopriate array ref
when called.  It will be passed the object ref on each row.

=item *

addition

An 'addition' is a generic term for adding a new object to the list manager.  
This will usually happen by creating a new object of the appropriate type.  This
argument takes an array ref of a label and a URL.   The default is:

['Add', '']

Which means the label is 'Add', with a null link.  In the 'full_list' style,
this link is followed via a GET request.  No extra arguments will be passed.  
You might consider making the 'addition' link and the 'profile' link be the same
and switch on whether you are passed an 'id'.

This can also take a code reference that will return the appopriate array ref
when called.

=item *

search_widget

Pass a a widget name to this argument to tell the listManager in which widgets
session data to look for its list criterion.  By default it will look in the
session data belonging to the 'search' widget.   The widget given here
must populate the 'field' and 'criterion' keys of its session data.  

The 'field' key can either be a scalar naming the field to search or an array 
ref containing a list of field names.

The 'criterion' key can either be a scalar giving the search criteria for the
field given in key 'field' or an array ref containing a list of criteria that 
should match, in order, the fields listed in key 'field'

See the notes section for an alternative to this that does not require another 
widget.

=item *

fields

Pass this argument a list of field names.  These field names should be a subset
of the field names returned by the listed objects my_meths method.  If this
argument is given, then only these fields will be displayed from each object
and they will be displayed in the order that they are passed.  If this argument
is not given then all the fields returned by my_meths will be displayed.

=item *

field_titles

This accepts a hash ref of field name to display name.  You can use it to change
the name of an existing field or to create a display name for a created field
when used with 'fields' and 'field_values'.  If you pass a non-existant field
name to 'fields', map that name to a display name here in 'field_titles' and
then provide values for that field in 'field_values' you can create new fields
that did not exist in the original object.

See 'field_values' and 'fields'

=item *

field_values

Set this to a sub ref.  This sub ref should accept an object and a field name
and return the value appropriate for that field and object.  Use this argument
to create completely new fields that do not exist in the original object.  If 
the sub ref returns undef, the 'my_meths' method of the object will be used
instead to find the value.

See 'field_titles' and 'fields'

=item *

constrain

A hash ref of constraints that are applied to the list before any sorting or 
searching is done.  This is useful when you only want to show a subset of all
objects of a certain type to the user.  This hash ref will be passed to the
'list' function of the object so make sure that the list function supports
the parameters you pass!

=item *

behavior

Dictates generally how this listManager behaves.  Currently this limited to 
whether this list shows all existing objects and a search will narrow this list,
or whether this list begins empty and searches expand the objects listed.  
The first behavior is default but can be explicitly set as:

behavior => 'narrow'

The second behavior can be set by passing 'expand' to this argument:

behavior => 'expand'

=item *

exclude

Exclude certain object instances from appearing in the list by passing this 
parameter an array ref of object IDs to exclude.  You can also pass a sub ref 
to this argument.  This sub ref will be called for each object to be displayed 
in the list, and be passed the object as the first arugment.  If the sub ref 
returns true, that object will be excluded from the list.  If it returns false
the object will stay in the list.

=item *

alter

Alter the values of a particular column via a sub ref.  The 'alter' argument 
takes a hash ref of field key name and sub ref.  That sub ref will be called
for every value in the column named by the field key and will be passed the
value of that column for that row.  For example, to make a column displaying
boolean values display yes/no rather than 1/0:

alter => {'active' => sub { $_[0] ? 'Yes' : 'No'}}

The alter code ref is passed the row value for a given column and the object 
for that row:

 $alter = sub {
     my ($val, $obj) = @_;
     ...
 }

=item *

featured

A list of 'featured' objects in this list.  These objects always appear in the 
list even if the criteria do not match them.  These objects are also hilighted
so they stand out against the other objects.

=item *

featured_color

The background color for the featured rows.  This can be any string that you
would normally pass to the 'bgcolor' attribute of the <tr> element.   This 
will default to a standard color if not passed.

=back

=head1 NOTES

There is one other way to pass search criteria to the listWidget.  By setting
a certain set of hidden fields, you can act as a parasite on the search widget
and force it to do your bidding.  The fields are:

=over 4

=item *

search|generic_cb

Should be set to a true value

=item *

search|generic_fields

Should be set to a '+' delimited list of field names.  These names should match
the names returned by my_meths of whatever object you are listing

=item *

search|generic_criteria

Should be set to a '+' delimited list of form field names whos values should be
the criteria to the fields listed in 'search|generic_fields'.

=back

So a simple example using two search parameters would be:

<input type='hidden' name='search|generic_cb' value='1'>
<input type='hidden' name='search|generic_fields' value='name+description'>
<input type='hidden' name='search|generic_criteria' value='name_field+desc_field'>
<input type='text' name='name_field'>
<input type='text' name='desc_field'>

When this form is submitted (and presumably takes the user to a page that has
the listManager widget on it), the list function for whatever object it being
listed will be called like:

$pkg->list({'name'        => $param->{'name_field'},
            'description' => $param->{'desc_field'}});


=cut
</%doc>

<%args>
$object                        # The object type to display
$style         => 'full_list'  # The list style (full or paginated)
$title         => 'Existing %n'# Text for the title of this list.
$sortBy        => ''           # Default to sorting by ID
$userSort      => 1            # A flag for whether the user can resort the list
$profile       => ['Edit', ''] # URL to the profile for this object.
$select        => ['Delete', ''] # Add a checkbox
$addition      => ['Add', '']  # Label and URL for adding an object to the list
$search_widget => 'search'     # Where to look for search criterion
$fields        => undef
$field_titles  => {}
$field_values  => undef
$constrain     => {}           # Always constrain the search on a set of params
$behavior      => 'narrow'     # How this list behaves.
$exclude       => undef           # Exclude certain objects from tjhe list.
$alter         => {}           # Alter the data for one field
$featured      => undef        # Make one row a featured row
$featured_color=> '#cccc99'    # The color for the bkground of the featured row 
$number        => 0            
$objs          => undef        # These are user objects to be listed.
</%args>

<%init>

#--------------------------------------#
# Initialize some values.

# Reset the state of this widget if the object name changes.
reset_state($widget, $object);

# Get the package name given the short name
my $pkg = get_package_name($object);

# Save the object type.
set_state_data($widget, 'object',   $object);
set_state_data($widget, 'pkg_name', $pkg);

# Get the master instance of this class.
my $meth = $get_my_meths->($pkg, $field_titles, $field_values);

# Set the fields to display
$fields ||= [sort keys %$meth];

# Set the title
my $name = get_class_info($object)->get_plural_name;
$title =~ s/\%n/$name/;

# We need a hash of featured IDs to use for later
my %featured_lookup = map { ($_,1) } @$featured;

#--------------------------------------#
# Find constraint and list objects.

my $list_arg = build_constraints($search_widget, $constrain, $meth, $sortBy);
my $param = {%$list_arg, %$constrain};

# Load the user provided objects into the @objs array.
my @objects;
@objects = @$objs if $objs;

my $empty_search;

# Only list if there are search parameters, or if our behaviour is 'narrow'.
if (!$objs && (scalar keys %$param or $behavior eq 'narrow')) {
    # Combine the list arguments and any passed constraints to search $pkg.
    @objects = $pkg->list($param);
} else {
    $empty_search = 1;
}

# Make sure our featured arguments are in the list
load_featured_objs(\@objects, $pkg, \%featured_lookup) if scalar(@$featured);

#--------------------------------------#
# Sort the objects.

my @sort_objs = sort_objects(\@objects, $meth, $exclude);

# Make sure we have some results.
my $no_results = (scalar(@sort_objs) == 0) && (scalar(keys(%$list_arg)) > 0);

#--------------------------------------#
# Build the table data array

my ($rows, $cols, $data) = build_table_data(\@sort_objs,
					    $meth,
					    $fields,
					    $select,
					    $profile,
					    $alter,
					    \%featured_lookup);

# Call the element to show this list
$m->comp("$style.mc", widget          => $widget,
	              title           => $title,
	              fields          => $fields,
	              data            => $data,
	              rows            => $rows,
	              pkg             => $pkg,
                      cols            => $cols,
                      userSort        => $userSort,
	 	      addition        => $addition,
	              featured        => \%featured_lookup,
	              featured_color  => $featured_color,
	              number          => $number,
	              empty_search    => $empty_search,
	);

</%init>

<%once>
my $widget = 'listManager';

my $get_my_meths = sub {
    my ($pkg, $field_titles, $field_values) = @_;
    my $meths = $pkg->my_meths();

    # Cook the display values
    while (my ($f, $t) = each %$field_titles) {
	$meths->{$f}->{'disp'} = $t;
    }

    # Cook the value methods
    if ($field_values) {
	foreach my $f (keys %$meths) {
	    my $meth = $meths->{$f}->{'get_meth'};

	    # Try to return a value from $field_values first.
	    my $cooked = sub { return ($field_values->($_[0], $f) ||
				       $meth->(@_)) };
	    
	    $meths->{$f}->{'get_meth'} = $cooked;
	}
    }

    return $meths;
};

sub build_table_data {
    my ($sort_objs, $meth, $fields, $select, $profile, $alter, $featured) = @_;
    my $data = [[map { $meth->{$_}->{'disp'} } @$fields]];
    my $cols = scalar @$fields;
    my $rows = 1 + scalar @$sort_objs;
    my $sel_cols = 0;
    my $prf_cols = 0;
    # Start at row 1 since we already have $fields loaded in $data
    my $r = 1;

    # Output the rows of data
    foreach my $o (@$sort_objs) {
	# Push the object id as the first value to be used in the listing comp.
	push @{$data->[$r]}, $o->get_id;

	# Load a flag to tell if this object is a featured object or not.
	my %flags = ('featured' => $featured->{$o->get_id});

	# Output for each field.
	foreach my $f (@$fields) {
	    my $val;
	    if ($meth->{$f}->{get_meth}) {
		# Try to call the get method.
		$val = $meth->{$f}->{get_meth}->($o,@{$meth->{$f}->{get_args}});
		# See if there is an existing alter method.
		$val = exists $alter->{$f} ? $alter->{$f}->($val, $o, \%flags)
                                           : $val;
	    }

	    # Add this value to the return data.
	    push @{$data->[$r]}, ($val || '&nbsp');
	}

	my @sel = output_select_controls($o, $select, \%flags);
	my @prf = output_profile_controls($o, $profile, \%flags);

	## Add the profile controls if any
	# MAX function
	$prf_cols = scalar @prf > $prf_cols ? scalar @prf : $prf_cols;

	push @{$data->[$r]}, @prf if @prf;
	
	## Add the select items if any
	if (@sel) {
	    $sel_cols = 1;
	    push @{$data->[$r]}, join('<br>', @sel);
	}

	$r++;
    }

    $cols += $sel_cols + $prf_cols;

    return ($rows, $cols, $data);
}

sub output_select_controls {
    my ($o, $select, $flags) = @_;
    my $vals = ref $select eq 'CODE' ? $select->($o, $flags) : $select;
    my @cntl;

    return unless $vals;

    # Turn this value into an array of arrays if it isn't already.
    $vals = ref($vals->[0]) eq 'ARRAY' ? $vals : [$vals];

    foreach my $v (@$vals) {
	my ($label, $name, $value) = @$v;
	$value ||= $o->get_id;

	push @cntl, $m->scomp('/widgets/profile/checkbox.mc', name  => $name,
	      	                                              value => $value).
		    $label;
    }

    return @cntl;
}

sub output_profile_controls {
    my ($o, $profile, $flags) = @_;
    my $vals = ref $profile eq 'CODE'  ? $profile->($o, $flags) : $profile;
    my @cntl;

    return unless $vals;

    # Turn this value into an array of arrays if it isn't already.
    $vals = ref($vals->[0]) eq 'ARRAY' ? $vals : [$vals];

    foreach my $v (@$vals) {
	my ($label, $url, $value) = @$v;

	# Don't set a default value if they passed the empty string.
	if ((not defined $value) or (length($value) > 0)) {
	    $value ||= 'id='.$o->get_id;
	    # Add the query string '?' if its not there already.
	    $value = "?$value" unless substr($value, 0, 1) eq '?';
	}

	push @cntl, "<a href='$url$value' class=redLink>$label</a>&nbsp;";
    }

    return @cntl;
}

sub build_constraints {
    my ($search_widget, $constrain, $meth, $sortBy) = @_;

    # Only get the criterion if we are still on the same page where it was set.
    my $prev = get_state_data($search_widget, 'crit_set_uri') || '';
    my $cur  = $r->uri || '';

    # Remove trailing slashes if they exsist.  Fixes a problem 
    # not realizing that '/foo/bar' and '/foo/bar/' are the same URL.
    substr($prev, -1, 1) = '' unless substr($prev, -1) ne '/';
    substr($cur, -1, 1)  = '' unless substr($cur, -1) ne '/';

    # Find the default search field.
    my $def_search_field;
    foreach my $f (keys %$meth) {
	# Break out of the loop if we find the searchable field.
	$def_search_field = $f and last if $meth->{$f}->{'search'};
    }

    # Initialize the sort column with the default search field.
    init_state_data($widget, 'sortBy', $sortBy || $def_search_field);

    my $crit = $cur eq $prev ? get_state_data($search_widget, 'criterion')
                             : undef;
    my $crit_field = get_state_data($search_widget, 'field');
    my $list_arg = {};

    # If any criteria were passed then we need to constrain our list.
    if ($crit && $crit_field) {
	# If field is an array, build a hash with the fields as the keys and 
        # $crit for vals
	if (ref $crit_field) {
	    @{$list_arg}{@$crit_field} = @$crit;
	} else {
	    $crit_field = $def_search_field if $crit_field eq '_default';
	    $list_arg->{$crit_field} = $crit;
	}
    }

    return $list_arg;
}

sub load_featured_objs {
    my ($objs, $pkg, $featured) = @_;
    # Find all loaded feature objects
    my %loaded = map { ($_->get_id, 1) } grep($featured->{$_->get_id}, @$objs);

    # Load any unloaded features.
    foreach (keys %$featured) {
	next if $loaded{$_};
	push @$objs, $pkg->lookup({'id' => $_});
    }

    return $objs;
}

sub sort_objects {
    my ($objs, $meth, $exclude) = @_;
    my @sort_objs;

    # Find which column to sort on.
    my $sort_by = get_state_data($widget, 'sortBy');

    # Only sort if the sort by was set in the state data.
    if ($sort_by) {
	# Make sure we pass an array ref to the sort arguments
	$sort_by = ref $sort_by ? $sort_by : [$sort_by];
	@sort_objs = sort { multisort($meth, @$sort_by) } @$objs;
    } else {
	@sort_objs = @$objs;
    }

    # Exclude objects with certain IDs.
    if ($exclude) {
	# Convert the exclude array into a HASH ref and return as a sub ref.
	if (ref $exclude eq 'ARRAY') {
	    my %h = map { $_ => '' } @$exclude;
	    $exclude = sub { exists $h{$_[0]->get_id} };
	}
	@sort_objs = grep(not($exclude->($_)), @sort_objs);
    }

    return @sort_objs;
}

sub multisort {
    my ($meth, @sort_list) = @_;
    my $sort_by               = shift @sort_list;
    my ($sort_get, $sort_arg) = @{$meth->{$sort_by}}{'get_meth', 'get_args'};

    # Do the case insensitive comparison
    my $val = lc($sort_get->($a, @$sort_arg)) cmp
              lc($sort_get->($b, @$sort_arg));

    # See if we need to do more comparisons or not.
    if (scalar(@sort_list) > 0) {
	return $val || multisort($meth, @sort_list);
    } else {
	return $val;
    }
}

</%once>


