<%doc>

=head1 NAME

bricolage-wysiwyg interface - Pass the available Bricolage internals to 
external JavaScript applications (like Wysiwyg editor)

=head1 SYNOPSIS

%js_vars = <& '/widgets/wysiwyg/bricolage-wysiwyg.mc' &>;

=head1 DESCRIPTION

Pick up any variable from Bricolage and pass to any JavaScript applications
that knows how to use it. In this case it's wysiwyg editor, but it could be 
anything. Returns a hash that will be delivered in <head> section as JS variables:
var $key_name = $value;

Here, the three strings (JS arrays) are returned, namely: related_images,
related_nonImages, and related_objects, containing all related media of MIME 
type image/, then all related stories together with all media of MIME type
other than image/, and finally all related media of MIME type suitable
for html object tag (audio, video, flash). 

To extend for passing other Bricolage internals just set 
$js_vars{your_js_variable} = $value;

=cut

</%doc>
<%init>
my %js_vars;
my ($title,$uuid);

my $doc = get_state_data(story_prof => 'story'); 
return unless ($doc);
my (@el) = $doc->get_elements();
my (@relmedii,@relstory);
foreach my $e (@el)  #make lists of all related stories and all related media
{
   if ($e->is_container) { push (@relmedii,$e) if $e->can_relate_media; };
   if ($e->is_container) { push (@relstory,$e) if $e->can_relate_story; }
}

@relmedii = map ($_->can_relate_media ? $_ : undef, @relmedii) if (@relmedii);
my (@mlist, @othermlist, @objectmlist, $rm, $media);
foreach $rm (@relmedii) {
   ($media) = $rm->get_related_media;
   if ($media) {
      if ($_=$media->get_media_type->get_name, s/^image//) {
        push (@mlist,$media); #image media
      } else {
        push (@othermlist,$media); #other non-image media
        if ( ($_=$media->get_media_type->get_name, s/^video//) || 
             ($_=$media->get_media_type->get_name, s/^audio//) || 
             ($_=$media->get_media_type->get_name, s/^application\/x-shockwave-flash//)
           ) {
           push(@objectmlist, $media); #object video and audio
        }
     }
   }
}
my (@items);
foreach $media (@mlist) {
    $title = $media->get_title;
    $uuid = $media->get_uuid;
    push (@items, "[ '$title', '/preview/media/$uuid' ]"); #cleanup /preview/media inside templates!
}
$js_vars{"related_images"} = "[ ['select image',''],".join(",",@items)." ];";

@items = ();
# make link-able objects: non-images, and stories
my ($rs, $stories);
foreach $rs (@relstory) {
   ($stories) = $rs->get_related_story;
   if ($stories) {
    $title = $stories->get_title;
    $uuid = $stories->get_uuid;
    push (@items, "[ 'story: $title', '/preview/media/$uuid' ]"); #dummy "preview/media" just to make templates simpler
   }
}
foreach $media (@othermlist) {
    $title = $media->get_title;
    $uuid = $media->get_uuid;
    push (@items, "[ 'media: $title', '/preview/media/$uuid' ]");
}
$js_vars{"related_nonImages"} = "[  ['select story/media',''],".join(",",@items)." ];";

@items = ();
# make flash objects: flash and video
my @flist;
foreach $media (@objectmlist) {
    $title = $media->get_title;
    $uuid = $media->get_uuid;
    push (@items, "[ '$title', '/preview/media/$uuid' ]");
}
$js_vars{"related_objects"} = "[  ['select flash/video/audio',''],".join(",",@items)." ];";
return %js_vars;
</%init>
