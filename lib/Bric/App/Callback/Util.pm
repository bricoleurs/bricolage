package Bric::App::Callback::Util;

use strict;
use Bric::App::Session qw(:state);
use HTTP::BrowserDetect;

use base qw(Exporter);
our @EXPORT_OK = qw(parse_uri status_msg);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my $statmsg_key = '_status_msg_';


sub parse_uri {
    my $uri = shift;
    return split /\//, substr($uri, 1);
}

sub status_msg {
    my @msgs = @_;

    my $old_autoflush = $m->autoflush;   # autoflush is restored below
    $m->autoflush(1);

    unless ($r->pnotes($statmsg_key)) {
        $m->out("<br />\n" x 2);
    }

    my $space = '&nbsp;' x 20;
    map $m->out(qq{$space<span class="errorMsg">$_</span><br />\n}), @msgs;
    $m->flush_buffer;
    $m->autoflush($old_autoflush);
    $r->pnotes($statmsg_key, 1);
}


1;

__END__

=head1 NAME

Bric::App::Callback::Util - utility functions for callbacks

=head1 VITALS

=over 4

=item Version

$Revision: 1.1.2.6 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.1.2.6 $ )[-1];

=item Date

$Date: 2003-06-10 15:27:17 $

=item CVS ID

$Id: Util.pm,v 1.1.2.6 2003-06-10 15:27:17 slanning Exp $

=back

=head1 SYNOPSIS

  use Bric::App::Callback::Util qw(:all);

  my ($section, $mode, $type) = parse_uri($uri);
  my $ua = detect_agent();
  status_msg(@msgs);

=head1 DESCRIPTION

This class provides utility functions for callback
classes to use. They generally are replacements for
what used to be done with $m->comp calls.

=head1 FUNCTIONS

=head2 parse_uri

Returns $section (e.g. admin), $mode (e.g. manager, profile)
and $type (e.g. user, media, etc). This is centralized here in case
it becomes a complicated thing to do. And, centralizing is nice.

Note: was comp/lib/util/parseUri.mc

=head2 status_msg

Sometimes there's a long process executing, and you want to send status messages
to the browser so that the user knows what's happening. This element will do
this for you. Call it each time you want to send one or more status messages,
and it'll take care of the rest for you. When you're done, you can either
redirect to another page, or simply finish drawing the current page. It will
draw in below the status messages.

Note: was comp/lib/util/status_msg.mc

=head1 AUTHOR

This module:

Scott Lanning <lannings@who.int>

Original authors:

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric::App::Callback|Bric::App::Callback>
