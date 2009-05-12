package Bric::Util::Cookie;

=head1 Name

Bric::Util::Cookie - Wrapper around Apache::Cookie, Apache2::Cookie, and CGI::Cookie

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Cookie;
  my $cookie = Bric::Util::Cookie->new($r);
  $cookie->bake;

=head1 Description

This package subclasses the C<Apache::Cookie>, C<Apache2::Cookie>, or
C<CGI::Cookie> class so that Bricolage doesn't have to care about which
version of Apache is running, or whether it is running at all.

=cut

use strict;
use Bric::Config qw(:mod_perl);
BEGIN {
    if (MOD_PERL) {
        if (MOD_PERL_VERSION < 2) {
            require Apache::Cookie;  Apache::Cookie->import();
            @Bric::Util::Cookie::ISA = 'Apache::Cookie';
        }
        else {
            require Apache2::Cookie;  Apache2::Cookie->import();
            @Bric::Util::Cookie::ISA = 'Apache2::Cookie';
        }
    }
    else {
        require CGI::Cookie;  CGI::Cookie->import();
        @Bric::Util::Cookie::ISA = 'CGI::Cookie';
    }
}

=head1 Interface

=head2 Constructor

=over 4

=item my $cookie = Bric::Util::Cookie->new($r, ...);

Returns a new C<Bric::Util::Cookie> object, which is actually either
an C<Apache::Cookie> object for mod_perl 1 or an C<Apache2::Cookie> object
for mod_perl 2.

In C<Apache::Cookie> or C<Apache2::Cookie> this method requires
the C<$r> object to be passed in, so you should always pass the C<$r> object
for compatibility.

=cut

sub new {
    my $pkg = shift;
    shift unless MOD_PERL;   # remove $r for CGI::Cookie
    my $super = $pkg->SUPER::new(@_);
    return bless($super, $pkg);
}

=back

=head2 Class methods

=over 4

=item my %cookies = Bric::Util::Cookie->fetch($r);

Returns a cookies hash. In C<Apache2::Cookie> this method requires
the C<$r> object to be passed in, so you should always pass the C<$r> object
for compatibility.

=cut

sub fetch {
    my $pkg = shift;
    shift unless MOD_PERL_VERSION >= 2;   # only pass $r for Apache2::Cookie
    return $pkg->SUPER::fetch(@_);
}

=back

=head2 Instance methods

Methods not documented here, like C<value>, are inherited from the base class.

=over 4

=item $cookie->bake($r);

In C<Apache2::Cookie> this method requires the C<$r> object to be passed in,
so you should always pass the C<$r> object for compatibility.

=cut

sub bake {
    my $self = shift;
    shift unless MOD_PERL_VERSION >= 2;   # only pass $r for Apache2::Cookie
    return $self->SUPER::bake(@_);
}

=back

=head1 Author

Scott Lanning <slanning@cpan.org>

=cut

1;
