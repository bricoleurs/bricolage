package Bric::SOAP::Auth;
###############################################################################

use strict;
use warnings;

use Bric::App::Auth;
use Apache;
use Apache::Constants qw(OK FORBIDDEN);

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;

=head1 NAME

Bric::SOAP::Auth - module to handle authentication for the SOAP interface

=head1 VERSION

$Revision: 1.3.2.1 $

=cut

our $VERSION = (qw$Revision: 1.3.2.1 $ )[-1];

=head1 DATE

$Date: 2002-11-08 01:34:53 $

=head1 SYNOPSIS

  # setup soap object
  my $soap = new SOAP::Lite
      uri => 'http://bricolage.sourceforge.net/Bric/SOAP/Auth',
      readable => DEBUG;

  # setup the proxy with a cookie jar to hold the auth cookie
  $soap->proxy('http://localhost/soap',
               cookie_jar => HTTP::Cookies->new(ignore_discard => 1));

  # call the login method
  my $response = $soap->login(name(username => USER), 
                              name(password => PASSWORD));

  # switch uri to call methods in other Bric::SOAP classes
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Story');

=head1 DESCRIPTION

This module provides a SOAP login service for Bricolage.  Clients call
the login() method before calling Bric::SOAP classes and recieve a
cookie.  Bric::SOAP::Handler validates this cookie using
Bric::App::Auth on every request.

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item $success = Bric::SOAP::Auth->login(username => $u, password => $p)

SOAP login method.  If login is successful returns 1 and sets an HTTP
cookie to be used on future calls to the SOAP interface.  On failure
returns a fault containing an error message.

Throws: NONE

Side Effects: NONE

Notes:

Calls Bric::App::Auth::login to check permissions and set the cookie.

=cut

sub login {
  my $pkg = shift;
  my $env = pop;
  my $args = $env->method || {};
  my $r = Apache->request;

  # check for required args
  die __PACKAGE__ . "::login : missing required parameter 'username'\n"
    unless exists $args->{username};
  die __PACKAGE__ . "::login : missing required parameter 'password'\n"
    unless exists $args->{password};

  print STDERR __PACKAGE__ . "::login : login attempt : $args->{username}\n"
    if DEBUG;

  # Workaround bug where an md5 of the password in utf-8 is not the
  # same as the md5 of the ascii password even if all characters are
  # 7-bit.
  my $password = $args->{password};
  $password = "$password";

  # call out to login
  my ($bool, $msg) = Bric::App::Auth::login($r,
                                            $args->{username},
                                            $password);

  return name(result => 1) if $bool;
  die __PACKAGE__ . "::login : login failed : $msg\n"; 
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>, L<Bric::SOAP::Handler|Bric::SOAP::Handler>

=cut

1;
