%#--- Documentation ---#

<%doc>

=head1 NAME

select_object - Provide a select box listing all objects of a certain type.

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2001-10-09 20:54:39 $

=head1 SYNOPSIS

<& '/widgets/select_object/select_object.mc', object     => 'Keyword'
                                              crit_field => 'active',
                                              crit_value => 1,
                                              sort_field => 'sort_name',
                                              name       => 'foo|keyword_id',
                                              field      => 'name',
                                              selected   => 'george w' &>

=head1 DESCRIPTION

This widget creates a pulldown menu populated with values from all objects of
a particular type.  The pulldown menu will have a name equal to the 'name' 
argument and its values will be the ID of an object.  The 'field' argument 
names the field to list for display.

The arguments are:

=over 4

=item *

object

The object type to list

=item *

name

The name of the form field element constructed by this widget.  You will need
to set this to get the value set on this widget!

=item *

field

The field that will be displayed as labels in this widget.  The values will be
the ID of the objects themselves.

=item *

crit_field

A field of object used to constrain the objects listed. Optional.

DEPRECIATED - Use the 'constrain' argument instead.

=item *

crit_value

The criterion value to use when choosing which objects to list.  The crit_field 
and crit_value will be passed directly to the objects 'list' method.  Optional.

DEPRECIATED - Use the 'constrain' argument instead.

=item *

sort_field

The field that should be used to sort the list of values.  This does not have 
to be the display field.  Optional.

=item *

selected

The entry matching 'field' to be selected by default. Optional.

=item *

default

An array ref of [default ID, default display].  Optional.

=item *

no_persist

If this is set to a true value, then this widget will not maintain state 
information about the value selected.

=item *

reset_key

If this is set to a defined value, then this value is used as a trigger for 
reseting the state of this widget;  if the value changes, a reset is triggered 
and all the state data for this widget is cleared.

=item *

exclude

Exclude certain object instances from appearing in the list by passing this 
parameter an array ref of object IDs to exclude.

=item *

constrain

Constrain the items listed by passing a hash ref of 'list' method key value 
pairs.  This argument replaces the 'crit_field' and 'crit_value' arguments.

=item *

js = Arbitrary JavaScript to be added to the select menu.

=item *

size - Number of items to display at once in a scrolling select list rather than
a dropdown.

=item *

req - Pass a true value to make this a required field.

=back

This widget will maintain its own state with regard to saving what is currently
selected.

=cut

</%doc>

<%once>
my $widget = 'select_object';
</%once>

%#--- Arguments ---#

<%args>
$style      => 'dropdown'
$object
$name       => ''
$field
$constrain  => {}
$crit_field => undef
$crit_value => undef
$sort_field => undef
$selected   => undef
$default    => undef
$no_persist => 0
$width      => 578
$indent     => FIELD_INDENT
$disp       => ''
$useTable   => 1
$reset_key  => undef
$exclude    => []
$readOnly   => 0
$req        => 0
$size       => undef
$js         => undef
</%args>

%#--- Initialization ---#

<%init>

# Append the object name to the end of the widget name to allow multiple select
# boxes to exist on the same page.
my $sub_widget .= "$widget.$object";

# Convert the exclude array into a hash
$exclude = { map { $_ => '' } @$exclude };

# Reset this widget if the reset key changes.
reset_state($sub_widget, $reset_key);

if ($no_persist) {
    # Do not maintain selected state if the no_persist flag is set.
    set_state_data($sub_widget, 'selected_id', undef)
} else {
    # Set the default value if one has been passed.
    init_state_data($sub_widget, 'selected_id', $selected);
}

# Set the name we are supposed to use so that we can check it and repopulate.
set_state_data($sub_widget, 'form_name', $name);
# Grab the package name.
my $pkg = get_package_name($object);
my @vals;

# Handle the depreciated arguments 'crit_field' and 'crit_value'
if ($crit_field) {
    $constrain->{$crit_field} = $crit_value;
}

if ($pkg) {
    my $meth = $pkg->my_meths();
    my @objs = $pkg->list($constrain);

    # Sort the items if required.
    if ($sort_field) {
        my $get = $meth->{$sort_field}->{'get_meth'};
        my $arg = $meth->{$sort_field}->{'get_args'};

        @objs = sort { $get->($a, $arg) cmp $get->($b, $arg) } @objs;
    }

    # Put the default value at the top if it exists.
    $vals[0] = [@$default] if ($default);

    # Add the rest of the values from the object.
    my $val_get = $meth->{$field}->{'get_meth'};
    my $val_arg = $meth->{$field}->{'get_args'};

    foreach my $o (@objs) {
        my $id = $o->get_id;

	# Do not add excluded IDs.
	next if exists $exclude->{$id};

        my $val = $val_get->($o, $val_arg);
	
        push @vals, [$id, $val];
    } 
} else {
    # Handle the case where the package name is not in the database.
    @vals = ([0,"Pkg get failed: '$object'"]);
}

$m->comp($style.'.html', 
	 widget   => $widget, 
	 object   => $object, 
	 vals     => \@vals,
	 width    => $width,
	 indent   => $indent,
	 disp     => $disp,
	 useTable => $useTable,
	 readOnly => $readOnly,
	 size     => $size || @vals <= 20 ? 1 : 5,
	 req      => $req,
	 sel_id   => $selected,
	 js       => $js
);

</%init>

%#--- Log History ---#


