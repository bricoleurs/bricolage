<%args>

</%args>

<%perl>

my $agent = $m->comp('/widgets/util/detectAgent.mc');

my ( # my, hey, hey rock and roll is here to stay

    $title,
    $header,
    $subHeader,
    $label,
    $redLabel,
    $burgandyLabel,
    $whiteLabel,
    $description,
    $errorMsg,
    $radioLabel,

    $body,
    $textInput,

    $sideNavActiveCell,
    $sideNavInactiveCell,
    $sideNavAdminCell,
    $workflowBold,
    $workflowHeader,
    $sideNavHeader,
    $sideNavHeaderBold,
    $sideNavHeaderBoldWhite,

    $blueLink,
    $blueLinkBold,
    $darkBlueLink,
    $orangeLink,
    $orangeLinkBold,
    $redLink,
    $whiteLink,
    $whiteUnderlinedLink,
    $whiteMedUnderlinedLink,
    $blackLink,
    $blackUnderlinedLink,
    $blackMedUnderlinedLink,
    $blackLinkBold,
    $redLinkLarge,

    $adminTab,
    $workflowTab,
    $whiteTextTab,
    $adminSubTab,
    $workflowSubTab,
    $darkHeader,
    $medHeader,
    $lightHeader,
    $tealHeader,
    $redHeader,
    $greyHeader,
    $tealHighlight,

    $fontFamily,
    $fontSizeSmall,
    $fontSizeMed,
    $fontSizeLarge,

);

$fontFamily    = "font-family:Verdana,Helvetica,Arial,sans-serif;";
$fontSizeSmall = "font-size:10pt;";
$fontSizeMed   = "font-size:11pt;";
$fontSizeLarge = "font-size:12pt;";

if ($agent->{browser} eq 'Mozilla') {
    if ($agent->{os} eq 'SomeNix') {
	$fontSizeSmall = "font-size:9.5pt;";
	$fontSizeMed   = "font-size:10pt;";
	$fontSizeLarge = "font-size:11pt;";
    } else {
	$fontSizeSmall = "font-size:7.5pt;";
	$fontSizeMed   = "font-size:8pt;";
	$fontSizeLarge = "font-size:10pt;";
    }
} elsif ($agent->{os} =~ /^Windows/) { # windows fonts one size smaller
	$fontSizeSmall = "font-size:8pt;";
	$fontSizeMed   = "font-size:8.5pt;";
	$fontSizeLarge = "font-size:10pt;";
} elsif ($agent->{os} eq "MacOS") { # mac fonts one size bigger
    if ($agent->{browser} eq "Netscape") {
	$fontSizeSmall = "font-size:9pt;";
	$fontSizeMed   = "font-size:10pt;";
	$fontSizeLarge = "font-size:11pt;";
    } else {
	$fontSizeSmall = "font-size:7.5pt;";
	$fontSizeMed   = "font-size:8.5pt;";
	$fontSizeLarge = "font-size:10pt;";
    }
}

# side nav classes
$sideNavActiveCell    = "{background:#999966}";
$sideNavInactiveCell  = "{background:#cccc99}";
$sideNavAdminCell     = "{background:#999966}";
$sideNavHeader        = "{$fontFamily $fontSizeSmall color:#000000; text-decoration:none}";
$sideNavHeaderBold    = "{$fontFamily $fontSizeSmall font-weight:bold; color:#000000; text-decoration:none}";
$sideNavHeaderBoldWhite="{$fontFamily $fontSizeSmall font-weight:bold; color:#ffffff; text-decoration:none}";
$workflowBold         = "{$fontFamily $fontSizeSmall font-weight:bold; color:#666633}";
$workflowHeader       = "{$fontFamily $fontSizeSmall font-weight:bold; color:#666633}";


# link classes
$orangeLink     = "{$fontFamily $fontSizeSmall color:#CC6633;}";
$orangeLinkBold = "{$fontFamily $fontSizeSmall font-weight:bold; color:#CC6633;}";
$blueLink      = "{$fontFamily $fontSizeSmall color:#669999;}";
$blueLinkBold  = "{$fontFamily $fontSizeSmall color:#669999; font-weight:bold}";
$darkBlueLink  = "{$fontFamily $fontSizeSmall color:#006666;}";
$redLink       = "{$fontFamily $fontSizeSmall color:#993300; font-weight:bold}";
$redLinkLarge  = "{$fontFamily $fontSizeMed   color:#993300; font-weight:bold}";
$whiteLink     = "{$fontFamily $fontSizeSmall color:#ffffff; text-decoration:none}";
$whiteUnderlinedLink     = "{$fontFamily $fontSizeSmall color:#ffffff;}";
$whiteMedUnderlinedLink = "{$fontFamily $fontSizeMed color:#ffffff;}";
$blackLink     = "{$fontFamily $fontSizeSmall color:#000000; text-decoration:none}";
$blackMedUnderlinedLink = "{$fontFamily $fontSizeMed color:#006666;}";
$blackLinkBold = "{$fontFamily $fontSizeSmall color:#000000; font-weight:bold}";
$blackUnderlinedLink = "{$fontFamily $fontSizeSmall color:#006666;}";

