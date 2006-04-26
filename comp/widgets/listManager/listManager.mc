<%doc>

=head1 NAME

listManager.mc - display a list of objects.

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  <& /widgets/listManager/listManager.mc
     object => $object,
     sortBy => $sortBy
  &>

=head1 DESCRIPTION

Display a list of objects in a table, with links to sort by any column header.

Required arguments to this widget:

=over 4

=item object

A short name for the object type to display, eg 'Person' translates to the
package name 'Bric::Biz::Person'. This mapping is maintained in the 'class'
table, where the short name is the 'disp_name' column and the package name is
in the 'pkg_name' column.

=item state_key

The short name used to look in the session data for search and pagination data
in the search and listManager widgets. It defaults to the same value as the
C<object> parameter, so it should usually be the right thing. But sometimes
you need something different, such as when two story workflows both search for
and list story objects, but should store their search data separately from
each other.

=back

Optional arguments to this widget:

=over 4

=item objs

An anonymous array of objects. If you pass these in, listManager won't bother
to call list() to look them up.

=item style

As with other widgets the 'style' argument provides the ability to display
itself in a variety of ways. Currently the only style available is 'full_list'
which produces a non-scrolling list of all the elements. Possible styles that
could be developed are paged_list, scrolled_list, etc. This widget will
default to 'full_list'.

=item sortBy

Provide the a default column by which to sort all the elements of the list. If
this argument is not passed the listManager will display the elements in the
order they were returned by the objects 'list' function.

=item def_sort_field

Use this only if you you don't pass sortBy and if you know that the objects
will be returned from list (or are stored in the objs argument -- see below)
in an order different than the default that will be returned by inspecting
my_meths(). For example, if normally my_meths() says that the objects are
sorted by name, but you're passing them via the objs argument in a different
order, then specify which field defines that order here.

=item def_sort_order

Use this when results should be sorted either ascending or descending by
default. Default is undefined, which has no effect. Possible values are
'ascending' or 'decending'.

=item userSort

A flag controlling whether the user is allowed to resort the list based on the
column headings. The default is 1 (true) or that the user can resort the list.

=item profile

A 'profile' is a generic term for any action that applies to one and only on
object in the list. It is a labeled link that typically points to an edit
page. This argument takes an array ref of a label, URL and query value. The
default is:

  ['Edit', '', "id=$o_id"]

Which means the label is 'Edit', with a null link and the id parameter set to
the current objects ID. Only the label argument needs to be filled in. In the
'full_list' style this link is followed via a GET request. If the value is a
list of lists, then multiple profile links will be displayed:

  [['Edit', ''], ['Update', '']]

will display two links labeled 'Edit' and 'Update'.

This can also take a code reference that will return the appropriate array ref
when called. It will be passed the object ref on each row.

=item select

A 'select' is a generic term for any action that applies to one or many
objects in the list. In the 'full_list' style it is represented as a checkbox
next to each object. This argument takes an array ref of a label, a callback,
the callback's value, and a hash ref of arguments to
comp/widgets/profile/checkbox.mc. The default is:

  ['Delete', '', $o_id]

Which means the label is 'Delete', the callback is null, the callback value is
the current object's ID, and no extra arguments are passed to the checkbox
widget. Only the label argument is required.

The listManager widget has two built in callbacks that can be used as actions
for the select. These are 'listManager|delete_cb' and
'listManager|deactivate_cb'. These will automatically call the delete or
deactivate method, respectively, on the object they represent.

If the value is a list of lists, then multiple profile links will be
displayed:

  [['Edit', ''], ['Update', '']]

will display two checkboxes labeled 'Edit' and 'Update'.

This can also take a code reference that will return the appropriate array ref
when called. It will be passed the object ref on each row.

=item addition

An 'addition' is a generic term for adding a new object to the list manager.
This will usually happen by creating a new object of the appropriate type.
This argument takes an array ref of a label, a URL, and an optional object
display name. The default is:

  ['Add', '']

Which means the label is 'Add', with a null link. In the 'full_list' style,
this link is followed via a GET request. No extra arguments will be passed.
You might consider making the 'addition' link and the 'profile' link be the
same and switch on whether you are passed an 'id'.

This can also take a code reference that will return the appropriate array ref
when called.

=item search_widget

