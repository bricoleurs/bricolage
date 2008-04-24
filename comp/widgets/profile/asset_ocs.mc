<& '/widgets/wrappers/table_top.mc',
    caption => 'Output Channels',
    number  => $num
&>

<& '/widgets/listManager/listManager.mc',
    object         => 'output_channel',
    userSort       => 0,
    def_sort_field => 'name',
    objs           => scalar $asset->get_output_channels,
    addition       => undef,
    fields         => [qw(name description primary)],
    field_titles   => { primary => 'Primary' },
    field_values   => $oc_sub,
    profile        => undef,
    select         => $select_sub,
&>

% if (@$at_ocs) {
<div class="actions">
<& '/widgets/select_object/select_object.mc',
    object     => 'output_channel',
    field      => 'name',
    no_persist => 1,
    name       => "$widget|add_oc_cb",
    default    => ['' => 'Add Output Channel'],
    objs       => $at_ocs,
    js         => "onchange='submit()'",
    useTable   => 0,
&>
</div>
% }
<& '/widgets/wrappers/table_bottom.mc' &>

<%args>
$widget
$asset
$ocs
$num
$at_ocs
</%args>

<%init>
my $sid = $asset->get_site_id;
my %curr_ocs = map { $_->get_id => undef } $asset->get_output_channels;
$at_ocs = [ grep { $_->get_site_id == $sid && !exists $curr_ocs{$_->get_id} } @$at_ocs ];
my $primid = $asset->get_primary_oc_id;
my $oc_sub = sub {
    return unless $_[1] eq 'primary';
    my $ocid = $_[0]->get_id;
    # Output a hidden field for this included OC.
    $m->scomp('/widgets/profile/radio.mc',
        name     => 'primary_oc_id',
        value    => $ocid,
        checked  => $ocid == $primid,
        useTable => 0
    );
};
my $select_sub = sub {
    return if $_[0]->get_id == $primid;
    return ['Delete', 'rem_oc']
};
</%init>

<%doc>

=head1 NAME

/widgets/profile/asset_ocs.mc - The Asset Output Channel display component

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

  $m->comp('/widgets/profile/asset_ocs.mc',
           asset  => $story,
           widget => $widget,
           ocs    => \@ocs
          );

=head1 DESCRIPTION

This component displays form widgets for adding output channels to business
assets. It lists all associated OCs along with a column of radio buttons to
choose which OC is the primary, and a column of delete checkboxes to remove
secondary OCs.  A list of possible additional OCs is provided to allow the 
user to associate others.

The arguments (all required) are:

=over 4

=item C<asset>

The asset for which the output channels are to be displayed.

=item C<widget>

The name of the widget for which the output channels are to be displayed
(either "story_prof" or "media_prof").

=item C<$ocs>

An anonymous array of all of the available output channels to be displayed.

=back

=pod

</%doc>
