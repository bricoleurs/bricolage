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
    <a href="<% $uri %>" target="download_<% SERVER_WINDOW_NAME %>" class="darkBlueLink"><% $media->get_file_name %></a>
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
    <td width="<% 578 - $indent %>">
      <input type="file" name="<% $widget %>|file" size="30">
    </td>
  <tr>
    <td></td>
    <td>
    <& '/widgets/profile/imageSubmit.mc',
       formName => "theForm",
       callback => $widget ."|update_pc",
       image    => "upload_red"
     &>
    </td>
  </tr>
  <tr>
    <td width"=150" align="right">
      <span class="label"><% $lang->maketext('Download') %>:</span>
    </td>
    <td>
%     if (my $uri = $media->get_local_uri()) {
      <a href="<% $uri %>" target="download_<% SERVER_WINDOW_NAME %>" class="darkBlueLink"><% $media->get_file_name %></a>
%     } else {
      <% $lang->maketext('No file has been uploaded')%>
%     }
    </td>
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
