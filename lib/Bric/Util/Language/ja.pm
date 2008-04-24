package Bric::Util::Language::ja;

=encoding utf8

=head1 NAME

Bric::Util::Language::ja - Bricolage Japanese translation

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2006-01-23 15:34:28 -0800 (Mon, 23 Jan 2006) $

=head1 SYNOPSIS

  use base qw( Bric );

=head1 DESCRIPTION

Translation to Japanese using Lang::Maketext.

=cut

use strict;
use utf8;
use base qw(Bric::Util::Language);

use constant key => 'ja';

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
