package Bric::Util::ApacheReq;

=head1 Name

Bric::Util::ApacheReq - Wrapper around Apache 1 and 2 Request classes

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::ApacheReq;
  my $r = Bric::Util::ApacheReq->instance;

=head1 Description

This package encapsulates the L<Apache::Request|Apache::Request> and
L<Apache2::RequestUtil|Apache2::RequestUtil> classes so that Bricolage doesn't
have to care about which version of Apache is running. So instead of doing
this:

  use Bric::Config qw(MOD_PERL_VERSION);
  BEGIN {
      if (MOD_PERL_VERSION < 2) {
          require Apache;
          require Apache::Request;
      } else {
          require Apache2::Request::Util;
      }
  }
  my $r = (MOD_PERL_VERSION < 2
      ? Apache::Request->instance(Apache->request)
      : Apache2::RequestUtil->request);

you do what's shown in the SYNOPSIS.

It also adds the C<server> method from L<Apache|Apache> or
L<Apache2::ServerUtil|Apache2::ServerUtil>, as appropriate.

=cut

use strict;
use Bric::Config qw(:mod_perl :ssl);
BEGIN {
    if (MOD_PERL) {
        if (MOD_PERL_VERSION < 2) {
            require Apache;
            require Apache::Request;
        } else {
            require Apache2::RequestUtil;
            require Apache2::ServerUtil;
        }
    }
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(parse_args);

=head1 Interface

=head2 Public Class Methods

=over 4

=item my $req = Bric::Util::ApacheReq->request;

Returns either C<< Apache->request >> for mod_perl 1
or C<< Apache2::RequestUtil->request >> for mod_perl 2.

=cut

sub request {
    return MOD_PERL_VERSION < 2
      ? Apache->request
      : Apache2::RequestUtil->request;
}

=item my $r = Bric::Util::ApacheReq->instance;

Returns the Apache request object, i.e. C<$r>.
Optionally takes the following argument:

=over 4

$req - the Apache request object obtained by C<request>.
In the case of mod_perl 2, this is already the instance itself so it's just returned.

=back

=cut

sub instance {
    my ($pkg, $req) = @_;

    if (defined $req) {
        return MOD_PERL_VERSION < 2
          ? Apache::Request->instance($req)
          : $req;
    }
    else {
        return MOD_PERL_VERSION < 2
          ? Apache::Request->instance(Apache->request)
          : Apache2::RequestUtil->request;
    }
}

=item my $server = Bric::Util::ApacheReq->server;

Returns either C<< Apache->server >> for mod_perl 1
or C<< Apache2::ServerUtil->server >> for mod_perl 2.

=cut

sub server {
    return MOD_PERL_VERSION < 2
      ? Apache->server
      : Apache2::ServerUtil->server;
}

=item my $url = Bric::Util::ApacheReq->url();

    my $url = Bric::Util::ApacheReq->url;
    my $url = Bric::Util::ApacheReq->url( uri => '/foo/bar' );
    my $url = Bric::Util::ApacheReq->url( ssl => 1 );

Returns a URL for the server, with the correct scheme (http or https), host
name, and port (if needed). Pass in a C<url> parameter (including a leading
slash) to have a particular URI path included in the URL. If it's not passed,
or is C<undef>, it defaults to "/". If you're prefer to have SSL if it's
enabled, pass in an C<ssl> parameter with a true value.

=cut

sub url {
    my $req  = shift->instance;
    my %p = @_;
    my $http = 'http';
    my $port;
    if ( SSL_ENABLE && (ALWAYS_USE_SSL || $p{ssl}) ) {
        $http .= 's';
        # Yes string comparisons, because the constants are inlined.
        $port  = SSL_PORT eq '*' || SSL_PORT eq '443' ? '' : ':' . SSL_PORT;
    } else {
        $port  = LISTEN_PORT eq '*' || LISTEN_PORT eq '80' ? '' : ':' . LISTEN_PORT;
    }
    return "$http://" . $req->hostname . $port . (defined $p{uri} ? $p{uri} : '/');
}

=back

=head2 Public Functions

=over 4

=item my %args = parse_args(scalar $r->args);

In mod_perl, C<< $r->args >> could be used in list context, to return a parsed
hash of C<< key => value >>, but in mod_perl2 it can only be used in scalar
context. This implements the old behavior for mod_perl2 using C<parse_args>
from C<Apache2::compat>. Always call C<< $r->args >> in scalar context in
Bricolage code, then use this function to parse the result if necessary.

=cut

sub parse_args {
    my ($string) = @_;
    return () unless defined $string and $string;
    return map {
        tr/+/ /;
        s/%([0-9a-fA-F]{2})/pack 'C', hex($1)/ge;
        $_;
    } split /[=&;]/, $string, -1;
}

=back

=head1 Author

Scott Lanning <slanning@cpan.org>

=cut

1;
