package Bric::SOAP::Handler;
###############################################################################

=head1 NAME

Bric::SOAP::Handler - Apache/mod_perl handler for SOAP interfaces

=head1 VERSION

$Revision: 1.12 $

=cut

our $VERSION = (qw$Revision: 1.12 $ )[-1];

=head1 DATE

$Date: 2003-04-01 04:57:26 $

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

=back

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item Bric::SOAP::Handler->handler()

Handles a request for a SOAP interface.  Calls
SOAP::Transport::HTTP::Apache->handler() to dispatch the request.

Throws: NONE

Side Effects: NONE

Notes: NONE

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

use strict;
use warnings;

use constant DEBUG => 0;

# turn on tracing when debugging
use SOAP::Lite +trace => [ (DEBUG ? ('all') : ()), fault => \&handle_err ];
use SOAP::Transport::HTTP;
use Bric::App::Auth;
use Bric::App::Session;
use Bric::Util::DBI qw(:trans);
use Bric::App::Event qw(clear_events);
use Bric::Util::Fault qw(:all);
use Apache::Constants qw(OK);
use Apache::Util qw(escape_html);

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

BEGIN {
    # Setup routines to serialize Exception::Class-based exceptions. It needs
    # to look like this (no, I'm not kidding):
    # sub SOAP::Serializer::as_Bric__Util__Fault__Exception__GEN {
    #     [ $_[2], $_[4], escape_html($_[1]->error) ];
    # }

    foreach my $ec (keys %Exception::Class::CLASSES) {
        $ec =~ s/::/__/g;
        eval qq{sub SOAP::Serializer::as_$ec {
            [ \$_[2], \$_[4], escape_html(\$_[1]->error) ];
        }};
    }
}

my $commit = 1;
my $apreq;

# dispatch to $SERVER->handler()
sub handler {
    my ($r) = @_;
    $apreq = $r;
    my $status;

    eval {
        # Start the database transactions.
        begin(1);

        my $action = $r->header_in('SOAPAction') || '';

        print STDERR __PACKAGE__ . "::handler called : $action.\n" if DEBUG;

        # setup user session
        Bric::App::Session::setup_user_session($r);

        # let everyone try to login
        if ($action eq '"http://bricolage.sourceforge.net/Bric/SOAP/Auth#login"') {
            $status = $SERVER->handler(@_);
        } else {

            # check auth
            my ($res, $msg) = Bric::App::Auth::auth($r);

            if ($res) {
                $status = $SERVER->handler(@_);
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
        }
    };

    # Do error processing, if necessary.
    handle_err(0, 0, $@) if $@;

    # Commit to the database, unless there was an error.
    if ($commit) {
        commit(1);
    } else {
        # Reset for the next request.
        $commit = 1;
    }

    # Free up the apache request object.
    undef $apreq;

    # Boogie!
    return $status;
}

sub handle_err {
    my ($code, $string, $err, $actor) = @_;

    # Prevent the commit in handler().
    $commit = 0;

    # Create an exception object unless we already have one.
    $err = Bric::Util::Fault::Exception::AP->new
        ( error => "Error executing SOAP command", payload => $err || $string )
        unless isa_bric_exception($err);

    # Rollback the database transactions.
    eval { rollback(1) };
    my $more_err = $@ ? "In addition, the database rollback failed: $@" : undef;

    # Clear out events so that they won't be logged.
    clear_events();

    # Send the error to the apache error log.
    $apreq->log->error($err->error . ': ' . ($err->payload || '') .
                       ($more_err ? "\n\n$more_err" : '') . "\nStack Trace:\n"
                       . join("\n", @{$err->get_stack}) . "\n\n");
}

# silence warnings from SOAP::Lite
{
    no warnings;
    use overload;
    sub SOAP::Serializer::gen_id { 
        overload::StrVal($_[1]) =~ /\((0x\w+)\)/o;
        $1;
    }
}

1;
