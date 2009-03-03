<%init>;
my ($i, $chk);
my %h = $r->headers_in;

# Get headers.
$m->out('<font face="Verdana, Helvetica, Arial"><b>Headers:</b></font>');
$m->out(qq{<table border="0" width="600" cellspacing="2">\n});
$m->out(qq{<tr bgcolor="lightgrey"><td style="white-space: nowrap;"><font face="Verdana, Helvetica, Arial"><b>Key</b></font></td><td><font face="Verdana, Helvetica, Arial"><b>Value</b></font></td></tr>\n});

while (my ($k, $v) = each %h) {
    my $c = $i ? 'lemonchiffon' : 'lightblue';
    $i = !$i;
    $chk = 1;
    HTML::Mason::Escapes::html_entities_escape(\$v);
    $m->out(qq{<tr bgcolor="$c" valign="top"><td align="right"><font face="Verdana, Helvetica, Arial"><b>$k</b></font></td><td><font face="Verdana, Helvetica, Arial">$v</font></td></tr>\n});
}
$m->out($chk ? "</table>\n" : qq{<tr bgcolor="lightblue"><td colspan="2"><font face="Verdana, Helvetica, Arial"><b>None</b></font></td><td></tr>\n</table>\n});
($chk, $i) = (0, 0);

# Get ARGS data.
$m->out('<br /><font face="Verdana, Helvetica, Arial"><b>ARGS:</b></font>');
$m->out(qq{<table border="0" width="600" cellspacing="2">\n});
$m->out(qq{<tr bgcolor="lightgrey"><td style="white-space: nowrap;"><font face="Verdana, Helvetica, Arial"><b>Key</b></font></td><td><font face="Verdana, Helvetica, Arial"><b>Value</b></font></td></tr>\n});
while (my ($k, $v) = each %ARGS) {
    my $c = $i ? 'lemonchiffon' : 'lightblue';
    $i = !$i;
    $chk = 1;
    $v ||= '&nbsp;';
    if (my $ref = ref $v) {
	local $" = "<br />\n";
	$v = $ref eq 'ARRAY' ? "@$v" : $ref;
    }
    HTML::Mason::Escapes::html_entities_escape(\$v);
    $m->out(qq{<tr bgcolor="$c" valign="top"><td align="right"><font face="Verdana, Helvetica, Arial"><b>$k</b></font></td><td><font face="Verdana, Helvetica, Arial">$v</font></td></tr>\n});
}
$m->out($chk ? "</table>\n" : qq{<tr bgcolor="lightblue"><td colspan="2"><font face="Verdana, Helvetica, Arial"><b>None</b></font></td></tr></table>\n\n});
</%init>

