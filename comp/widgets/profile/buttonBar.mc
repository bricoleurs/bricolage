<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.10 $

=head1 DATE

$Date: 2002-09-26 01:39:12 $

=head1 SYNOPSIS
$m->comp("/widgets/profile/buttonBar.mc",

);

=head1 DESCRIPTION

Button layout to be used at the bottom of story/template/media profile pages.

=cut

</%doc>
<%args>
$widget
$cd
$desks
$obj
</%args>

<%init>;
# browser spacing stuff
my $agent = $m->comp("/widgets/util/detectAgent.mc");
my $ieSpacer = $agent->{os} ne "SomeNix" ?
  qq{<tr><td colspan="3"><img src="/media/images/spacer.gif" } .
  qq{width="5" height="5" /></td></tr>}
  : '';

my $deskText = qq{<select name="$widget|desk">};
my $can_pub;

if ($desks) {
    foreach (@$desks) {
        my $id = $_->get_id;
        $deskText .= qq{<option value="$id"};
        $deskText .= " selected" if $id == $cd->get_id;
        $deskText .= ">to " .  $_->get_name . "</option>";
        $can_pub = 1 if $_->can_publish and chk_authz($_, EDIT, 1);
    }

    # Set up choice to remove from workflow.
    $deskText .='<option value="remove">and Shelve</option>';

    # Set up choice to publish, if possible.
    if ($can_pub) {
        my ($act, $cb) = $widget eq 'tmpl_prof' ?
          ('Deploy', 'deploy') : ('Publish', 'publish');
        $deskText .= qq{<option value="$cb">and $act</option>};
    }
    $deskText .= "</select>";
}

my $versions = $obj->get_versions;
my $versionText = '';

if ($versions) {
    $versionText = qq{<select name="$widget|version">};
    foreach (sort {$b->get_version <=> $a->get_version}  @$versions ) {
        my $v = $_->get_version;
        $versionText .= qq{<option value="$v">$v</option>};
    }
    $versionText .= "</select>";
}

</%init>


<table width="580" border="0" cellpadding="0" cellspacing="0">
<tr>
  <td align="center" colspan="3" valign="middle"><input type="checkbox" name="<% $widget %>|delete" value="Delete"> <span class="burgandyLabel">Delete this Profile</span></td>
</tr>
<tr>
  <td class="lightHeader" colspan="3"><img src="/media/images/spacer.gif" width="580" height="1"></td>
</tr>
<% $ieSpacer %>
<tr>
  <td width="33%">
  <table border="0" cellpadding="0" cellspacing="3">
  <tr>
    <td valign="middle"><input type="image" src="/media/images/check_in_dgreen.gif" border="0" name="<% $widget %>|checkin_cb" value="Check In"></td>
    <td valign="middle"><% $deskText %></td>
  </tr>
  </table>
  </td>
  <td width="34%" align="center">
<%perl>;
my $wf;
my $work_id = get_state_data($widget, 'work_id');
my $type;
if ($widget eq 'story_prof') {
    $type = 'story';
} elsif ($widget eq 'media_prof') {
    $type = 'media';
} else {
    $type = 'fa';
}

my $story = get_state_data($widget, $type);
if ($work_id) {
   $wf = Bric::Biz::Workflow->lookup( { id => $work_id });
} else {
   $work_id = $story->get_workflow_id();
   $wf = Bric::Biz::Workflow->lookup( { id => $work_id });
}
</%perl>
<table border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td>
      &nbsp;
    </td>
  </tr>
  </table>
  </td>
  <td align="right" widht="33%">
  <table border="0" cellpadding="0" cellspacing="0">
  <tr>
% if ($versions && @$versions > 1) {
    <td valign="middle"><input type="image" src="/media/images/revert_dgreen.gif" border=0 name="<% $widget %>|revert_cb" value="revert"></td>
    <td valign="middle">&nbsp;to <% $versionText %></td>
    <td valign="middle"><input type="image" src="/media/images/view_text_dgreen.gif" border=0 hspace=5 name="<% $widget %>|view_cb" value="view"></td>
% } else {
  <td>&nbsp;</td>
% }
  </tr>
  </table> 
  </td>
</tr>
<tr>
</tr>
<% $ieSpacer %> 
<tr>
  <td class=lightHeader colspan="3"><img src="/media/images/spacer.gif" width=580 height=1></td>
</tr>
<% $ieSpacer %> 
</table>

<table width=580 cellpadding=0 cellspacing=0>
<tr>
  <td width=60><img src="/media/images/spacer.gif" width=60 height=1></td>
  <td><input type="image" src="/media/images/save_red.gif" border=0 name="<% $widget %>|save_cb" value="Save"></td>
  <td><input type="image" src="/media/images/save_and_stay_lgreen.gif" border="0" name="<% $widget %>|save_and_stay_cb"></td>
  <td width=60><img src="/media/images/spacer.gif" width=60 height=1></td>
  <td><input type="image" src="/media/images/cancel_lgreen.gif" border=0 name="<% $widget %>|return_cb" value="Return To Desk"></td>
  <td><input type="image" src="/media/images/cancel_check_out_lgreen.gif" border=0 name="<% $widget %>|cancel_cb" value="Cancel Checkout"></td>
  <td width=60><img src="/media/images/spacer.gif" width=60 height=1></td>
</tr>
</table>
