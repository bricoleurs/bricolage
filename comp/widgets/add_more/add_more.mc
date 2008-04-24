<table>
<%perl>;
# Output the headers.
unless ($no_labels) {
    $m->out(qq{<thead><tr>\n});
    $m->out(qq{    <th><span class="label">$_</span></th>\n}) for map { $meths->{$_}->{disp} } @$fields;
    $m->out(qq{    <th></th>\n}) unless $read_only || !@$objs; # placeholder for delete column
    $m->out(qq{</tr></thead>\n});
}
$m->out(qq{<tbody id="add-more-$type">});
# Display all the rows.
for my $obj (@$objs) {
        $m->out(qq{<tr>\n});
        # Go through all the fields.
        foreach my $f (@$fields) {
            # Grab the value.
            my $value = $use_vals ? $obj->{$f}
              : $meths->{$f}{get_meth}->($obj,@{ $meths->{$f}{get_args} });
            $m->out(qq{    <td>});
            # Output the field.
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
            $m->out("</td>\n");
        }
        my $id = $use_vals ? $obj->{id} : $obj->get_id;
        if (defined $id && !$read_only) {
            $m->out(qq{<td style="text-align: center;">});
            
            # Output a hidden field with the ID.
            $m->comp('/widgets/profile/hidden.mc', name => "${type}_id", value => $id);
            
            # Output a delete button.
            $m->comp('/widgets/profile/button.mc',
                name => "del_$type\_button",
                js   => qq{onclick="Element.remove(this.parentNode.parentNode); return false"},
                button => 'delete_red',
                useTable => 0
            );
            
            $m->out("</td>\n");
        }
        $m->out(qq{</tr>\n});
}
</%perl>

% if (!$read_only) {
    <tr id="new_<% $type %>">
%    foreach my $f (@$fields) {
        <td>
%       delete $meths->{$f}{value};
        <& '/widgets/profile/displayFormElement.mc', 
            key => $f,
            vals => $meths->{$f}, 
            name => '', 
            useTable => 0
        &>
        </td>
%   }
    <td>
    <& '/widgets/profile/button.mc',
        name => "del_$type\_button",
        js   => qq{onclick="Element.remove(this.parentNode.parentNode); return false"},
        button => 'delete_red',
        useTable => 0
    &>
    </td>
    </tr>
% }
</tbody>
</table>
<script type="text/javascript">
var <% $type %>ElementCache = document.createElement("table");
<% $type %>ElementCache.appendChild($('new_<% $type %>'));
% unless (scalar @$objs) {
$('add-more-<% $type %>').appendChild(<% $type %>ElementCache.firstChild.cloneNode(true));
% }
</script>

% unless ($read_only) {
<& '/widgets/profile/button.mc',
    name   => "add_more_$type",
    button => "add_more_lgreen",
    disp   => 'Add More',
    useTable => 0,
    js     => qq{onclick="\$('add-more-$type').appendChild(} . $type . qq{ElementCache.firstChild.cloneNode(true)); return false"}
&>
<& '/widgets/profile/hidden.mc', 'name' => 'addmore_type', 'value' => $type &>
% }

<%args>
$no_labels => undef
$type
$objs      => []
$fields    => undef
$meths     => undef
$use_vals  => 0
$read_only => undef
$param     => {}
</%args>
<%init>;
my $num = scalar @$objs || 1;

# Grab the my_meths() data.
unless ($use_vals) {
    my $pkg = get_package_name($type);
    $meths ||= $pkg->my_meths;
    # Fields should default to getting all the fields, in order.
    $fields ||= [ map { $_->{name} } $pkg->my_meths(1) ];
}
</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/add_more/add_more.mc - The Add More Widget.

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

  my $contacts = $user->get_contacts;
  $m->comp('/widgets/add_more/add_more.mc', type => 'contact',
           fields => [qw(type value)], name => 'contact',
           objs => $contacts);

=head1 DESCRIPTION

This widget assists in the display and editing of multiple objects of the same
type. The idea is that, if an object can have an unlimited number of other
objects associated with it (e.g., contacts associated with people), the
interface needs to be able to accommodate the user adding as many associated
objects as she would like. This widget assists by displaying the existing
associated objects, plus extra fields to add more objects.

For example, let's say we have a user object with two contacts associated with
it. The two rows will display the existing two contacts, plus delete buttons 
next to them. Each time the "Add More" button is clicked, it will display 
another field so that the user can add another value.

While the Add More widget handles the display of each row of input fields, 
managing the changes of each row, as well as the addition of each row, must be 
managed by you. It works by relying on arrays of the relevant fields. Each row
has fields for each object that are named the same across rows.

The first field is a hidden field with the ID of the object displayed in that
row. The name of that field is C<"${type}_id">. Thus, if the type argument
passed to add_more.mc is "contact", each hidden field will be named
"contact_id". Rows for which there is no object will not have this field.

Following the ID hidden input, inputs will be output for each field defined by
the C<fields> argument. For the contacts example cited in the Synopsis above, 
there will be a "type" input and a "value" input in each row, regardless of 
whether there's a pre-existing object for that row or not.

When the delete button is clicked, the row is removed from the page via
JavaScript, so that when Save is clicked, the values in that row will not be
included.

When processing the rows, go through the list of values (in our contact 
example, we can use C<@{ $param->{value} }>), and update the object if there is
a corresponding hidden ID field (e.g., C<$param->{contact_id}>). If there 
isn't, then delete it. Then loop through all of the existing objects and check
to see if their IDs exist in C<$param->{contact_id}>.  If they don't, delete 
them.

For an example of the Add More widget in practice, see the contacts in a user
profile. You can see how the deltas are handled by the callbacks by looking at
L<Bric::App::Callback::Util::Contact>.

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
the keys in the objs anonymous hashes if use_vals is true.

=item *

use_vals - Pass a true value if the items in the objs anonymous hash are
anonymous hashes of data and the meths anonymous hash has values formatted
according the the spec for the vals argument of displayFormElement.

=item *

type - Required. A package key name that will be looked up in order to retrieve
the contents of my_meths() unless use_vals is true. This type should describe
the objects in $objs. The value of this key will also be used to name the 
hidden field with the id of the object in that row. If the objects in the 
C<$objs> anonymous array are contacts, for example, and type is "contact", then
each row of existing contacts will have this field:

  <input type="hidden" name="contact_id" value="<% $obj->get_id %>" />

This allows you to update contacts when they're changed.

=item *

no_labels - If passed a true value, prevents the labels for each column of inputs
from being displayed.

=back

</%doc>
