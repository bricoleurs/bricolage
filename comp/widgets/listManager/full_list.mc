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
	  $m->out("<a class=$aclass href='$url?listManager|sortBy_cb=$f'>" . ($disp || "") . "</a>");
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

% # here's where the rows diplayed are limited - see lines 209-18
% foreach my $r ($start..$end) {
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

%# Paging footer stuff
% if( $rppg && ( $rows - 1 ) > $rppg ) {
%     my $align = QA_MODE ? "left" : "center";
<table align="<% $align %>" border="0" cellpadding="0" cellspacing="0" width="435">
<tr>

<%perl>
my $sprint_string = qq( <a href="$url?$param) . qq(listManager|start_page_cb=%d">%s</a> );

if( $multiple_pages ) {
    my $pages = sprintf( "%d", ( ( $rows - 1 ) / $rppg ) ) + ( ( $rows - 1 ) % $rppg ? 1 : 0 )
	if( defined( $rppg ) );
    my $next = sprintf( $sprint_string, $current_page + 1, 'Next' )
	if( $current_page + 1 <= $pages );
    my $prev = sprintf( $sprint_string, $current_page - 1, 'Previous' )
	if( $current_page - 1 >= 1 );

    $m->out( '<td align="left">' . ($prev || '') . '&nbsp;' );

    for my $i( 1..$pages ) {
	$m->out( $i != $current_page ? sprintf( $sprint_string, $i, $i ) : $i );
    }

    $m->out( '&nbsp;' . ($next || '') . '</td>' );

    $m->out( "<td align=\"right\"><a href=\"$url?$param" .
             "listManager|show_all_listings_cb=1\">Show All</a></td>" );

} else {
    $m->out( qq{ <td align="left"> } . sprintf( $sprint_string, 1, 'Paginate Records' ) . "</td>" );
}
</%perl>

</tr>
</table>
% }
%# End Paging Footer Stuff

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
# Setup paging vars
my ($current_page, $end, $start);

# indicates whether search paging is on and if so
# how many rows to show per page
my $rppg = Bric::Util::Pref->lookup_val( 'Search Results / Page' ) || 0;

# set 'show all rows' bool
my $multiple_pages = get_state_data( 'listManager', 'multiple_pages' ) || 0;

# checking the query string to see if we're in the Elements admin
# if we are the query string will have to be prepended to the paging
# links; see lines 104-29
my $param = grep( /elem_type/, $r->param ) ?
    "elem_type=" . $r->param('elem_type') . "&" :
    "";

# block for setting $new_params...this block is designed to support
# proper paging associated with the admin->publishing->elements.
# if a different element type is selected from the drop down we
# want to reset the current_page to 1. the past element type if any
# is grabbed from the 'params' var.  if a new query string is supplied
# to the mason component then $new_params is set to 1.
my $new_params = 0;
if ($param) {
    my $old_param = get_state_data( $widget, 'params' ) || '';

    if ( $old_param eq '' ||
         ( $old_param && $param ne $old_param ) ) {
        set_state_data( $widget, 'params', $param );
        $new_params = 1;
    }
}

# Enter here if the multiple page flag bool is set of if search paging is
# turned on and we're looking at a new item from the Elements drop-down list
if ( $multiple_pages != 0 ||
     ( $rppg && $new_params ) ) {

    $multiple_pages ||= 1;

    # resets $current_page and the session value 'start_page' to 1 if:
    # 'start_page' is undefined OR
    # 'start_page' eq 'x' OR
    # $new_params is non-zero (hence a new query string was supplied
    # by /admin/profile/element)
    if( not ( $current_page = get_state_data( $widget, 'start_page' ) )
        || $current_page eq 'x'
        || $new_params ) {
	set_state_data( $widget, 'start_page', 1 );
	$current_page = 1;
    }

    $end = ( $current_page * $rppg ) - 1;
    $end = $#{ $data } - 1
        if( ( ( $current_page * $rppg ) - 1 ) > ( $#{ $data } - 1 ) );
    $start = 0;
    $start = ( $current_page - 1 ) * $rppg
        if( $current_page - 1 > 0 );
} else {
# show all rows of data...
    $end = $#{ $data } - 1;
    $start = 0;
}

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
