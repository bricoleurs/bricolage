package Bric::Util::Language::zh_hk;

=encoding utf8

=head1 NAME

Bric::Util::Language::zh_hk - Bricolage 正體中文翻譯

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

In F<bricolage.conf>:

  LANGUAGE = zh_hk

=head1 DESCRIPTION

Bricolage 正體中文翻譯.

=cut

use strict;
use utf8;
use base qw(Bric::Util::Language:zh_tw);

use constant key => 'zh_hk';

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
