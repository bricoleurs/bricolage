%#--- Documentation ---#

<%doc>

=head1 NAME

publish - A widget to display publish options.

=head1 VERSION

$Revision: 1.9 $

=head1 DATE

$Date: 2004/03/17 09:34:02 $

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
    ($story_pub_ids, $media_pub_ids) = @{$d}{qw(story media)};
    # Get related assets, too
    my ($rel_story_ids, $rel_media_ids) = @{$d}{qw(rel_story rel_media)};
    push @$story_pub_ids, @$rel_story_ids
      if defined($rel_story_ids) && @$rel_story_ids;
    push @$media_pub_ids, @$rel_media_ids
      if defined($rel_media_ids) && @$rel_media_ids;
}

my $objs = [];
# Get the stories together.
foreach my $sid (@{ mk_aref($story_pub_ids) }) {
    my $s = $story_pkg->lookup({ id => $sid });
    if ($s->get_checked_out) {
        add_msg('Cannot publish checked-out story "[_1]"', $s->get_title);
	next;
    }
    push @$objs, $s;
}

# Get the media together.
foreach my $mid (@{ mk_aref($media_pub_ids) }) {
    my $m = $media_pkg->lookup({ id => $mid });
    if ($m->get_checked_out) {
        add_msg('Cannot publish checked-out media "[_1]"', $m->get_title);
	next;
    }
    push @$objs, $m;
}

$m->comp('/widgets/listManager/listManager.mc',
	 object => 'asset',
	 title => '%n to Publish',
	 addition => undef,
	 objs => $objs,
	 fields => [qw(id name uri cover_date)],
	 profile => undef,
	 select => $select,
	);
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

