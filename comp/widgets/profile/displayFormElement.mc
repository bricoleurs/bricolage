<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  $m->comp("/widgets/profile/displayFormElement.mc",
          vals => $vals,
          key => 'color'
          js => 'optional script'
  );

  $m->comp("/widgets/profile/displayFormElement.mc",
          key => "fname",
          objref => $obj,
          js => 'optional script'
  );

=head1 DESCRIPTION

There are two usages:

=over 4

=item 1)

Pass a vals hash with values with which to populate the element, and properties
of the form element, display form element html. For example:

  my $vals = {
               disp      => "Pick color",
               value     => 'Red', # optional, if you want one preselected
               props     => { type => 'select',
                              vals => { 1 => 'Red',
                                        2 => 'Blue',
                                        3 => 'Orange'
                                      }
                            }
             };

  $m->comp("/widgets/profile/displayFormElement.mc",
           vals => $vals,
           key  => 'color',
           js   => 'optional javascript string'
  );

=item 2)

Pass an object and field name. The element will introspect the object and
populate the form field with whatever it finds there. For example:

  $m->comp("/widgets/profile/displayFormElement.mc",
           key    => "fname",
           objref => $obj,
           js     => 'optional javascript string'
  );

=back

All possible attributes of a form field are supported, but all have defaults.
If you choose to override the default javascript, none of the default behavior
(ie, setting the changed flag) will be implemented, unless the overriding
string does so explicitly.  This is a feature, as it allows the onChange
to be eliminated entirely if needed.

The types of form fields supported are:

=over 4

=item *

text

=item *

password

=item *

select

=item *

codeselect - select list obtained from perl code

=item *

hidden

=item *

textarea

=item *

checkbox

=item *

radio

=item *

single_rad - A single radio input, rather than an array of them.

=item *

date - Simple date formatting.

=back

=cut

</%doc>
<%args>
$localize => 1
$vals     => 0
$name     => undef
$key      => ''
$objref   => 0
$js       => ''
$useTable => 1
$readOnly => 0
$width    => undef
$indent   => undef
$cols     => undef
$rows     => undef
$id       => undef
</%args>
<%perl>;
$vals->{props}{cols} = $cols if $cols;
$vals->{props}{rows} = $rows if $rows;
$localize_opts = $localize;

if ($objref) {
    # fetch ref to introspection hash
    my $methods = $objref->my_meths;
    # basically, switch on this value to determine form element type.
    my $formType = $methods->{$key}{props}{type} || return;
    # Determine if we're fetching a date, and if so, get it in the right format.
    my @date_arg = $formType eq 'date' ? (ISO_8601_FORMAT) : ();
    # Fetch the value.
    my $value = $methods->{$key}{get_meth}->($objref, @date_arg,
      @{ $methods->{$key}{get_args} }) if $methods->{$key}{get_meth};
    $width  ||= 578;
    $indent ||= FIELD_INDENT;
    my $label    =  "label" . ($methods->{$key}{req} ? " required" : "");

    # Get the name and localize it, if necessary.
    $name = $methods->{$key}{disp} unless defined $name;
    $name = $lang->maketext($name) if $localize && $name && $formType ne 'date';

    # Assemble javascript.
    if (! $methods->{$key}{set_meth} ) {
        # Don't overwrite another onFocus method.
        $js .= ' onFocus="blur();"' unless index($js, 'onFocus') != -1;
    }

    # Execute the formatting code.
    $formSubs{$formType}->($key, $methods->{$key}, $value, $js, $name, $width,
                           $indent, $useTable, $label, $readOnly, $id)
      if $formSubs{$formType};
} elsif ($vals) {
    my $value     = $vals->{value};
    my $formType  = $vals->{props}{type} || return;;
    $width        ||= $vals->{width}  ? $vals->{width}  : 578;
    $indent       ||= $vals->{indent} ? $vals->{indent} : FIELD_INDENT;
    my $label     =  "label" . ($vals->{req} ? " required" : "");

    # Get the name and localize it, if necessary.
    $name = $vals->{disp} unless defined $name;
    $name = $lang->maketext($name) if $localize && $name && $formType ne 'date';
    $js = $vals->{js} || $js || '';

    # Execute the formatting code.
    $formSubs{$formType}->($key, $vals, $value, $js, $name, $width, $indent,
                           $useTable, $label, $readOnly, $id)
      if $formSubs{$formType};
} else {
    # Fuhgedaboudit!
}

return $key;

