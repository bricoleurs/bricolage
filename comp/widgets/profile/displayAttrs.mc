% if ($usePosition) {
<script>
var selectOrderNames = new Array("attr_pos")
</script>
% }
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
use Bric::App::Util qw(:msg :redir :history);

my @meta_props = qw(type length maxlength rows cols multiple size precision);
</%once>
<%perl>;
my $num_fields = @$attr;
my $sel_opts = [(1..$num_fields)];
my $curField = 1;
my $width = 578 - 100 * $useDelete - 100 * $usePosition;

$m->out(qq{<table>});

foreach my $attr (@$attr) {
    # Assemble the properties.
    my $props = { map { $_ => $attr->{meta}{$_}{value} } @meta_props };

    # Assemble any select/radio values.
    if (my $tmp = $attr->{meta}{vals}{value}) {
        my $val_prop;
        if ($attr->{meta}{type}{value} eq 'codeselect') {
            # For a `codeselect', evaluate the perl code,
            # which must return a list of hashrefs,
            # to put it in the form that `select' normally expects.
            # XXX: This is very unsafe, but they need to be able
            # to do things like DBI queries; would that work with Safe?
            my $items = eval "$tmp";
            if (ref $items eq 'ARRAY' and !(@$items % 2)) {
                for (my $i = 0; $i < @$items; $i += 2) {
                    push @$val_prop, [$items->[$i], $items->[$i+1]];
                }
            } else {
                add_msg("Invalid codeselect code (didn't return an array ref of even size)");
                redirect(last_page());
            }
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
        disp  => $attr->{meta}{disp}{value},
    };

    $m->out(qq{<tr><td>\n});

    # Spit out a hidden field.
    $m->comp('/widgets/profile/hidden.mc',
         value => $attr->{name},
         name => 'attr_name'
     ) if (!$readOnly);

    # Spit out the attribute.
    $m->comp('/widgets/profile/displayFormElement.mc',
         key => "attr|$attr->{name}",
         vals => $vals,
         useTable => 1,
         width => $width,
         indent => FIELD_INDENT,
         localize => $localize,
         readOnly => $readOnly
     );

    $m->out("</td>");

    if ($usePosition) {
        $m->out(qq{<td class="position">\n});
        $m->comp(
            '/widgets/profile/select.mc',
            disp     => '',
            value    => $curField++,
            options  => $sel_opts,
            useTable => 0,
            name     => 'attr_pos',
            readOnly => $readOnly,
            js       => qq{onChange="reorder(this, '$form_name')"}
        );
        $m->out("</td>");
    }

    if ($useEdit) {
        $m->out(qq{<td class="edit">\n});

        my $url = '/admin/profile/element_type_data/' . $attr->{id};
        my $edit_url = sprintf('<a href="%s" class=redLink>%s</a>&nbsp;',
                               $url, $lang->maketext('Edit'));
        $m->out($edit_url);
        $m->out("</td>");
    }

    if ($useDelete) {
    # And spit out a delete checkbox.
        $m->out(qq{<td class="delete">\n});
        $m->comp(
            '/widgets/profile/checkbox.mc',
            checked => 0,
            label_after => 1,
            disp => 'Delete',
            value => $attr->{name},
            name => "delete_attr",
            useTable => 0,
            readOnly => $readOnly
        );
        $m->out("</td>\n");
    }

    $m->out("</tr>\n");
}
$m->out("</table>");
</%perl>
