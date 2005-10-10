<%doc>

=head1 NAME

media_prof.mc - Profile for media documents

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

<& '/widgets/media_prof/media_prof.mc' &>

=head1 DESCRIPTION

The Widget for displaying media objects

=cut

</%doc>
<%once>
my $widget = 'media_prof';

my $needs_reload = sub {
    my ($media, $id, $checkout, $version) = @_;

    # We need a reload if there is no media object.
    return 1 unless $media;

    # Reload if the IDs don't match.
    return 1 if $media->get_id != $id;

    # Reload if there is a user ID but its not the current user ID
    return 1 if defined $media->get_user__id and ($media->get_user__id != get_user_id);

    # Reload if $checkout is passed but doesn't sync w/ the media checkout.
    return 1 if defined($checkout) and ($media->get_checked_out != $checkout);

    # Reload if $version is passed but doesn't sync w/ the media version.
    return 1 if defined($version) and ($media->get_version != $version);

    # No reload is necessary
    return 0;
};
</%once>
%#--- Arguments ---#
<%args>
$id		  => undef
$work_id  => undef
$checkout => undef
$version  => undef
$param    => undef
$section
$return	  => undef
</%args>
%#-- Initialization --#
<%init>
# clear state if this is new
if ($section eq 'new') {
    # A hacky fix for the 'sidenav query string breakin shit' problem.
    # Get an existing workflow ID if we weren't passed one.
    $work_id ||= get_state_data($widget, 'work_id');

    set_state( $widget, 'edit', { 'work_id' => $work_id});
} else {
	# get the id that was passed in or get it from state
	$id ||= get_state_data($widget, 'id');
	set_state_data($widget, 'id', $id);

	init_state_name($widget, 'view');
}

if ($id) {
    my $media = get_state_data($widget, 'media');

    # Reload the media unless $media is defined AND
    if ($needs_reload->($media, $id, $checkout, $version)) {
        my $param = {'id' => $id};

        $param->{checked_in} = 1 unless $checkout;
        $param->{version} = $version if defined $version;
        $media = Bric::Biz::Asset::Business::Media->lookup($param);

        # Clear the media state data
        clear_state($widget);

        # Clear the container profile state data.  WARNING!  this is not
        # a cool thing to do, but I can't think of any legitimate way of
        # clearing state.  new.html does it the right way though...
        clear_state('container_prof');

        # Set the media in the state data.
        set_state_data($widget, 'media', $media);
        set_state_data($widget, 'version_view', 1) if defined($version);
    }

    if ($param->{diff}) {
        set_state_data($widget, version_view => 1);

        my $version = $media ? $media->get_version : 0;

        for my $pos (qw(from to)) {
            my $pos_version = $param->{"$pos\_version"};

            my ($diff_media) = $pos_version == $version
                ? $media
                : Bric::Biz::Asset::Business::Media->list({
                id      => $id,
                version => $pos_version,
            });

            # Find the relevant event.
            my $event = Bric::Util::Event->lookup({
                obj_id   => $id,
                Limit    => 1,
                (
                    $pos_version == $version
                        ? ( key_name => 'media_save')
                        : ( key_name => 'media_checkin',
                            value => $pos_version )
                )
            });
            $param->{"$pos\_time"} = $event->get_timestamp('epoch') if $event;
            $param->{$pos} = $diff_media;
        }
    }

    my $state_name = 'view';
    unless (defined $version || $param->{diff}) {
        my $m_uid = $media->get_user__id;
        # Don't go into edit mode if this is a previous version.
        $state_name = 'edit'
            if defined $m_uid && $m_uid == get_user_id
               && chk_authz($media, EDIT, 1);
    }

    # Set the state to either edit or view.
    set_state_name($widget, $state_name);
    set_state_data($widget, 'last_page', last_page(0)) if $state_name eq 'view';
}

if ($return) {
    set_state_data($widget, 'return', $return);
}

my $state = get_state_name($widget);

if (my $media = get_state_data($widget, 'media')) {
    # Make sure the user has the correct permissions
    chk_authz($media, $state eq 'edit' ? EDIT : READ);
    # Set the title for this request.
    $r->pnotes("$widget|title", '&quot;' . $media->get_title . '&quot;');
}

$m->comp($state.'_'.$section.'.html', widget => $widget, param => $param);
</%init>
