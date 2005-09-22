<!-- Start "Related Stories" -->
% my @rel = $element->get_elements;

% if (@rel > 0) {
<table>

% foreach my $rs (@rel) {
<tr><td>
% $burner->display_element($rs);
</td></tr>
% }

</table>
% }
<!-- End "Related Stories" -->
