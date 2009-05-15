package Bric::Util::Language::my;

=encoding utf8

=head1 Name

Bric::Util::Language::my - Bricolage Burmese translation

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

In F<bricolage.conf>:

  LANGUAGE = my

=head1 Description

Translation to Burmese using Lang::Maketext.

=cut

use strict;
use utf8;
use base qw(Bric::Util::Language);

use constant key => 'my';

our %Lexicon = (
    '_AUTO' => 1,
);

1;
__END__

=head1 Author

Maybe You? <devel@lists.bricolage.cc>

=head1 See Also

L<Bric::Util::Language|Bric::Util::Language>

L<Bric::Util::Language::en_us|Bric::Util::Language::en_us>

L<Bric::Util::Language::de_de|Bric::Util::Language::de_de>

=cut
