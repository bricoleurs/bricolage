package Bric::SOAP::Auth;
###############################################################################

=head1 NAME

Bric::SOAP::Auth - module to handle authentication for the SOAP interface

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-01-11 22:55:18 $

=head1 SYNOPSIS

  <Location /soap>
    SetHandler perl-script
    PerlHandler Bric::SOAP::Handler
    PerlAccessHandler Bric::SOAP::Auth
  </Location>

=head1 DESCRIPTION

This module provides both a PerlAccessHandler and a SOAP login()
method.  Clients call the login() method before calling Bric::SOAP
classes and recieve a cookie.  The PerlAccessHandler validates this
cookie on every request.

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item $success = Bric::SOAP::Auth->login(username => $u, password => $p)

SOAP login method.  If login is successful returns 1 and sets an HTTP
cookie to be used on future calls to the SOAP interface.  On failure
returns 0 and does not set a cookie.

Throws: NONE

Side Effects: NONE

Notes: NONE

=item Bric::SOAP::Auth->handler()

Checks auth cookie handed out by login().  If the cookie is not
present the client recieves an HTTP FORBIDEN.  This should work fine
with SOAP::Lite clients - it remains to be seen if other SOAP toolkits
are ready for HTTP errors.

Throws: NONE

Side Effects: NONE

Notes: NONE

=back 4

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

use strict;
use warnings;


1;
