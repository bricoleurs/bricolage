<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

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

