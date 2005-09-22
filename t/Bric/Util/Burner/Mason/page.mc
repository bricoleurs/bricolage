<div class="page">
<%perl>;
for my $e ($element->get_elements) {
    $m->print('<p>', $e->get_value, "</p>\n");
}
</%perl>
</div>
