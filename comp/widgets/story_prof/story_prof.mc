<%doc>

=head1 NAME

story_prof.mc - The profile of stories widget

=head1 SYNOPSIS

<& '/widgets/story_prof/story_prof.mc' &>

=head1 DESCRIPTION



=cut

</%doc>
<%once>
my $widget = 'story_prof';

my $needs_reload = sub {
    my ($story, $id, $checkout, $version) = @_;

    # We need a reload if there is no story object.
    return 1 unless $story;

    # Reload if the IDs don't match.
    return 1 if $story->get_id != $id;

    # Reload if there is a user ID but its not the current user ID
    my $uid = $story->get_user__id;
    return 1 if defined $uid and $uid != get_user_id;

    # Reload if $checkout is passed but doesn't sync w/ the story checkout.
    return 1 if defined $checkout and !$story->get_checked_out;

    # Reload if $version is passed but doesn't sync w/ the story version.
    return 1 if defined $version and $story->get_version != $version;

    # No reload is necessary
    return 0;
};
</%once>
%#--- Arguments ---#
<%args>
$id       => undef
$work_id  => undef
$checkout => undef
$version  => undef
$param    => undef
$return	  => undef
$section
</%args>
%#--- Initialization ---#
<%init>
# Clear out the state data if this is our first time here.
if ($section eq 'new' or $section eq 'find_alias' or $section eq 'clone') {
    # A hacky fix for the 'sidenav query string breakin shit' problem.
    # Get an existing workflow ID if we weren't passed one.
    $work_id ||= get_state_data($widget, 'work_id');

    set_state($widget, 'edit', {'work_id' => $work_id});
} else {
    # Use the ID passed or otherwise take if from the state data.
    $id ||= get_state_data($widget, 'id');
    set_state_data($widget, 'id', $id);

    init_state_name($widget, 'view');
}

# Lookup the Story
if ($id) {
    my $story = get_state_data($widget, 'story');

    # Reload the story unless $story is defined AND
    if ($needs_reload->($story, $id, $checkout, $version)) {
        my $param = {'id' => $id};

        $param->{checked_in} = 1 unless $checkout;
        $param->{version} = $version if defined $version;
        $story = Bric::Biz::Asset::Business::Story->lookup($param);

        # Clear the story state data
        clear_state($widget);

        # Clear the container profile state data.  WARNING!  this is not
        # a cool thing to do, but I can't think of any legitimate way of
        # clearing state.  new.html does it the right way though...
        clear_state('container_prof');

        # Set the story in the state data.
        set_state_data($widget, 'story', $story);

    }

    if (not exists $param->{diff} and exists $param->{'diff.x'}) {
        # IE only sends diff.x and diff.y for <input type="image">
        $param->{diff} = 1;
    }

    if ($param->{diff}) {
        my $version = $story ? $story->get_version : 0;

        for my $pos (qw(from to)) {
            my $pos_version = $param->{"$pos\_version"};

            my ($diff_story) = $pos_version == $version
                ? $story
                : Bric::Biz::Asset::Business::Story->list({
                id      => $id,
                version => $pos_version,
            });

            # Find the relevant event.
            my $event = Bric::Util::Event->lookup({
                obj_id   => $id,
                Limit    => 1,
                (
                    $pos_version == $version
                        ? ( key_name => 'story_save')
                        : ( key_name => 'story_checkin',
                            value => $pos_version )
                )
            });
            $param->{"$pos\_time"} = $event->get_timestamp('epoch') if $event;
            $param->{$pos} = $diff_story;
        }
    }

    my $state_name = 'view';
    if (defined $version || $param->{diff}) {
        set_state_data($widget, 'version_view', 1) if defined $version;
    } else {
        my $s_uid = $story->get_user__id;
        # Don't go into edit mode if this is a previous version.
        $state_name = 'edit'
            if defined $s_uid && $s_uid == get_user_id
               && chk_authz($story, EDIT, 1);
    }

    # Set the state to either edit or view.
    set_state_name($widget, $state_name);
    set_state_data($widget, 'last_page', last_page(0)) if $state_name eq 'view';
}

if ($return) {
    set_state_data($widget, 'return', $return);
}

# Get the current state.
my $state = get_state_name($widget);

if (my $story = get_state_data($widget, 'story')) {
    # Make sure the user has the correct permissions
    chk_authz($story, $state eq 'edit' ? EDIT : READ);
    # Set the title for this request.
    $r->pnotes("$widget|title", '&quot;' . $story->get_title . '&quot;');
}

if ($state eq "edit" && $section eq "contributors") {
    $m->comp("/widgets/profile/contributors/edit.html", asset_type => 'story', widget => $widget, param => $param);
} else {
    $m->comp($state.'_'.$section.'.html', widget => $widget, param => $param);
}
</%init>
