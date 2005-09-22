<%perl>;
for my $e ($element->get_elements(qw(header para _pull_quote_))) {
    my $kn = $e->get_key_name;
    if ($kn eq 'para') {
        $m->print('<p>', $e->get_value, "</p>\n");
    } elsif ($kn eq 'header') {
        # Test sdisplay_element() on a field.
        $m->print('<h3>', $burner->sdisplay_element($e), "</h3>\n");
    } elsif ($kn eq '_pull_quote_' && $e->get_object_order > 1) {
        # Test sdisplay_element() on a container.
        $m->print($burner->sdisplay_element($e));
    } else {
        # Test display_element().
        $burner->display_element($e);
    }
}
$burner->display_pages('_page_');
</%perl>
