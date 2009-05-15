package Bric::App::AccessHandler;

=head1 Name

Bric::App::AccessHandler - Handles Authentication and Session setup during the Apache Access phase.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

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

=head1 Description

This module handles the Access phase of an Apache request. It authenticates
users to Bricolage, and sets up Session handling.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependencies
use Bric::App::Session;
use Bric::App::Util qw(:redir :history);
use Bric::App::Auth qw(auth logout);
use Bric::Config qw(:err :ssl :cookies :mod_perl);
use Bric::Util::ApacheConst;
use Bric::Util::Cookie;
use Bric::Util::ApacheUtil qw(unescape_url);
use Bric::Util::ApacheReq qw(parse_args);

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
my $port = LISTEN_PORT == 80 ? '' : ':' . LISTEN_PORT;
my $ssl_port = SSL_PORT == 443 ? '' : ':' . SSL_PORT;

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

=item my $status = handler($r)

Sets up the user session and checks authentication. If the authentication is
current, it returns OK and the request continues. Otherwise, it caches
the requested URI in the session and returns HTTP_FORBIDDEN.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handler {
    my $r = shift;
    # Do nothing to subrequests.
    return OK if $r->main;

    my $ret = eval {
        # Silently zap foolish user access to http when SSL is always required
        # by web master.
        if (ALWAYS_USE_SSL && SSL_ENABLE && LISTEN_PORT == $r->get_server_port) {
            $r->custom_response(
                HTTP_FORBIDDEN,
                Bric::Util::ApacheReq->url( ssl => 1, uri => '/logout/' )
            );
            return HTTP_FORBIDDEN;
        }

        my %cookies = Bric::Util::Cookie->fetch($r);
        # Propagate SESSION and AUTH cookies if we switched server ports
        my %qs = parse_args(scalar $r->args);

        # work around multiple servers if login event
        if ( exists $qs{&AUTH_COOKIE} && ! $cookies{&AUTH_COOKIE} ) {
            foreach(&COOKIE, &AUTH_COOKIE) {
                if (exists $qs{$_} && $qs{$_}) {
                    my $cook = unescape_url($qs{$_});
                    $cookies{$_} = $cook;           # insert / overwrite value
                    # propagate this particular cookie back to the browser with
                    # all properties
                    $r->err_headers_out->add('Set-Cookie',$_ . '=' . $cook);
                }
            }
            my $http_cook = '';
            while(my($k,$v) = each %cookies) {
                # Reconstitute the input cookie
                $http_cook .= '; ' if $http_cook;
                $v = (split('; ',$v))[0];
                $http_cook .= $k .'='. $v;
            }
            $r->headers_in->{'Cookie'} = $http_cook;
            # Replacement HTTP_COOKIE string
        }
        # Continue, the session is not the wiser about inserted cookies IN.

        # Set up the user's session data.
        Bric::App::Session::setup_user_session($r);
        my ($res, $msg) = auth($r);
        return OK if $res;

        # If we're here, the user needs to authenticate. Figure out where they
        # wanted to go so we can redirect them there after they've logged in.
        $r->log_reason($msg) if $msg;
#       my $uri = $r->uri;
#       my $args = $r->args;
#       $uri = "$uri?$args" if $args;
#       set_redirect($uri);
        # Commented out the above and set the login to always redirect to "/".
        # This is because the session might otherwise get screwed up. The
        # del_redirect() function in Bric::App::Util depends on this
        # knowledge, so if we ever change this, we'll need to make sure we fix
        # that function, too.
#        set_redirect('/');
        my $hostname = $r->hostname;
        $r->custom_response(
            HTTP_FORBIDDEN,
            Bric::Util::ApacheReq->url( ssl => 1, uri => '/login/' )
        );
        return HTTP_FORBIDDEN;
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
        logout($r);
        # Expire the user's session.
        Bric::App::Session::expire_session($r);

        # Redirect to the login page.
        my $hostname = $r->hostname;
        if (SSL_ENABLE) {
            # if SSL and logging out of server #1, make sure and logout of
            # server #2
            if (ALWAYS_USE_SSL) {
                # Just need to log out.
                $r->custom_response(HTTP_FORBIDDEN, '/login/');
            } elsif (scalar $r->args =~ /goodbye/) {
                # Logged out of both ports.
                $r->custom_response(
                    HTTP_FORBIDDEN,
                    Bric::Util::ApacheReq->url( ssl => 1, uri => '/login/' )
                );
            } else {
                # Need to log out of the other port.
                my $url = Bric::Util::ApacheReq->url(
                    ssl => $r->get_server_port != &SSL_PORT,
                    uri => '/logout?goodbye',
                );
                $r->custom_response( HTTP_MOVED_TEMPORARILY, $url );
                return HTTP_MOVED_TEMPORARILY;
            }
        } else {
            $r->custom_response(HTTP_FORBIDDEN, '/login/');
        }
        return HTTP_FORBIDDEN;
    };
    return $@ ? handle_err($r, $@) : $ret;
}

################################################################################

=item my $status = okay($r)

This handler should B<only> be used for the '/login' location of the SSL
virtual host. It simply sets up the user session and returns OK.

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

    $err = Bric::Util::Fault::Exception::AP->new(
        error => 'Error executing AccessHandler',
        payload => $err,
    );
    $r->pnotes('BRIC_EXCEPTION' => $err);

    # Send the error to the apache error log.
    $r->log->error($err->full_message);

    # Exception::Class::Base provides trace->as_string, but trace_as_text is
    # not guaranteed. Use print STDERR to avoid escaping newlines.
    print STDERR $err->can('trace_as_text')
      ? $err->trace_as_text
      : join ("\n",
              map {sprintf "  [%s:%d]", $_->filename, $_->line }
                $err->trace->frames),
        "\n";

    # Return OK so that Mason can handle displaying the error element.
    return OK;
}

################################################################################

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
