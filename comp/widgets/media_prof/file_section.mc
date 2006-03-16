% if ($read_only) {
% $m->comp("/widgets/wrappers/sharky/table_top.mc",
%          caption => "The File",
%          number => 2 );
<table border="0" width="578" cellpadding="0" cellspacing="0">
  <tr>
    <td class="medHeader">
      <img src="/media/images/spacer.gif" height="18" width="1" />
    </td>
    <td width="<% $indent %>" align="right" class="medHeader">
      <span class="label"><% $lang->maketext('Download') %>:&nbsp;</span></td>
    <td width="470">&nbsp;
%     if (my $uri = $media->get_local_uri) {
    <a href="<% $uri %>" onclick="window.open(this.href, 'download_} . SERVER_WINDOW_NAME . qq{'); return false;" title="<% $lang->maketext('Download this media') %>"><% $media->get_file_name %></a>
%     } else {
    <% $lang->maketext('No file has been uploaded') %>
%     }
    </td>
  </tr>
</table>
% $m->comp("/widgets/wrappers/sharky/table_bottom.mc");
% } else {
<%perl>
$m->comp("/widgets/wrappers/sharky/table_top.mc",
         caption => "Upload a file",
         number => $num
        );
</%perl>
<table width="578" cellpadding="2" cellspacing="0">
  <tr>
    <td width="<% $indent %>" valign="top" align="right">
      <span class="label"><%$lang->maketext('File Path')%>:</span>
    </td>
    <td width="200">
      <input type="file" name="<% $widget %>|file" size="30">
    </td>
    <td>
      <& '/widgets/profile/imageSubmit.mc',
         formName => "theForm",
         callback => $widget ."|update_cb",
         image    => "upload_red"
       &>
    </td>
  </tr>
  <tr>
    <td align="right">
      <span class="label"><% $lang->maketext('Download') %>:</span>
    </td>
%   if (my $uri = $media->get_local_uri()) {
    <td>
    <a href="<% $uri %>" onclick="window.open(this.href, 'download_} . SERVER_WINDOW_NAME . qq{'); return false;" title="<% $lang->maketext('Download this media') %>"><% $media->get_file_name %></a>
    </td>
    <td>
      <& '/widgets/profile/imageSubmit.mc',
         formName => "theForm",
         callback => $widget ."|delete_media_cb",
         image    => "delete_red"
       &>    
    </td>
%   } else {
    <td colspan="2">
      <% $lang->maketext('No file has been uploaded')%>
    </td>
%   }
  </tr>
</table>
% $m->comp("/widgets/wrappers/sharky/table_bottom.mc");
% }
<%args>
$media
$widget
$num
$indent
$read_only => 0
</%args>
