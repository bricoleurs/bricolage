
<!-- Start "Cover" -->
%# Lets make this a 3 column cover.
% my @elem = $element->get_elements;
%# Find the elements per column
% my $per_col = int((scalar @elem)/3) + 1;

<table>
<tr>
<%perl>
# Lay these elements out over three columns.
while (scalar @elem) {
    foreach (1..$per_col) {
        my $e = shift @elem || last;
        $burner->display_element($e);
        $m->out('<br />');
    }
}
</%perl>
</tr>
</table>
<!-- End "Cover" -->
