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
          my $sortsign = '';
          my $sortsymbol = '';

          if (($sortBy eq $f) && ($sortOrder !~ /^reverse$/)) {
              $sortsign = '-';
              $sortsymbol = '<img src="/media/images/listsort_down.gif" border="0">';
          } elsif ($sortBy eq $f) {
              $sortsymbol = '<img src="/media/images/listsort_up.gif" border="0">';
          }
          $m->out(qq{<a class="$aclass" href="$url?listManager|sortBy_cb=$sortsign$f">} .
                  ($disp || "") . "&nbsp;$sortsymbol</a>");
      } else {
	  $m->out($disp);
      }
      $m->out("</th>");
  }

  # Adjust the tabel size.
  if (scalar @$fields < $cols) {
      $m->out("<th colspan=".($cols - scalar @$fields).' class=medHeader style="border-style:solid; border-color:#cccc99;">' );

      # insert 'Check All' link if necessary. see &$insert_check_all below or
      # check_all in lib.js for more info...
      my $form_name = lc(get_disp_name($pkg));
      if (&$insert_check_all($form_name, $form_names, $url)) {
          $m->out(<<EOF);
<script language="JavaScript">
// checkbox field name suffixes to search
var args = new Array('recall_cb','checkout_cb','deactivate_cb','delete_cb');
</script>
<a class="blackLink" href="javascript:check_all( '$form_name\_manager', args )">Check All</a>
EOF
      }

      $m->out('</th>');
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

<%once>;
# determines whether to insert the 'Check All' link based on
# the package name of the items being listed, the list of
# packages that should have the link inserted (@$form_names)
# and the url of the current screen.
# if we return 1 then the link is inserted and a click on
# the last column heading of the list_manager results in a
# call to function check_all in lib.js
my $insert_check_all = sub {
    my ($form_name, $forms, $url) = @_;
    my $bool = 0;
    $form_name =~ s| |_|g;
    $form_name =~ s|utor||;
    $form_name = $form_name eq 'group' ? 'grp' : $form_name;

    my $names = join("|",@$forms);
    $bool = 1 if $form_name =~ /^(?:$names)$/ && $url !~ /change_user/;

    return $bool;
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
</%args>

%#--- Initialization ---#

<%init>;
# Forms on which to display the 'Check All' table header
my @$form_names = qw(alert_type category contrib contrib_type destination
element element_type grp media source story output_channel template
user workflow);

my $url       = $r->uri;
my $object    = get_state_data($widget, 'object');
my $sortBy    = get_state_data($widget, 'sortBy')
  || get_state_data($widget, 'defaultSort');
my $sortOrder = get_state_data($widget, 'sortOrder') || '';
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
