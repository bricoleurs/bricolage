<table border="0">
% foreach my $key (keys %map) {
%     my $method = $map{$key};
<tr>
    <td align="right"><font face="Verdana, Helvetica, Arial"><b><% $key %>:&nbsp;</b></font></td>
    <td><font face="Verdana, Helvetica, Arial"><% $agent->$method %></font></td>
</tr>
%}
</table>
<br />

<%init>;
my $agent = detect_agent();
my %map = (
    'Browser' => 'browser_string',
    'Version' => 'version',
    'OS'      => 'os_string',
    'Type'    => 'robot',
);
</%init>