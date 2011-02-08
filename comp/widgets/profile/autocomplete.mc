<%doc>
###############################################################################

=head1 NAME

=head1 SYNOPSIS

  $m->comp("/widgets/profile/autocomplete.mc",
      $disp      => ''
      $value     => ''
      $name      => ''
      $length    => ''
      $maxlength => ''
      $js        => ''
      $width     => ''
      $indent    => ''
 );

=head1 DESCRIPTION

Use to create an autocomplete text input field.

=cut

</%doc>
<%once>;
my $widget = 'autocomplete';
</%once>
<%args>
$object
$disp      => ''
$value     => ''
$name      => ''
$id        => undef
$length    => ''
$size      => ''
$maxlength => ''
$js        => ''
$req       => 0
$width     => ''
$indent    => ''
$useTable  => 1
$localize  => 1
$readOnly  => 0
$class     => undef
$title     => undef
$reset_key => undef
$no_persist => 0
</%args>
<%perl>;
my $sub_widget .= "$widget.$object";

# Reset this widget if the reset key changes.
reset_state($sub_widget, $reset_key);

if ($no_persist) {
    # Do not maintain value if the no_persist flag is set.
    set_state_data($sub_widget, 'value', undef)
} else {
    # Set the default value if one has been passed.
    init_state_data($sub_widget, 'value', $value);
    $value = get_state_data($sub_widget, 'value') if !defined $value || $value eq '';
}

# Set the name we are supposed to use so that we can check it and repopulate.
set_state_data($sub_widget, 'form_name', $name);

my $vals = { disp      => $disp,
             value     => $value,
             props     => { type      => 'text',
                            length    => $size || $length,
                            maxlength => $maxlength,
                            title     => $title,
                            class     => $class,
                          },
             js        => $js,
             req       => $req,
           };

$m->comp("/widgets/profile/displayFormElement.mc",
         key       => $name,
         vals      => $vals,
         width     => $width,
         indent    => $indent,
         useTable  => $useTable,
         localize  => $localize,
         readOnly  => $readOnly,
         id        => $id,
);
$m->comp('/widgets/profile/hidden.mc',
    name    => "$widget|save_value_cb",
    value   => $object,
);
</%perl>
