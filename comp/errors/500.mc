% # Check to see if this is a preview screen.
% my $prev = $r->uri =~ m:workflow/profile/preview:;
<& '/widgets/wrappers/sharky/header.mc',
	title => 'Error',
        useSideNav => !$prev,
        no_toolbar => !$prev,
	context => 'An error occurred.',
  debug => (QA_MODE || TEMPLATE_QA_MODE)
 &>

<p class="header">An error occurred while processing your request:</p>

<p class="errorMsg"><% $msg %></p>
% if (TEMPLATE_QA_MODE) {
<font face="Verdana, Helvetica, Arial">
<p><b>An exception was thrown:</b></p>
<b>Fault Type:</b> <% ref $fault %><br />
<b>Timestamp:</b> <% strfdate($fault->get_timestamp) %><br />
<b>Package:</b> <% $fault->get_pkg %><br />
<b>Filename:</b> <% $fault->get_filename %><br />
<b>Line:</b> <% $fault->get_line %><br />
<b>Message:</b> <% $fault->get_msg . ($more_err ? "\n\n$more_err" : '') %>
% if ($is_burner_error) {
</p>
% } else {
<br /><b>Payload:</b>
<font size="-1"><pre>
<% $pay %>
</pre></font>
</p>
% }
</font>

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
<b>Stack:</b><br /><% join("<br />\n", map { ref $_ ? join(' - ', @{$_}[1,3,2]) : $_ } @{$fault->get_stack} ) %>

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
<p class="errorMsg"><% $pay %></p>
% }
<p class="header">Please report this error to your administrator.</p>
% }

<& '/widgets/wrappers/sharky/footer.mc' &>














<!--

% $m->comp('error.html', %ARGS);

-->


<%args>
$fault => undef
$more_err => undef
</%args>
<%init>;
# Clear out messages - they're likely irrelevant now.
clear_msg();
unless (UNIVERSAL::isa($fault, 'Bric::Util::Fault::Exception')) {
    my %h = $r->headers_in;
    my $payload = isa_mason_exception($fault) ? $fault->as_brief : $h{BRIC_ERR_PAY};
    if (UNIVERSAL::isa($payload, 'Bric::Util::Fault::Exception')) {
        $payload = $payload->get_msg();
    }
    $fault = Bric::Util::Fault::Exception::AP->new(
      { msg => $h{BRIC_ERR_MSG} || 'No error message found',
        payload => $payload });
}

my $msg = $fault->get_msg || '';
# Get the payload if this is a Mason-level or burn system error.
my $pay = $fault->get_payload if $msg eq 'Error processing Mason elements.'
  ||  $msg =~ /^Unable to find template/
  ||  TEMPLATE_QA_MODE ;
my $is_burner_error = ($msg =~ /^Unable to find template/);
</%init>
