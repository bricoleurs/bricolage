<%doc>
###############################################################################

=head1 NAME

parseUri.mc. Examine url and return section, mode and type parameters for
calling element.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = substr(q$Revision: 1.1 $, 10, -1);

=head1 DATE

$Date: 2001-09-06 21:51:57 $

=head1 SYNOPSIS

=head1 DESCRIPTION

Returns $section (ie. admin), $mode (ie. manager, profile) and $type (ie. user,
media, etc). This is centralized here in case it becomes a complicated thing to
do. And, centralizing is nice.

=head1 REVISION HISTORY
$Log: parseUri.mc,v $
Revision 1.1  2001-09-06 21:51:57  wheeler
Initial revision

</%doc>

<%perl>;
# this is centralized in case uri parsing becomes unexpectedly complicated.
my @items = split /\//, $r->uri;
return @items[1..$#items];
#my $type = $items[3];
#my $mode = $items[2];
#my $section = $items[1];
#return ( $section, $mode, $type );
</%perl>
