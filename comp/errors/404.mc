<%perl>;
# Clear out messages and buffer - they're likely irrelevant now.
clear_msg();
$m->clear_buffer;
# Check to see if this is a preview screen.
my $prev = $r->notes('burner.preview');
$m->comp('/widgets/wrappers/header.mc',
         title      => '404 NOT FOUND',
         context    => 'Invalid page request',
         debug      => QA_MODE,
         useSideNav => !$prev,
         no_toolbar => !$prev);
</%perl>
<p><% $lang->maketext('The URL you requested, <b>[_1]</b>, was not found on this server', $r->uri)%>.</p>

<p><% $lang->maketext('Please check the URL and try again. If you feel you have reached this page as a result of a server error or other bug, please notify the server administrator. Be sure to include as much detail as possible, including the type of browser, operating system, and the steps leading up to your arrival here.')%></p>

<& '/widgets/wrappers/footer.mc', param => \%ARGS &>
% $r->status(HTTP_NOT_FOUND);
% $m->abort;
