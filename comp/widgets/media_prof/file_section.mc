% $indent = $indent ? " width: ${indent}px;" : '';
% if ($read_only) {
% $m->comp("/widgets/wrappers/table_top.mc",
%          caption => "The File",
%          number => 2 );
<table class="containerProf">
  <tr>
    <th style="text-align: right;<% $indent %>"><% $lang->maketext('Download') %>:&nbsp;</th>
%     if (my $uri = $media->get_local_uri) {
    <td><a href="<% $uri %>" onclick="window.open(this.href, 'download_} . SERVER_WINDOW_NAME . qq{'); return false;" title="<% $lang->maketext('Download this media') %>"><% $media->get_file_name %></a></td>
%     } else {
    <td><% $lang->maketext('No file has been uploaded') %></td>
%     }
  </tr>
</table>
% $m->comp("/widgets/wrappers/table_bottom.mc");
% } else {
<%perl>
$m->comp("/widgets/wrappers/table_top.mc",
         caption => "Upload a file",
         number => $num
        );
</%perl>
<table class="containerProf">
  <tr>
    <th style="text-align: right";<% $indent %>><%$lang->maketext('File Path')%>:</th>
    <td><input type="file" name="<% $widget %>|file" size="30" /> </td>
    <td><& '/widgets/profile/imageSubmit.mc',
         formName => "theForm",
         callback => $widget ."|update_cb",
         image    => "upload_red"
    &></td>
  </tr>
%   if (my $uri = $media->get_local_uri) {
  <tr>
    <th style="text-align: right;"><% $lang->maketext('Download') %>:</th>
    <td><a href="<% $uri %>" onclick="window.open(this.href, 'download_} . SERVER_WINDOW_NAME . qq{'); return false;" title="<% $lang->maketext('Download this media') %>"><% $media->get_file_name %></a></td>
    <td><& '/widgets/profile/imageSubmit.mc',
         formName => "theForm",
         callback => $widget ."|delete_media_cb",
         image    => "delete_red"
    &></td>
  </tr>
% }
</table>
% $m->comp("/widgets/wrappers/table_bottom.mc");
% }
<%args>
$media
$widget
$num
$indent
$read_only => 0
</%args>
