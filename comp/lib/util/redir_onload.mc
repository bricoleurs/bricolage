<SCRIPT>
document.location='<% shift %>';
</SCRIPT>
% $m->abort;
<%doc>
This element forces the web browser to redirec when it has finished loading
this element. This is a good way to move on to another page if status messages
have been sent to the browser and processing has finished.

  $m->comp('/lib/redir_onload.js', $url);
</%doc>