Pass a widget name to this argument to tell the listManager in which widget's
session data to look for its list criterion. By default it will look in the
session data belonging to the 'search' widget. The widget given here must
populate the 'field' and 'criterion' keys of its session data.

The 'field' key can either be a scalar naming the field to search or an array
ref containing a list of field names.

The 'criterion' key can either be a scalar giving the search criteria for the
field given in key 'field' or an array ref containing a list of criteria that
should match, in order, the fields listed in key 'field'

See the notes section for an alternative to this that does not require another
widget.

=item fields

Pass this argument a list of field names. These field names should be a subset
of the field names returned by the listed objects my_meths method. If this
argument is given, then only these fields will be displayed from each object
and they will be displayed in the order that they are passed. If this argument
is not given then all the fields returned by my_meths will be displayed.

=item field_titles

This accepts a hash ref of field name to display name. You can use it to
change the name of an existing field or to create a display name for a created
field when used with 'fields' and 'field_values'. If you pass a non-existent
field name to 'fields', map that name to a display name here in 'field_titles'
and then provide values for that field in 'field_values' you can create new
fields that did not exist in the original object.

See C<field_values> and C<fields>

=item field_values

Set this to a sub ref. This sub ref should accept an object and a field name
and return the value appropriate for that field and object. Use this argument
to create completely new fields that do not exist in the original object. If
the sub ref returns undef, the 'my_meths' method of the object will be used
instead to find the value.

See <field_titles> and C<fields>

=item constrain

A hash ref of constraints that are applied to the list before any sorting or
searching is done. This is useful when you only want to show a subset of all
objects of a certain type to the user. This hash ref will be passed to the
'list' function of the object so make sure that the list function supports the
parameters you pass!

=item behavior

Dictates generally how this listManager behaves. Currently this is limited to
whether this list shows all existing objects and a search will narrow this
list, or whether this list begins empty and searches expand the objects
listed. The first behavior is default but can be explicitly set as:

  behavior => 'narrow'

The second behavior can be set by passing 'expand' to this argument:

  behavior => 'expand'

=item exclude

Exclude certain object instances from appearing in the list by passing this
parameter an array ref of object IDs to exclude. You can also pass a sub ref
to this argument. This sub ref will be called for each object to be displayed
in the list, and be passed the object as the first argument. If the sub ref
returns true, that object will be excluded from the list. If it returns false
the object will stay in the list.

=item alter

Alter the values of a particular column via a sub ref. The 'alter' argument
takes a hash ref of field key name and sub ref. That sub ref will be called
for every value in the column named by the field key and will be passed the
value of that column for that row. For example, to make a column displaying
boolean values display yes/no rather than 1/0:

  alter => { active => sub { $_[0] ? 'Yes' : 'No'} }

The alter code ref is passed the row value for a given column and the object
for that row:

 $alter = sub {
     my ($val, $obj) = @_;
     ...
 }

=item featured

A list of 'featured' objects in this list. These objects always appear in the
list even if the criteria do not match them. These objects are also
highlighted so they stand out against the other objects.

=item featured_color

The background color for the featured rows. This can be any string that you
would normally pass to the 'bgcolor' attribute of the <tr> element. This will
default to a standard color if not passed.

=back

=head1 NOTES

There is one other way to pass search criteria to the listManager. By setting
a certain set of hidden fields, you can act as a parasite on the search widget
and force it to do your bidding. The fields are:

=over 4

=item search|generic_cb

Should be set to a true value

=item search|generic_fields

Should be set to a '+' delimited list of field names. These names should match
the names returned by my_meths of whatever object you are listing

=item search|generic_criteria

Should be set to a '+' delimited list of form field names whose values should
be the criteria to the fields listed in 'search|generic_fields'.

=back

So a simple example using two search parameters would be:

  <input type="hidden" name="search|generic_cb" value="1" />
  <input type="hidden" name="search|generic_fields" value="name+description" />
  <input type="hidden" name="search|generic_criteria" value="name_field+desc_field" />
  <input type="text" name="name_field" />
  <input type="text" name="desc_field" />

When this form is submitted (and presumably takes the user to a page that has
the listManager widget on it), the list function for whatever object it being
listed will be called like:

  $pkg->list({
      name        => $param->{name_field},
      description => $param->{desc_field},
  });

=cut

