%#--- Init ---#
<%init>;
$m->comp("display.html", %ARGS);
</%init>
%#--- Documentation ---#
<%doc>

=head1 NAME

perm - A widget for displaying permissions.

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

  $m->comp('/widgets/perm/perm.mc',
           grp       => $grp,
           num       => $num,
           read_only => $read_only);

=head1 DESCRIPTION

Displays the permissions for a group. The arguments are as follows:

=over 4

=item *

grp - The Bric::Util::Grp object for which permissions are granted. Required.

=item *

num - The number to put into the table_top box. Defaults to undef.

=item *

read_only - Disables the form inputs and outputs only text data instead.

=back

</%doc>