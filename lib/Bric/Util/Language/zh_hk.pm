package Bric::Util::Language::zh_hk;

=head1 NAME

Bric::Util::Language::zh_hk - Bricolage 正體中文翻譯

=head1 VERSION

$LastChangedRevision$

=cut

INIT {
    require Bric; our $VERSION = Bric->VERSION
}

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

In F<bricolage.conf>:

  LANGUAGE = zh_hk

=head1 DESCRIPTION

Bricolage 正體中文翻譯.

=cut

use constant key => 'zh_hk';

our @ISA = qw(Bric::Util::Language::zh_tw);

our %Lexicon = (

);

1;
__END__

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 SEE ALSO

L<Bric::Util::Language|Bric::Util::Language>

L<Bric::Util::Language::zh_tw|Bric::Util::Language::zh_tw>

=cut


1;
