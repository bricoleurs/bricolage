<%doc>
###############################################################################

=head1 NAME

parseUri.mc. Examine url and return section, mode and type parameters for
calling element.

=head1 VERSION

$Revision: 1.7 $

=cut

our $VERSION = (qw$Revision: 1.7 $ )[-1];

=head1 DATE

$Date: 2002-09-21 00:52:09 $

=head1 SYNOPSIS

=head1 DESCRIPTION

Returns $section (ie. admin), $mode (ie. manager, profile) and $type (ie. user,
media, etc). This is centralized here in case it becomes a complicated thing to
do. And, centralizing is nice.

=cut

</%doc>

<%perl>;
# This is centralized in case uri parsing becomes unexpectedly complicated,
# although it now looks like it couldn't get much simpler.
return split /\//, substr($r->uri, 1);
</%perl>
