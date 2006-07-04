<%args>
$attr
$usePosition => 1
$form_name   => 'theForm'
$useDelete   => 1
$readOnly    => 0
$localize    => 0
$useEdit     => 0
</%args>
<%once>;
my @meta_props = qw(type length maxlength rows cols multiple size precision);
</%once>
<%perl>;
my $num_fields = @$attr;
my $sel_opts = [ map { [ $_ => $_] } 1..$num_fields ];
my $curField = 1;

$m->out(qq{<div id="containerprof"><ul id="attrs">});

foreach my $attr (@$attr) {
    # Assemble the properties.
    my $props = { map { $_ => $attr->{meta}{$_}{value} } @meta_props };

    # Assemble any select/radio values.
    if (my $tmp = $attr->{meta}{vals}{value}) {
        my $val_prop;
        if ($attr->{meta}{type}{value} eq 'codeselect') {
            $val_prop = eval_codeselect($tmp);
        } else {
            foreach my $line (split /\n/, $tmp) {
                # Commas are escaped with a backslash
                # XXX: this should probably check that two items are returned
                # XXX: comp/widgets/container_prof/edit.html contains
                # duplicate code in the DATA TILE DISPLAY section
                my ($v, $l) = split /\s*(?<!\\),\s*/, $line;
                for ($v, $l) { s/\\,/,/g }
                push @$val_prop, [$v, $l];
            }
        }
        $props->{vals} = $val_prop;
    }
    
    # Assemble the vals argument.
    my $vals = {
        value => $attr->{value},
        props => $props,
    };

    (my $attr_name = $attr->{name}) =~ s/\s|\|/_/g; # Replace spaces and pipes with underscores
    $m->out(qq{<li id="attr_$attr_name" class="element clearboth"><h3 class="name">\n});

    # Spit out a hidden field.
    $m->comp('/widgets/profile/hidden.mc',
         value => $attr->{name},
         name => 'attr_name'
     ) if (!$readOnly);

    $m->out($attr->{meta}{disp}{value} . qq{:</h3>});
    
    $m->out(qq{<div class="content">});

    # Spit out the attribute.
    $m->comp('/widgets/profile/displayFormElement.mc',
         key => "attr|$attr->{name}",
         vals => $vals,
         useTable => 0,
         localize => $localize,
         readOnly => $readOnly
    );
    
    $m->out("</div>");
    
    if ($useEdit) {
        $m->out(qq{<div class="edit">\n});

        my $url = '/admin/profile/field_type/' . $attr->{id};
        my $edit_url = sprintf('<a href="%s" class=redLink>%s</a>&nbsp;',
                               $url, $lang->maketext('Edit'));
        $m->out($edit_url);
        $m->out("</div>");
    }

    if ($useDelete) {
    # And spit out a delete checkbox.
        $m->out(qq{<div class="delete">\n});
        $m->comp(
            '/widgets/profile/button.mc',
            disp      => $lang->maketext("Delete"),
            name      => 'delete_' . $attr_name,
            button    => 'delete_red',
            js        => qq[onclick="if (Container.confirmDelete()) { Element.remove(this.parentNode.parentNode); \$('attr_pos').value = Sortable.sequence('attrs'); } return false"],
            useTable  => 0
        );
        $m->out("</div>\n");
    }

    $m->out("</li>\n");
}
$m->out("</ul></div>");
</%perl>

% if ($usePosition) {
<input type="hidden" name="attr_pos" id="attr_pos" value="" />
<script type="text/javascript">
Sortable.create('attrs', { 
    onUpdate: function(elem) { 
        $('attr_pos').value = Sortable.sequence(elem);
    },
    handle: 'name'
});
$('attr_pos').value = Sortable.sequence('attrs');
</script>
% }