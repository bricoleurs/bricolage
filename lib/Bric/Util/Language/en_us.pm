package Bric::Util::Language::en_us;

=head1 NAME

Bric::Util::Language::pt_pt - Bricolage Portuguese translation

=head1 VERSION

$Revision: 1.2.6.1 $

=cut

our $VERSION = (qw$Revision: 1.2.6.1 $ )[-1];

=head1 DATE

$Date: 2003-06-11 09:46:43 $

=head1 SYNOPSIS

In F<bricolage.conf>:

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
