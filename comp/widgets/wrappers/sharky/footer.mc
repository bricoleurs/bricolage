<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2002/05/08 19:46:55 $

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

</table>
<!-- end side nav and content table -->


</body>
</html>

