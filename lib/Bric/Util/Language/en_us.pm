package Bric::Util::Language::en_us;

=head1 NAME

Bric::Util::Language::pt_pt - Bricolage Portuguese translation

=head1 VERSION

$Revision: 1.4 $

=cut

our $VERSION = (qw$Revision: 1.4 $ )[-1];

=head1 DATE

$Date: 2004/01/07 15:23:33 $

=head1 SYNOPSIS

In F<bricolage.conf>:

  LANGUAGE = en_us

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
