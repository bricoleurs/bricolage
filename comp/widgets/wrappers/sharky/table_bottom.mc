<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:38 $

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/table_top.mc" &>

=head1 DESCRIPTION

generate a top table

=cut

</%doc>

<%init>

my ($section, $mode, $type) = $m->comp("/lib/util/parseUri.mc"); 
my $borderColor = ($section eq "admin") ? "999966" : "669999";

</%init>
</td>
<td valign="top" bgcolor="<% $borderColor %>" width=1>
<img src="/media/images/spacer.gif" width="1" height="1" border="0">
</td>

</tr>
</table>
<table width=580 border=0 cellpadding=0 cellspacing=0>
<tr>
  <td valign="top" bgcolor="<% $borderColor %>"><img src="/media/images/spacer.gif" width="1" height="1" border="0"></td>
  <td valign="top" bgcolor="<% $borderColor %>" colspan=2><img src="/media/images/spacer.gif" width="578" height="1" border="0"></td>
  <td valign="top" bgcolor="<% $borderColor %>"><img src="/media/images/spacer.gif" width="1" height="1" border="0"></td>
</tr>
<tr>
  <td colspan=4><img src="/media/images/spacer.gif" width="580" height="10" border="0"></td>
</tr>
</table>
