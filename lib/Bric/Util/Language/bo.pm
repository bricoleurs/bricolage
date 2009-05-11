package Bric::Util::Language::bo;

=encoding utf8

=head1 NAME

Bric::Util::Language::bo - Bricolage Tibetan translation

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 SYNOPSIS

In F<bricolage.conf>:

  LANGUAGE = bo

=head1 DESCRIPTION

Translation to Tibetan using Lang::Maketext.

=cut

use strict;
use utf8;
use base qw(Bric::Util::Language);

use constant key => 'bo';

our %Lexicon = (
    '_AUTO' => 1,
);

1;
__END__

=head1 AUTHOR

Maybe You? <devel@lists.bricolage.cc>

=head1 SEE ALSO

L<Bric::Util::Language|Bric::Util::Language>

L<Bric::Util::Language::en_us|Bric::Util::Language::en_us>

L<Bric::Util::Language::de_de|Bric::Util::Language::de_de>

=cut

