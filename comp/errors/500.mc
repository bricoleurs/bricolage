<& '/widgets/wrappers/sharky/header.mc',
	title => 'Error',
        useSideNav => $r->uri =~ m:workflow/profile/preview: ? 0 : 1,
	context => 'An error occured.',
  debug => Bric::Config::QA_MODE
 &>

<p class="header">An error occurred while processing your request:</p>

<p class="errorMsg"><% $msg %></p>
% if (ref $pay) {
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

<& '/widgets/wrappers/sharky/footer.mc' &>














<!--

% $m->comp('error.html', %ARGS);

-->


<%args>
$fault => undef
</%args>
<%init>;
# Clear out messages - they're likely irrelevant now.
clear_msg();
unless ($fault) {
    my %h = $r->headers_in;
    $fault = Bric::Util::Fault::Exception::AP->new(
      { msg => $h{BRIC_ERR_MSG} || 'No error message found',
        payload => $h{BRIC_ERR_PAY} });
}
my $msg = $fault->get_msg || '';
# Get the payload if this is a Mason-level or burn system error.
my $pay = $fault->get_payload if $msg eq 'Error processing Mason elements.'
  ||  $msg =~ /^Unable to find template/;
</%init>
