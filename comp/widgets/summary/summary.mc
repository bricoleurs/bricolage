<%doc>

=head1 NAME

summary - Displays a summary of asset objects.

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

<& '/widgets/story_summary/story_summary.mc' &>

=head1 DESCRIPTION



=cut

</%doc>
<%args>
$asset
$type   => 'story'
$style  => 'meta'
$header => undef
$number => undef
$frame  => 1
$button => undef
</%args>
<%once>;
my $widget = 'summary';

my %types = (
    'Bric::Biz::Asset::Template'        => 'template',
    'Bric::Biz::Asset::Business::Story' => 'story',
    'Bric::Biz::Asset::Business::Media' => 'media'
);
</%once>
<%init>;
  my ($asset_id, $asset_obj);
  my $pkg = ref $asset;

  # Truncate any of the subpackage stuff on media
  $pkg = 'Bric::Biz::Asset::Business::Media'
    if $pkg =~ /Bric::Biz::Asset::Business::Media/;

  if ($pkg) {
      $asset_id  = $asset->get_id;
      $asset_obj = $asset;
      $type      = $types{$pkg} || 'story';
  } else {
      $asset_id  = $asset;
      my $pkg = get_package_name($type);
      $asset_obj = $pkg->lookup({'id' => $asset_id});
  }

  my $sub_widget = $widget.'.'.$type.'.'.$asset_id;
  set_state_data($sub_widget, 'asset', $asset_obj);

  $m->comp($type.'_'.$style.'.html',
       widget => $sub_widget,
       header => $header,
       number => $number,
       frame  => $frame,
       button => $button);
</%init>
