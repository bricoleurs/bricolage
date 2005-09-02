<%doc>

=head1 NAME

container_prof - The container profile editor.

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

<& '/widgets/container_prof/container_prof.mc', state => 'edit' &>

=head1 DESCRIPTION

A widget to allow the creation and modification of container tiles.

=cut

</%doc>
<%args>
$tile => undef
$title => undef
$num => undef
$action
$start_count => undef
$show_summary => undef
$args         => \%ARGS
</%args>

%#--- Initialization ---#

<%once>
my $widget = 'container_prof';
</%once>

<%init>;
# Default to using the tile passed in followed by the tile in state.
$tile ||= get_state_data($widget, 'tile');

# Set the tile that we will be editing into state.
set_state_data($widget, 'tile', $tile);
set_state_data($widget, 'start', $start_count);
my $state = get_state_name($widget);

# Always set $state to $action unless $action is 'view';
$state = $action unless $action eq 'view';
$state = set_state_name($widget, $state || 'edit');
$action = 'edit_bulk' if $state eq 'edit_bulk';

# Add a bit of error correction when users try to use the back buttons.
$m->out("<input type='hidden' name='$widget|top_stack_tile_id' value='".$tile->get_id."' />\n");
$m->out("<input type='hidden' name='$widget|state_name' value='".$state."' />\n");

return $m->comp(
    "$action.html",
    widget       => $widget,
    num          => $num,
    title        => $title,
    show_summary => $show_summary,
    args         => $args,
);

</%init>

%#--- Log History ---#


