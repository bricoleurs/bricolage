package Bric::SOAP::Handler;
###############################################################################

=head1 NAME

Bric::SOAP::Handler - Apache/mod_perl handler for SOAP interfaces

=head1 VERSION

$Revision: 1.4 $

=cut

our $VERSION = (qw$Revision: 1.4 $ )[-1];

=head1 DATE

$Date: 2002-02-13 00:50:48 $

=head1 SYNOPSIS

  <Location /soap>
    SetHandler perl-script
    PerlHandler Bric::SOAP::Handler
    PerlCleanupHandler Bric::App::CleanupHandler
    PerlAccessHandler Apache::OK
  </Location>

=head1 DESCRIPTION

This module provides an Apache/mod_perl PerlHandler for the Bricolage
SOAP interface.  This handler dispatches calls to the various
Bric::SOAP modules.

=head1 CONSTANTS

=over 4

=item SOAP_CLASSES

Array of SOAP interface module names.  The handler will only dispatch
calls to these classes.

=back 4

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item Bric::SOAP::Handler->handler()

Handles a request for a SOAP interface.  Calls
SOAP::Transport::HTTP::Apache->handler() to dispatch the request.

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

use constant DEBUG => 0;

# turn on tracing when debugging
use SOAP::Lite (DEBUG ? ('trace') : ());
use SOAP::Transport::HTTP;
use Bric::App::Auth;
use Bric::App::Session;
use Apache::Constants qw(OK);

use constant SOAP_CLASSES => [qw(
				 Bric::SOAP::Auth
				 Bric::SOAP::Story
				 Bric::SOAP::Media
				 Bric::SOAP::Template
				 Bric::SOAP::Element
				 Bric::SOAP::Category
				 Bric::SOAP::Workflow
				)];

my $SERVER = SOAP::Transport::HTTP::Apache->dispatch_to(@{SOAP_CLASSES()});

# setup serializer to pretty-print XML if debugging
$SERVER->serializer->readable(1) if DEBUG;

# dispatch to $SERVER->handler()
sub handler { 
  my ($r) = @_;  
  my $action = $r->header_in('SOAPAction') || '';

  print STDERR __PACKAGE__ . "::handler called : $action.\n" if DEBUG;
    
  # setup user session
  Bric::App::Session::setup_user_session($r);

  # let everyone try to login
  return $SERVER->handler(@_)
    if $action eq '"http://bricolage.sourceforge.net/Bric/SOAP/Auth#login"';

  # check auth
  my ($res, $msg) = Bric::App::Auth::auth($r);
  
  if ($res) {
    return $SERVER->handler(@_); 
  } else {
    $r->log_reason($msg);
    $r->send_http_header('text/xml');
    # send a SOAP fault.  I can't find an easy way to do this with
    # SOAP::Lite without reinventing some wheels...
    print <<END;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope 
 xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
 xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
 xmlns:xsd="http://www.w3.org/1999/XMLSchema" 
 SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
 xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Body>
    <SOAP-ENV:Fault xmlns="http://schemas.xmlsoap.org/soap/envelope/">
      <faultcode xsi:type="xsd:string">SOAP-ENV:Client</faultcode>
      <faultstring xsi:type="xsd:string">$msg</faultstring>
      <faultactor xsi:null="1"/>
    </SOAP-ENV:Fault>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
END
  }

  return OK;
}
1;
