package Bric::Dist::Handler;

=head1 NAME

Bric::Dist::Handler - Apache/mod_perl handler for executing distribution jobs.

=head1 VERSION

$Revision: 1.7.2.1 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.7.2.1 $ )[-1];

=head1 DATE

$Date: 2003-07-02 21:52:49 $

=head1 SYNOPSIS

  <Location /dist>
      SetHandler perl-script
      PerlHandler Bric::Dist::Handler
  </Location>

=head1 DESCRIPTION

This module is a simple Apache/mod_perl handler for executing Bricolage distribution
jobs. It responds to a request with the headers "execute" and/or expire, where
the values are a comma-separated list of Bric::Dist::Job IDs. Bric::Dist::Handler
will instantiate and execute and/ore expire each of those jobs in turn. See
Bric::Dist::Client for an interface to send those headers.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::Fault qw(:all);
use Bric::App::Event qw(log_event clear_events);
use Bric::Dist::Job;
use Apache::Constants qw(HTTP_OK);
use Apache::Log;

################################################################################
# Inheritance
################################################################################

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################

################################################################################
# Instance Fields

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

NONE.

=head2 Destructors

=over 4

=item $h->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

NONE.

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $ret_code = handler($r)

Handles the HTTP request.

B<Throws:> NONE. All exceptions are logged to the Apache error log.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handler {
    my $r = shift;
    eval {
        $r->content_type('text/plain');
        $r->header_out(BricolageDist => 1);
        $r->send_http_header;

	my %headers = $r->headers_in;
	# Execute all the jobs.
	foreach my $jid (split /\s*,\s*/, $headers{Execute}) {
	    eval {
		my $job = Bric::Dist::Job->lookup({ id => $jid }) ||
                    throw_gen(error => "Job $jid does not exist.");
		$job->execute_me();
		log_event("job_exec", $job);
	    };
	    # Log any errors.
	    log_err($r, $@, "Error executing Job $jid") if $@;
	}
    };

    # Log any errors.
    log_err($r, $@, "Error processing jobs") if $@;

    return HTTP_OK;
}

=item my $bool = log_err($r, $err, $msg)

Logs an error to the Apache error log. Will handle both standard error messages
as well as Bric::Util::Fault objects.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub log_err {
    my ($r, $err, $msg) = @_;

    $err = Bric::Util::Fault::Exception::AP->new(
        error   => "Error processing Mason elements.",
        payload => $err,
    ) unless isa_exception($err);

    # Clear out events so that they won't be logged.
    clear_events();

    # Send the error to the client.
    $r->print($err->message);

    # Log it!
    $r->log->crit($err->as_text);
}

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric::Dist::Job|Bric::Dist::Job>

=cut
