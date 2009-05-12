package Bric::App::Auth;

=head1 Name

Bric::App::Auth - Does the dirty work of authentication.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  <Perl>
  use lib '/usr/local/bricolage/lib';
  </Perl>
  <VirtualHost _default_:443>
      ErrorLog /usr/local/apache/logs/error_log
      TransferLog /usr/local/apache/logs/access_log
      SSLEngine on
      SSLCipherSuite ALL:!ADH:!EXP56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
      SSLCertificateFile /usr/local/apache/conf/ssl.crt/server.crt
      SSLCertificateKeyFile /usr/local/apache/conf/ssl.key/server.key
      <Location /login>
          SetHandler perl-script
          PerlHandler Bric::App::Auth
      </Location>
  </VirtualHost>

=head1 Description

This module handles the user authentication.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:auth :cookies :mod_perl);
use Bric::Util::ApacheConst;
use Bric::App::Session qw(:user);
use Bric::App::Cache;
use Bric::App::Util qw(:redir);
use Bric::Biz::Person::User;
use Bric::Util::Cookie;
use Digest::MD5 qw(md5_hex);
use URI::Escape;
use base qw( Exporter );

our @EXPORT_OK = qw(auth login logout);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

################################################################################
# Inheritance
################################################################################

################################################################################
# Function and Closure Prototypes
################################################################################
my ($make_cookie, $make_hash, $fail);

################################################################################
# Constants
################################################################################
use constant LOGIN_MARKER_REGEX => qr/${ \LOGIN_MARKER() }/;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $ap = 'Bric::Util::Fault::Exception::AP';
my ($c);

################################################################################

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

=item my ($res, $msg) = auth($r)

Checks to see if the user is logged in to the current session. Used by
Bric::App::AccessHandler.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub auth {
    my $r = shift;
    return &$fail($r) unless my %cookies = Bric::Util::Cookie->fetch($r);
    return &$fail($r) unless my $cookie = $cookies{&AUTH_COOKIE};
    my %val = $cookie->value;
     return &$fail($r) unless $val{exp} > time;
    return &$fail($r, 'Malformed cookie.')
      unless $val{ip} && $val{hash} && $val{user} && $val{exp} && $val{lmu};

    # Get the hash for this cookie.
    my ($hash, $exp, $ip, $lul) = &$make_hash($r, @val{qw(user exp ip lmu)});

    if ( $hash ne $val{hash}) {
        # Oh-oh, someone's been monkeying with the cookie (or maybe the secret
        # changed?).
        my $c = $r->connection;
        $ip = $c->remote_ip;
        my $host = $c->remote_host;
        return &$fail($r, "Cookie hash mismatch from $ip (Hostname '$host') "
                      . "for user '$val{user}.'");
    }
    $c ||= Bric::App::Cache->new;
    my $u = get_user_object();
    if ( !$u || ($c->get_lmu_time || 0) > $lul) {
        # There have been changes to the users. Reload this user from the
        # database.
        (my $look = $val{user}) =~ s/([_%\\])/\\$1/g;
        return &$fail($r, 'User does not exist or is disabled.') unless
          $u = Bric::Biz::Person::User->lookup({ login => $look });

        # Set up the user and expire the user sites from the session.
        set_user($r, $u);
        # XXX Wish there were a better place to do this...
        Bric::App::Session::set_state_data('site_context', 'sites' => 0);
        $lul = time;
    }
    $make_cookie->($r, $val{user}, $lul);
}

################################################################################

=item my ($bool, $msg) = login($r, $username, $password)

Logs the user into Bricolage, setting the authentication cookie to allow future
access that can be checked by a call to auth(). $bool is true on successful
login. $bool is undef on failed login, and $msg contains the reason why the
login failed.

