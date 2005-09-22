<!-- Start "Related Story" -->
% my $rel_story = $element->get_related_story;
<b>Title:</b>&nbsp;
<% $element->get_value('alternate_title') || $rel_story->get_title %><br />
<b>Teaser:</b>&nbsp;
<% $element->get_value('alternate_teaser') ||
$rel_story->get_description %><br />
<!-- End "Related Story" -->
