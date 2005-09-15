 <table border="0" width="578">
% foreach my $spec (@{ $conf{$field_type} }) {
<tr><td valign="top" width="578">
<& $spec->[2],
   spec  => $spec,
   field => $field,
   meta  => $meta,
&>
</td></tr>
% }
</table>
<%def .text>
<%args>
$field
$spec
$meta
</%args>
<& /widgets/profile/text.mc,
   name  => $spec->[0],
   value => $meta->{$spec->[0]}->{get_meth}->($field),
   disp   => $spec->[1],
   size  => 32,
&>
</%def>
<%def .number>
<%args>
$field
$spec
$meta
</%args>
<& /widgets/profile/text.mc,
   name  => $spec->[0],
   value => $meta->{$spec->[0]}->{get_meth}->($field),
   disp  => $spec->[1],
   size  => 6,
&>
</%def>
<%def .textarea>
<%args>
$field
$spec
$meta
</%args>
<& /widgets/profile/textarea.mc,
   name  => $spec->[0],
   value => $meta->{$spec->[0]}->{get_meth}->($field),
   disp  => $spec->[1],
&>
</%def>
<%def .check>
<%args>
$field
$spec
$meta
</%args>
% my $val = $meta->{$spec->[0]}->{get_meth}->($field);
<& /widgets/profile/checkbox.mc,
   name     => $spec->[0],
   value    => $val,
   disp     => $spec->[1],
   checked  => $val,
   useTable => 1,
&>
</%def>
<%def .precision>
<%args>
$field
$spec
$meta
</%args>
<& '/widgets/profile/select.mc',
   name    => $spec->[0],
   value   => $meta->{$spec->[0]}->{get_meth}->($field),
   disp    => $spec->[1],
   options => Bric::Util::Time::PRECISIONS,
&>
</%def>
<%args>
$field
</%args>
<%init>;
my $meta = $field->my_meths;
my $field_type = $meta->{field_type}->{get_meth}->($field);


# Note: don't confuse $meta->{'disp'} with a row in %conf
# beginning with 'disp'
</%init>
<%once>;
my %conf = (
    # XXX: how this turned into a hash of 2-d arrays, i'm not sure...
    # feel free to change it to something better
    'text' => [
        [ 'name'        => 'Label',         '.text'      ],
        [ 'default_val' => 'Default Value', '.text'      ],
        [ 'length'      => 'Size',          '.number'    ],
        [ 'max_length'  => 'Maximum size',  '.number'    ],
    ],
    'radio' => [
        [ 'name'        => 'Group Label',    '.text'      ],
        [ 'default_val' => 'Default Value',  '.text'      ],
        [ 'vals'        => 'Options, Label', '.textarea'  ],
    ],
    'checkbox' => [
        [ 'name'        => 'Label',          '.text'      ],
        [ 'default_val' => 'Checked',        '.check'     ],
    ],
    'pulldown' => [
        [ 'name'        => 'Label',          '.text'      ],
        [ 'default_val' => 'Default Value',  '.text'      ],
        [ 'vals'        => 'Options, Label', '.textarea'  ],
    ],
    'select' => [
        [ 'name'        => 'Label',          '.text'      ],
        [ 'default_val' => 'Default Value',  '.text'      ],
        [ 'length'      => 'Size',           '.number'    ],
        [ 'vals'        => 'Options, Label', '.textarea'  ],
        [ 'multiple'    => 'Allow multiple', '.check'     ],
    ],
    'codeselect' => [
        [ 'name'        => 'Label',          '.text'      ],
        [ 'default_val' => 'Default Value',  '.text'      ],
        [ 'length'      => 'Size',           '.number'    ],
        [ 'vals'        => 'Code',           '.textarea'  ],
        [ 'multiple'    => 'Allow multiple', '.check'     ],
    ],
    'textarea' => [
        [ 'name'        => 'Label',          '.text'      ],
        [ 'default_val' => 'Default Value',  '.textarea'  ],
        [ 'max_length'  => 'Max size',       '.number'    ],
        [ 'rows'        => 'Rows',           '.number'    ],
        [ 'cols'        => 'Columns',        '.number'    ],
    ],
    'wysiwyg' => [
        [ 'name'        => 'Label',          '.text'      ],
        [ 'rows'        => 'Rows',           '.number'    ],
        [ 'cols'        => 'Columns',        '.number'    ],
    ],
    'date' => [
        [ 'name'        => 'Caption',        '.text'      ],
        [ 'precision'   => 'Precision',      '.precision' ],
    ],
);
</%once>
