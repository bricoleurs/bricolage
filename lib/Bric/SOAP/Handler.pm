package Bric::SOAP::Handler;
###############################################################################

=head1 NAME

Bric::SOAP::Handler - Apache/mod_perl handler for SOAP interfaces

=head1 VERSION

$Revision: 1.2 $

=cut

our $VERSION = (qw$Revision: 1.2 $ )[-1];

=head1 DATE

$Date: 2002-01-16 21:46:13 $

=head1 SYNOPSIS

  <Location /soap>
    SetHandler perl-script
    PerlHandler Bric::SOAP::Handler
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

use constant SOAP_CLASSES => [qw(
				 Bric::SOAP::Auth
				 Bric::SOAP::Story
				 Bric::SOAP::Media
				 Bric::SOAP::Formatting
				 Bric::SOAP::Element
				 Bric::SOAP::Category
				 Bric::SOAP::Workflow
				)];

my $SERVER = SOAP::Transport::HTTP::Apache->dispatch_to(@{SOAP_CLASSES()});

# setup serializer to pretty-print XML if debugging
$SERVER->serializer->readable(1) if DEBUG;

# dispatch to $SERVER->handler()
sub handler { return $SERVER->handler(@_); }

1;