</%doc>
<%args>
$object                         # The object type to display
$state_key      => $object      # Where to look for session data.
$style          => 'full_list'  # The list style (full or paginated)
$sortBy         => ''           # Default to sorting by ID
$userSort       => 1            # A flag for whether the user can resort the list
$profile        => ['Edit', ''] # URL to the profile for this object.
$select         => ['Delete', ''] # Add a checkbox
$addition       => ['Add', '']  # Label and URL for adding an object to the list
$search_widget  => 'search'     # Where to look for search criterion
$fields         => undef
$field_titles   => {}
$field_values   => undef
$constrain      => {}           # Always constrain the search on a set of params
$behavior       => 'narrow'     # How this list behaves.
$exclude        => undef           # Exclude certain objects from the list.
$alter          => {}           # Alter the data for one field
$featured       => undef        # Make one row a featured row
$featured_color => '#cccc99'    # The color for the bkground of the featured row
$objs           => undef        # These are user objects to be listed.
$def_sort_field => undef
$def_sort_order => undef        # Whether to sort in descending order by default
$cx_filter      => 1            # Make false to override Filter by Site Context.
</%args>
<%init>;

#--------------------------------------#
# Initialize some values.

my $state = get_state_data($widget, $state_key) || {};
my $pkg   = get_package_name($object);

# Get the master instance of this class.
my $meth = $get_my_meths->($pkg, $field_titles, $field_values);

# Set the fields to display
$fields ||= [sort keys %$meth];

# We need a hash of featured IDs to use for later
my %featured_lookup = map { ($_,1) } @$featured;

# limit the number of results to display per page
my $limit = Bric::Util::Pref->lookup_val( "Search Results / Page" ) || 0;
my $site_cx;
$site_cx = $c->get_user_cx(get_user_id)
  if $cx_filter
  && Bric::Util::Pref->lookup_val( "Filter by Site Context" )
  && $pkg->HAS_MULTISITE;

#--------------------------------------#
# Set up pagination data.

my $pagination = $state->{pagination};
$pagination    = $limit ? 1 : 0 unless defined $pagination;
my $offset     = $limit ? $state->{offset} : undef;
my $show_all   = $state->{show_all};

#--------------------------------------#
# Find constraint and list objects.

my ($param, $do_list);
if ($show_all || ($pagination && defined $offset)) {
    # We're processing pages. Just return the last query parameters.
    $param = $state->{list_params};
    $do_list = 1;
} else {
    # Construct the parameters and then save them for future pages, if necessary.
    my $list_arg = $build_constraints->($state, $state_key, $search_widget,
                                        $constrain, $meth, $sortBy,
                                        $def_sort_field);
    $param = {%$list_arg, %$constrain};

    $param->{site_id} = $site_cx if $site_cx;
    $state->{list_params} = $param if $pagination;
    $do_list = 1 if %$list_arg;
}

# Load the user provided objects into the @objs array.
my @objects = $objs ? @$objs : ();

my $empty_search;

# Only list if there are search parameters, or if our behaviour is 'narrow'.
if (!$objs && ($behavior eq 'narrow' or $do_list)) {
    # Combine the list arguments and any passed constraints to search $pkg.
    @objects = $pkg->list($param);
} else {
    $empty_search = 1;
}

# Make sure our featured arguments are in the list
$load_featured_objs->(\@objects, $pkg, \%featured_lookup) if scalar(@$featured);

#--------------------------------------#
# Sort the objects.
$state->{sort_order} ||= $def_sort_order;
my $sort_objs  = $sort_objects->($state, \@objects, $meth, $exclude);

# Make sure we have some results.
my $no_results = @$sort_objs == 0 && $do_list;

#--------------------------------------#
# Build the table data array

# Search Paging vars - also see $insert_footer and build_table_data()
# number of records returned from lookup
my $count = scalar @$sort_objs;

my ($pages, $current_page) = (1,1);
if ($limit) {
    # determine the total number of pages
    $pages = int( ($count / $limit) + ($count % $limit ? 1 : 0));

    # which page don't we link
    $current_page = $offset && $pages > 1 ?
      int($offset / $limit + ($offset % $limit >= 0 ? 1 : 0)) : 1;
}

