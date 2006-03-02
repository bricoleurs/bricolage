<table border="0" cellpadding="2" cellspacing="0">
<%perl>;
my $spacer = ($useTable) ? '<img src="/media/images/spacer.gif" width='. (FIELD_INDENT-8) .' height=1>'
                         : '<img src="/media/images/spacer.gif" width=50 height=1>';
# Output the headers.
unless ($no_labels) {
    $m->out("<tr>\n");
    $m->out("<td>$spacer</td>");
    if (!$deleteLabelOnly) {
        $m->out(qq{    <td><span class="label">&nbsp;$meths->{$_}->{disp}</td>\n})
          for @$fields;
    } else {
        $m->out("<td></td>");
    }
    if (!$deleteLabelOnly) {
        $m->out(qq{    <td><span class="label">&nbsp;$_</td>\n})
          for map { $_->{disp} } @$extras;
    } else {
        $m->out("<td></td>");
    }
    $m->out(qq{    <td><span class="label">&nbsp;}.$lang->maketext('Delete')."</td>\n")
      unless $read_only || !@$objs;
    $m->out("</tr>\n");
}
# Display all the rows.
for my $i (0..$num) {
    $m->out(qq{<tr>\n});
    $m->out("<td>$spacer</td>");
    if (my $obj = $objs->[$i]) {
        # There's an existing row. Output a hidden field with the ID.
        my $id = $use_vals ? $obj->{id} : $obj->get_id;
        $m->comp('/widgets/profile/hidden.mc', name => "${type}_id",
                 value => $id) if defined $id && !$read_only;
        # Go through all the fields.
        foreach my $f (@$fields) {
            # Grab the value.
            my $value = $use_vals ? $obj->{$f}
              : $meths->{$f}{get_meth}->($obj,@{ $meths->{$f}{get_args} });
            $m->out('    <td>');
            # Output the field.
            if ($no_ed->{$f}) {
                # Just output uneditable text.
                $m->out(qq{<span class="label">&nbsp;&nbsp;$value</span>});
            } else {
                # We can output a full form element.
                my @args = (key => $f, name => '', useTable => 0,
                            readOnly => $read_only);
                if ($use_vals) {
                    # Use vals passed explicitly.
                    $meths->{$f}{value} = $value;
                    push @args, vals => $meths->{$f};
                } else {
                    # Use objects.
                    push @args, objref => $obj;
                }
                $m->comp('/widgets/profile/displayFormElement.mc', @args);
            }
            $m->out("</td>\n");
        }
        # Output any extra fields.
        &$mk_extras($extras, $id, $obj) if $extras;
        if (defined $id && !$read_only) {
            # Output a delete checkbox.
            $m->out("<td>&nbsp;&nbsp;&nbsp;");
            $m->comp('/widgets/profile/checkbox.mc', checked => 0, label_after => 1,
                     value => $id, name => "del_$type");
            $m->out("</td>\n");
        }
    } elsif (!$read_only) {
        # There is no existing row. Output empty fields.
        foreach my $f (@$fields) {
            $m->out('    <td>');
            # Grab any existing value from when the 'Add More' button was
            # clicked.
            $param->{$f} = [ $param->{$f} ] unless ref $param->{$f};
            $meths->{$f}{value} =
              $param->{$f}[ $no_ed->{$f} ? $i - $#$objs - 1 : $i];
            $m->comp('/widgets/profile/displayFormElement.mc', key => $f,
                     vals => $meths->{$f}, name => '', useTable => 0);
            $m->out("</td>\n");
        }
        # Make any extra fields.
        &$mk_extras($extras) if $extras;
        $m->out("<td>&nbsp;</td>\n");
    }
    $m->out("</tr>\n");
}
$m->out("<tr>\n");
unless ($read_only) {
    my $span = @$fields;
    $m->out(qq{<td>$spacer</td>});
    $m->out(qq{<td colspan="$span">});
</%perl>
<& '/widgets/profile/imageSubmit.mc',
  formName => $formName,
  callback => "$widget|add_cb",
  image    => "add_more_lgreen",
  alt      => 'Add More',
&>
<& '/widgets/profile/hidden.mc', 'name' => 'addmore_type', 'value' => $type &>
% }
</table>
<%args>
$no_edit   => []
$no_labels => undef
$reset_key
$type
$objs      => []
$fields    => undef
$incr      => 1
$num       => 4
$label     => 'Add More'
$meths     => undef
$use_vals  => 0
$extras    => undef
$useTable  => 1
$read_only => undef
$param     => {}
$formName  => "theForm"
$deleteLabelOnly => 0
</%args>
<%once>;
my $widget = 'add_more';
# This subref will output extra fields, if necessary.
my $mk_extras = sub {
    my ($extras, $id, $obj) = @_;
    foreach (@$extras) {
        # Execute the coderef, if there is one.
        $_->{sub}->($_, $id, $obj) if $_->{sub};
        # Output the field.
        $m->out("<td>&nbsp;");
        $m->comp('/widgets/profile/displayFormElement.mc', vals => $_,
                 key => $_->{key}, useTable => 0, name => '');
        $m->out("</td>\n");
    }
};
</%once>
<%init>;
# Decrement, because we start from 0.
--$num;
# Grab the current URI.
my $uri = $r->uri;
substr($uri, -1, 1) = '' unless substr($uri, -1) ne '/';
# Get the current state for this widget.
my $data = get_state_data($widget);
my $add;
if ($data->{uri} && $uri eq $data->{uri}) {
    if (defined $data->{$type}{reset_key}
        && $reset_key == $data->{$type}{reset_key}) {
        # The context is the same. Retain the current state.
        $num = $data->{$type}{num};
        $add = $data->{"add_$type"};
        set_state_data($widget, "add_$type");
    }
} else {
    # Clear out the session state.
    clear_state($widget);
}
# Increment the number of rows, if necessary.
$num += $incr if $add;
# Make the minimum equal to the number of existing rows, if that number is
# larger than $num.
$num = $#$objs if $#$objs > $num;
# Set the current state.
@{$data}{'uri', $type} = ($uri, { num => $num, reset_key => $reset_key });
set_state_data($widget, $data);

# Grab the my_meths() data.
unless ($use_vals) {
    my $pkg = get_package_name($type);
    $meths ||= $pkg->my_meths;
    # Fields should default to getting all the fields, in order.
    $fields ||= [ map { $_->{name} } $pkg->my_meths(1) ];
}
# Assemble the list of no_edit fields into a hash.
my $no_ed = { map { $_ => 1 } @$no_edit };
</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/add_more/add_more.mc - The Add More Widget.

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  my $contacts = $user->get_contacts;
  $m->comp('/widgets/add_more/add_more.mc', type => 'contact',
           fields => [qw(type value)], name => 'contact',
           reset_key => $id, objs => $contacts);

=head1 DESCRIPTION

This widget assists in the display and editing of multiple objects of the same
type. The idea is that, if an object can have an unlimited number of other
objects associated with it (e.g., contacts associated with people), the
interface needs to be able to accommodate the user adding as many associated
objects as she would like. This widget assists by displaying the existing
associated objects, plus extra fields to add more objects.

For example, let's say we have a user object with two contacts associated with
it, but you'd like to be able to have a minimum of four sets of fields for
contacts. The first two rows will display the existing two contacts, plus delete
checkboxes next to them. The other two rows will have no values, but can be
filled in by the user and then submitted.

Now let's say the same user has 4 contacts, and you would like to add more. You
go to the user profile and sees the four existing contacts, but no fields to add
more contacts. All you need to do is to click the "Add More" button, and the
profile will be reloaded with the 4 contacts, plus a couple of new, empty rows
into which you can enter new contact information. Once you're done, click "Save"
and the new contacts will be added. The next time that user profile is brought
up, all 6 contacts will be displayed.

While the Add More widget handles the display of each row of input fields, as
well as deciding how many rows to display, managing the changes of each row, as
well as the addition of each row, must be managed by you. How it works is by
relying on arrays of the relevant fields. Each row has fields for each object
that are named the same across rows.

The first field is a hidden field with the ID of the object displayed in that
row. The name of that field is C<"${type}_id">. Thus, if the type argument
passed to add_more.mc is "contact", each hidden field will be named
"contact_id". Rows for which there is no object will not have this field.

Following the ID hidden input, inputs will be put out for each field defined
by the fields argument. Each of these will of course be named across rows. For
the contacts example cited in the Synopsis above, there will be a "type" input
and a "value" input in each row, regardless of whether there's an object for
that row or not.

Finally, a checkbox field will be output. It's name will be C<"del_$type"> and
its value will be the ID of the current object. Delete checkboxes are not output
for rows with no existing object in the $objs anonymous array.

The idea, in processing the rows, is to go through the list of values (in our
contact example, we can use C<@{ $param->{value} }>), and if there is a
corresponding hidden ID field (e.g., $param->{contact_id}), updated it. If there
isn't, then delete it. Then use the delete array (e.g.,
C<@{ $param->{del_contact} }> to delete any IDs found there. Unchecked delete
checkboxes will not have their IDs submitted.

For an example of the Add More widget in practice, see the contacts in a user
profile. You can see how the deltas are handled by the callbacks by looking at
/widgets/profile/user.mc. A standard example demonstrating the Add More widget
(but that doesn't save or delete any records - it just adds more when you click
the "Add More" button), see the widget example file,
/widgets/add_more/index.html.

The Add More widget takes the following arguments:

=over 4

=item *

objs - An anonymous array of existing objects to be displayed. May also pass in
an array of hashrefs - but be sure to pass a true value to use_vals if you do
and a list of methods via the meths argument. See /widgets/add_more/add_more.mc
for an example.

=item *

fields - An anonymous array of the fields to be displayed in each row. The
fields will be looked up for each object's my_meths() hash or the meths passed
via the meths argument. If no values are passed via fields, add_more.mc will use
all of the fields returned by my_meths(1) (does not apply when use_vals is true).

=item *

param - A reference to the %ARGS hash in your element. The add_more widget
uses these values to populate the fields when you add some values, then click
'Add More', but you haven't saved the values yet.

=item *

meths - An anonymous hash of data formatted according to the specification for
the vals argument to displayFormElement. The idea is to override the methods
returned by my_meths(), but it is required that you pass in these values if
use_vals is true and the objects in the objs anonymous array are anonymous
hashes of data rather than objects. The keys in the meths anonymous hash must
correspond to the names of the fields passed in via the fields argument, and to
the keys in the objs anonymous hashes if use_vals is true. See
/widgets/add_more/index.html for an example.

=item *

use_vals - Pass a true value if the items in the objs anonymous hash are
anonymous hashes of data and the meths anonymous hash has values formatted
according the the spec for the vals argument of displayFormElement.

=item *

type - Required. A package key name that will be looked up in order to retrieve
the contents of my_meths() unless use_vals is true. This type should describe
the objects in $objs. The value of this key will also be used to name two inputs
that the Add More widget inserts. The first is a hidden field at the beginning
of each row with the id of the object in that row. If the objects in the $objs
anonymous array are contacts, for example, and type is "contact", then the
beginning of each row of existing contacts will have this field:

  <input type="hidden" name="contact_id" value="<% $obj->get_id %>" />

This allows you to update contacts when they're changed. The second input is
a delete checkbox, which will look like this:

  <input type="checkbox" name="del_contact" value="<% $obj->get_id %>" />

This allows you to delete contacts when the delete checkboxes have been, um,
checked.

=item *

reset_key - Required. A unique identifier for the object that the objects in
$objs are related to. This ID will be cached and compared for each call to
add_more.mc in order to prevent the number of rows created for one object to be
used to display an incorrect number of rows for another object. The type
argument and URI are also used to check for these kinds of changes, so that even
if the reset_key is the same but the object type or URI is different, the cache
will be properly cleared.

=item *

incr - The number of rows to add to the display when the user hits the "Add
More" button. Defaults to 1.

=item *

num - The minimum number of rows to display. Defaults to 4.

=item *

label - The label that will be used for the "Add More" button. Defaults to "Add
More", of course.

=item *

no_labels - If passed a true value, prevents the labels for each column of inputs
from being displayed.

=item *

no_edit - If you'd like some of the fields in existing records not to be
editable, pass them into this anonymous array, and they'll be displayed as
simple text instead. Good for stuff like keywords, where users can delete them,
but not change them.

=item *

extras - Pass in an array reference of extra field $vals arguments (as defined
for /widgets/profile/displayFormElement.mc) to be used for each item. In
addition, you can pass in a "sub" key in $vals that is a subroutine reference.
It will be passed the current $vals hashref, the ID of the current object, and
the current object itself for each row. If the you're using a hashrefs in your
objs arguments rather than objects, the "id" key (if present) will be passed for
each anonymous has in the objs anonymous array. See /widgets/add_more/index.html
for an example.

=back

</%doc>
