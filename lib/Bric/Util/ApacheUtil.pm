package Bric::Util::ApacheUtil;

=head1 Name

Bric::Util::ApacheUtil - Wrapper around Apache::Util and Apache2::Util classes

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::ApacheUtil qw(escape_html escape_uri unescape_url);

=head1 Description

This package encapsulates the L<Apache::Util|Apache::Util> and
L<Apache2::Util|Apache2::Util> classes so that Bricolage doesn't have to care
about which version of Apache is running.

=cut

use strict;

use URI::Escape ();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(unescape_url escape_uri);

use Bric::Config qw(:mod_perl);
BEGIN {
    if (MOD_PERL) {
        if (MOD_PERL_VERSION < 2) {
            require Apache;          Apache->import();
            require Apache::Util;    Apache::Util->import();
        } else {
            require Apache2::Util;   Apache2::Util->import();
            require Apache2::URI;    Apache2::URI->import();
        }
    }
}

=head1 Interface

=head2 Functions

=over 4

=item my $str = Bric::Util::ApacheUtil::unescape_url($url);

C<Apache::unescape_url> or C<Apache2::URI::unescape_url>.

=cut

sub unescape_url {
    return MOD_PERL_VERSION < 2
      ? Apache::unescape_url(@_)
      : Apache2::URI::unescape_url(@_);
}

=item my $str = Bric::Util::ApacheUtil::escape_uri($uri, $r->pool);

Replaces C<Apache::Util::escape_uri>, C<Apache2::Util::escape_path>,
or C<URI::Escape::uri_escape>.

=cut

sub escape_uri {
    # note: uri_escape takes a 2nd arg, which differs from escape_path,
    # so don't just alias this
    return URI::Escape::uri_escape($_[0]);
}

=back

=head1 Author

Scott Lanning <slanning@cpan.org>

=cut

1;
