package Bric::Util::Language::zh_hk;

=head1 NAME

Bric::Util::Language::zh_hk - Bricolage 正體中文翻譯

=head1 VERSION

$Revision: 1.2.2.1 $

=cut

use Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$Date: 2004/04/30 00:45:40 $

=head1 SYNOPSIS

In F<bricolage.conf>:

  LANGUAGE = zh_hk

=head1 DESCRIPTION

Bricolage 正體中文翻譯.

=cut

use constant key => 'zh_hk';

our @ISA = qw(Bric::Util::Language);

our %Lexicon = (

);
1;

__END__

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 SEE ALSO

L<Bric::Util::Language|Bric::Util::Language>

=cut


1;
