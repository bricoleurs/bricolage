<table border=0 cellpadding=0 cellspacing=0 width=580>
  <tr>
    <td class=<% $tab %> valign=top width=11><% $curve_left %></td>
    <td class=<% $tab %> width=558>&nbsp;<% uc($title) %></td>
    <td class=<% $tab %> valign=top width=11 align=right><img src="<% $curve_right %>" width=11 height=19></td>
  </tr>
</table>

% if ($addition) {
<table border=0 cellpadding=0 cellspacing=0 width=580>
  <tr>
    <td class=lightHeader width=1><img src="/media/images/spacer.gif" width=1 height=19></td>
    <td width=10><img src="/media/images/spacer.gif" width=10 height=25></td>
    <td width=568><a class=redLinkLarge href="<% $addition->[1] %>"><% $addition->[0] %> a New <% get_class_info($object)->get_disp_name %></a></td>
    <td class=lightHeader width=1><img src="/media/images/spacer.gif" width=1 height=19></td>
  </tr>
</table>
% }


<!-- table header display -->
<table border=1 cellpadding=2 cellspacing=0 width=580 bordercolor="#cccc99" style="border-style:solid; border-color:#cccc99;">
  <tr>
<%perl>
  my $field_disp = shift @$data;
  # Output the table header.
  foreach my $i (0..$#{$fields}) {
      my $f = $fields->[$i];
      my $disp = shift @$field_disp;

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
	  $m->out("<a class=$aclass href='$url?listManager|sortBy_cb=$f'>$disp</a>");
      } else {
	  $m->out($disp);
      }
      $m->out("</th>");
  }

  # Adjust the tabel size.
  if (scalar @$fields < $cols) {
      $m->out("<th colspan=".($cols - scalar @$fields).' class=medHeader style="border-style:solid; border-color:#cccc99;"><img src="/media/images/spacer.gif" width=1 height=19></th>');
  }
</%perl>

  </tr>

%# Output the rows of data
% my $first;
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
      $m->out("<td>&nbsp;</td>\n");
  }

</%perl>

%# End foreach my $o (@$objs)
  </tr>
% }

%# If there were no results (and thus none of the above is output) tell the user
% if ($rows == 1) {
% if ($empty_search) {
  <tr><td colspan="<% scalar @$fields %>"></td></tr>
% } else {
  <tr><td colspan="<% scalar @$fields %>">No <% lc(get_class_info($object)->get_plural_name) %> were found</td></tr>
% }
% }
</table>

%#--- END HTML ---#

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
</%args>

%#--- Initialization ---#

<%init>;
# Load some values.
my $url       = $r->uri;
my $object    = get_state_data($widget, 'object');
my $sortBy    = get_state_data($widget, 'sortBy')
  || get_state_data($widget, 'defaultSort');
my $sort_col  = 0;

# Figure out where we are.
my ($section) = $m->comp('/lib/util/parseUri.mc');
my ($tab, $curve_left, $curve_right, $sort_class, $scolor, $ccolor);

if ($section eq 'admin') {
    ($ccolor, $scolor, $sort_class) = (qw(CC6633 CC6633 redHeader));
} else {
    ($ccolor, $scolor, $sort_class) = (qw(669999 006666 tealHeader));
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

%#--- Log History ---#


