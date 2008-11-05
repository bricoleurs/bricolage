<%doc>
###############################################################################

=head1 NAME

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
my $pkg;
my $disp;
if ($widget eq 'story_prof') {
    $pkg = get_package_name('story');
    $disp = get_disp_name('story');
} elsif ($widget eq 'media_prof') {
    $pkg = get_package_name('media');
    $disp = get_disp_name('media');
} else {
    $pkg = get_package_name('template');
    $disp = get_disp_name('template');
}

my $deskText = qq{<select name="$widget|desk">};
my $can_pub;
if ($desks) {
    my $to      = $lang->maketext('to');
    my $and     = $lang->maketext('and');
    my $shelve  = $lang->maketext('Shelve');

    foreach my $d (@$desks) {
        my $id = $d->get_id;
        my $ag_id = $d->get_asset_grp;
        next unless chk_authz(undef, READ, 1, $ag_id);
        $deskText .= qq{<option value="$id"};
        $deskText .= ' selected="selected"' if $id == $cd->get_id;
        $deskText .= ">$to " .  $d->get_name . "</option>";
        $can_pub = 1 if $d->can_publish and
          chk_authz(undef, PUBLISH, 1, $ag_id);
    }

    # Set up choice to remove from workflow.
    $deskText .= qq{<option value="remove">$and $shelve</option>};

    # Set up choice to publish, if possible.
    if ($can_pub) {
        my ($act, $cb) = $widget eq 'tmpl_prof'
          ? ($lang->maketext('Deploy'), 'deploy')
          : ($lang->maketext('Publish'), 'publish');
        $deskText .= qq{<option value="$cb">$and $act</option>};
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
    <& '/widgets/profile/checkbox.mc',
        name    => "$widget|delete",
        id      => $widget . "delete",
        value   => "Delete",
        disp    => $lang->maketext("Delete this " . $disp),
        label_after => 1,
        useTable    => 0,
    &>
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
    <& "/widgets/buttons/submit.mc",
        disp      => 'Revert',
        widget    => $widget,
        cb        => 'revert_cb',
        button    => 'revert_dgreen',
        useTable  => 0
    &>
    <% $lang->maketext('to') %> <% $versionText %>
    <& "/widgets/profile/hidden.mc",
        name    => "$widget|view_cb",
        value   => "",
    &>
    <a href="<% $r->uri %>" class="orangeLinkBold" title="View previous version" onclick="return customSubmit('theForm', '<% $widget %>|view_cb', 1)"><% $lang->maketext('View') %></a>
    <& "/widgets/profile/hidden.mc",
        name    => "$widget|diff_cb",
        value   => "",
    &>
    <a href="<% $r->uri %>" class="orangeLinkBold" title="Diff previous version" onclick="return customSubmit('theForm', '<% $widget %>|diff_cb', 1)"><% $lang->maketext('Diff') %></a>
</div>
% }

<div class="buttons">
<div class="save">
    <& "/widgets/buttons/submit.mc",
        disp      => 'Save',
        widget    => $widget,
        cb        => 'save_cb',
        button    => 'save_red',
        useTable  => 0
    &>
    <& "/widgets/buttons/submit.mc",
        disp      => 'Save and Stay',
        widget    => $widget,
        cb        => 'save_and_stay_cb',
        button    => 'save_and_stay_lgreen',
        useTable  => 0
    &>
</div>
<div class="cancel">
    <& "/widgets/buttons/submit.mc",
        disp      => 'Return',
        widget    => $widget,
        cb        => 'return_cb',
        button    => 'cancel_lgreen',
        useTable  => 0
    &>
    <& "/widgets/buttons/submit.mc",
        disp      => 'Cancel Checkout',
        widget    => $widget,
        cb        => 'cancel_cb',
        button    => 'cancel_check_out_lgreen',
        useTable  => 0
    &>
</div>
</div>

</div>
