<%args>

$cb        => 'save_cb'
$val       => undef
$type
$section
$return    => undef
$no_del    => 0
$no_ret    => 0
$no_save   => 0
$stay      => ''
$widget    => 'profile'
$chk_label => 'Delete this Profile'
$ret_val   => 'cancel_red'
</%args>

% $return ||= last_page();

<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td colspan=2>
<%perl>;
$m->comp('/widgets/profile/displayFormElement.mc',
	 key => 'delete',
	 vals => { 
		   props => { type => 'checkbox' }
		 },
	useTable => 0
	) unless $no_del;

$m->out('&nbsp;<span class=burgandyLabel>' . $lang->maketext($chk_label) . '</span>') unless $no_del;
</%perl>
  </td>
</tr>
<tr>
   <td align=left>
<%perl>;
$stay = qq{&nbsp;<input type="image" src="/media/images/$lang_key/save_and_stay_lgreen.gif" border="0" name="$widget|$stay" value="save_and_stay" vspace="2" />} if $stay;
if (!$val) {
    $val = '';
    $m->out(qq{<input type="image" src="/media/images/$lang_key/save_red.gif" border="0" name="$widget|$cb" value="$val" vspace="2" />$stay})
      unless $no_save;
} else {
    $m->out(qq{<input type="image" src="/media/images/$lang_key/${val}.gif" border=0 name="$widget|$cb" value="$val" />$stay}) unless $no_save;
}
</%perl>
   </td>
   <td align="right">
<%perl>;
$m->out(qq{<a href="#" onClick="window.location.href='$return'; return false;"><img src="/media/images/$lang_key/$ret_val.gif" border=0 name="return" value="Return" vspace=2 /></a>}) unless $no_ret;
</%perl>

  </td>
</tr>
</table>

<%doc>
###############################################################################

=head1 NAME

formButtons.mc

=head1 VERSION

$Revision: 1.8 $

=cut

our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Date: 2003-09-23 17:25:57 $

=head1 SYNOPSIS

<& '/widgets/profile/formButtons.mc', type => $type, section => $section,
   return => $return_url, no_del => $del
 &>

=head1 DESCRIPTION

Generalized dump of form buttons for bottom of profile display. The arguments
are:

=over

=item *

type - The class type part of the URL being processed. Required.

=item *

val - Optional value for the submit button. Defaults to "Save" image button, 
but becomes a standard labeled button if a value is provided.

=item *

cb - Optional name for the Save button's callback function. Defaults to
'save_cb'.

=item *

section - The section of the site (admin, workflow, etc). Required for the
Return button's URL (unless the return argument is passed).

=item *

return - An optional URL to which the browser will be redirected when the Return
button is clicked. Defaults to the last URL visited (using last_page()).

=item *

no_del - If passed a true value, the "Delete this Profile" checkbox will
not be displayed.

=item *

no_ret - If passed a true value, the "Return" button will not be displayed.

=item *

chk_label - Label for the 'delete' checkbox. Defaults to 'Delete this Profile'.

=back

</%doc>
