package Bric::Util::Language::en_us;

=head1 NAME

Bric::Util::Language::pt_pt - Bricolage Portuguese translation

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