B<Throws:> None.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub login {
    my ($r, $un, $pw) = @_;
    (my $look = $un) =~ s/([_%\\])/\\$1/g;
    my $u = Bric::Biz::Person::User->lookup({ login => $look });

    # Return failure if authentication fails.
    return (0, 'Invalid username or password. Please try again.')
      unless $u && $u->chk_password($pw);

    # Authentication succeeded. Set up session data and the authentication
    # cookie.
    set_user($r, $u);
    my $cookie = $make_cookie->($r, $un, time);
    # Work around to redirect cookies to second server
    my $args = $r->args;
    return $cookie if defined $args and $args =~ LOGIN_MARKER_REGEX;
    # The presumption is made that any redirect passed to login will properly
    # terminate a trailing directory with '/', otherwise all bets are off!
    my $redirect = del_redirect() || '/'; # root if no redirect
    $redirect .= ($redirect =~ /\?/) ? '&' : '?';
    #       : ($redirect =~ m|/$|) ? '?' : '/?';
    set_redirect($redirect . LOGIN_MARKER . '=' . LOGIN_MARKER);
    return $cookie;
}

################################################################################

=item masquerade($r, $user)

Sets up a different user for the current user to masquerade as. This is useful
when an administrator needs a to masquerade as another user in order to check
in assets that user hasn't checked in. Note that C<masquerade()> performs no
authentication. It is expected that the current user will have permission to
masquerade as the user passed in.

B<Throws:> None.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub masquerade {
    my ($r, $u) = @_;
    # Set up session data and the authentication cookie.
    set_user($r, $u);
    $make_cookie->($r, $u, time);
}

################################################################################

=item my $bool = logout($r)

Logs the currently logged-in user out.

B<Throws:> None.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub logout {
    my $r = shift;
    my $cookie = Bric::Util::Cookie->new($r,
      -name    => AUTH_COOKIE,
      -expires => "-1d",
      -path    => '/',
      -value   => "logout");
    $cookie->bake($r);
    return 1;
}

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $cookie = $make_cookie->($r, $username)

=item my $cookie = $make_cookie->($r, $username, $lul_time)

Bakes the authentication cookie.

B<Throws:> None.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$make_cookie = sub {
    my ($r, $un, $lul) = @_;
    my ($hash, $exp, $ip) = &$make_hash($r, $un, undef, undef, $lul);
    my @args = ( -name    => AUTH_COOKIE,
                 -expires => "+" . AUTH_TTL . "S",
                 -path    => '/',
                 -value   => { ip => $ip,
                               user => $un,
                               hash => $hash,
                               exp => $exp,
                               lmu => $lul
                             }
               );

    my $cookie = Bric::Util::Cookie->new($r, @args);
    $cookie->bake($r) if MOD_PERL; # CGI::Cookie hasn't always had bake().
    return $cookie;
};

=item my ($hash, $exp, $ip) = &$make_hash($r, $un)

=item my ($hash, $exp, $ip) = &$make_hash($r, $un, $exp, $ip, $lul)

Returns the data points required for baking cookies. These include the MD5 hash,
the expiration time, and the IP subnet.

B<Throws:> None.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$make_hash = sub {
    my ($r, $un, $exp, $ip, $lul) = @_;
    my $time = time;
    $lul ||= $time;
    $exp ||= $time + AUTH_TTL;
    unless ($ip) {
        $ip = $r->connection->remote_ip;
        $ip = substr($ip, 0, rindex($ip, '.'));
    }

    # work around Perl bug where utf-8 strings result in different md5
    # hashes.
    $exp = "$exp";
    $ip  = "$ip";
    $lul = "$lul";
    $un  = "$un";

    my $hash = md5_hex(AUTH_SECRET .
                       md5_hex(join ':', AUTH_SECRET, $ip, $exp, $un, $lul));
    return ($hash, $exp, $ip, $lul);
};

=item my ($ret, $msg) = &$fail($r, $msg)

Expires the user session and then returns an error message explaining why the
user wasn't able to authenticate.

B<Throws:>

=over 4

=item *

Unable to expire user session.

=item *

Difficulties tie'ing the session hash.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$fail = sub {
    my ($r, $msg) = @_;
    # Expire the existing session.
    Bric::App::Session::expire_session($r);
    # Now create a new session.
    Bric::App::Session::setup_user_session($r, 1);
    # Return the failure message.
    return (0, $msg);
};

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
