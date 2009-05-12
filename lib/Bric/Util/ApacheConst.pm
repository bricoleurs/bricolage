package Bric::Util::ApacheConst;

=head1 Name

Bric::Util::ApacheConst - Common Apache and HTTP status code constants

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::ApacheConst qw(:common);
  use Bric::Util::ApacheConst;

=head1 Description

This package implements common constants used by mod_perl handlers for return
values and HTTP status codes so that Bricolage doesn't have to care about
which version of Apache is running.

=head1 Author

Scott Lanning <slanning@cpan.org>

=cut

use strict;

use constant OK                         =>   0;
use constant DECLINED                   =>  -1;

use constant HTTP_OK                    => 200;
use constant HTTP_CREATED               => 201;
use constant HTTP_ACCEPTED              => 202;
use constant HTTP_NO_CONTENT            => 204;

use constant HTTP_MOVED_PERMANENTLY     => 301;
use constant HTTP_MOVED_TEMPORARILY     => 302;
use constant HTTP_SEE_OTHER             => 303;
use constant HTTP_NOT_MODIFIED          => 304;

use constant HTTP_BAD_REQUEST           => 400;
use constant HTTP_UNAUTHORIZED          => 401;
use constant HTTP_FORBIDDEN             => 403;
use constant HTTP_NOT_FOUND             => 404;
use constant HTTP_CONFLICT              => 409;

use constant HTTP_INTERNAL_SERVER_ERROR => 500;
use constant HTTP_NOT_IMPLEMENTED       => 501;
use constant HTTP_BAD_GATEWAY           => 502;
use constant HTTP_SERVICE_UNAVAILABLE   => 503;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    OK
    DECLINED

    HTTP_OK
    HTTP_CREATED
    HTTP_ACCEPTED
    HTTP_NO_CONTENT

    HTTP_MOVED_TEMPORARILY
    HTTP_MOVED_PERMANENTLY
    HTTP_SEE_OTHER
    HTTP_NOT_MODIFIED

    HTTP_BAD_REQUEST
    HTTP_UNAUTHORIZED
    HTTP_FORBIDDEN
    HTTP_NOT_FOUND
    HTTP_CONFLICT

    HTTP_INTERNAL_SERVER_ERROR
    HTTP_NOT_IMPLEMENTED
    HTTP_BAD_GATEWAY
    HTTP_SERVICE_UNAVAILABLE
);

1;
