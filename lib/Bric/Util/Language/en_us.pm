package Bric::Util::Language::en_us;

=head1 NAME

Bric::Util::Language::pt_pt - Bricolage Portuguese translation

=head1 VERSION

$Revision: 1.2 $

=cut

our $VERSION = (qw$Revision: 1.2 $ )[-1];

=head1 DATE

$Date: 2003-02-18 03:38:22 $

=head1 SYNOPSIS

In F<bricoalage.conf>:

  LANGUAGE = pt_pt

=head1 DESCRIPTION

Bricolage US English dictionary.

=cut

use constant key => 'en_us';

our @ISA = qw(Bric::Util::Language);
our %Lexicon = ( _AUTO => 1 );

1;
__END__

=head1 AUTHOR

ClE<aacute>udio Valente <cvalente@co.sapo.pt>

=head1 SEE ALSO

L<Bric::Util::Language|Bric::Util::Language>

=cut
