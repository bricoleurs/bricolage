% # Check to see if this is a preview screen.
% my $prev = $r->notes('burner.preview');
<& /widgets/wrappers/sharky/header.mc,
	title      => 'Error',
        useSideNav => !$prev,
        no_toolbar => !$prev,
	context    => 'An error occurred.',
        debug      => QA_MODE || TEMPLATE_QA_MODE
 &>

<p class="header"><% $lang->maketext('An error occurred while processing your request:')%></p>

<p class="errorMsg"><% escape_html($fault->error) %></p>

% if (isa_bric_exception($fault) and my $pay = $fault->payload) {
<pre><% escape_html($pay) %></pre>
% }

% if (QA_MODE or (TEMPLATE_QA_MODE and $is_burner_error)) {
<div class="debug">
<dl>
%     if ($is_burner_error) {
  <dt>Output Channel</dt> <dd><% $fault->oc || '&nbsp;' %></dd>
  <dt>Category</dt>       <dd><% $fault->cat || '&nbsp;' %></dd>
  <dt>Element</dt>        <dd><% $fault->elem || '&nbsp;' %></dd>
%     }
  <dt>Fault Class</dt>    <dd><% ref $fault %></dd>
  <dt>Description</dt>    <dd><% $fault->description || '&nbsp;' %></dd>
  <dt>Timestamp</dt>      <dd><% strfdate($fault->time) %></dd>
  <dt>Package</dt>        <dd><% $fault->package || '&nbsp;' %></dd>
  <dt>Filename</dt>       <dd><% $fault->file || '&nbsp;' %></dd>
  <dt>Line</dt>           <dd><% $fault->line || '&nbsp;' %></dd>
</dl>

<p><b>Stack:</b></p>
<pre><% isa_mason_exception($fault) ? $fault->as_text : $fault->trace_as_text %></pre>

%     if (QA_MODE) {
<p><b>Request args:</b></p>
<dl>
%         while (my ($arg, $value) = each %req_args) {
  <dt><% $arg %></dt> <dd><% escape_html($value) %></dd>
%         }
</dl>
<& '/widgets/debug/debug.mc' &>
%     }
</div>
% } else {

<!-- DEBUGGING INFORMATION.

Error: <% escape_html($fault->error) %>

%     if ($is_burner_error) {
  Output Channel: <% $fault->oc || '' %>
  Category:       <% $fault->cat || '' %>
  Element:        <% $fault->elem || '' %>
%     }
  Fault Class:    <% ref $fault %>
  Description:    <% $fault->description || '' %>
  Timestamp:      <% strfdate($fault->time) %>
  Package:        <% $fault->package || '' %>
  Filename:       <% $fault->file || '' %>
  Line:           <% $fault->line || '' %>
%     if (isa_bric_exception($fault)) {
  Payload:        <% $fault->payload || '' %>
%     }

STACK:

<% isa_mason_exception($fault) ? $fault->as_text : $fault->trace_as_text %>
  
END DEBUGGING INFORMATION -->

% }
% unless (isa_bric_exception($fault, 'Exception::Burner::User')) {
<p class="header">Please report this error to your administrator.</p>
% }

<& '/widgets/wrappers/sharky/footer.mc' &>

<%init>;
# Clear out messages - they're likely irrelevant now.
clear_msg();

# exception object ($fault) and $more_args are now always
# in pnotes, not passed in %args
my $fault = $r->pnotes('BRIC_EXCEPTION');
warn '$fault not an exception object' unless isa_exception($fault);

my $more_err = $r->pnotes('BRIC_MORE_ERR');

my $pay = isa_bric_exception($fault) ? ($fault->payload || '') : '';

my $is_burner_error = isa_bric_exception($fault, 'Exception::Burner');
my %req_args = HTML::Mason::Request->instance->request_args;
</%init>
