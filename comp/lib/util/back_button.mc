<a href="#" onClick="window.location.href='<% $url %>'; return false;"><img src="/media/images/return_dgreen.gif" border=0  /></a>
<%args>
$label => 'Back'
$url => undef
</%args>
<%init>;
$url ||= last_page();
</%init>
<%doc>
=head1 NAME

/lib/util/bac_button.mc - Adds a self-contained back button to a page

=head1 VERSION

$Revision: 1.6 $

=head1 DATE

$Date: 2002-05-20 03:21:57 $

=head1 SYNOPSIS

  $m->comp('/lib/util/bac_button.mc');

=head1 DESCRIPTION

This element adds a self-contained back button to a page. The back button
lives in its own form tags, so it can stand alone on a page that otherwise
purely displays information. There are two optional arguments to this element.

=over 4

=item *

label - The label for the back button. Defaults to 'Back'.

=item *

url - The URL to which the browser is redirected when the back button is
clicked. Defaults to the value returned by last_page().

=back

</%doc>
