package Bric::Util::Language::en_us;

=encoding utf8

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
our %Lexicon = (
  '[quant,$quant,Contributors] [_1] [quant,$quant,disassociated].' => '[quant,$quant,Contributors] [_1] [quant,$quant,disassociated].',
  '[quant,_1,Alert] acknowledged.' => '[quant,_1,Alert,Alerts] acknowledged.',
  '[quant,_1,Contributor] "[_2]" associated.' => '[quant,_1,Contributor,Contributors] "[_2]" assocuated.',
  '[quant,_1,Template] deployed.' => '[quant,_1,Template,Templates] deployed.',
  '[quant,_1,media,media] published.' => '[quant,_1,media,media] published',
  '[quant,_1,story,stories] published.' => '[quant,_1,story,stories] published',
 _AUTO => 1
);

1;
__END__

=head1 AUTHOR

ClE<aacute>udio Valente <cvalente@co.sapo.pt>

=head1 SEE ALSO

L<Bric::Util::Language|Bric::Util::Language>

=cut
