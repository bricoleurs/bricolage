package Bric::Util::ApacheReq;

=head1 NAME

Bric::Util::ApacheReq - wrapper around Apache 1 and 2 Request classes

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2006-03-18 02:10:10 +0100 (Sat, 18 Mar 2006) $

=head1 SYNOPSIS

  use Bric::Util::ApacheReq;
  my $r = Bric::Util::ApacheReq->instance;

=head1 DESCRIPTION

This package encapsulates the C<Apache::Request> and C<Apache2::RequestUtil>
classes so that Bricolage doesn't have to care about which version of Apache is running.
So instead of doing this:

  use Bric::Config qw(MOD_PERL_VERSION);
  BEGIN {
      if (MOD_PERL_VERSION < 2) {
          require Apache;
          require Apache::Request;
      } else {
          require Apache2::Request::Util;
      }
  }
  my $r = (MOD_PERL_VERSION < 2 ? Apache::Request->instance(Apache->request) : Apache2::RequestUtil->request);

you do what's shown in the SYNOPSIS.

=cut

use strict;
use Bric::Config qw(:mod_perl);
BEGIN {
    if (MOD_PERL) {
        if (MOD_PERL_VERSION < 2) {
            require Apache;
            require Apache::Request;
        } else {
            require Apache2::Request::Util;
        }
    }
}

=head1 INTERFACE

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

=back

=head1 AUTHOR

Scott Lanning <slanning@cpan.org>

=cut


1;
