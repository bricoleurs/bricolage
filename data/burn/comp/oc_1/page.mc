<!-- Start "Page" -->
<%perl>
foreach my $e ($element->get_elements) {
    my $key_name = $e->get_key_name;
    if ($key_name eq 'paragraph') {
        $m->out('<p>'.$e->get_data.'</p>');

    } elsif ($key_name eq 'pull_quote') {
        $burner->display_element($e);

    } elsif ($key_name eq 'inset') {
        $burner->display_element($e);

    }
}
</%perl>

<hr />

%# $burner numbers pages from '0' not '1'.
% my $pnum = $burner->get_page + 1;

%# Show 'previous' link
% my $prev = $element->get_data('previous');
% if ($prev) {
<a href="index<% $pnum-2 != 0 ? $pnum-2 : '' %>.html">
&lt;&lt;&lt; Page <% $pnum - 1 %> : </a>
<% $prev %>
% }

&nbsp;&nbsp;&nbsp;

%# Show 'next' link
% my $next = $element->get_data('next');
% if ($next) {
<% $next %>
<a href="index<% $pnum %>.html">
 : Page <% $pnum + 1 %> &gt;&gt;&gt;
</a>
% }

<!-- End "Page" -->
