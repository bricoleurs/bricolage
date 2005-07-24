<div class="page">
<%perl>;
for my $e ($element->get_elements) {
    $m->print('<p>', $e->get_data, "</p>\n");
}
</%perl>
</div>
