<%doc>

=head1 NAME

tmpl_prof - Handle adding and updating templates.

=head1 SYNOPSIS

<& '/widgets/tmpl_prof/tmpl_prof.mc' &>

=head1 DESCRIPTION



=cut

</%doc>
<%once>
my $widget = 'tmpl_prof';
my $needs_reload = sub {
    my ($fa, $id, $checkout, $version) = @_;

    # We need a reload if there is no media object.
    return 1 unless $fa;

    # Reload if the IDs don't match.
    return 1 if $fa->get_id != $id;

    # Reload if there is a user ID but its not the current user ID
    my $uid = $fa->get_user__id;
    return 1 if defined $uid and $uid != get_user_id;

    # Reload if $checkout is passed but doesn't sync w/ the fa checkout.
    return 1 if defined $checkout and !$fa->get_checked_out;

    # Reload if $version is passed but doesn't sync w/ the fa version.
    return 1 if defined $version and $fa->get_version != $version;

    # No reload is necessary
    return 0;
};
</%once>
%#--- Arguments ---#
<%args>
$id         => undef
$work_id    => undef
$checkout   => undef
$version    => undef
$param      => undef
$section
$return     => undef
</%args>
%#--- Initialization ---#
<%init>
# Clear out the state data if this is our first time here.
if ($section eq 'new') {
    # A hacky fix for the 'sidenav query string breakin shit' problem.
    # Get an existing workflow ID if we weren't passed one.
    $work_id ||= get_state_data($widget, 'work_id');

    # Clear the state and set the work ID and create a reset key to use later.
    set_state($widget, edit => {
        work_id   => $work_id,
        reset_key => time
    });
} else {
    # Use the ID passed or otherwise take if from the state data.
    $id ||= get_state_data($widget, 'id');
    set_state_data($widget, id => $id);
    init_state_name($widget => 'view');
}

# Lookup the FA
if ($id) {
    my $fa = get_state_data($widget, 'template');

    # Set up diff versions.
    # Reload the story unless $fa is defined AND
    if ($needs_reload->($fa, $id, $checkout, $version)) {
        # Clear the fa state data
        clear_state($widget);

        my $param = { id => $id };
        $param->{checked_in} = 1 unless $checkout;
        $param->{version}    = $version if defined $version;
        $fa = Bric::Biz::Asset::Template->lookup($param);

        # Set the fa in the state data.
        set_state_data($widget, template => $fa);
    }

    if (not exists $param->{diff} and exists $param->{'diff.x'}) {
        # IE only sends diff.x and diff.y for <input type="image">
        $param->{diff} = 1;
    }

    if ($param->{diff}) {
        my $version = $fa ? $fa->get_version : 0;

        for my $pos (qw(from to)) {
            my $pos_version = $param->{"$pos\_version"};

            my ($tmpl) = $pos_version == $version ? do {
                $pos eq 'to' ? $fa : ref($fa)->list({
                    id         => $id,
                    checked_in => 1,
                })
            } : ref($fa)->list({
                id          => $id,
                version     => $pos_version,
            });

            # Find the relevant event.
            my $event = Bric::Util::Event->lookup({
                obj_id   => $id,
                Limit    => 1,
                (
                    $pos_version == $version
                        ? ( key_name => 'template_save')
                        : ( key_name => 'template_checkin',
                            value => $pos_version )
                )
            });
            $param->{"$pos\_time"} = $event->get_timestamp('epoch') if $event;
            $param->{$pos} = $tmpl;
        }
    }

    my $state_name = 'view';
    if (defined $version || $param->{diff}) {
        set_state_data($widget, 'version_view', 1) if defined $version;
    } else {
        my $t_uid = $fa->get_user__id;
        # Don't go into edit mode if this is a previous version.
        $state_name = 'edit'
            if defined $t_uid && $t_uid == get_user_id
               && chk_authz($fa, EDIT, 1);
    }

    # Set the state to either edit or view.
    set_state_name($widget, $state_name);
}

if ($return) {
    set_state_data($widget, 'return', $return);
}

# Get the current state.
my $state = get_state_name($widget);

if (my $fa = get_state_data($widget, 'template')) {
    # Make sure the user has the correct permissions
    chk_authz($fa, $state eq 'edit' ? EDIT : READ);
    # Set the title for this request.
    $r->pnotes("$widget|name", '&quot;' . $fa->get_name . '&quot;');
}

$m->comp($state.'_'.$section.'.html', widget => $widget, param => $param);
</%init>
