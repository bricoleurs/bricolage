<%perl>
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

    $m->comp('/widgets/listManager/listManager.mc',
	     object => 'output_channel',
	     userSort => 0,
	     def_sort_field => 'name',
	     title => 'Output Channels',
	     objs => scalar $asset->get_output_channels,
	     addition => undef,
	     fields => [qw(name description primary)],
	     field_titles => { primary => 'Primary' },
	     field_values => $oc_sub,
	     profile => undef,
	     select =>  sub { return if $_[0]->get_id == $primid;
                              return ['Delete', 'rem_oc']
                            },
	     number => $num
	    );

</%perl>
<table border="1" cellpadding="2" cellspacing="0" width="580" bordercolor="#cccc99" style="border-style:solid; border-color:#cccc99;">
<tr><td class="medHeader" style="border-style:solid; border-color:#cccc99;"><& '/widgets/select_object/select_object.mc',
    object => 'output_channel',
    field  => 'name',
    exclude => [ map { $_->get_id } $asset->get_output_channels ],
    no_persist => 1,
    name   => "$widget|add_oc_cb",
    default => ['' => 'Add Output Channel'],
    objs => $at_ocs,
    js => "onChange='submit()'",
    useTable => 0,
&></td></tr>
</table>
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

$Revision: 1.3 $

=head1 DATE

$Date: 2003-08-07 18:21:48 $

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
