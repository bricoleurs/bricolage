% # Clear out messages and buffer - they're likely irrelevant now.
% clear_msg();
% $m->clear_buffer;
<& '/widgets/wrappers/sharky/header.mc', 
   title => '404 NOT FOUND', 
   context => 'Invalid page request',
   debug => (QA_MODE)
 &>

<p class="header">The URL you requested, <b><% $r->uri %></b>, was not found on
this server.</p>

<p class="header">Please check the URL and try again. If you feel you have
reached this page as a result of a server error or other bug, please notify the
server administrator. Be sure to include as much detail as possible, including
the type of browser, operating system, and the steps leading up to your arrival
here.</p>

<& '/widgets/wrappers/sharky/footer.mc', param => \%ARGS &>
% $m->abort;
