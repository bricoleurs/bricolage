% if (@$ocs < 4) {
%    # Output check boxes.
<table border="0" width="578" cellpadding="0" cellspacing="0">
  <tr><td align="right" width="125" valign="top">
    <span class="label">Output Channels:</span>
  </td>
  <td width="4"><img src="/media/images/spacer.gif" width="4" height="1" /></td>
  <td width="449">
     <& /widgets/profile/hidden.mc, name => "$widget|do_ocs" &>
%    my %curocs = map { $_->get_id => $_ } $asset->get_output_channels;
%    foreach my $oc (@$ocs) {
         <& /widgets/profile/checkbox.mc,
                 label_after => 1,
                 checked => delete $curocs{$oc->get_id},
                 disp => $oc->get_name,
                 value => $oc->get_id,
                 name => "$widget|oc",
          &><br />
%    }
%    # Add any remainders from the asset itself.
%    foreach my $oc (values %curocs) {
         <& /widgets/profile/checkbox.mc,
                 label_after => 1,
                 checked => 1,
                 disp => $oc->get_name,
                 value => $oc->get_id,
                 name => "$widget|oc",
          &><br />
%    }
  </td></tr>
</table>
<%perl>;
} else {
    # Output double list manager.
    my $left = [ map { { description => $_->get_name, value => $_->get_id } }
                 @$ocs ];
    my $right = [ map { { description => $_->get_name, value => $_->get_id } }
                  $asset->get_output_channels ];
    $m->out("<br />\n");
    $m->comp( "/widgets/doubleListManager/doubleListManager.mc",
              size         => 4,
	      leftOpts     => $left,
	      rightOpts    => $right,
	      formName     => 'theForm',
	      leftName     => 'rem_oc',
	      rightName    => 'add_oc',
	      leftCaption  => "Available Output Channels",
	      rightCaption => 'Current Output Channels',
	    );
}
</%perl>
<%args>
$widget
$asset
$ocs
</%args>
<%doc>

=head1 NAME

/widgets/profile/asset_ocs.mc - The Asset Output Channel display component

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2002-10-09 17:40:25 $

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
