% if ($addition) {
<div class="addnewitem">
    <a href="<% $addition->[1] %>">
        <% $lang->maketext($addition->[0]." a New ". ($addition->[2] || get_class_info($object)->get_disp_name)) %>
    </a>
</div>
% }
<!-- table header display -->
<table class="listManager">
  <tr>
<%perl>;
  my $field_disp = shift @$data;
  # Output the table header.
  foreach my $i (0..$#{$fields}) {
      my $f = $fields->[$i];
      my $disp = $lang->maketext(shift @$field_disp);

      my ($sort_sign, $class);
      if ($userSort && $sortBy eq $f) {
          $class = qq{ class="}
              . (($sortOrder =~ /^descending/) ? "sortup" : "sortdown")
              . qq{"};
          $sort_col  = $i;
          $sort_sign = '-' if ($userSort && $sortOrder !~ /^descending$/);
      }

      $m->out(qq{    <th$class>});

      # Only make a link if user sorting is enabled.
      if ($userSort) {
          $m->out(qq{<a href="$url?listManager|sortBy_cb=$sort_sign$f">} . ($disp || "") . "</a>");
      } else {
          $m->out($disp);
      }

      $m->out("</th>\n");
  }

  # Adjust the table size.
  if (scalar @$fields < $cols) {
      $m->out(qq{<th colspan="} . ($cols - scalar @$fields) . qq{"></th>});
  }
</%perl>
  </tr>
%# Output the rows of data
% my $first;
% # here's where the rows diplayed are limited
% my $i = 0;
% for my $row (0..$#{$data}) {
% my $o_id = shift @{$data->[$row]};
% my $class = qq{ class="} . ($row % 2 ? "odd" : "even") . qq{"};
  <tr<% $class %><% $featured->{$o_id} ? " bgcolor=\"$featured_color\"" : "" %>>
<%perl>;
  # Output for each field.
  my $remainingCols = $cols;
  for my $class_idx (0..$#{$data->[$row]}) {
      my $val   = $data->[$row]->[$class_idx];
      my $class = qq{ class="selected"} if $class_idx == $sort_col;
      $m->out(qq{    <td$class>$val</td>\n});
      $remainingCols--;
  }

  if ($actions) {
      foreach my $class_idx (0..$#{$actions->[$row]}) {
          my $val   = $actions->[$row]->[$class_idx];
          $m->out(qq{    <td class="action">$val</td>\n});
          $remainingCols--;
      }
  }

  # Fill out the rest of the columns.
  foreach (1..$remainingCols) {
      $m->out(qq{<td></td>\n});
  }

</%perl>
%# End foreach my $o (@$objs)
  </tr>
% }
% # If there were no results (and thus none of the above is output) tell the user
% if ($rows == 1) {
%   my $message;
%   $message = $lang->maketext("No ".lc(get_class_info($object)->get_plural_name) . " were found") if !$empty_search;
    <tr><td colspan="<% scalar @$fields %>"><% $message %>&nbsp;</td></tr>
% }
</table>
% $m->comp('.footer', pagination => $pagination, cols => $cols)
%    if $pagination->{pages} > 1;
<%once>;
# Returns a link to the page specified with the given label. Used by .footer.
my $page_link = sub {
    my ($page_num, $label, $limit, $url, $title) = @_;
    $title = qq{ title="$title"} if $title;
    my $offset = ($page_num - 1) * $limit;
    return qq{<a href="$url?listManager|set_offset_cb=$offset"$title>} .
      $lang->maketext($label) . q{</a> };
};
</%once>
<%args>
$widget
$object
$fields
$state
$data
$actions => undef
$rows
$cols
$userSort # Whether users can resort the list.
$addition
$featured => undef
$featured_color
$empty_search
$pkg => undef
$pagination => {}
</%args>
<%init>;
my $url       = $r->uri;
my $sortBy    = $state->{sort_by} || $state->{default_sort};
my $sortOrder = $state->{sort_order};
my $sort_col  = 0;

# Get the real values if these are code refs.  Handle profile and select
# on a row by row basis.
$addition = &$addition($pkg) if ref $addition eq 'CODE';
</%init>
<%def .footer>
<%args>
$pagination
$cols
</%args>
<%init>;
my $url = $r->uri;
my $align = QA_MODE ? "left" : "center";
my $style = qq{style="border-style:solid; border-color:#cccc99;"};
$m->out(qq{<div class="paginate">\n});
unless ($pagination->{pagination}) {
    $m->out(qq{<div class="all">} .
            $page_link->(0, 'Paginate Results', 0, $url) . "</div>\n");
} else {
    $m->out(qq{<div class="pages">});
    # previous link, if applicable
    if( $pagination->{curr_page} - 1 >= 1 ) {
        $m->out($page_link->($pagination->{curr_page} - 1,
                             qq{&laquo;},
                             $pagination->{limit}, $url, 'Previous Page') . '&nbsp;');
    }

    # links to other pages by number
    foreach ( 1..$pagination->{pages} ) {
        if ($_ == $pagination->{curr_page}) {
            $m->out(qq{<span class="current">$_</span>&nbsp;});
        } else {
            $m->out($page_link->($_, "$_", $pagination->{limit}, $url) .
                    '&nbsp;');
        }
    }

    # next link, if applicable
    if( $pagination->{curr_page} + 1 <= $pagination->{pages} ) {
        $m->out('&nbsp;' . $page_link->($pagination->{curr_page} + 1,
                                        qq{&raquo;},
                                        $pagination->{limit}, $url, 'Next Page'));
    }
    $m->out(qq{</div>});
    $m->print(qq{<div class="all"><a href="$url?listManager|show_all_records_cb=1">},
            $lang->maketext('Show All'), '</a></div>');
}
$m->out(qq{</div>});
</%init>
</%def>
