<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.2.2.18 $

=head1 DATE

$Date: 2001-11-17 00:01:46 $

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/header.mc" &>

=head1 DESCRIPTION

HTML wrapper for top and side navigation.

=cut
</%doc>

<%args>
$title   => "Bricolage"
$jsInit  => ""
$context
$useSideNav => 1
$no_toolbar => 1
$no_hist => 0
$debug => undef
</%args>

<%init>;

if ($useSideNav) {
    # first, let's bail if we need to...
    do_queued_redirect();

    # Next, log this page in the URI history
    log_history() unless $no_hist;
}

# Figure out where we are (assume workflow).
my ($section, $mode, $type) = $m->comp("/lib/util/parseUri.mc");
$section ||= 'workflow';

my ($layer, $properties);
my $agent       = $m->comp('/widgets/util/detectAgent.mc');
my $tab         = ($section eq "admin") ? "adminTab" : "workflowTab";
my $curve_left  = ($section eq "admin") ? "/media/images/CC6633_curve_left.gif" : "/media/images/006666_curve_left.gif";
my $curve_right = ($section eq "admin") ? "/media/images/CC6633_curve_right.gif" : "/media/images/006666_curve_right.gif";
my @title       = split (/ /, $title);
my $uri         = $r->uri;

# calculate number of links displayed by side nav and pad out this table cell to make the page
# long enough (in the browser's mind) to render a scroll bar if needed
my $nav = get_state_data("nav");

# calculate number of links it is possible to display in the side nav
my $numLinks = $c->get("__NUM_LINKS__");
$numLinks ||= 50;

$numLinks += 8 if ($agent->{os} eq "MacOS");

# define variables to output sideNav layer or iframe
if ($agent->{browser} eq "Netscape") {
    $layer = "layer";
    $properties = qq { width=150 height="100%" border=0 scrolling="no" frameborder="no" z-index=10 left=8 top=35 };
} else {
    $layer = "iframe";
    $properties = ($agent->{os} eq "MacOS") ? qq { width=150 border=0 scrolling="no" frameborder="no" style="z-index:10;" }
                                            : " width=150 height=" . $numLinks * 24 . qq { border=0 scrolling="no" frameborder="no" style="z-index:10;" };
}

# clean up the title
$title = '';
foreach my $t (@title) {
  $title .= uc(substr($t,0,1)) .lc( substr($t,1) ) . " " ;
}
</%init>

<html>
<head>
<title><% $title %></title>
% if ($useSideNav) {
<script language="JavaScript" src="/javascripts/lib.js"></script>
% }
<script language="JavaScript">

var checkboxValues = new Array();

function init() {

    <% $jsInit %>;
% # the following is a hack for pc/ns because it fails to obey 
% # the style rule when it is first drawn.
% if ($agent->{browser} eq 'Netscape' && $jsInit =~ /showForm/) {
    <% $jsInit %>;
% }

}

% if ($no_toolbar) {
if (window.name != 'Bricolage_<% SERVER_WINDOW_NAME %>') {
    // Send the current window to a blank page.
    document.location = 'about:blank';
    // Turn off the toolbar, back button, etc.
    window.open("<% $uri %>", 'Bricolage_<% SERVER_WINDOW_NAME %>',
                'menubar=0,location=0,toolbar=0,personalbar=0,status=1,scrollbars=1,resizable=1,width=750');
} else {
    history.forward(1);
}
% } # if
</script>
<meta http-equiv="expires" content="Wed, 20 Feb 2000 08:30:00 GMT">
</head>

<& "/widgets/wrappers/sharky/css.mc" &>

<body bgcolor="#ffffff" onLoad="init()">
<noscript>
<h1>Warning! Bricolage is designed to run with JavaScript enabled.</h1>
Using Bricolage without JavaScript can result in corrupt data and system instability.
Please activate JavaScript in your browser before continuing.
</noscript>

<!-- begin top table -->
<table border=0 cellpadding=0 cellspacing=0 width=750>
<tr>
	<td width=150>
