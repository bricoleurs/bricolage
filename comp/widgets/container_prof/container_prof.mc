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
$state = $action unless $state && $action eq 'view';

# The old code here read:
#
#   # Don't change the state unless $action isn't 'edit'.
#   $state = $action unless $action eq 'edit';
#
# This exception was causing the container_prof code to occasionally show a
# view screen rather than an edit screen.  Maybe there was a good reason
# for this exception and the bug is really in another place in container_prof?
# Set the state name if it has not been set.
#
# At any rate, it was changed to:
#
# # Always set $state to $action unless $action is 'view';
# $state = $action unless $action eq 'view';
#
# But that caused problems for super bulk editing media. So I think that the
# above may be correct now. Time will tell.


$state = set_state_name($widget, $state || 'edit');

if ($state eq 'edit_bulk') {
    $action = 'edit_bulk';

    # Load up the data the first time around.
    unless (get_state_data($widget, 'dtiles')) {
        my $field = get_state_data($widget, 'field');

        # Grab only the tiles that have the name $field
        my @dtiles = grep($_->get_key_name eq $field, $tile->get_tiles());

        # Load the data into an array which will be used until they finish.
        my @data = map { $_->get_data } @dtiles;

        # Initialize the state data.
        set_state_data($widget, 'dtiles',    \@dtiles);
        set_state_data($widget, 'data',      \@data);
        init_state_data($widget, 'separator', "\n");
        init_state_data($widget, 'cols',      78);
        init_state_data($widget, 'rows',      30);
    }
} elsif ($state eq 'edit_super_bulk') {
    $action = 'edit_super_bulk';

    # Load up the data the first time around.
    unless (get_state_data($widget, 'dtiles')) {
        # Grab all tiles
        my @data;
        my @dtiles = $tile->get_tiles();

        # Load the data into an array which will be used until they finish.
        my $def_fld = get_state_data('_tmp_prefs', 'container_prof.def_field');
        foreach my $dt (@dtiles) {
            # Ignore containers when looking to fill the default element.
            unless ($dt->is_container) {
                my $atd = $dt->get_element_data_obj();
                if (!defined($def_fld) and $atd->get_quantifier) {
                    $def_fld = lc($atd->get_key_name);
                    $def_fld =~ y/a-z0-9/_/cs;
                }
            }
            push @data, [$dt->get_key_name, $dt->get_data];
        }

        # Initialize the state data.
        set_state_data('_tmp_prefs', 'container_prof.def_field', $def_fld);
        set_state_data($widget, 'dtiles',    \@dtiles);
        set_state_data($widget, 'data',      \@data);
        init_state_data($widget, 'separator', "\n");
        init_state_data($widget, 'cols',      78);
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


