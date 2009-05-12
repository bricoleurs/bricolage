package Bric::SOAP::Handler;

###############################################################################

=head1 Name

Bric::SOAP::Handler - Apache/mod_perl handler for SOAP interfaces

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  <Location /soap>
    SetHandler perl-script
    PerlHandler Bric::SOAP::Handler
    PerlCleanupHandler Bric::App::CleanupHandler
    PerlAccessHandler Apache::HTTP_OK
  </Location>

=head1 Description

This module provides an Apache/mod_perl PerlHandler for the Bricolage
SOAP interface.  This handler dispatches calls to the various
Bric::SOAP modules.

=head1 Constants

=over 4

=item SOAP_CLASSES

Array of SOAP interface module names.  The handler will only dispatch
calls to these classes.

=back

=head1 Interface

=head2 Public Class Methods

=over 4

=item Bric::SOAP::Handler->handler()

Handles a request for a SOAP interface.  Calls
SOAP::Transport::HTTP::Apache->handler() to dispatch the request.

Throws: NONE

Side Effects: NONE

Notes: NONE

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>

=cut

use strict;
use warnings;

use constant DEBUG => 0;

# turn on tracing when debugging
use SOAP::Lite +trace => [ (DEBUG ? ('all') : ()), fault => \&handle_soap_err ];
use SOAP::Transport::HTTP;
use Bric::Config qw(:l10n);
use Bric::App::Auth;
use Bric::App::Session;
use Bric::Util::DBI qw(:trans);
use Bric::Util::Fault qw(:all);
use Bric::App::Event qw(clear_events);
use Bric::App::Util qw(:pref);
use Exception::Class 1.12;
use Bric::Util::ApacheReq;
use HTML::Entities;
require Encode if ENCODE_OK;

use constant SOAP_CLASSES => [qw(
                                 Bric::SOAP::Auth
                                 Bric::SOAP::Story
                                 Bric::SOAP::Media
                                 Bric::SOAP::Template
                                 Bric::SOAP::ElementType
                                 Bric::SOAP::Category
                                 Bric::SOAP::MediaType
                                 Bric::SOAP::Site
                                 Bric::SOAP::Keyword
                                 Bric::SOAP::User
                                 Bric::SOAP::Desk
                                 Bric::SOAP::Workflow
                                 Bric::SOAP::ATType
                                 Bric::SOAP::OutputChannel
                                 Bric::SOAP::ContribType
                                 Bric::SOAP::Destination
                                 Bric::SOAP::Preference
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

    foreach my $ec (Exception::Class->VERSION >= 1.20
                    ? Exception::Class::Classes()
                    : Exception::Class::Base->Classes)
    {
        $ec =~ s/::/__/g;
        eval qq{sub SOAP::Serializer::as_$ec {
            [ \$_[2], \$_[4], encode_entities(\$_[1]->error) ];
        }};
    }
}

if ( Bric::Config::ENCODE_OK && $SOAP::Lite::VERSION lt '0.71.03' ) {
    # XXX http://rt.cpan.org/Ticket/Display.html?id=35041
    package SOAP::Serializer;
    no warnings 'redefine';
    eval q{
        my $xmlize = \&xmlize;
        *xmlize = sub {
            my $ret = $xmlize->(@_);
            Encode::_utf8_off($ret) if Encode::is_utf8($ret);
            return $ret;
        }
    };
}

my $commit = 1;

# dispatch to $SERVER->handler()
sub handler {
    my ($r) = @_;
    my $status;

    eval {
        # Start the database transactions.
        begin(1);

        my $action = $r->headers_in->{'SOAPAction'} || '';

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
                # Set up the language object and handle the request.
                Bric::Util::Language->get_handle(get_pref('Language'));
                $status = $SERVER->handler(@_);
            } else {
                $r->log_reason($msg);
                $r->content_type('text/xml; charset=utf-8');
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

    # Boogie!
    return $status;
}

sub handle_err {
    my ($code, $string, $err, $actor) = @_;

    # Prevent the commit in handler().
    $commit = 0;

    # Create an exception object unless we already have one.
    $err = Bric::Util::Fault::Exception::AP->new(
        error   => "Error executing SOAP command",
        payload => $err || $string,
    ) unless isa_bric_exception($err);

    # Rollback the database transactions.
    eval { rollback(1) };
    my $more_err = $@ ? "In addition, the database rollback failed: $@" : undef;

    # Clear out events so that they won't be logged.
    clear_events();

    # Send the error(s) to the apache error log.
    my $log = Bric::Util::ApacheReq->server->log;
    $log->error($err->full_message);
    $log->error($more_err) if $more_err;

    # Exception::Class::Base provides trace->as_string, but trace_as_text is
    # not guaranteed. Use print STDERR to avoid escaping newlines.
    print STDERR $err->can('trace_as_text')
      ? $err->trace_as_text
      : join ("\n",
              map {sprintf "  [%s:%d]", $_->filename, $_->line }
                $err->trace->frames),
        "\n";
}

sub handle_soap_err {
    my $caller = (caller(2))[3];
    $caller = (caller(3))[3] if $caller =~ /eval/;
    chomp(my $msg = join ' ', grep { defined } @_);
    my $log = Bric::Util::ApacheReq->server->log;
    my $err = Bric::Util::Fault::Exception->new("$caller: $msg");
    handle_err(0, 0, $err);
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
