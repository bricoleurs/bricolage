package Bric::Dist::Handler;

=head1 NAME

Bric::Dist::Handler - Apache/mod_perl handler for executing distribution jobs.

=head1 VERSION

$Revision: 1.6 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.6 $ )[-1];

=head1 DATE

$Date: 2002-01-06 04:40:36 $

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
use Bric::Util::Fault::Exception::GEN;
use Bric::App::Event qw(log_event);
use Bric::Dist::Job;
use Apache::Constants qw(:common);
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
my $gen = 'Bric::Util::Fault::Exception::GEN';

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
	$r->content_type('text/html');
	$r->send_http_header;
	my %headers = $r->headers_in;
	# Execute all the jobs.
	foreach my $jid (split /\s*,\s*/, $headers{Execute}) {
	    eval {
		my $job = Bric::Dist::Job->lookup({ id => $jid }) ||
		  die $gen->new({msg => "Job $jid does not exist." });
		$job->execute_me;
		log_event("job_exec", $job);
	    };
	    # Log any errors.
	    log_err($r, $@, "Error executing Job $jid") if $@;
	}
    };
    # Log any errors.
    log_err($r, $@, "Error processing jobs") if $@;

    # Return okay.
    return OK;
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
    # Get a handle on the log.
    my $log = $r->log;
    unless (ref $err) {
	# Just get it over with if it's not an exception object.
	$log->crit("$msg: $err");
	return 1;
    }

    # Otherwise, log the exception. Start by formatting the environment.
    my $env = $err->get_env;
    my $env_msg;
    while (my ($k, $v) = each %$env) { $env_msg .= "$k => $v\n" }
    # Log it!
    $log->crit("$msg: " . $err->get_msg . "\nContext: " . $err->get_pkg . " (" .
	       $err->get_filename . "), Line " . $err->get_line . "\nPayload:\n"
	       . ($err->get_payload || '') . "\nEnvironment:\n$env_msg\n");
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
