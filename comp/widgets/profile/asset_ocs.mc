<%perl>
    my $sid = $asset->get_site_id;
    my %curr_ocs = map { $_->get_id => undef } $asset->get_output_channels;
    $at_ocs = [ grep { $_->get_site_id == $sid && !exists $curr_ocs{$_->get_id} } @$at_ocs ];
    my $primid = $asset->get_primary_oc_id;
    my $oc_sub = sub {
        return unless $_[1] eq 'primary';
        my $ocid = $_[0]->get_id;
        # Output a hidden field for this included OC.
        $m->scomp('/widgets/profile/radio.mc',
                  name => 'primary_oc_id',
                  value => $ocid,
                  checked => $ocid == $primid,
                  useTable => 0
                 );
    };

    $m->comp(
        '/widgets/wrappers/sharky/table_top.mc',
        caption => 'Output Channels',
        number => $num
    );

    $m->comp(
        '/widgets/listManager/listManager.mc',
        object         => 'output_channel',
        userSort       => 0,
        def_sort_field => 'name',
        title          => 'Output Channels',
        number         => $num,
        objs           => scalar $asset->get_output_channels,
        addition       => undef,
        fields         => [qw(name description primary)],
        field_titles   => { primary => 'Primary' },
        field_values   => $oc_sub,
        profile        => undef,
        select         => sub {
            return if $_[0]->get_id == $primid;
            return ['Delete', 'rem_oc']
        },
    );
</%perl>
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
<& '/widgets/wrappers/sharky/table_bottom.mc' &>
<%args>
$widget
$asset
$ocs
$num
$at_ocs
</%args>
<%doc>

=head1 NAME

/widgets/profile/asset_ocs.mc - The Asset Output Channel display component

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  $m->comp('/widgets/profile/asset_ocs.mc',
           asset  => $story,
           widget => $widget,
           ocs    => \@ocs
          );

=head1 DESCRIPTION

This component displays form widgets for adding output channels to business
assets. If the number of possible output channels (passed via the C<$ocs>
array reference argument) to be displayed is less than four, it will output
check boxes with all of the output channels. If the number of possible output
channels is four or more, it will display a double list with four rows of
output channels visible in each scrollable list.

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

If the fields are checkboxes, there will be a hidden field called
"$widget|do_ocs" and the checkbox names will be "$widget|oc". These will be an
array reference if more than one checkbox is checked. If the fields are in the
form of a double list, the field names will be "add_oc" and "rem_oc". The
former will be a single ID or array reference of IDs to be added to the
story. The latter will be a single ID or array reference of IDs to be removed
from the story.

=pod

</%doc>
