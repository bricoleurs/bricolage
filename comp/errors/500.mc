% # Check to see if this is a preview screen.
% my $prev = $r->uri =~ m:workflow/profile/preview:;
<& '/widgets/wrappers/sharky/header.mc',
	title => 'Error',
        useSideNav => !$prev,
        no_toolbar => !$prev,
	context => 'An error occurred.',
  debug => (QA_MODE || TEMPLATE_QA_MODE)
 &>

<p class="header"><% $lang->maketext('An error occurred while processing your request:')%></p>

<p class="errorMsg"><% $fault->error %></p>
% if (TEMPLATE_QA_MODE) {
<font face="Verdana, Helvetica, Arial">
<p><b>An exception was thrown:</b></p>
<b>Fault Type:</b> <% $fault->description %><br />
<b>Timestamp:</b> <% strfdate($fault->time) %><br />
<b>Package:</b> <% $fault->package %><br />
<b>Filename:</b> <% $fault->file %><br />
<b>Line:</b> <% $fault->line %><br />
<b>Message:</b> <% $fault->error . ($more_err ? "\n\n$more_err" : '') %>
% if ($is_burner_error) {
</p>
% } else {
<br /><b>Payload:</b>
<font size="-1"><pre>
<% "$pay" %>
</pre></font>
</p>
% }
</font>

<font face="Verdana, Helvetica, Arial"><p><b>Request args:</b></font>
<table border="0" cellpadding="2" cellspacing="2">
% foreach my $arg (keys %req_args) {
    <tr>
        <td align="right"><span class="label"><% $arg %>:</span></td>
        <td align="left"><% $req_args{$arg} %></td>
    </tr>
% }
</table>

% if ($is_burner_error) {
<font face="Verdana, Helvetica, Arial"><p><b>Payload:</b></font>
<table border="0" cellpadding="2" cellspacing="2">
    <tr>
        <td align="right"><span class="label">Class:</span></td>
        <td align="left"><% $pay->{class} %></td>
    </tr>
    <tr>
        <td align="right"><span class="label">Action:</span></td>
        <td align="left"><% $pay->{action} %></td>
    </tr>
    <tr>
        <td align="right"><span class="label">Output Channel:</span></td>
        <td align="left"><% $pay->{context}{oc}->get_name %></td>
    </tr>
    <tr>
        <td align="right"><span class="label">Category:</span></td>
        <td align="left"><% $pay->{context}{cat}->get_name %></td>
    </tr>
    <tr>
        <td align="right"><span class="label">Element:</span></td>
        <td align="left"><% $pay->{context}{elem}->get_name %></td>
    </tr>
</table>
% }
<font face="Verdana, Helvetica, Arial">
<b>Stack:</b><br /><% join("<br />\n", @{$fault->get_stack} ) %>

<br /><br />
<& '/widgets/debug/debug.mc' &>
% } else {
% if ($is_burner_error) {
<table border="0" cellpadding="2" cellspacing="2">
    <tr>
        <td align="right"><span class="label">Class:</span></td>
        <td align="left"><% $pay->{class} %></td>
    </tr>
    <tr>
        <td align="right"><span class="label">Action:</span></td>
        <td align="left"><% $pay->{action} %></td>
    </tr>
    <tr>
        <td align="right"><span class="label">Output Channel:</span></td>
        <td align="left"><% $pay->{context}{oc}->get_name %></td>
    </tr>
    <tr>
        <td align="right"><span class="label">Category:</span></td>
        <td align="left"><% $pay->{context}{cat}->get_name %></td>
    </tr>
    <tr>
        <td align="right"><span class="label">Element:</span></td>
        <td align="left"><% $pay->{context}{elem}->get_name %></td>
    </tr>
</table>
% } elsif ($pay) {
<p class="errorMsg"><% "$pay" %></p>
% }
<p class="header">Please report this error to your administrator.</p>
% }

<& '/widgets/wrappers/sharky/footer.mc' &>


<%args>
$fault => undef
$more_err => undef
</%args>
<%init>;
# Clear out messages - they're likely irrelevant now.
clear_msg();

# If $fault is undef, the exception object MUST BE in pnotes
# (from AccessHandler or PreviewHandler)
unless (defined $fault) {
    $fault = $r->pnotes('BRIC_EXCEPTION');
}
warn '$fault not an exception object' unless isa_exception($fault);

# From here on, $fault MUST BE an exception object

# Get payload, stringify if payload is an exception object
my $pay = isa_bric_exception($fault) ? ($fault->payload || '') : '';

my $is_burner_error = ($fault->error =~ /^Unable to find template/);

my %req_args = HTML::Mason::Request->instance->request_args;
</%init>
