<%doc>;
###############################################################################

=head1 NAME

/widgets/doubleListManager/doubleListManager.mc

=cut

use Bric; our $VERSION = Bric->VERSION;

=head1 SYNOPSIS

$m->comp("/widgets/doubleListManager/doubleListManager.mc",
	leftOpts        => @leftOpts,
	rightOpts       => @rightOpts,
	rightSort       => 1,
	leftSort        => 1,
        size            => 10,
        readOnly        => true || false  # toggles display of buttons to move items btwn lists.  Default is false.
        leftCaption     => $leftCaption   # optional string displayed above left list
        rightCaption    => $rightCaption  # optional string displayed above right list
	leftName        => $leftName,     # optional if there is only one double list manager on the page
	rightName       => $rightName,    # optional if there is only one double list manager on the page
        readOnlyLeft    => @readOnlyLeft, # optional array of values that should not be moved from the left list
        readOnlyRight   => @readOnlyRight # optional array of values that should not be moved from the right list
);

=head1 DESCRIPTION

This is a sub element that creates a double list manager. Can be supplied with
an array of hashes for option values and descriptions for either left or right
side options.  Values added to the readOnly arrays for either side will not be
moved when the user hits the add or remove buttons.  Only values that are added
to the right side list by the user will be sent to the server when the form
is submitted.

</%doc>
<%once>;
my $widget = 'doubleListManager';
</%once>
<%args>
@leftOpts	=> ()
@rightOpts	=> ()
$leftCaption    => ''
$rightCaption   => ''
$leftName	=> "all_groups"
$rightName	=> "selected_groups"
@readOnlyLeft	=> ()
@readOnlyRight	=> ()
$readOnly       => 0
$useTable       => 1
$showLeftList   => 1
$showRightList  => 1
$leftJs         => ''
$rightJs        => ''
$leftSort       => 0
$rightSort      => 0
$formName       => 'theForm'
$size           => 10
</%args>
<%init>;
my ($left, $right, %seen) = ('', '');
my (@leftVals, @rightVals);

$leftCaption  = $lang->maketext($leftCaption);
$rightCaption = $lang->maketext($rightCaption);
my %rol = map { $_ => undef } @readOnlyLeft;
my %ror = map { $_ => undef } @readOnlyRight;

# Build the right-hand list.

foreach my $opt ($rightSort
                   ? sort { lc $a->{description} cmp lc $b->{description} } @rightOpts
                   : @rightOpts)
{
    $seen{$opt->{value}} = 1;
    $rightVals[@rightVals] = $opt->{value};
    my $ro = exists $ror{$opt->{value}} ? ' disabled="disabled"' : '';
    $right .= !$readOnly
      ? qq{   <option value="$opt->{value}"$ro>$opt->{description}</option>\n}
      : $opt->{description} . "<br />";
}

# Build the left-hand list.
foreach my $opt ($leftSort
                 ? sort { lc $a->{description} cmp lc $b->{description} } @leftOpts
                 : @leftOpts)
{
    next if $seen{$opt->{value}};
    $leftVals[@leftVals] = $opt->{value};
    my $ro = exists $rol{$opt->{value}} ? ' disabled="disabled"' : '';
    $left .= !$readOnly
      ?  qq{   <option value="$opt->{value}"$ro>$opt->{description}</option>\n}
      : $opt->{description} . "<br />";
}

# Track the form element names for use when cleaning up submission
$m->out(qq{<script type="text/javascript">\n},
        qq{doubleLists[doubleLists.length] = ["$leftName", "$rightName"];\n},
        qq{</script>\n});
</%init>
% # begin html ---------------
<table width="578" border="0" cellpadding="0" cellspacing="0" class="dlman">
  <tr>
<%perl>;
if ($showLeftList) {
    $m->out(qq{  <td width="50"><img src="/media/images/spacer.gif" width="50" height="1" /></td>
                 <td width="230" align="center"><span class="label">$leftCaption</span></td>}  );
} else {
    $m->out(' <td width="50">&nbsp;</td><td>&nbsp;</td>');
}
</%perl>
<td width="18" rowspan="3"><img src="/media/images/spacer.gif" width="18" height="1" /></td>
<%perl>;
if ($showRightList) {
    $m->out(qq { <td align="center" width="230"><span class="label">$rightCaption</span></td>
                 <td width="50"><img src="/media/images/spacer.gif" width="50" height="1" /></td>} );
} else {
    $m->out(qq{ <td>&nbsp;</td><td width="50"><img src="/media/images/spacer.gif" width="50" height="1" /></td>});
}
</%perl>
</tr>

<tr>
    <td>&nbsp;</td><td valign="top" align="right">
% if ($showLeftList) {
%   if (!$readOnly) {
      <select name="<% $leftName %>" id="<% $leftName %>" size="<% $size %>" multiple="multiple" >
      <% $left %>
      </select>
%   } else {
      <% $left %>
%   }
% }
    </td>
    <td valign=top>
% if ($showRightList) {
%   if (!$readOnly) {
      <select name="<% $rightName %>" id="<% $rightName %>" size="<% $size %>" multiple="multiple" >
      <% $right %>
      </select>
%   } else {
      <% $right %>
%   }
% }
    </td>
    <td>&nbsp;</td>
</tr>
<%perl>;
if ($showLeftList && $showRightList && !$readOnly) {
    $m->out(qq{ <tr class="dlbtns"><td>&nbsp;</td><td align="right"> });
    $m->out(qq{ <a href="#" onclick="move_item('} . $formName . qq{', '} . $leftName . qq{', '} . $rightName . qq{'); return false;">});
    $m->out(qq{<img src="/media/images/$lang_key/add_to_list_lgreen.gif" border=0 /></a>} );
    $m->out(qq{ </td><td align="left"> } );
    $m->out(qq{ <a href="#" onClick="move_item('} . $formName . qq{', '} . $rightName . qq{', '} . $leftName . qq{'); return false;">} );
    $m->out(qq{<img src="/media/images/$lang_key/remove_from_list_red.gif" border=0 /></a>} );
    $m->out(qq{ </td><td>&nbsp;</td></tr> });
}
</%perl>
</table>
