%#--- Documentation ---#

<%doc>

=head1 NAME

container_prof - The container profile editor.

=head1 VERSION

$Revision: 1.4 $

=head1 DATE

$Date: 2001-11-20 00:04:06 $

=head1 SYNOPSIS

<& '/widgets/container_prof/container_prof.mc', state => 'edit' &>

=head1 DESCRIPTION

A widget to allow the creation and modification of container tiles.

=cut

</%doc>

%#--- Arguments ---#

<%args>
$tile => undef
$title => undef
$num => undef
$action
$start_count => undef
$show_summary => undef
</%args>

%#--- Initialization ---#

<%once>
my $widget = 'container_prof';
</%once>

<%init>

# Default to using the tile passed in followed by the tile in state.
$tile ||= get_state_data($widget, 'tile');

# Set the tile that we will be editing into state.
set_state_data($widget, 'tile', $tile);
set_state_data($widget, 'start', $start_count);
my $state = get_state_name($widget);

# Don't change the state unless $action isn't 'edit'.
$state = $action unless $action eq 'edit';

# Set the state name if it has not been set.
$state = set_state_name($widget, $state || 'edit');

if ($state eq 'edit_bulk') {
    $action = 'edit_bulk';

    # Load up the data the first time around.
    unless (get_state_data($widget, 'dtiles')) {
	my $field = get_state_data($widget, 'field');

	# Grab only the tiles that have the name $field
	my @dtiles = grep($_->get_name eq $field, $tile->get_tiles());

	# Load the data into an array which will be used until they finish.
	my @data = map { $_->get_data } @dtiles;

	# Intialize the state data.
	set_state_data($widget, 'dtiles',    \@dtiles);
	set_state_data($widget, 'data',      \@data);
	init_state_data($widget, 'separator', "\n");
	init_state_data($widget, 'cols',      80);
	init_state_data($widget, 'rows',      30);
    }
}

# Add a bit of error correction when users try to use the back buttons.
$m->out("<input type='hidden' name='$widget|top_stack_tile_id' value='".$tile->get_id."'>\n");
$m->out("<input type='hidden' name='$widget|state_name' value='".$state."'>\n");

return $m->comp("$action.html",
	 widget       => $widget,
	 num          => $num,
	 title        => $title,
	 show_summary => $show_summary,
	);

</%init>

%#--- Log History ---#


