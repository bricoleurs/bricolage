package Bric::App::AccessHandler;

=head1 NAME

Bric::App::AccessHandler - Handles Authentication and Session setup during the
Apache Access phase.

=head1 VERSION

$Revision: 1.2 $

=cut

# Grab the Version Number.
our $VERSION = substr(q$Revision: 1.2 $, 10, -1);

=head1 DATE

$Date: 2001-09-06 22:30:06 $

=head1 SYNOPSIS

  <Perl>
  use lib '/usr/local/bricolage/lib';
  </Perl>
  PerlModule Bric::App::AccessHandler    <Location /media>
        SetHandler default-handler
    </Location>

  PerlModule Bric::App::Handler
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
  </Directory>

=head1 DESCRIPTION

This module handles the Access phase of an Apache request. It authenticates
users to Bricolage, and sets up Session handling.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Apache::Constants qw(:common);
use Apache::Log;
use Bric::App::Session;
use Bric::App::Util qw(:redir :history);
use Bric::App::Auth qw(auth logout);
use Bric::Config qw(:err);

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

=item my $status = handler($r)

Sets up the user session and checks authetication. If the authentication is current,
it returns OK and the request continues. Otherwise, it caches the requested URI in
the session and returns FORBIDDEN.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handler {
    my $r = shift;

    my $ret = eval {
	# Set up the user's session data.
	Bric::App::Session::setup_user_session($r);
	my ($res, $msg) = auth($r);
	return OK if $res;

	# If we're here, the user needs to authenticate. Figure out where they
	# wanted to go so we can redirect them there after they'ved logged in.
	$r->log_reason($msg);
#	my $uri = $r->uri;
#	my $args = $r->args;
#	$uri = "$uri?$args" if $args;
#	set_redirect($uri);
	set_redirect('/');
	my $hostname = $r->hostname;
	$r->custom_response(FORBIDDEN, "https://$hostname/login");
	return FORBIDDEN;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

################################################################################

=item my $status = logout_handler($r)

Logs the user out.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub logout_handler {
    my $r = shift;

    my $ret = eval {
	# Set up the user's session data.
	Bric::App::Session::setup_user_session($r);
	# Logout.
	logout();
	# Expire the user's session.
	Bric::App::Session::expire_session($r);

	# Rredirect to the login page.
	my $hostname = $r->hostname;
	$r->custom_response(FORBIDDEN, "https://$hostname/login");
	return FORBIDDEN;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

################################################################################

=item my $status = okay($r)

This handler should B<only> be used for the '/login' location of the SSL virtual
host. It simply sets up the user session and returns OK.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub okay {
    my $r = shift;
    my $ret = eval {
	# Set up the user's session data.
	Bric::App::Session::setup_user_session($r);
	return OK;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

################################################################################

=item my $status = handle_err($r, $err)

Handles errors for the other handlers in this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handle_err {
    my ($r, $err) = @_;
    # Set the filename for the error element.
    my $uri = $r->uri;
    (my $fn = $r->filename) =~ s/$uri/${\ERROR_URI}/;
    $r->uri(ERROR_URI);
    $r->filename($fn);
    my $msg = 'Error executing AccessHandler';
    # Set some headers so that the error element can have some error
    # messages to display.
    $r->header_in(BRIC_ERR_MSG => $msg . '.');
    $r->header_in(BRIC_ERR_PAY => $err);
    # Send the error to the apache error log.
    $r->log->error("$msg: $err");
    # Return OK so that Mason can handle displaying the error element.
    return OK;
}

################################################################################

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

=head1 REVISION HISTORY

$Log: AccessHandler.pm,v $
Revision 1.2  2001-09-06 22:30:06  samtregar
Fixed remaining BL->App, BC->Biz conversions

Revision 1.1.1.1  2001/09/06 21:52:57  wheeler
Upload to SourceForge.

=cut
