<table border=0 cellpadding=0 cellspacing=0 width=580>
  <tr>
    <td class=<% $tab %> valign=top width=11><% $curve_left %></td>
    <td class=<% $tab %> width=558>&nbsp;<% uc($title) %></td>
    <td class=<% $tab %> valign=top width=11 align=right><img src="<% $curve_right %>" width=11 height=19></td>
  </tr>
</table>

% if ($addition) {
<table border="0" cellpadding="0" cellspacing="0" width="580">
  <tr>
    <td class="lightHeader" width="1"><img src="/media/images/spacer.gif" width="1" height="19"></td>
    <td width="10"><img src="/media/images/spacer.gif" width="10" height="25"></td>
    <td width=568><a class=redLinkLarge href="<% $addition->[1] %>"><% $lang->maketext($addition->[0]." a New ".get_class_info($object)->get_disp_name) %></a></td>
    <td class="lightHeader" width="1"><img src="/media/images/spacer.gif" width="1" height="19"></td>
  </tr>
</table>
% }


<!-- table header display -->
<table border="1" cellpadding="2" cellspacing="0" width="580" bordercolor="#cccc99" style="border-style:solid; border-color:#cccc99;">
  <tr>
<%perl>
  my $field_disp = shift @$data;
  # Output the table header.
  foreach my $i (0..$#{$fields}) {
      my $f = $fields->[$i];
      my $disp = $lang->maketext(shift @$field_disp);

      my ($aclass, $thclass);
      if ($sortBy eq $f) {
          ($aclass, $thclass) = ('whiteLink', $sort_class);
          $sort_col = $i;
      } else {
          ($aclass, $thclass) = ('blackLink', 'medHeader')
      }

      $m->out(qq{<th class=$thclass style="border-style:solid; border-color:#cccc99;">&nbsp;});

      # Only make a link if user sorting is enabled.
      if ($userSort) {
          my $sortsign = '';
          my $sortsymbol = '';

          if (($sortBy eq $f) && ($sortOrder !~ /^reverse$/)) {
              $sortsign = '-';
              $sortsymbol = qq{<img src="/media/images/listsort_down_$sscolor.gif" border="0">};
          } elsif ($sortBy eq $f) {
              $sortsymbol = qq{<img src="/media/images/listsort_up_$sscolor.gif" border="0">};
          }
          $m->out(qq{<a class="$aclass" href="$url?listManager|sortBy_cb=$sortsign$f">} .
                  ($disp || "") . "&nbsp;$sortsymbol</a>");
      } else {
          $m->out($disp);
      }
      $m->out("</th>");
  }

  # Adjust the table size.
  if (scalar @$fields < $cols) {
      $m->out("<th colspan=".($cols - scalar @$fields).' class=medHeader style="border-style:solid; border-color:#cccc99;">&nbsp;</th>');
  }
</%perl>

  </tr>

%# Output the rows of data
% my $first;
% if ($sortOrder eq 'reverse') {
%     @$data = reverse @$data;
% }

% # here's where the rows diplayed are limited - see lines 209-18
% foreach my $r (0..$#{$data}) {
% my $o_id = shift @{$data->[$r]};
  <tr <% $featured->{$o_id} ? "bgcolor=\"$featured_color\"" : "" %>>
<%perl>
  # Output for each field.
  foreach my $c (0..$#{$data->[$r]}) {
      my $val   = $data->[$r]->[$c];
      if ($c eq $sort_col) {
          $m->out(qq{<td height=25 valign=top style="border-style:solid; border-color:#cccc99;"><b>$val</b></td>\n});
      } else {
          $m->out(qq{<td height=25 valign=top style="border-style:solid; border-color:#cccc99;">$val</td>\n});
      }
  }

  # Fill out the rest of the columns.
  foreach ((@{$data->[$r]}+1)..$cols) {
      $m->out(qq{<td style="border-style:solid; border-color:#cccc99;">} .
              qq{&nbsp;</td>\n});
  }

</%perl>

%# End foreach my $o (@$objs)
  </tr>
% }
% $m->comp('.footer', pagination => $pagination, cols => $cols)
%    if $pagination->{pages} > 1;