my ($rows, $cols, $data, $actions) = $build_table_data->(
    $sort_objs,
    $meth,
    $fields,
    $select,
    $profile,
    $alter,
    \%featured_lookup,
    $count,
    $limit,
    $offset,
    $pagination
);

# Call the element to show this list
$m->comp("$style.mc",
         widget          => $widget,
         object          => $object,
         fields          => $fields,
         data            => $data,
         actions         => $actions,
         rows            => $rows,
         pkg             => $pkg,
         state           => $state,
         cols            => $cols,
         userSort        => $userSort,
         addition        => $addition,
         featured        => \%featured_lookup,
         featured_color  => $featured_color,
         empty_search    => $empty_search,
         pagination      => { curr_page  => $current_page,
                              limit      => $limit,
                              pages      => $pages,
                              pagination => $pagination
                            }
        );
set_state_name($widget => $state_key);
set_state_data($widget, $state_key => $state);
</%init>
<%once>
my $widget = 'listManager';

my $get_my_meths = sub {
    my ($pkg, $field_titles, $field_values) = @_;

    my $meths = $pkg->my_meths;

    # Just return the package meths unless there are titles or values to be
    # replaced.
    return $meths unless $field_titles || $field_values;

    # Copy the package methods.
    $meths = { %$meths };

    # Cook the value methods
    if ($field_titles && !$field_values) {
        # Cook the display values
        while (my ($f, $t) = each %$field_titles) {
            $meths->{$f} = { %{ $meths->{$f} } }; # Copy.
            $meths->{$f}->{disp} = $t;
        }
    } elsif ($field_values) {
        $field_titles ||= {};
        foreach my $f (keys %$meths) {
            # Copy the method metadata.
            $meths->{$f} = { %{ $meths->{$f} } };
            # Install the new display name, if there is one.
            $meths->{$f}->{disp} = delete $field_titles->{$f}
              if exists $field_titles->{$f};

            my $meth = $meths->{$f}->{get_meth};
            # Try to return a value from $field_values first.
            my $cooked = sub { return ($field_values->($_[0], $f) ||
                                       $meth->(@_)) };
            $meths->{$f}->{get_meth} = $cooked;
        }
        # Check to see if there are some bonus fields to be added.
        while (my ($f, $t) = each %$field_titles) {
            $meths->{$f}{disp} = $t;
            $meths->{$f}{get_meth} = sub { return $field_values->($_[0], $f) };
        }
    }
    return $meths;
};

my $output_select_controls = sub {
    my ($o, $select, $flags) = @_;
    my $vals = ref $select eq 'CODE' ? $select->($o, $flags) : $select;
    return unless $vals;
    # Just return the value if it's not a reference.
    return $vals unless ref $vals;

    # Turn this value into an array of arrays if it isn't already.
    $vals = ref $vals->[0] eq 'ARRAY' ? $vals : [$vals];

    my @cntl;
    foreach my $v (@$vals) {
        my ($label, $name, $value, $args) = @$v;
        $value ||= $o->get_id;

        push @cntl, $m->scomp('/widgets/profile/checkbox.mc', name  => $name,
                                                              value => $value,
                                                              %$args)
          . $lang->maketext($label);
    }
    return @cntl;
};

my $output_profile_controls = sub {
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

        push @cntl, qq{<a href="$url$value" class="redLink">}
            . $lang->maketext($label) . '</a>';
    }

    return @cntl;
};

my $build_table_data = sub {
    my ($sort_objs, $meth, $fields, $select, $profile, $alter, $featured,
        $count, $limit, $offset, $pagination) = @_;
    my $data = [[map { $meth->{$_}->{'disp'} } @$fields]];
    my $actions;
    my $cols = scalar @$fields;
    my $rows = 1 + scalar @$sort_objs;
    my $sel_cols = 0;
    my $prf_cols = 0;
    # Start at row 1 since we already have $fields loaded in $data
    my $row = 1;

    my $slice;
    if ($pagination) {
        # make sure $limit + $offset is within range
        my $end = $limit + $offset > $count - 1
            ? $count - 1
            : $limit + $offset - 1;

        # extract array slice
        @$slice = @$sort_objs[$offset..$end];
    } else {
        # if pagination is off show everything
        $slice = $sort_objs;
    }
    # Output the rows of data
    foreach my $o (@$slice) {

        # Push the object id as the first value to be used in the listing comp.
        push @{$data->[$row]}, $o->get_id;

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
            push @{$data->[$row]}, ! defined $val || $val eq '' ? '&nbsp;' : $val;
        }

        my @sel = $output_select_controls->($o, $select, \%flags);
        my @prf = $output_profile_controls->($o, $profile, \%flags);

        ## Add the profile controls if any
        # MAX function
        $prf_cols = scalar @prf > $prf_cols ? scalar @prf : $prf_cols;

        # XXX Actions are 0-based for some reason. Dunno why.
        push @{$actions->[$row - 1]}, @prf if @prf;

        ## Add the select items if any
        if (@sel) {
            $sel_cols = 1;
            push @{$actions->[$row - 1]}, join q{ }, @sel;
        }

        $row++;
    }

    $cols += $sel_cols + $prf_cols;

    return ($rows, $cols, $data, $actions);
};

