<%doc>
###############################################################################

=head1 NAME

=head1 SYNOPSIS

<& "/widgets/wrappers/table_top.mc" &>

=head1 DESCRIPTION

generate a top table

=cut

</%doc>
<%args>
$number    => 0
$caption   => "&nbsp;"
$height    => 1
$rightText => "&nbsp;"
$border    => 1
$localize  => 1
$search    => 0
$id        => undef
$class     => undef
$object    => undef
</%args>
<%init>;
$caption =~ s /^\s*|\s{2,}|\s*$//g;
$caption = $lang->maketext($caption) if $localize;
my $name = get_class_info($object)->get_plural_name if $object;
$caption =~ s/\%n/$lang->maketext($name)/e if $object;

my ($section, $mode, $type) = parse_uri($r->uri);

$class .= ($class) ? " clearboth" : "clearboth";
$class .= " border" if ($border);

# If it's a search box, it doesn't matter what section we're in.
$section = "search" if $search;

# If $number != 0, then use a class that makes the background
# light, with a colored number.  If $number == 0, make the whole
# tab colored.
my $headerClass = ($number) ? "header" : "fullHeader";

my $attrs = $id ? qq{ id="$id"} : '';
$attrs .= qq{ class="$class"};
</%init>
% if ($number) {

<a name="section<% $number %>"></a>
% }
<div class="<% $section %>Box clearboth">
  <div class="<% $headerClass %>">
    <div class="number"><% ($number) ? $number : "&nbsp;" %></div>
    <div class="caption"><% $caption %></div>
    <div class="rightText"><% $rightText %></div>
  </div>
  <div<% $attrs %>>