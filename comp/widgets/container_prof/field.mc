<h3 class="name"><% $vals->{props}{disp} %>:</h3>
<div class="content">
<& '/widgets/profile/displayFormElement.mc',
  key      => $key,
  vals     => $vals,
  useTable => 0,
  localize => 0
&>

% if ($element->is_autopopulated()) {
<div class="autopopulated">
    <& '/widgets/profile/hidden.mc',
        name    => "$widget|lock_val_cb",
        value   => $element->get_id,
    &>
    &nbsp;Lock Val: 
    <& '/widgets/profile/checkbox.mc',
        name    => "$widget|lock_val_" . $element->get_id,
        checked => ($element->is_locked ? 1 : 0),
    &>
</div>
% }

% unless ($no_del) {
    <& '/widgets/profile/button.mc',
        disp      => $lang->maketext("Delete"),
        name      => 'delete_' . $name,
        button    => 'delete_red',
        js        => qq{onclick="Container.deleteElement('subelement_$name'); return false;"},
        useTable  => 0 
    &>
% }
</div>

<%args>
$widget
$element
</%args>

<%init>
my $at_obj = $element->get_field_type;
my $name = 'dat' . $element->get_id;
my $vals = { props => {
    type      => $at_obj->get_widget_type,
    disp      => $at_obj->get_name,
    length    => $at_obj->get_length,
    size      => $at_obj->get_length,
    cols      => $at_obj->get_cols,
    rows      => $at_obj->get_rows,
    maxlength => $at_obj->get_max_length,
    precision => $at_obj->get_precision,
    vals      => $at_obj->get_vals,
    multiple  => $at_obj->get_multiple,
}};

my $key =  $widget . '|' . $element->get_id;
my $no_del = $at_obj->get_required && $element->get_object_order == 1;


# Get the value.
$vals->{value} = $element->get_value(ISO_8601_FORMAT)
    || $at_obj->get_default_val;
if ($vals->{props}{type} eq 'checkbox') {
    $vals->{props}{chk} = $vals->{value};
    $vals->{value} = 1;
}

# Set the array of possible values, if necessary.
if ( my $tmp = $vals->{props}{vals} ) {
    if ($vals->{props}{type} eq 'codeselect') {
        $vals->{props}{vals} = eval_codeselect($tmp);
    } else {
        my $val_prop;
        foreach my $line (split /\n/, $tmp) {
            # (c.f. comp/widgets/profile/displayAttrs.mc)
            my ($v, $l) = split /\s*(?<!\\),\s*/, $line;
            for ($v, $l) { s/\\,/,/g }
            push @$val_prop, [$v, $l];
        }
        $vals->{props}{vals} = $val_prop;
    }
}
</%init>