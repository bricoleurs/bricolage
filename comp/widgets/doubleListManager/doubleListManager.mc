<%doc>;
###############################################################################

=head1 NAME

/widgets/doubleListManager/doubleListManager.mc

=head1 VERSION

$Revision: 1.12 $

=cut

use Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$Date: 2004/03/03 23:04:23 $

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
@rightOpts 	=> ()
$leftCaption    => ''
$rightCaption   => ''
$leftName 	=> "all_groups"
$rightName 	=> "selected_groups"
@readOnlyLeft 	=> ()
@readOnlyRight 	=> ()
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


# Build the right-hand list.

foreach my $opt ($rightSort ? sort { lc $a->{description} cmp lc $b->{description} } @rightOpts : @rightOpts) {
    $seen{$opt->{value}} = 1;
    $rightVals[@rightVals] = $opt->{value};
    $right .= (!$readOnly) ? qq{   <option value="$opt->{value}">$opt->{description}</option>\n} : $opt->{description} . "<br />";
}

# Build the left-hand list.
foreach my $opt ($leftSort ? sort { lc $a->{description} cmp lc $b->{description} } @leftOpts : @leftOpts) {
    next if $seen{$opt->{value}};
    $leftVals[@leftVals] = $opt->{value};
    $left .= (!$readOnly) ?  qq{   <option value="$opt->{value}">$opt->{description}</option>\n} : $opt->{description} . "<br />";
}

</%init>

<%perl>
# if there are elements in the read only arrays, put them
# on the page in a javascript array

$m->out('<script language="javascript">'."\n");

# track the form element names for use when cleaning up submission
$m->out('doubleLists[doubleLists.length] = "' . $leftName . ":"  . $rightName . '"' . "\n\n");

# verify will need the form name too...
$m->out("formObj = false\n\n");

my $txt = '';

# write any read only values for the left side
$m->out("var $leftName"."_readOnly = new Array(" );
foreach my $opt (@readOnlyLeft) {
	$txt .= '"' . $opt . '", ';
}
$txt = substr($txt, 0, length($txt) - 2);
$m->out($txt);
$m->out(")\n\n");

$txt = ''; 

# write any read only values for the right side
$m->out("var $rightName"."_readOnly = new Array(" );
foreach my $opt (@readOnlyRight) {
	$txt .= '"' . $opt . '", ';
}
$txt = substr($txt, 0, length($txt) - 2);
$m->out($txt);
$m->out(")\n\n");

$txt = ''; 

# write all original right values
$m->out("var $rightName"."_values = new Array(" );
foreach my $val (@rightVals) {
	$txt .= '"' . $val . '", ';
}
$txt = substr($txt, 0, length($txt) - 2);
$m->out($txt);
$m->out(")\n\n");

$txt = ''; 

# write all original left values 
$m->out("var $leftName"."_values = new Array(" );
foreach my $val (@leftVals) {
	$txt .= '"' . $val . '", ';
}
$txt = substr($txt, 0, length($txt) - 2);
$m->out($txt);
$m->out(")\n\n");

$m->out("\n</script>");


</%perl>

% # begin html ---------------


<table width=578 border=0 cellpadding=0 cellspacing=0>
<%perl>
if ($showLeftList) {
    $m->out(qq{  <td width=50><img src="/media/images/spacer.gif" width=50 height=1 /></td>
                 <td width=230 align=center><span class=label>$leftCaption</span></td>}  );
} else {
    $m->out(" <td width=50>&nbsp;</td><td>&nbsp;</td>");
}
</%perl>
<td width=18 rowspan=3><img src="/media/images/spacer.gif" width=18 height=1 /></td>
<%perl>
if ($showRightList) {
    $m->out(qq { <td align=center width=230><span class=label>$rightCaption</span></td>
                 <td width=50><img src="/media/images/spacer.gif" width=50 height=1 /></td>} );
} else {
    $m->out(qq{ <td>&nbsp;</td><td width=50><img src="/media/images/spacer.gif" width=50 height=1 /></td>});
}
</%perl>
</tr>

<tr>
    <td>&nbsp;</td><td valign=top align=right>
% if ($showLeftList) {
%   if (!$readOnly) {
      <select name="<% $leftName %>" size="<% $size %>" multiple style="width:225px" width="210">
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
      <select name="<% $rightName %>" size="<% $size %>" multiple style="width:225px" width="210">
      <% $right %>
      </select>
%   } else {
      <% $right %>
%   }
% }
    </td>
    <td>&nbsp;</td>
</tr>

<%perl>

if ($showLeftList && $showRightList && !$readOnly) {
    $m->out(qq{ <tr><td>&nbsp;</td><td align="right"> });
    $m->out(qq{ <a href="#" onClick="return addToList('} .$formName . qq{', '$leftName', '$rightName'); $leftJs;">});
    $m->out(qq{<img src="/media/images/$lang_key/add_to_list_lgreen.gif" border=0 /></a>} );
    $m->out(qq{ </td><td align="left"> } );
    $m->out(qq{ <a href="#" onClick="return removeFromList('} .$formName . qq{', '$leftName', '$rightName'); $rightJs;">} );
    $m->out(qq{<img src="/media/images/$lang_key/remove_from_list_red.gif" border=0 /></a>} );
    $m->out(qq{	</td><td>&nbsp;</td></tr> });
}
</%perl>

</table>


<%doc>
</%doc>