</%perl>
<%once>;
my $localize_opts = 1;
my $opt_sub = sub {
    my ($k, $v, $value) = @_;
    for ($k, $v, $value) { $_ = '' unless defined $_ }
    $v = escape_html($v) if $v;
    my $out = qq{                <option value="$k"};
    # select it if there's a match
    $out .= qq{ selected="selected"} if (ref $value && $value->{$k}) || $k eq $value;
    return "$out>". ($localize_opts ? $lang->maketext($v) : $v) . "</option>\n";
};

my $len_sub = sub {
    my ($vals) = @_;
    my $max = $vals->{props}{maxlength};
    my $len = $vals->{props}{length} || 32;
    return qq{ size="$len"} . ($max ? qq{ maxlength="$max"} : '');
};

my $inpt_sub = sub {
    my ($type, $key, $vals, $value, $js, $name, $width, $indent,
        $useTable, $label, $readOnly, $id, $extra) = @_;

    my @classes = ref $vals && defined $vals->{props}{class}
        ? ($vals->{props}{class})
        : ();
    push @classes, "textInput" if ($type eq "text" || $type eq "password");
    push @classes, "required" if ($vals->{req});
    my $class = ' class="' . join(" ", @classes) . '"' if scalar @classes;

    $extra ||= '';
    my $out;
    my $disp_value = defined $value && $type ne 'password'
      ? ' value="' . escape_html($value) . '"'
      : '';
    $disp_value = defined $value && $type eq 'image'
      ? ' value="' . escape_html($value) . '"'
      : $disp_value;
    my $src = ref $vals && defined $vals->{props}{src}
      ? ' src="' . $vals->{props}{src} . '"'
      : '';
    my $title = ref $vals && defined $vals->{props}{title}
      ? ' title="' . $vals->{props}{title} . '"'
      : '';
    $key = escape_html($key) if $key;
    $js = $js ? " $js" : '';

    (my $idout = $id || $key) =~ s/\|/_/g;
    if ($type ne "checkbox" && $type ne "hidden") {
        $out  = qq{<div class="row">\n} if $useTable;
        $out .= qq{        <div class="$label">} if $useTable;
        if ($name) {
            $out .= qq{<label for="$idout">} unless $readOnly;
            $out .= qq{$name};
            $out .= qq{</label>} unless $readOnly;
            $out .= ":";
        } else {
            $out .= ($useTable) ? '&nbsp;' : '';
        }
        $out .= qq{</div>\n} if $useTable;

        $out .= qq{        <div class="input">} if $useTable;
        if (!$readOnly) {
            $out .= qq{<input type="$type"$class name="$key" id="$idout"$src$title$disp_value$extra$js />};
        } else {
            $out .= qq{<p>};
            $out .= ($type ne "password") ? $value : "********";
            $out .= qq{</p>};
        }
        $out .= qq{</div>\n} if $useTable;

    } else {

        $out  = qq{<div class="row">\n} if $useTable;
        $out .= qq{        <div class="$label">$name:</div>\n} if $name && !$vals->{props}{label_after};

        if (!$readOnly) {
            $out .= qq{        <div class="input">} if $useTable;
            $out .= qq{<input type="$type" };
            $out .= qq{id="$id" } if $id;
            $out .= qq{name="$key"$src$disp_value$extra$js />};
            $out .= qq{</div>\n} if $useTable;
        } else {
            if ($type eq "radio" || $type eq "checkbox") {
                $out .= " ". $lang->maketext($value ? "Yes" : "No");
                $out .= "<br />";
            }
        }

        $out .= qq{ <span class="label">$name</span>&nbsp;}
          if $name && $vals->{props}{label_after};
    }

    $out .= "    </div>\n" if $useTable;

    $m->out($out);
};

