package Bric::Util::Language::en_us;

# $Id $

=encoding utf8

=head1 NAME

Bric::Util::Language::en_us - Bricolage US English translation

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 SYNOPSIS

In F<bricolage.conf>:

  LANGUAGE = en_us

=head1 DESCRIPTION

Bricolage US English dictionary.

=cut

use strict;
use utf8;
use base qw(Bric::Util::Language);

use constant key => 'en_us';

our %Lexicon = (
  '[quant,$quant,Contributors] [_1] [quant,$quant,disassociated].' => '[quant,$quant,Contributors] [_1] [quant,$quant,disassociated].',
  '[quant,_1,Alert] acknowledged.' => '[quant,_1,Alert,Alerts] acknowledged.',
  '[quant,_1,Contributor] "[_2]" associated.' => '[quant,_1,Contributor,Contributors] "[_2]" assocuated.',
  '[quant,_1,Template] deployed.' => '[quant,_1,Template,Templates] deployed.',
  '[quant,_1,media,media] published.' => '[quant,_1,media,media] published.',
  '[quant,_1,media,media] expired.' => '[quant,_1,media,media] expired.',
  '[quant,_1,story,stories] published.' => '[quant,_1,story,stories] published.',
  '[quant,_1,story,stories] expired.' => '[quant,_1,story,stories] expired.',
  'D (for Deployed)'  => 'D',
  'P (for Published)' => 'P',
  '[quant,_1,Day]' => '[quant,_1,Day,Days,None]',
  'Field "[_1]" cannot be added. There are already [quant,_2,field,fields] of this type, with a max of [_3].' => 'Field “[_1]” cannot be added. There are already [quant,_2,field,fields] of this type, with a max of [_3].',
  'Element "[_1]" cannot be added. There are already [quant,_2,element,elements] of this type, with a max of [_3].' => 'Element “[_1]” cannot be added. There are already [quant,_2,element,elements] of this type, with a max of [_3].',
  'Field "[_1]" cannot be deleted. There must be at least [quant,_2,field,fields] of this type.' => 'Field “[_1]” cannot be deleted. There must be at least [quant,_2,field,fields] of this type.',
  'Element "[_1]" cannot be deleted. There must be at least [quant,_2,element,elements] of this type.' => 'Element “[_1]” cannot be deleted. There must be at least [quant,_2,element,elements] of this type.',
  'Field "[_1]" appears [_2] times around line [_3]. Please remove all but [_4].' => 'Field “[_1]” appears [quant,_2,time,times] around line [_3]. Please remove all but [_4].',
  _AUTO => 1
);

1;
__END__

=head1 AUTHOR

ClE<aacute>udio Valente <cvalente@co.sapo.pt>

=head1 SEE ALSO

L<Bric::Util::Language|Bric::Util::Language>

=cut
