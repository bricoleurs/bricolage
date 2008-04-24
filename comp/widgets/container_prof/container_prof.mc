<%doc>

=head1 NAME

container_prof - The container profile editor.

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

<& '/widgets/container_prof/container_prof.mc', state => 'edit' &>

=head1 DESCRIPTION

A widget to allow the creation and modification of container elements.

=cut

</%doc>
<%args>
$element        => undef
$title          => undef
$num            => undef
$action
$start_count    => undef
$show_summary   => undef
$args           => \%ARGS
</%args>
<%once>
my $widget = 'container_prof';
</%once>
<%init>;
# Default to using the element passed in followed by the element in state.
$element ||= get_state_data($widget, 'element');

# Set the element that we will be editing into state.
set_state_data($widget, 'element', $element);
set_state_data($widget, 'start', $start_count);
my $state = get_state_name($widget);

# Always set $state to $action unless $action is 'view';
$state = $action unless $state && $action eq 'view';
$state = set_state_name($widget, $state || 'edit');
$action = 'edit_bulk' if $state eq 'edit_bulk';

# Add a bit of error correction when users try to use the back buttons.
$m->comp('/widgets/profile/hidden.mc',
          name  => "$widget|top_stack_element_id",
          value => $element->get_id,
);
$m->comp('/widgets/profile/hidden.mc',
          name  => "$widget|state_name",
          value => $state,
);

return $m->comp(
    "$action.html",
    widget       => $widget,
    num          => $num,
    title        => $title,
    show_summary => $show_summary,
    args         => $args,
);

</%init>
