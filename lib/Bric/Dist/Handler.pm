package Bric::Dist::Handler;

=head1 Name

Bric::Dist::Handler - Apache/mod_perl handler for executing distribution jobs.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  <Location /dist>
      SetHandler perl-script
      PerlHandler Bric::Dist::Handler
  </Location>

=head1 Description

This module is a simple Apache/mod_perl handler for executing Bricolage
distribution jobs. It responds to a request with the headers "execute" and/or
"expire", where the values are a comma-separated list of Bric::Util::Job IDs.
Bric::Dist::Handler will instantiate and execute and/or expire each of those
jobs in turn. See Bric::Dist::Client for an interface to send those headers.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:mod_perl);
use Bric::Util::Fault qw(:all);
use Bric::App::Event qw(log_event clear_events);
use Bric::App::Util qw(:pref);
use Bric::Util::Job;
use Bric::Util::Time qw(:all);
use Bric::Util::ApacheConst qw(OK);

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

=head1 Interface

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

=head1 Private

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
        $r->headers_out->{BricolageDist} = 1;
        $r->send_http_header if MOD_PERL_VERSION < 2;

        # Set up the language object and handle the request.
        Bric::Util::Language->get_handle(get_pref('Language'));

        # Execute all the jobs.
        for my $job (Bric::Util::Job->list({
            sched_time  => [undef, strfdate()],
            comp_time   => undef,
            failed      => 0,
            executing   => 0,
        })) {
            $job->execute_me;
            Bric::Util::Burner->flush_another_queue;
            log_event("job_exec", $job);
        }
    };

    # Log any errors.
    log_err($r, $@, "Error processing jobs") if $@;

    return OK;
}

##############################################################################

=item my $bool = log_err($r, $err, $msg)

Logs an error to the Apache error log. Will handle both standard error
messages as well as Bric::Util::Fault objects.

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
    $r->print($err->full_message);

    # Send the error(s) to the apache error log.
    $r->log->crit($err->full_message);

    # Exception::Class::Base provides trace->as_string, but trace_as_text is
    # not guaranteed. Use print STDERR to avoid escaping newlines.
    print STDERR $err->can('trace_as_text')
      ? $err->trace_as_text
      : join ("\n",
              map {sprintf "  [%s:%d]", $_->filename, $_->line }
                $err->trace->frames),
        "\n";
}

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::Job|Bric::Util::Job>

=cut
