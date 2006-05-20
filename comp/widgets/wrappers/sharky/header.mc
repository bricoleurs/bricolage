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
$scrollx => 0
$scrolly => 0
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

my ($properties);
my @title       = split (/ /, $title);
my $uri         = $r->uri;

if(ref($title) eq 'ARRAY') {
    $title = $lang->maketext(@$title);
} else {
    # clean up the title
    $title = $lang->maketext( join ' ', map { ucfirst($_) } split / /, $title);
}

</%init>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<meta name="bricolage-version" content="<% Bric->VERSION %>" />
<link rel="stylesheet" type="text/css" href="/media/css/style.css" />
% if (DISABLE_NAV_LAYER) {
<link rel="stylesheet" type="text/css" href="/media/css/style-nav.css" />
% }
<link rel="stylesheet" type="text/css" href="/media/css/i18n/<% $lang_key %>.css" />
<script type="text/javascript" src="/media/js/lib.js"></script>
<script type="text/javascript" src="/media/js/i18n/<% $lang_key %>_messages.js"></script>
<title><% $title %></title>
<script type="text/javascript"><!--
var lang_key = '<% $lang_key %>';
var checkboxValues = new Array();
multiOnload.onload(function () {
    findFocus();
    <% $jsInit %>;
% #    restoreScrollXY(<% $scrollx %>, <% $scrolly %>);
});

% if ($no_toolbar) {
if (window.name == 'sideNav') { parent.location.href = location.href; }
if (window.name != 'Bricolage_<% SERVER_WINDOW_NAME %>' && window.name != 'sideNav') {
    // Redirect to the window opening page.
    location.href = '/login/welcome.html?referer=<% $r->uri %>';
} else {
    history.forward(1);
}
% } # if
--></script>
</head>
<body>
<noscript>
<h1><% $lang->maketext("Warning! Bricolage is designed to run with JavaScript enabled.") %></h1>
<p><% $lang->maketext('Using Bricolage without JavaScript can result in corrupt data and system instability. Please activate JavaScript in your browser before continuing.') %></p>
</noscript>

<div id="mainContainer">
<div id="bricLogo">
% if ($useSideNav) {
        <a href="#" title="About Bricolage" id="btnAbout" onclick="openAbout()"><img src="/media/images/bricolage.gif" alt="Bricolage" /></a>
% } else {
        <img src="/media/images/bricolage.gif" alt="Bricolage" />
% }
</div>
<%perl>;
# handle the various states of the side nav
if ($useSideNav) {
    my $uri = $r->uri;
    $uri .= "&amp;debug=$debug" if $debug;
    # create a unique uri to defeat browser caching attempts.
    $uri .= "&amp;rnd=" . time;
    chomp $uri;

    if (DISABLE_NAV_LAYER) {
        $m->out('<div name="sideNav" id="sideNav">');
        $m->comp("/widgets/wrappers/sharky/sideNav.mc", uri => $uri);
        $m->out('</div>');
    } else {
        $m->out( qq{<iframe name="sideNav" id="sideNav" } .
                 qq{        src="/widgets/wrappers/sharky/sideNav.mc?uri=$uri" } .
                 qq{        scrolling="no" frameborder="0"></iframe>} );
    }
}

</%perl>

<!-- begin content area -->
<div id="contentContainer">
% # top tab, help, logout buttons
    <div id="headerContainer">
        <div class="<% $section %>Box">
            <div class="fullHeader">
                <div class="number">&nbsp;</div>
                <div class="caption"><% $title %></div>
                <div class="rightText">&nbsp;</div>
            </div>
        </div>
% if ($useSideNav) {
        <div class="buttons">
            <& "/widgets/buttons/help.mc", context => $context, page => $title &>
            <a href="/workflow/profile/alerts" title="My Alerts"><img src="/media/images/<% $lang_key %>/my_alerts_orange.gif" alt="My Alerts" /></a>
            <a href="/logout" title="Logout"><img src="/media/images/<% $lang_key %>/logout.gif" alt="Logout" /></a>
        </div>
% }
% if (defined get_user_id()) {
        <div class="userinfo">
            Logged in as <a href="/admin/profile/user/<% get_user_id %>" title="<% $lang->maketext("User Profile") %>"><strong><% get_user_object->format_name %></strong></a>
        </div>
% }
    </div>

% # top message table
    <div id="breadcrumbs">
        <p><% $context %></p>
% if ($useSideNav) {
        <form id="sitecontext" action="#">
            <div class="siteContext"><& /widgets/site_context/site_context.mc &></div>
        </form>
% }
    </div>
<%perl>;
# handle error messaging
while (my $txt = next_msg) {
     # insert whitespace on top to balance the line break the form tag inserts after these messages.
    if ($txt =~ /(.*)<span class="l10n">(.*)<\/span>(.*)/) {
        $txt = escape_html($1) . '<span class="l10n">'
          . escape_html($2) . '</span>' . escape_html($3);
    } else {
        $txt = escape_html($txt);
    }
</%perl>
    <p class="errorBox">
        <span class="errorMsg"><% $txt %></span>
    </p>
% }