# general classes
$body         = "{$fontFamily $fontSizeSmall}";
$title        = "{$fontFamily $fontSizeLarge}";
$header       = "{$fontFamily $fontSizeLarge}";
$subHeader    = "{$fontFamily $fontSizeMed}";
$label        = "{$fontFamily $fontSizeSmall font-weight:bold}";
$redLabel     = "{$fontFamily $fontSizeSmall font-weight:bold; color:red}";
$burgandyLabel= "{$fontFamily $fontSizeSmall font-weight:bold; color:#993300}";
$whiteLabel   = "{$fontFamily $fontSizeSmall font-weight:bold; color:white}";
$description  = "{$fontFamily $fontSizeSmall color:blue}";
$errorMsg     = "{$fontFamily $fontSizeLarge color:red; font-weight:bold}";
$radioLabel   = "{$fontFamily $fontSizeLarge font-weight:bold;}";

# body classes
$adminTab        = "{background:#cc6633; $fontFamily $fontSizeLarge color:white; font-weight:bold;}";
$adminSubTab     = "{background:#cc6633; $fontFamily $fontSizeSmall color:white; font-weight:bold;}";
$workflowTab     = "{background:#006666; $fontFamily $fontSizeLarge color:white; font-weight:bold;}";
$whiteTextTab    = "{$fontFamily $fontSizeMed color:white; font-weight:bold;}";
$workflowSubTab  = "{background:#006666; $fontFamily $fontSizeSmall color:white; font-weight:bold;}";
$darkHeader      = "{background:#666633; $fontFamily $fontSizeSmall color:white; font-weight:bold;}";
$medHeader       = "{background:#999966;}";
$lightHeader     = "{background:#cccc99;}";
$greyHeader      = "{background:#cccccc;}";
$redHeader       = "{background:#993300; $fontFamily $fontSizeLarge color:white; font-weight:bold;}";
$tealHeader      = "{background:#669999; $fontFamily $fontSizeLarge color:white; font-weight:bold;}";
$textInput       = "{$fontFamily $fontSizeSmall width:200px;}";
$tealHighlight  = "{background:#669999; $fontFamily $fontSizeSmall color:white; font-weight:bold;}";
</%perl>

<style type="text/css">

BODY       <% $body %>
TD         <% $body %>
TH         <% $header %>
.textInput <% $textInput %>
.textArea  <% $body %>

.blueLink       <% $blueLink %>
.blueLinkBold   <% $blueLinkBold %>
.orangeLink     <% $orangeLink %>
.orangeLinkBold <% $orangeLinkBold %>
.darkBlueLink   <% $darkBlueLink %>
.redLink        <% $redLink %>
.redLinkLarge   <% $redLinkLarge %>
.whiteLink      <% $whiteLink %>
.whiteUnderlinedLink      <% $whiteUnderlinedLink %>
.blackLink      <% $blackLink %>
.blackLinkBold  <% $blackLinkBold %>
.whiteMedUnderlinedLink <% $whiteMedUnderlinedLink %>
.blackUnderlinedLink <% $blackUnderlinedLink %>
.blackMedUnderlinedLink <% $blackMedUnderlinedLink %>
.sideNavActiveCell   <% $sideNavActiveCell %>
.sideNavInactiveCell <% $sideNavInactiveCell %>
.sideNavAdminCell    <% $sideNavAdminCell %>
.sideNavHeader       <% $sideNavHeader %>
.sideNavHeaderBold   <% $sideNavHeaderBold %>
.sideNavHeaderBoldWhite <% $sideNavHeaderBoldWhite %>


.workflowBold        <% $workflowBold %>
.workflowHeader      <% $workflowHeader %>

.title       <% $title %>
.header      <% $header %>
.subHeader   <% $subHeader %>
.label       <% $label %>
.redLabel    <% $redLabel %>
.burgandyLabel <% $burgandyLabel %>
.whiteLabel  <% $whiteLabel %>
.description <% $description %>
.errorMsg    <% $errorMsg %>
.radioLabel  <% $radioLabel %>

.adminTab       <% $adminTab %>
.workflowTab    <% $workflowTab %>
.adminSubTab    <% $adminSubTab %>
.whiteTextTab   <% $whiteTextTab %>
.workflowSubTab <% $workflowSubTab %>
.darkHeader     <% $darkHeader %>
.medHeader      <% $medHeader %>
.lightHeader    <% $lightHeader %>
.redHeader      <% $redHeader %>
.tealHeader     <% $tealHeader %>
.greyHeader     <% $greyHeader %>
.tealHighlight  <% $tealHighlight %>

</style>
<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.9 $

=head1 DATE

$Date: 2002-02-14 21:59:39 $

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/css.mc" &>

=head1 DESCRIPTION

Generate platform specific stylesheets.

</%doc>
