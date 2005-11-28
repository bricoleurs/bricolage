<%doc>
###############################################################################

=head1 NAME

widgets/help/help.mc

=head1 SYNOPSIS

  <& "/widgets/help/help.mc" &>

=head1 DESCRIPTION

Returns a help button with a link to a helpfile.

Uses Javascript to build URI and open window.  See media/js/lib.js.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=cut

</%doc>
<%once>;
my $widget = 'help';
</%once>
<%perl>;
set_state_data($widget, \%ARGS);
</%perl>
<a href="<% $r->uri %>" title="Help" id="btnHelp" onclick="return openHelp()"><img src="/media/images/<% $lang_key %>/help.gif" alt="Help" /></a>
