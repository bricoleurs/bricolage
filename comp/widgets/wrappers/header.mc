<%doc>
###############################################################################

=head1 NAME

=head1 SYNOPSIS

<& "/widgets/wrappers/header.mc" &>

=head1 DESCRIPTION

HTML wrapper for top and side navigation.

=cut

</%doc>
<%args>
$title   => get_pref('Bricolage Instance Name')
$jsInit  => ""
$context
$useSideNav => 1
$popup      => 0
$no_toolbar => NO_TOOLBAR
$no_hist => 0
$debug => undef
$scrollx => 0
$scrolly => 0
</%args>
<%init>;
$context =~ s/\&quot\;/\"/g;
my @context =  split /\|/, $context;

$useSideNav = 0 if $popup;

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
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=8" />
<meta name="bricolage-version" content="<% Bric->VERSION %>" />
<link rel="stylesheet" type="text/css" href="/media/css/style.css" />
<link rel="stylesheet" type="text/css" href="/media/css/style-nav.css" />
<link rel="stylesheet" type="text/css" href="/media/css/i18n/<% $lang_key %>.css" />
<script type="text/javascript" src="/media/js/prototype.js"></script>
<script type="text/javascript" src="/media/js/scriptaculous.js"></script>
<script type="text/javascript" src="/media/js/lib.js"></script>
<script type="text/javascript" src="/media/js/i18n/<% $lang_key %>_messages.js"></script>
<title><% $title %></title>
<script type="text/javascript"><!--
var lang_key = '<% $lang_key %>';
var checkboxValues = new Array();
Event.observe(window, "load", function () {
    findFocus();
% #    restoreScrollXY(<% $scrollx %>, <% $scrolly %>);
});
% if ($jsInit) {
Event.observe(window, "load", function() { <% $jsInit %>; });
% }

% if ($no_toolbar) {
if (window.name != 'Bricolage_<% SERVER_WINDOW_NAME %>' && !/BricolagePopup/.test(window.name)) {
    // Redirect to the window opening page.
    location.href = '/login/welcome.html?referer=<% $r->uri %>';
} else {
    history.forward(1);
}
% } # if ($no_toolbar)
--></script>
</head>
% my $popupClass = ($popup ? ' class="popup"' : '');
<body id="bricolage_<% SERVER_WINDOW_NAME %>"<% $popupClass %>>
<noscript>
<h1><% $lang->maketext("Warning! Bricolage is designed to run with JavaScript enabled.") %></h1>
<p><% $lang->maketext('Using Bricolage without JavaScript can result in corrupt data and system instability. Please activate JavaScript in your browser before continuing.') %></p>
</noscript>

<div id="mainContainer">
% if ($useSideNav) {
    <div id="bricLogo">
        <a href="#" title="About Bricolage" id="btnAbout" onclick="openAbout()"><img src="/media/images/bricolage.gif" alt="Bricolage" /></a>
    </div>
% } elsif (!$popup) {
    <div id="bricLogo">
        <img src="/media/images/bricolage.gif" alt="Bricolage" />
    </div>
% }
<%perl>;
# handle the various states of the side nav
if ($useSideNav) {
    my $uri = $r->uri;
    chomp $uri;

    $m->out('<div id="sideNav">');
    $m->comp("/widgets/wrappers/sideNav.mc", uri => $uri);
    $m->out('</div>');
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
            <a href="/workflow/profile/alerts/" title="My Alerts"><img src="/media/images/<% $lang_key %>/my_alerts_orange.gif" alt="My Alerts" /></a>
            <a href="/logout" title="Logout"><img src="/media/images/<% $lang_key %>/logout.gif" alt="Logout" /></a>
        </div>
% }
% if (!$popup && defined get_user_id()) {
%     my $prefix = SSL_ENABLE && get_state_name('login') ne 'ssl'
%         ? Bric::Util::ApacheReq->url( ssl => 1, uri => '' ) : '';
        <div class="userinfo">
            Logged in as <a href="<% $prefix %>/admin/profile/user/<% get_user_id %>" title="<% $lang->maketext("User Profile") %>"><strong><% get_user_object->format_name %></strong></a>
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
    
<div id="errors">
<%perl>;
# handle error messaging
my $count = 1;
while (my $txt = next_msg) {
     # insert whitespace on top to balance the line break the form tag inserts after these messages.
    if ($txt =~ /(.*)<span class="l10n">(.*)<\/span>(.*)/) {
        $txt = escape_html($1) . '<span class="l10n">'
          . escape_html($2) . '</span>' . escape_html($3);
    } else {
        $txt = escape_html($txt);
    }
</%perl>

%   if ($count == 4) {  # Start the extraErrors box on the 4th error
    <div id="showMoreErrors">(<a href="#" onclick="Element.hide(this.parentNode); Effect.BlindDown('extraErrors'); return false">more</a>)</div>
    <div id="extraErrors" style="display: none;">
%   }
    <div class="errorMsg"><% $txt %></div>
% }
% if ($count > 3) {  # Close the extraErrors box if there were more than 3 errors
    <div id="showFewerErrors">(<a href="#" onclick="Effect.BlindUp(this.parentNode.parentNode); Effect.Appear('showMoreErrors', { queue: 'end'}); return false;">less</a>)</div>
    </div>
% }

% $count++;
</div>
