<& "/widgets/wrappers/table_top.mc",
    caption => "The File",
    number => 2
&>
% if ($read_only && !$uri) {
<div class="noneFound"><% $lang->maketext("No file has been uploaded.") %></div>
% } else {
<div class="editmeta">
% unless ($read_only) {
<div class="row"
    <div class="label"><%$lang->maketext('File Path')%>:</div>
    <div class="input"><input type="file" name="<% $widget %>|file" size="30" />
        <& '/widgets/profile/imageSubmit.mc',
            formName => "theForm",
            callback => $widget ."|update_cb",
            image    => "upload_red"
        &>
    </div>
</div>
% }
% if ($uri) {
<div class="row">
    <div class="label"><% $lang->maketext('Download') %>:</div>
    <div class="input"><a href="<% $uri %>" onclick="window.open(this.href, 'download_<% SERVER_WINDOW_NAME %>'); return false;" title="<% $lang->maketext('Download this media') %>"><% $media->get_file_name %></a>
%       unless ($read_only) {
        <& '/widgets/profile/imageSubmit.mc',
            formName => "theForm",
            callback => $widget ."|delete_media_cb",
            image    => "delete_red"
        &>
%       }
    </div>
</div
% }
</div>
% }
<& "/widgets/wrappers/table_bottom.mc" &>
<%args>
$media
$widget
$num
$read_only => 0
</%args>
<%init>
my $uri = $media->get_local_uri;
</%init>
