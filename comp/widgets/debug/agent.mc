<table border="0">
% foreach my $key (qw(Browser Version OS Type)) {
<tr>
    <td align="right"><font face="Verdana, Helvetica, Arial"><b><% $key %>:&nbsp;</b></font></td>
    <td><font face="Verdana, Helvetica, Arial"><% $agent->{lc $key} %></font></td>
</tr>
%}
</table>
<br />

<%init>;
my $agent = detect_agent();
</%init>