% # If there were no results (and thus none of the above is output) tell the user
% if ($rows == 1) {
%     if ($empty_search) {
  <tr><td style="border-style:solid; border-color:#cccc99;" colspan="<% scalar @$fields %>">&nbsp;</td></tr>
%     } else {
  <tr><td colspan="<% scalar @$fields %>"><%$lang->maketext("No ".lc(get_class_info($object)->get_plural_name)." were found") %></td></tr>
%     }
% }
</table>

%#--- END HTML ---#

<%once>;
# Returns a link to the page specified with the given label. Used by .footer.
my $page_link = sub {
    my ($page_num, $label, $limit, $url, $class) = @_;
    $class ||= 'subHeader';
    my $offset = ($page_num - 1) * $limit;
    return qq{ <a href="$url?listManager|set_offset_cb=$offset" } .
      qq{class="redLinkLarge"><span class="$class">$lang->maketext($label)</span></a> };
};
</%once>

%#--- Arguments ---#

<%args>
$widget
$title
$fields
$data
$rows
$cols
$userSort # Whether users can resort the list.
$addition
$featured => undef
$featured_color
$number => 0
$empty_search
$pkg => undef
$pagination => {}
</%args>

%#--- Initialization ---#

<%init>;
my $url       = $r->uri;
my $object    = get_state_data($widget, 'object');
my $sortBy    = get_state_data($widget, 'sortBy')
  || get_state_data($widget, 'defaultSort');
my $sortOrder = get_state_data($widget, 'sortOrder') || '';
my $sort_col  = 0;

# Figure out where we are.
my ($section) = $m->comp('/lib/util/parseUri.mc');
my ($tab, $curve_left, $curve_right, $sort_class, $scolor, $ccolor, $sscolor);

if ($section eq 'admin') {
    ($ccolor, $scolor, $sort_class, $sscolor) =
      (qw(CC6633 CC6633 redHeader red));
} else {
    ($ccolor, $scolor, $sort_class, $sscolor) =
      (qw(669999 006666 tealHeader teal));
}

if ($number) {
    $tab = 'lightHeader';
    $curve_left = qq{<img src="/media/images/numbers/${ccolor}_curve_$number.gif" width="20" height="19" />};
    $curve_right = qq{/media/images/CCCC99_curve_right.gif};
} else {
    $tab = $section . 'SubTab';
    $curve_left = qq{<img src="/media/images/${scolor}_curve_left.gif" width="11" height="19" />};
    $curve_right = qq{/media/images/${scolor}_curve_right.gif};
}

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
$m->out(qq{<tr valign="middle" height="25" valign="top" class="lightHeader">\n});
my $style = qq{style="border-style:solid; border-color:#cccc99;"};
unless ($pagination->{pagination}) {
    $m->out(qq{<td $style colspan="$cols">} .
            $page_link->(0, 'Paginate Results', 0, $url) . "</td>");
} else {
    --$cols;
    $m->out(qq{<td $style colspan="$cols">\n});

    # previous link, if applicable
    if( $pagination->{curr_page} - 1 >= 1 ) {
        $m->out($page_link->($pagination->{curr_page} - 1,
                             qq{&laquo;},
                             $pagination->{limit}, $url, 'header') . '&nbsp;');
    }

    # links to other pages by number
    foreach ( 1..$pagination->{pages} ) {
        if ($_ == $pagination->{curr_page}) {
            $m->out(qq{<span class="subHeader"><b>$_</b>&nbsp;</span>});
        } else {
            $m->out($page_link->($_, "$_", $pagination->{limit}, $url) .
                    '&nbsp;');
        }
    }

    # next link, if applicable
    if( $pagination->{curr_page} + 1 <= $pagination->{pages} ) {
        $m->out('&nbsp;' . $page_link->($pagination->{curr_page} + 1,
                                        qq{&raquo;},
                                        $pagination->{limit}, $url, 'header'));
    }

    $m->out(qq{</td><td $style align="right"><a href="$url?listManager|show_all_records_cb=1" class="redLinkLarge">} .
            qq{Show All</a></td>});
}
$m->out(qq{</tr>});
</%init>
</%def>
