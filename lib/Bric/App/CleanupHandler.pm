package Bric::App::CleanupHandler;

=head1 NAME

Bric::App::CleanupHandler - Cleans up at the end of a request.

=head1 VERSION

$Revision: 1.2.2.2 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.2.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:32 $

=head1 SYNOPSIS

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

=head1 DESCRIPTION

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
use Apache::Constants qw(OK);
use Bric::App::Session;
use Bric::App::ReqCache;
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
my $ap = 'Bric::Util::Fault::Exception::AP';

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
    eval {
	# Commit events (and send alerts).
	begin(1);
	commit_events();
	commit(1);

	# Sync the user's session data.
	Bric::App::Session::sync_user_session($r);
	Bric::App::ReqCache->clear;
    };
    # Log any errors.
    if (my $err = $@) {
	rollback();
	$r->log->error($err);
    }
    # Bail (this actually isn't required, but let's be consistent!).
    return OK;
}


=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),

=cut
