%#--- Documentation ---#

<%doc>

=head1 NAME

publish - A widget to display publish options.

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2001-11-20 00:04:07 $

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
    ($story_pub_ids, $media_pub_ids) = @{$d}{qw(story media)};
}

my $objs = [];
# Get the stories together.
foreach my $sid (@{ mk_aref($story_pub_ids) }) {
    my $s = $story_pkg->lookup({ id => $sid });
    if ($s->get_checked_out) {
        add_msg("Cannot publish checked-out story &quot;" . $s->get_title
                . ".&quot;");
	next;
    }
    push @$objs, $s;
}

# Get the media together.
foreach my $mid (@{ mk_aref($media_pub_ids) }) {
    my $m = $media_pkg->lookup({ id => $mid });
    if ($m->get_checked_out) {
        add_msg("Cannot publish checked-out media &quot;" . $m->get_title
                . ".&quot;");
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
	 select => undef,
	);
</%init>

%#--- Log History ---#


