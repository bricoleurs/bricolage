%#--- Documentation ---#

<%doc>

=head1 NAME

summary - Displays a summary of a asset objects.

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:31 $

=head1 SYNOPSIS

<& '/widgets/story_summary/story_summary.mc' &>

=head1 DESCRIPTION



=cut

</%doc>

%#--- Arguments ---#

<%args>
$asset
$type   => 'story'
$style  => 'meta'
$header => undef
$number => undef
$frame  => 1
$button => undef
</%args>

%#--- Initialization ---#

<%once>
my $widget = 'summary';

my %types = ('Bric::Biz::Asset::Formatting' => 'formatting',
	     'Bric::Biz::Asset::Business::Story' => 'story',
	     'Bric::Biz::Asset::Business::Media' => 'media');
</%once>

<%init>
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

%#--- Log History ---#

<%doc>
$Log: summary.mc,v $
Revision 1.1  2001-09-06 21:52:31  wheeler
Initial revision

</%doc>
