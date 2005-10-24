%#--- Documentation ---#

<%doc>

=head1 NAME

publish - A widget to display publish options.

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

<& '/widgets/publish/publish.mc' &>

=head1 DESCRIPTION



=cut

</%doc>

%#-- Once Section --#
<%once>;
my $widget = 'publish';
my $story_key_name = 'story';
my $media_key_name = 'media';
my $story_pkg = get_package_name($story_key_name);
my $media_pkg = get_package_name($media_key_name);
</%once>

%#-- Init Section --#
<%init>;
my ($story_pub_ids, $media_pub_ids);
if (my $d = get_state_data($widget)) {
    # Get the original assets
    $story_pub_ids = mk_aref($d->{story});
    $media_pub_ids = mk_aref($d->{media});
    # Get related assets, too
    my ($rel_story_ids, $rel_media_ids) = @{$d}{qw(rel_story rel_media)};

    # Check for related stories.
    if (defined $rel_story_ids && @$rel_story_ids) {
        # Create hidden callback fields for the original stories.
        $m->comp('/widgets/profile/hidden.mc',
                 name => 'publish|select_publish_cb',
                 value => "story=$_")
          for @$story_pub_ids;
        # Push the related stories onto the list.
        push @$story_pub_ids, @$rel_story_ids
    }

    # Check for related media.
    if (defined $rel_media_ids && @$rel_media_ids) {
        # Create hidden callback fields for the original media.
        $m->comp('/widgets/profile/hidden.mc',
                 name => 'publish|select_publish_cb',
                 value => "media=$_")
          for @$media_pub_ids;
        # Push the related media onto the list.
        push @$media_pub_ids, @$rel_media_ids
    }
}

my $objs = [];
# Get the stories together.
if (@$story_pub_ids) {
    for my $s ( $story_pkg->list({
        version_id => ANY(@{ mk_aref($story_pub_ids) })
    }) ) {
        if ($s->get_checked_out) {
            add_msg('Cannot publish checked-out story "[_1]"', $s->get_title);
            next;
        }
        push @$objs, $s;
    }
}

# Get the media together.
if (@$media_pub_ids) {
    for my $m ( $media_pkg->list({
        version_id => ANY(@{ mk_aref($media_pub_ids) })
    }) ) {
        if ($m->get_checked_out) {
            add_msg('Cannot publish checked-out media "[_1]"', $m->get_title);
            next;
        }
        push @$objs, $m;
    }
}

$m->comp('/widgets/wrappers/sharky/table_top.mc',
         caption => '%n to Publish',
         object  => 'asset' );
$m->comp('/widgets/listManager/listManager.mc',
	 object => 'asset',
	 addition => undef,
	 objs => $objs,
	 fields => [qw(id name uri cover_date)],
	 profile => undef,
	 select => $select,
	);
$m->comp('/widgets/wrappers/sharky/table_bottom.mc');
</%init>

<%once>
my $select = sub {
    my $asset = shift;
    my $id = $asset->get_id;
    my $key = $asset->key_name;  # 'story' or 'media'

    # determine if $asset is a related asset
    if (my $d = get_state_data('publish')) {   # $widget eq 'publish'
        foreach my $k (qw(story media)) {
            my %rel_ids = map { $_ => 1 } @{ mk_aref($d->{"rel_$k"}) };
            if (exists $rel_ids{$id}) {
                # it's a related asset
                return ['Publish', 'publish|select_publish_cb',
                        "$key=$id", { checked => 1 }];
            }
        }

        # if it gets here, it must not be a related asset,
        # so we don't show a checkbox
        return;
    }
};
</%once>

%#--- Log History ---#

