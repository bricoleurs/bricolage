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


=head1 NAME

Bric::SOAP::Auth - module to handle authentication for the SOAP interface

=head1 VERSION

$Revision: 1.2 $

=cut

our $VERSION = (qw$Revision: 1.2 $ )[-1];

=head1 DATE

$Date: 2002-01-23 19:52:28 $

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

=item Bric::SOAP::Auth->handler()

Checks auth cookie handed out by login().  If the cookie is not
present the client recieves a SOAP fault.

Throws: NONE

Side Effects: NONE

Notes: NONE

=back 4

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

sub handler {
  return OK;
}



1;
