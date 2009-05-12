package Bric::Util::AuthLDAP;

=head1 Name

Bric::Util::AuthLDAP - Bricolage LDAP authentication

=head1 Synopsis

In F<bricolage.conf>

  AUTH_ENGINES = LDAP

=head1 Description

This module provides an interface for the Bricolage to authenticate users
against an LDAP server. If one of the authentication engines assigned to the
C<AUTH_ENGINES> F<bricolage.conf> directive is "LDAP", then this module will
be loaded by the user class and used for authentication. See the Bric::Admin
L<Bric::Admin/"Authentication Configuration"|Authentication Configuration>
section for more in-depth information on authentication engines, as well as
its L<Bric::Admin/"LDAP Configuration"|LDAP Configuration> section for the
specifics on configuring Bricolage to authenticate against your LDAP server.

This module is used internally by
L<Bric::Biz::Person::User|Bric::Biz::Person::User>; it should not be used
directly.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependencies
use Bric::Config qw(:ldap);
use Bric::Util::Fault qw(throw_auth);
use Net::LDAP qw(LDAP_INVALID_CREDENTIALS LDAP_SUCCESS);
use Net::LDAP::Util qw(ldap_error_desc);
use Net::LDAP::Filter;

##############################################################################
# Public Class Fields
require Bric; our $VERSION = Bric->VERSION;

##############################################################################
# Class Methods.
##############################################################################

=head1 Interface

=head2 Class Methods

=head3 authenticate

  Bric::Util::AuthLDAP->authenticate($user, $password);

Pass a user object and a password to this method to authenticate the user to
an LDAP server with the password. Returns true if the password validates, and
false if it does not.

Note that a user may successfully authenticate to the LDAP server but still
not successfully authenticate to Bricolage if you've set the L<LDAP_GROUP>
directive to the DN of a user grop on your LDAP server. In such a case, the
user must also be a member of that group to use Bricolage. This provides a
simple allow and disallow users to access Bricolage from within LDAP. Users
must still exist within Bricolage with the same username, however. A user that
can successfully authenticate to the LDAP server will not be able to
authenticate in Bricolage until a the corresponding Bricolage user object has
been created.

=cut

sub authenticate {
    my ($pkg, $user, $pwd) = @_;

    # Connect to the LDAP server.
    my $ldap = Net::LDAP->new(
        LDAP_SERVER,
        version => LDAP_VERSION,
        onerror => sub {
            my $mesg = shift;
            # Invalid credentials are okay.
            return $mesg if $mesg->code == LDAP_INVALID_CREDENTIALS;
            throw_auth "LDAP Error: " . ldap_error_desc($mesg);
        }
    ) or throw_auth error => "Unable to connect to LDAP Server", payload => $@;

    # Use encryption.
    $ldap->start_tls if LDAP_TLS;

    # Bind to the server. Use the uesrname and password if we got them, and
    # bind anonymously if we don't.
    my $mesg = $ldap->bind(
        LDAP_USER ? (LDAP_USER, password => LDAP_PASS) : ()
    );

    throw_auth error   => "Unable to bind to the LDAP server",
               payload => ldap_error_desc($mesg)
      unless $mesg->code == LDAP_SUCCESS;

    # Create a filter to search for the user object.
    my $filter = Net::LDAP::Filter->new(
        sprintf "(&(%s=%s)%s)",
        LDAP_UID_ATTR, $user->get_login, LDAP_FILTER
    );

    # Search for the user object.
    $mesg = $ldap->search(
        base   => LDAP_BASE,
        filter => $filter,
        attrs  => ['dn'],
    );

    # Bail if we didn't find the user.
    return unless $mesg->count;

    # Re-bind as the user. This is the authetication. Just return if it fails.
    my $entry = $mesg->first_entry;
    $mesg = $ldap->bind($entry->dn, password => $pwd);
    return unless $mesg->code == LDAP_SUCCESS;

    # If we get here, we've successfully authenticated. Just return true
    # unless we need to make sure that the user is in a particular group.
    return $pkg unless LDAP_GROUP;

    # Create a filter to search for the group.
    $filter = Net::LDAP::Filter->new(
        sprintf "(%s=%s)", LDAP_MEMBER_ATTR, $entry->dn
    );

    $mesg = $ldap->search(
        base   => LDAP_GROUP,
        filter => $filter,
        attrs  => ['dn'],
        scope  => 'base',
    );

    # Just bail if we didn't find a group.
    return $mesg->count;

    # Otherwise, success!
    return $pkg;
}

##############################################################################

=head3 set_password

  Bric::Util::AuthLDAP->set_password($user, $password);

This method is a no-op; it simply returns the invocant. It is not currently
possible to change LDAP passwords from Bricolage. This functionality may
be added in the future.

=cut

# XXX No-op. We cannot change passwords because the user changing the password
# has to be authenticated. If a user is changing her own password, we can do
# it by authenticating the old password and then changing to the new one. But
# if a user is changing someone else's password, there is currently no way
# to authenticate the user doing the changing, as her password is not stored
# anywhere. We could change this, but then we have the security implications of
# storing the plain-text password somewhere (such as in a session). So we just
# punt on the issue for now.

sub set_password { shift }

1;
__END__

##############################################################################

=head1 Author

David Wheeler <david@kineticode.com>

=head1 See Also

=over 4

=item Bric::Admin: L<Bric::Admin/"Authentication Configuration"|Authentication Configuration>

Provides a description of the Bricolage authentication system and details on
how to configure it.

=item Bric::Admin: L<Bric::Admin/"LDAP Configuration"|LDAP Configuration>

LDAP authentication configuration information.

=item L<Bric::Util::AuthInternal|Bric::Util::AuthInternal>

Provides Bricolage's default, internal authentication interface.

=item L<Bric::Biz::Person::User|Bric::Biz::Person::User>

The user class calls out to this module to authenticate users and change
passwords.

=item L<Bric::Security|Bric::Security>

Detailed discussion of Bricolage security, including authentication.

=back

=head1 Copyright and License

Copyright (c) 2005 Kineticode, Inc. See L<Bric::License|Bric::License> for
complete license terms and conditions.
