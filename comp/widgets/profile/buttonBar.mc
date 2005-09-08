<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

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

my ($type, $pkg);
if ($widget eq 'story_prof') {
    $type = 'story';
    $pkg = get_package_name($type);
} elsif ($widget eq 'media_prof') {
    $type = 'media';
    $pkg = get_package_name($type);
} else {
    $type = 'fa';
    $pkg = get_package_name('formatting');
}

my $deskText = qq{<select name="$widget|desk">};
my $can_pub;
if ($desks) {
    foreach my $d (@$desks) {
        my $id = $d->get_id;
        my $ag_id = $d->get_asset_grp;
        next unless chk_authz(undef, READ, 1, $ag_id);
        $deskText .= qq{<option value="$id"};
        $deskText .= " selected" if $id == $cd->get_id;
        $deskText .= ">to " .  $d->get_name . "</option>";
        $can_pub = 1 if $d->can_publish and
          chk_authz(undef, PUBLISH, 1, $ag_id);
    }

    # Set up choice to remove from workflow.
    $deskText .='<option value="remove">and Shelve</option>';

    # Set up choice to publish, if possible.
    if ($can_pub) {
        my ($act, $cb) = $widget eq 'tmpl_prof'
          ? ($lang->maketext('Deploy'), 'deploy')
          : ($lang->maketext('Publish'), 'publish');
        $deskText .= qq{<option value="$cb">and $act</option>};
    }
    $deskText .= "</select>";
}

my $versionText = '';
my $version = $obj->get_version;

if ($version) {
    $versionText = qq{<select name="$widget|version">};
    foreach my $v (reverse 1..$version ) {
        $versionText .= qq{<option value="$v">$v</option>};
    }
    $versionText .= "</select>";
}

</%init>

<div class="buttonBar">
<div class="delete">
    <input type="checkbox" name="<% $widget %>|delete" id="<% $widget %>delete" value="Delete" /> <label for="<% $widget %>delete"><% $lang->maketext('Delete this Profile') %></label>
</div>
<div class="checkin">
<& "/widgets/profile/button.mc",
	disp      => 'Save and Check In',
	widget    => $widget,
	cb        => 'checkin_cb',
	button    => 'check_in_dgreen',
	useTable  => 0
&> <% $deskText %>
</div>

% if ($version) {
<div class="revert">
	<input type="image" src="/media/images/<% $lang_key %>/revert_dgreen.gif" border="0" name="<% $widget %>|revert_cb" value="revert">
	<% $lang->maketext('to') %> <% $versionText %>
    <input type="hidden" name="<% $widget %>|view_cb" value="" />
     <a href="<% $r->uri %>" class="orangeLinkBold" title="View previous version" "onclick="return customSubmit('theForm', '<% $widget %>|view_cb', 1)"><% $lang->maketext('View') %></a>
    <input type="hidden" name="<% $widget %>|diff_cb" value="" />
     <a href="<% $r->uri %>" class="orangeLinkBold" title="Diff previous version" "onclick="return customSubmit('theForm', '<% $widget %>|diff_cb', 1)"><% $lang->maketext('Diff') %></a>
</div>
% }

<div class="buttons">
<div class="save">
	<input type="image" src="/media/images/<% $lang_key %>/save_red.gif" border="0" name="<% $widget %>|save_cb" value="Save">
	<input type="image" src="/media/images/<% $lang_key %>/save_and_stay_lgreen.gif" border="0" name="<% $widget %>|save_and_stay_cb">
</div>
<div class="cancel">
	<input type="image" src="/media/images/<% $lang_key %>/cancel_lgreen.gif" border="0" name="<% $widget %>|return_cb" value="Return To Desk">
	<input type="image" src="/media/images/<% $lang_key %>/cancel_check_out_lgreen.gif" border="0" name="<% $widget %>|cancel_cb" value="Cancel Checkout">
</div>
</div>

</div>
