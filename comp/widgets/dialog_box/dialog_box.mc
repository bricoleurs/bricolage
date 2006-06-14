<div class="dialog" id="<% $id %>">
  <div class="dragger" onmousedown="beginDrag(event, this.parentNode);">
    <button class="dclose" title="<% $lang->maketext('Close this dialog box') . ' ' . $lang->maketext('(Access Key: c)') %>" accesskey="c" onclick="return closeDialog(document.getElementById('<% $id %>'));">&#x00d7;</button>
    <% $lang->maketext($title) %>
  </div>
  <div class="dialogcontent">
<%perl>;
$m->print($m->content, qq{<ul class="buttons">\n});
for my $button (@buttons) {
    $m->print(
        qq{  <li><button class="button" title="},
        $lang->maketext($button->{title}), ' ',
        $lang->maketext('(Access Key: [_1])', $button->{accesskey}),
        qq{" accesskey="$button->{accesskey}"},
        qq{ onclick="$button->{onclick}">},
        $lang->maketext($button->{label}),
        "</button></li>\n"
    );
}
</%perl>
  <li><button class="button" title="<% $lang->maketext('Close this dialog box') . ' ' . $lang->maketext('(Access Key: c)') %>" accesskey="c" onclick="return closeDialog(document.getElementById('<% $id %>'));"><% $lang->maketext($close_label) %></button></li>
</ul>
  </div>
</div>
<%args>
$id
$title       => 'Bricolage Dialog Box'
$close_label => 'Cancel'
@buttons => ()
</%args>
