<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:34 $

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/footer.mc" &>

=head1 DESCRIPTION

Finish off the HTML.

=cut
</%doc>

	<!-- footer -->
% if (Bric::Config::QA_MODE) {
<& '/widgets/debug/debug.mc', %{$ARGS{param}} &>
% }
	
	</td>
</tr>
<tr>
  <td bgcolor="#666633">&nbsp;</td>
</tr>
</table>
<!-- end side nav and content table -->


</body>
</html>
