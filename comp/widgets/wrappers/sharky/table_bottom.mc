<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2003/03/12 03:25:54 $

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/table_top.mc" &>

=head1 DESCRIPTION

Generates the bottom of a table. Use the C<$border> parameter to determine
whether to draw border lines. Defaults to true.

=cut

</%doc>

<%args>
$border => 1
</%args>
<%init>

my ($section, $mode, $type) = $m->comp("/lib/util/parseUri.mc");
my $borderColor = ($section eq "admin") ? "999966" : "669999";

</%init>
% if ($border) {
</td>
<td valign="top" bgcolor="<% $borderColor %>" width="1">
<img src="/media/images/spacer.gif" width="1" height="1" border="0">
</td>
% }
</tr>
</table>
<table width="580" border="0" cellpadding="0" cellspacing="0">
% if ($border) {
<tr>
  <td bgcolor="<% $borderColor %>"><img src="/media/images/spacer.gif" width="1" height="1" border="0"></td>
  <td bgcolor="<% $borderColor %>" colspan="2"><img src="/media/images/spacer.gif" width="578" height="1" border="0"></td>
  <td bgcolor="<% $borderColor %>"><img src="/media/images/spacer.gif" width="1" height="1" border="0"></td>
</tr>
% }
<tr>
  <td colspan="4"><img src="/media/images/spacer.gif" width="580" height="10" border="0"></td>
</tr>
</table>
