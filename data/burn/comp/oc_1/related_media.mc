<!-- Start "Related Media" -->
% my $rel_media = $element->get_related_media;

%# This template only handles images.
% if (substr($rel_media->get_media_type->get_name, 0, 5) eq 'image') {
<img src="<% $rel_media->get_uri %>">
% }
<!-- End "Related Media" -->