% if ($useSideNav) {
        <a href="#" onClick="window.open('/help/about.html', 'About_<% SERVER_WINDOW_NAME %>', 'menubar=0,location=0,toolbar=0,personalbar=0,status=0,scrollbars=1,height=600,width=620'); return false;"><img src="/media/images/bricolage.gif" width="150" height="25" border="0" /></a>
% } else {
        <img src="/media/images/bricolage.gif" width="150" height="25" border="0" />
% }
	</td>
	<td width=600 align=right>
	 &nbsp;
	</td>
</tr>
</table>
<!-- end top tab table -->

% # this is the Netscape doNav function.  IE looks for it in the iframe file (ie: sideNav.mc)
<script language="javascript">
function doNav(callback) {

% if ($agent->{os} eq "SomeNix") {

    window.location.href = callback;
    return false;

% } else {

    var rndNum = Math.round(Math.random() * 10000);
    document.layers["sideNav"].src = callback + "&uri=<% $r->uri %>&rnd=" + rndNum
    return false;

% }
}

function doLink(link) {

    window.location.href = link
    return false
}
</script>

<!-- begin side nav and content container table -->
<table border=0 cellpadding=0 cellspacing=0 width=750 height="100%">
<tr>
  <td width=150 valign=top bgcolor="#666633" height="100%">

<%perl>

# handle the various states of the side nav
# login screen: no side nav
# Netscape (non Unix platforms): include as src of a layer
# IE: include as an iframe
# Netscape (Unix platforms): include as plain html

if ($useSideNav) {

    if ($agent->{os} eq "SomeNix") {
	$m->comp("/widgets/wrappers/sharky/sideNav.mc", debug => $debug);
    } else {
	my $uri = $r->uri;
	$uri .= "&debug=$debug" if $debug;
	# create a unique uri to defeat browser caching attempts.
	$uri .= "&rnd=" . time;
	chomp $uri;
	$m->out(qq { <img src="/media/images/spacer.gif" width=150 height=1> } ) if ($agent->{browser} eq "Netscape");
	$m->out( qq {<$layer name="sideNav" src="/widgets/wrappers/sharky/sideNav.mc?uri=$uri" $properties>} );
	$m->out("</$layer>\n");
    }

}


$m->out(qq { <img src="/media/images/spacer.gif" width=150 height=1> } );
</%perl>

% # write out space so the silly browser will provide a scroll bar for the layered content
% if ($agent->{browser} eq "Netscape" && !$agent->{browser} eq "SomeNix") { 

  <script language="javascript">
  for (var i=0; i < <% $numLinks %>; i++) {
      document.write("<p>&nbsp;</p>");
  }
  </script>

% }

  </td>
  <td rowspan=2><img src="/media/images/spacer.gif" width=20 height=1></td>

<!-- begin content area -->

  <td width=580 valign=top rowspan=2>
% # top tab, help, logout buttons
  <table width=580 cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td class=<% $tab %> valign=top width=11><img src="<% $curve_left %>" width=11 height=22></td>
    <td class=<% $tab %> width=348><% $title %></td>
    <td valign=top width=11 class=<% $tab %>><img src="<% $curve_right %>" width=11 height=22></td>
% if ($useSideNav) {
    <td width=140 align=right valign=top>&nbsp;<a href="/workflow/profile/alerts"><img src="/media/images/my_alerts_orange.gif" width=77 height=20 border=0 hspace=3 /></a></td>
    <td align=right width=70>
    <a href="/logout"><img src="/media/images/logout.gif" width=70 height=20 border=0></a>
    </td>
% } else {
    <td width="217">&nbsp;</td>
% }
  </tr>
  </table>

% # top message table
  <table width=580 cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td class=medHeader height=20>&nbsp;&nbsp;<% $context %></td>
  </tr>

  </table>

<%perl>
# handle error messaging
my $firstMsg = 1;
while (my $txt = next_msg) {
     # insert whitespace on top to balance the line break the form tag inserts after these messages.
    if ($firstMsg) {	
	$m->out("<P>");
	$firstMsg = 0;
    }
</%perl>
<table width=580 cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td height=20 valign=center>
%    $m->out("<span class=errorMsg>$txt</span>\n");
    </td>
  </tr>
  </table>
% }






