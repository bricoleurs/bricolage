<%once>;
my $key = '_status_msg_';
my $space = '&nbsp;' x 20;
</%once>
<%init>;
local $m->interp->{out_mode} = 'stream';
unless ( $rc->get($key) ) {
    # We haven't called this thing yet. Throw up some initial information.
    $m->out("<br />\n" x 2);
#    $m->out(qq{
#<body bgcolor="white">
#<style type="text/css">
#.errorMsg {font-family:Verdana,Helvetica,Arial,sans-serif; font-size:12pt; color:red; font-weight:bold}
#</style>
#<img src="/media/images/spacer.gif" height="50" width="1"><br />
#    });
}
map $m->out(qq{$space<span class="errorMsg">$_</span><br />\n}), @_;
$m->flush_buffer;
$rc->set($key, 1);
</%init>
<%doc>

=head1 NAME

status_msg.mc - Sends messages to the browser in real-time

=head1 VERSION

$Revision: 1.1.1.1.2.1 $

=head1 DATE

$Date: 2001-10-09 21:51:02 $

=head1 SYNOPSIS

$m->comp('/lib/util/status_msg.mc', @msgs);

=head1 DESCRIPTION

Sometimes there's a long process executing, and you want to send status messages
to the browser so that the user knows what's happening. This element will do
this for you. Call it each time you want to send one or more status messages,
and it'll take care of the rest for you. When you're done, you can either
redirect to another page, or simply finish drawing the current page. It will
draw in below the status messages.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

</%doc>