my %formSubs = (
        text => sub { &$inpt_sub('text', @_, &$len_sub($_[1]) ) },
        password => sub { &$inpt_sub('password', @_, &$len_sub($_[1]) ) },
        hidden => sub { &$inpt_sub('hidden', @_) },
        image => sub { &$inpt_sub('image', @_) },

        date => sub {
            my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
                $label, $readOnly) = @_;
            $m->comp("/widgets/select_time/select_time.mc",
                     base_name => $key,
                     def_date  => $value,
                     useTable  => $useTable,
                     width     => $width,
                     disp      => $name,
                     read_only => $readOnly,
                     precision => $vals->{props}{precision},
                 );
        },

        checkbox => sub {
            my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
                $label, $readOnly, $id) = @_;
            my $extra = '';
            if (exists $vals->{props}{chk}) {
                $extra .= ' checked="checked"' if $vals->{props}{chk}
            } elsif ($value) {
                $extra .= ' checked="checked"';
            }
            $extra .= qq{ id="$id"} if defined $id;
            $indent -= 5 if ($useTable && !$readOnly);
            &$inpt_sub('checkbox', $key, $vals, $value, $js, $name, $width,
                       $indent, $useTable, $label, $readOnly, $id, $extra);
        },

        textarea => sub {
            my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
                $label, $readOnly) = @_;
            my $rows =  $vals->{props}{rows} || 5;
            my $cols = $vals->{props}{cols}  || 30;

            my $out;
            $out .= qq{<div class="row">\n} if $useTable;
            $out .= $name ? qq{        <div class="$label">$name:</div>\n} : '';
            $value = defined $value ? escape_html($value) : '';
            $key = $key ? escape_html($key) : '';

            $out .= qq{        <div class="input">\n} if $useTable;
            if (!$readOnly) {
            $js = $js ? " $js" : '';
            my $uniquename = $key;
            $uniquename =~ s/[\||_]//g;
            # if we've set a maximum length then display the textcounter
            if ($vals->{props}{maxlength}) {
                # use a 'nice' unique name for js call, IE doesn't like | or _
                my $upval = length($value);
                my $dwval = $vals->{props}{maxlength} - $upval;
                my $textstring = $lang->maketext('Characters')
                                  . qq {: <span id="textCountUp$uniquename">$upval</span> }
                                  . $lang->maketext('Remaining')
                                  . qq{: <span id="textCountDown$uniquename">$dwval</span><br />};
                my $functioncode = "textCount('$uniquename',$vals->{props}{maxlength})";
                $out .= qq{$textstring\n};
                $out .= qq{            <div class="textarea">}  if $useTable;
                $out .= qq{            <textarea id="$uniquename" }
                  . qq{onkeyup="$functioncode"\n onkeydown="$functioncode"\n }
                  . qq{name="$key" rows="$rows" cols="$cols"}
                  . qq{ wrap="soft" $js>\n$value</textarea>};
                $out .= qq{            </div>\n}  if $useTable;
            } else {
                $out .= qq{            <div class="textarea">}  if $useTable;
                $out .= qq{            <textarea name="$key" id="$uniquename" rows="$rows" cols="$cols" width="200"}
                  . qq{ wrap="soft" $js>$value</textarea>\n};
                $out .= qq{            </div>\n}  if $useTable;
            }
        } else {
            $out .= $value;
        }

        $out .= qq{        </div>\n} if $useTable;
        $out .= qq{    </div>\n} if $useTable;
        $m->out($out);
    },

        wysiwyg => sub {
            my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
                $label, $readOnly) = @_;
            my $rows =  $vals->{props}{rows} || 5;
            my $cols = $vals->{props}{cols}  || 30;

            my $out;
            $out .= qq{<div class="row">\n} if $useTable;
            $out .= $name ? qq{        <div class="$label">$name:</div>\n} : '';
            $value = defined $value ? escape_html($value) : '';
            $key = $key ? escape_html($key) : '';

            $out .= qq{        <div class="input">\n} if $useTable;
            if (!$readOnly) {
                if (lc(WYSIWYG_EDITOR) eq 'js-quicktags') {
                    $out .= qq{
 <script type="text/javascript">
   edToolbar('$key');
 </script>
}
                }
                $js = $js ? " $js" : '';
                $out .= qq{            <textarea name="$key" id="$key" rows="$rows" cols="$cols" width="200"}
                     . qq{ wrap="soft" class="textArea"$js>$value</textarea><br />\n};

                if (lc(WYSIWYG_EDITOR) eq 'xinha' || lc(WYSIWYG_EDITOR) eq 'htmlarea') {
                    $out .= qq{
 <script type="text/javascript">
   editors.push("$key");
 </script>
}
                }
        } else {
            $out .= $value;
        }

        $out .= qq{        </div>\n} if $useTable;
        $out .= qq{    </div>\n} if $useTable;
        $m->out($out);
    },

        select => sub {
            my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
                $label, $readOnly, $id) = @_;
            $key = escape_html($key) if $key;
            my $values = $vals->{props}{vals};
            my $ref    = ref $values;

            my $only_one = $ref eq 'ARRAY' ? @$values == 1 : keys %$values == 1;

            # Make the values a reference if this is a multiple select list.
            # XXX It would be better if the calling code could call
            # get_values(), instead.
            $value = { map { $_ => 1 } split /__OPT__/, $value }
              if $vals->{props}{multiple};

            $m->print(qq{<div class="row">\n}) if $useTable;
            $m->print(qq{    <div class="$label">$name:</div>\n}) if $name;
            $m->print('<br />') if !$useTable && $name;
            $m->print(qq{        <div class="input">\n}) if $useTable;

            if ($readOnly) {
                # Just output the value.
                $m->print(escape_html($value));
            }

            elsif ($only_one) {
                # Output the value and a hidden field.
                my ($val, $lab) = $ref eq 'ARRAY'
                    ? ref $values->[0] ? @{$values->[0]} : ($values->[0]) x 2
                    : ((keys %$values)[0], (values %$values)[0]);
                $m->print(escape_html($lab));
                $m->comp(
                    'hidden.mc',
                    name  => $key,
                    id    => $id,
                    value => $val,
                );
            }

            else {
                # Output the select list.
                $js = $js ? " $js" : '';
                $m->print(
                    qq{            <select name="$key" size="},
                    $vals->{props}{size} || ($vals->{props}{multiple} ? 5 : 1),
                    '"'
                );
                $m->print(' multiple="multiple"') if $vals->{props}{multiple};
                $m->print(qq{ id="$id"}) if defined $id;
                $m->print("$js>\n");

                # Iterate through values to create options.
                if ($ref eq 'HASH') {
                    # Might need to make sure that the key '' sorts first. See
                    # how it was done in rev_1_8.
                    for my $opt (
                        sort { $a->[2] cmp $b->[2] }
                        map  { [ $_ => $values->{$_}, lc $values->{$_} ] }
                        keys %$values
                    ) {
                        $m->print($opt_sub->(@{$opt}[0, 1], $value));
                    }
                }

                elsif ($ref eq 'ARRAY') {
                    for my $k (@$values) {
                        $m->print($opt_sub->((ref $k ? @$k : ($k, $k)), $value));
                    }
                }

                $m->print("</select>\n") unless $readOnly;
            }

            $m->print("        </div>\n    </div>\n") if $useTable;
        },

        radio => sub {
            my ($key, $vals, $value, $js, $name, $width, $indent, $useTable,
                $label, $readOnly, $id) = @_;
            my $out = '';
            $out .= qq{<div class="row">\n} if $useTable;

            # print caption for the group
            $out .= qq{    <div class="$label">$name:</div>\n} if $name;
            $out .= qq{    <div class="input">\n} if $useTable;
            if ($readOnly) {
                # Find the selected value
                my $values = $vals->{props}{vals};
                my $ref = ref $values;
                if ($ref eq 'HASH') {
                    foreach my $k (sort { $values->{$a} cmp $values->{$b} }
                                   keys %$values) {
                        $out .= $values->{$k} if ( $value eq $values->{$k});
                    }
                } elsif ($ref eq 'ARRAY') {
                    foreach my $k (@$values ) {
                        $k = [$k, $k] unless ref $k;
                        $out .= $k->[1] if ($value eq $k->[0]);
                    }
                }
            }
            $out .= "</div></div>" if $useTable;
            $m->out($out);

            if (!$readOnly) {
                # Iterate through the values and draw each button:
                my $values = $vals->{props}{vals};
                my $ref = ref $values;
                if ($ref eq 'HASH') {
                    foreach my $k (sort { $values->{$a} cmp $values->{$b} }
                                   keys %$values) {
                        &$inpt_sub('radio', $key, {}, $k, $js, $values->{$k},
                                   $width, $indent, $useTable, $label, $readOnly,
                                   $id, $value eq $k ? ' checked="checked"' : '');
                        $m->out("<br />\n") if (!$useTable);
                    }
                } elsif ($ref eq 'ARRAY') {
                    foreach my $k (@$values ) {
                        $k = [$k, $k] unless ref $k;
                        &$inpt_sub('radio', $key, $k->[0], $k->[0], $js, $k->[1],
                                   $width, $indent, $useTable, $label, $readOnly,
                                   $id, $value eq $k->[0] ? ' checked="checked"' : '');
                        $m->out("<br />\n") if (!$useTable);
                    }
                }
            }
        },
        single_rad => sub {
            my ($key, $vals, $value, $js, $name) = @_;
            if (exists $vals->{props}{chk}) {
                push @_, ' checked="checked"' if $vals->{props}{chk}
            } elsif ($value) {
                push @_, ' checked="checked"';
            }
            &$inpt_sub('radio', @_);
        }
);
# pulldown is the same as select.
# codeselect is the same as select, but values are evaluated perl.
$formSubs{codeselect} = $formSubs{pulldown} = $formSubs{select};
</%once>