my $build_constraints = sub {
    my ($state, $state_key, $search_widget, $constrain, $meth, $sortBy,
        $def_sort_field) = @_;

    # Find the default search field.
    unless ($def_sort_field) {
        foreach my $f (keys %$meth) {
            # Break out of the loop if we find the searchable field.
            $def_sort_field = $f and last if $meth->{$f}->{search};
        }
    }

    # Initialize the sort column with the default search field.
    $state->{sort_by}    ||= $sortBy;
    $state->{default_sort} = $def_sort_field;

    my $search_state = get_state_data($search_widget => $state_key);

    my $crit       = $search_state->{criterion};
    my $crit_field = $search_state->{field};
    my $list_arg   = {};

    # If any criteria were passed then we need to constrain our list.
    if ($crit && $crit_field) {
        # If field is an array, build a hash with the fields as the keys and
        # $crit for vals
        if (ref $crit_field) {
            @{$list_arg}{@$crit_field} = @$crit;
        } else {
            $crit_field = $def_sort_field if $crit_field eq '_default';
            $list_arg->{$crit_field} = $crit;
        }
    }

    return $list_arg;
};

my $load_featured_objs = sub {
    my ($objs, $pkg, $featured) = @_;
    # Find all loaded feature objects
    my %loaded = map { ($_->get_id, 1) } grep($featured->{$_->get_id}, @$objs);

    # Load any unloaded features.
    foreach (keys %$featured) {
        next if $loaded{$_};
        push @$objs, $pkg->lookup({'id' => $_});
    }

    return $objs;
};

my $recursivesort;
my $multisort = sub {
    my ($meth, @sort_list) = @_;
    my $sort_by = shift @sort_list;
    my ($sort_get, $sort_arg) = @{$meth->{$sort_by}}{'get_meth', 'get_args'};
    my $type = $meth->{$sort_by}{props}{type};

    my $val;
    if ($sort_by eq 'id'|| $sort_by eq 'version') {
        # Do a numeric sorting.
        $val = $sort_get->($a, @$sort_arg) <=> $sort_get->($b, @$sort_arg);
    } elsif ($type eq 'date') {
        # Pass in the ISO format so that it always sorts properly.
        $val = $sort_get->($a, ISO_8601_FORMAT) cmp
          $sort_get->($b, ISO_8601_FORMAT);
    } else {
        # Do the case insensitive comparison
        $val = lc($sort_get->($a, @$sort_arg)) cmp
          lc($sort_get->($b, @$sort_arg));
    }

    # See if we need to do more comparisons or not.
    if (scalar(@sort_list) > 0) {
        return $val || $recursivesort->($meth, @sort_list);
    } else {
        return $val;
    }
};
# Cheat so that &$multisort can sneakily call itself. :-)
$recursivesort = $multisort;

my $sort_objects = sub {
    my ($state, $objs, $meth, $exclude) = @_;
    my @sort_objs;

    # Find which column to sort on.
    my $sort_by = $state->{sort_by};

    # Only sort if the sort by was set in the state data.
    if ($sort_by) {
        # Make sure we pass an array ref to the sort arguments
        $sort_by = ref $sort_by ? $sort_by : [$sort_by];
        @sort_objs = sort { $multisort->($meth, @$sort_by) } @$objs;
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

    my $sort_order = $state->{sort_order} || '';
    return $sort_order eq 'descending' ? [ reverse @sort_objs ] : \@sort_objs;
};
</%once>
