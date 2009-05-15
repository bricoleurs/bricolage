package Bric::Util::Language::lo;

=encoding utf8

=head1 Name

Bric::Util::Language::lo - Bricolage Lao translation

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

In F<bricolage.conf>:

  LANGUAGE = lo

=head1 Description

Translation to Lao using Lang::Maketext.

=cut

use strict;
use utf8;
use base qw(Bric::Util::Language);

use constant key => 'lo';

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

