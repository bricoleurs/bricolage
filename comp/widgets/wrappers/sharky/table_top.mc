<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/table_top.mc" &>

=head1 DESCRIPTION

generate a top table

=cut

</%doc>
<%args>
$number  => 0
$caption => ''
$height  => 1
$ghostly => 0
$rightText => undef
$border => 1
$localize => 1
</%args>
<%init>;
$caption =~ s /^\s*|\s{2,}|\s*$//g;
$caption = $lang->maketext($caption) if $localize;

my ($section, $mode, $type) = parse_uri($r->uri);
my $borderColor = ($section eq "admin") ? "999966" : "669999";
my $numberColor = ($section eq "admin") ? "CC6633" : "669999";

my ($leftGif, $num1, $num2);
my $width = 20;
my $rightGif = '<img src="/media/images/lt_green_curve_right.gif" width=8 height=18>';

if ($number > 0 && $number < 10) {
    $leftGif = '<img src="/media/images/numbers/' . $numberColor . "_curve_" . $number . '.gif" width=20 height=18>';
} elsif ($number >=10 ) {
    $num1 = substr($number, 0 ,1);
    $num2 = substr($number, 1 ,1);
    $width = 35;
    $leftGif = '<img src="/media/images/numbers/' . $numberColor . "_curve_" . $num1 . '.gif" width=20 height=18>';
    $leftGif.= '<img src="/media/images/numbers/' . $numberColor . "_" . $num2 . '.gif">';
} else {
    $leftGif = '<img src="/media/images/numbers/' . $numberColor . '_curve_blank.gif" width=20 height=18>';
}
</%init>
% if ($number) {
<a name="section<% $number %>"></a>
% }
% if ($ghostly) {
<table width="580" border="0" cellpadding="0" cellspacing="0">
<tr>
  <td width="<% $width %>' bgcolor="<% $numberColor %>"><% $leftGif %></td>
  <td width="560" style="padding-left: 4px;"><% uc( $caption ) %></td>
</tr>
</table>
% } else {
<table width="580" border="0" cellpadding="0" cellspacing="0">
<tr>
  <td width="<% $width %>' bgcolor="<% $numberColor %>"><% $leftGif %></td>
% if ($rightText) {
% my $remWidth = 580 - $width - 8;
  <td width="<% $remWidth %>" class="lightHeader">
  <table border="0" cellpadding="0" cellspacing="0" width="<% 580 - $width - 8 %>">
  <tr class="lightHeader">
    <td width="<% int($remWidth / 2) %>" class="lightHeader" style="padding-left: 4px;"><% uc( $caption ) %></td>
    <td width="<% int($remWidth / 2) %>" class"=lightHeader" align="right"><% $rightText %></td>
  </tr>
  </table>
  </td>
% } else {
  <td class="lightHeader" width="552" style="padding-left: 4px;"><% uc( $caption ) %></td>
% }
  <td width="8" bgcolor="<% $numberColor %>"><% $rightGif %></td>
</tr>
</table>
<!-- open box -->
% if ($border) {
<div style="width: 578px; margin-bottom: 10px; border-style: solid; border-color: #<% $borderColor %>; border-width: 0 1px 1px 1px;">
% } else {
<div style="width: 580px; margin-bottom: 10px;">
% }
% }
