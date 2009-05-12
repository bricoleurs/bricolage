package Bric::App::CleanupHandler;

=head1 Name

Bric::App::CleanupHandler - Cleans up at the end of a request.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  <Perl>
  use lib '/usr/local/bricolage/lib';
  </Perl>
  PerlModule Bric::App::Handler
  PerlModule Bric::App::AccessHandler
  PerlModule Bric::App::CleanupHandler
  PerlFreshRestart    On
  DocumentRoot "/usr/local/bricolage/comp"
  <Directory "/usr/local/bricolage/comp">
      Options Indexes FollowSymLinks MultiViews
      AllowOverride None
      Order allow,deny
      Allow from all
      SetHandler perl-script
      PerlHandler Bric::App::Handler
      PerlAccessHandler Bric::App::AccessHandler
      PerlCleanupHandler Bric::App::CleanupHandler
  </Directory>

=head1 Description

This module handles the cleanup phase of an Apache request. It logs all events
to the database (which in turn send any alerts), syncs the session data, and
clears out the request cache.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::ApacheConst qw(OK);
use Bric::App::Session;
use Bric::App::Event qw(commit_events);
use Bric::Util::DBI qw(:trans);

################################################################################
# Inheritance
################################################################################

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################

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

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Functions

=over 4

=item my $status = handler()

Handles the apache request.

B<Throws:> None - the buck stops here!

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handler {
    my $r = shift;
    # Do nothing to subrequests.
    return OK if $r->main;

    eval {
        # Commit events (and send alerts).
        begin(1);
        commit_events();
        commit(1);
    };
    # Log any errors.
    if (my $err = $@) {
        rollback(1);
        $r->log->error($err->full_message);

        # Exception::Class::Base provides trace->as_string, but trace_as_text is
        # not guaranteed. Use print STDERR to avoid escaping newlines.
        print STDERR $err->can('trace_as_text')
          ? $err->trace_as_text
            : join ("\n",
                    map {sprintf "  [%s:%d]", $_->filename, $_->line }
                      $err->trace->frames),
          "\n";
    }

    eval {
        # Sync the user's session data.
        Bric::App::Session::sync_user_session($r);
    };
    # If there's a problem with this (unlikely!), then we're hosed. Apache will
    # hang and need to be rebooted.
    $r->log->error(ref $@ ? $@->as_text : $@) if $@;
    # Bail (this actually isn't required, but let's be consistent!).
    return OK;
}


=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
