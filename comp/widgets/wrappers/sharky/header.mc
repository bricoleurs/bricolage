<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/header.mc" &>

=head1 DESCRIPTION

HTML wrapper for top and side navigation.

=cut

</%doc>
<%args>
$title   => get_pref('Bricolage Instance Name')
$jsInit  => ""
$context
$useSideNav => 1
$no_toolbar => NO_TOOLBAR
$no_hist => 0
$debug => undef
</%args>
<%init>;
$context =~ s/\&quot\;/\"/g;
my @context =  split /\|/, $context;

for (@context){
    s/^\s+//g;
    s/\s+$//g;
    if (/^(\"?)(.+?)(\"?)$/) {
        my ($startquote, $text, $endquote) = ($1, $2, $3);
        $text =~ s/([\[\],~])/~$1/g;
        my $underscores = ($text =~ s/^(_+)//) ? $1 : '';
        $_ = qq{$startquote<span class="110n">$underscores}
          . $lang->maketext($text) . "</span>$endquote";
    }
}

$context = join ' | ', @context;

# Figure out where we are (assume workflow).
my ($section, $mode, $type) = parse_uri($r->uri);
$section ||= 'workflow';

my ($layer, $properties);
my $agent       = detect_agent();
my $tab         = $section eq "admin" ? "adminTab" : "workflowTab";
my @title       = split (/ /, $title);
my $uri         = $r->uri;
my $curve_left  = $section eq "admin"
  ? "/media/images/CC6633_curve_left.gif"
  : "/media/images/006666_curve_left.gif";
my $curve_right = $section eq "admin"
  ? "/media/images/CC6633_curve_right.gif"
  : "/media/images/006666_curve_right.gif";

# calculate number of links displayed by side nav and pad out this table cell
# to make the page long enough (in the browser's mind) to render a scroll bar
# if needed
my $nav = get_state_data("nav");

my $margins = DISABLE_NAV_LAYER && $agent->gecko
  ? 'marginwidth="5" marginheight="5"'
  : '';

if(ref($title) eq 'ARRAY') {
    $title = $lang->maketext(@$title);
} else {
    # clean up the title
    $title = $lang->maketext( join ' ', map { ucfirst($_) } split / /, $title);
}

# XXX Doctype is a lie...for now.
</%init>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<meta name="bricolage-version" content="<% Bric->VERSION %>" />
<link rel="stylesheet" type="text/css" href="/media/css/style.css" />
<link rel="stylesheet" type="text/css" href="/media/css/<% $lang_key %>.css" />
<script type="text/javascript" src="/media/js/lib.js"></script>
<script type="text/javascript" src="/media/js/<% $lang_key %>_messages.js"></script>
<title><% $title %></title>
<script type="text/javascript">

var checkboxValues = new Array();

function init() {

    <% $jsInit %>;
% # the following is a hack for pc/ns because it fails to obey
% # the style rule when it is first drawn.
% if ($agent->nav4 && $jsInit =~ /showForm/) {
    <% $jsInit %>;
% }

}

% if ($no_toolbar) {
if (window.name == 'sideNav') { parent.location.href = location.href; }
if (window.name != 'Bricolage_<% SERVER_WINDOW_NAME %>' && window.name != 'sideNav') {
    // Redirect to the window opening page.
    location.href = '/login/welcome.html?referer=<% $r->uri %>';
} else {
    history.forward(1);
}
% } # if
</script>
</head>

<body bgcolor="#ffffff" <% $margins %> onLoad="init()" marginwidth="8" marginheight="8" topmargin="8" leftmargin="8">
<noscript>
<h1><% $lang->maketext("Warning! Bricolage is designed to run with JavaScript enabled.") %></h1>
<% $lang->maketext('Using Bricolage without JavaScript can result in corrupt data and system instability. Please activate JavaScript in your browser before continuing.') %>
</noscript>

<!-- begin top table -->
<div id="bricLogo">
% if ($useSideNav) {
        <a href="#" onClick="window.open('/help/<% $lang_key %>/about.html', 'About_<% SERVER_WINDOW_NAME %>', 'menubar=0,location=0,toolbar=0,personalbar=0,status=0,scrollbars=1,height=600,width=505'); return false;"><img src="/media/images/<% $lang_key %>/bricolage.gif" width="150" height="25" border="0" /></a>
% } else {
        <img src="/media/images/<% $lang_key %>/bricolage.gif" width="150" height="25" border="0" />
% }
</div>
<!-- end top tab table -->

% # this is the Netscape doNav function.  IE looks for it in the iframe file (ie: sideNav.mc)
<script type="text/javascript">
function doNav(callback) {
% if (DISABLE_NAV_LAYER || ((! $agent->gecko) && $agent->user_agent =~ /(linux|freebsd|sunos)/)) {
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

<div id="mainContainer">
<%perl>;
# handle the various states of the side nav
if ($useSideNav) {

    if (DISABLE_NAV_LAYER || ((! $agent->gecko) && $agent->user_agent =~ /(linux|freebsd|sunos)/)) {
	$m->comp("/widgets/wrappers/sharky/sideNav.mc", debug => $debug);
    } else {
	my $uri = $r->uri;
	$uri .= "&debug=$debug" if $debug;
	# create a unique uri to defeat browser caching attempts.
	$uri .= "&rnd=" . time;
	chomp $uri;
        $m->out( qq{<iframe name="sideNav" id="sideNav" } .
                 qq{        src="/widgets/wrappers/sharky/sideNav.mc?uri=$uri" } .
                 qq{        scrolling="no" frameborder="no"></iframe>} );
    }
}

</%perl>

<!-- begin content area -->
<div id="contentContainer">
% # top tab, help, logout buttons
  <table width="580" cellpadding="0" cellspacing="0" border="0">
  <tr>
    <td class="<% $tab %>" valign="top" width="11"><img src="<% $curve_left %>" width="11" height="22"></td>
    <td class="<% $tab %>" width="330"><% $title %></td>
    <td valign="top" width="11" class="<% $tab %>"><img src="<% $curve_right %>" width="11" height="22"></td>
% if ($useSideNav) {
    <td width="10">&nbsp;</td>
    <td valign="top"><& "/widgets/help/help.mc", context => $context, page => $title &></td>
    <td valign="top">
        <a href="/workflow/profile/alerts"><img src="/media/images/<% $lang_key %>/my_alerts_orange.gif" border="0" hspace="3" /></a>
    </td>
    <td valign="top">
    <a href="/logout"><img src="/media/images/<% $lang_key %>/logout.gif" border="0"></a>
    </td>
% } else {
    <td width="228">&nbsp;</td>
% }
  </tr>
  </table>

% # top message table
  <table width=580 cellpadding=0 cellspacing=0 border=0>
  <tr class="medHeader"><td colspan="2"><img src="/media/images/spacer.gif" height="2" /></td></tr>
  <tr class="medHeader" height="16">
    <td>&nbsp;&nbsp;<% $context %></td>
% if ($useSideNav) {
    <td align="right"><& /widgets/site_context/site_context.mc &>&nbsp;</td>
% }
  </tr>
  <tr class="medHeader"><td colspan="2"><img src="/media/images/spacer.gif" height="2" /></td></tr>
  </table>
<%perl>;
# handle error messaging
my $firstMsg = 1;
while (my $txt = next_msg) {
     # insert whitespace on top to balance the line break the form tag inserts after these messages.
    if ($firstMsg) {
	$m->out("<p>");
	$firstMsg = 0;
    }
    if ($txt =~ /(.*)<span class="l10n">(.*)<\/span>(.*)/) {
        $txt = escape_html($1) . '<span class="l10n">'
          . escape_html($2) . '</span>' . escape_html($3);
    } else {
        $txt = escape_html($txt);
    }
</%perl>
<table width="580" cellpadding="0" cellspacing="0" border="0">
  <tr>
    <td height="20" valign="center">
      <span class="errorMsg"><% $txt %></span>
    </td>
  </tr>
  </table>
% }
<br />
