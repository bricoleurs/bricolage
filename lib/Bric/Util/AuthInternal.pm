package Bric::Util::AuthInternal;

=head1 Name

Bric::Util::AuthInternal - Default, internal Bricolage authentication engine

=head1 Synopsis

In F<bricolage.conf>

  AUTH_ENGINES = Internal

=head1 Description

This module provides an interface for the default method of authentication in
Bricolage. If one of the authentication engines assigned to the
C<AUTH_ENGINES> F<bricolage.conf> directive is "Internal", then this module
will be loaded by the user class and used for authentication and password
changes. See L<Bric::Admin/"Authentication Configuration"|Bric::Admin> for
more in-depth information on authentication engines and configuring Bricolage
to use an LDAP server for atuhentication.

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
use Digest::MD5 qw(md5_hex);

##############################################################################
# Fields
##############################################################################
# Private Class Fields
my $secret = '$8fFidf*34;,a(o};"?i8J<*/#1qE3 $*23kf3K4;-+3f#\'Qz-4feI3rfe}%:e';

##############################################################################
# Public Class Fields
require Bric; our $VERSION = Bric->VERSION;

##############################################################################
# Class Methods.
##############################################################################

=head1 Interface

=head2 Class Methods

=head3 authenticate

  Bric::Util::AuthInternal->authenticate($user, $password);

Pass a user object and a password to this method to authenticate the user with
the password. Returns true if the password validates, and false if it does
not.

=cut

sub authenticate {
    my ($pkg, $user, $pwd) = @_;
    my $cur = $user->_get('password');
    return $pkg unless $cur;
    return md5_hex($secret . md5_hex($pwd)) eq $cur ? $user : undef;
}

##############################################################################

=head3 set_password

  Bric::Util::AuthInternal->set_password($user, $password);

Sets the password for the user object to the given password.

=cut

sub set_password {
    my ($pkg, $user, $pwd) = @_;
    $user->_set( ['password'] => [ md5_hex($secret . md5_hex($pwd)) ] );
}

1;
__END__

##############################################################################

=head1 Author

David Wheeler <david@kineticode.com>

=head1 See Also

=over 4

=item L<Bric::Admin/"Authentication Configuration"|Bric::Admin>

Provides a description of the Bricolage authentication system and details on
how to configure it.

=item L<Bric::Util::AuthLDAP|Bric::Util::AuthLDAP>

Provides LDAP-based authentication for Bricolage.

=item L<Bric::Biz::Person::User|Bric::Biz::Person::User>

The user class calls out to this module to authenticate users and change
passwords.

=item L<Bric::Security|Bric::Security>

Detailed discussion of Bricolage security, including authentication.

=back

=head1 Copyright and License

Copyright (c) 2005 Kineticode, Inc. See L<Bric::License|Bric::License> for
complete license terms and conditions.
