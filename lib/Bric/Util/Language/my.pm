package Bric::Util::Language::my;

=encoding utf8

=head1 NAME

Bric::Util::Language::my - Bricolage Burmese translation

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

In F<bricolage.conf>:

  LANGUAGE = my

=head1 DESCRIPTION

Translation to Burmese using Lang::Maketext.

=cut

use strict;
use utf8;
use base qw(Bric::Util::Language);

use constant key => 'my';

our %Lexicon =
  (
   '_AUTO' => 1,
  );

=begin comment

To translate:

  "All jobs" => "All jobs",
  "Today's jobs" => "Today's jobs",
  "Future jobs" => "Future jobs",
  "Expire jobs" => "Expire jobs",
  "Failed jobs" => "Failed jobs",
  "My jobs" => "My jobs",
  'Field "[_1]" can not be added. There are already [_2] [quant,_2,field] of this type, with a max of [_3].' => 'Field "[_1]" can not be added. There are already [_2] [quant,_2,field] of this type, with a max of [_3].',
  'Element "[_1]" can not be added. There are already [_2] [quant,_2,element] of this type, with a max of [_3].' => 'Element "[_1]" can not be added. There are already [_2] [quant,_2,element] of this type, with a max of [_3].',
  'Field "[_1]" cannot be deleted. There must be at least [_2] [quant,_2,field] of this type.' => 'Field "[_1]" cannot be deleted. There must be at least [_2] [quant,_2,field] of this type.',
  'Element "[_1]" cannot be deleted. There must be at least [_2] [quant,_2,element] of this type.' => 'Element "[_1]" cannot be deleted. There must be at least [_2] [quant,_2,element] of this type.',
  'min_occurrence must be a positive number.' => 'min_occurrence must be a positive number.',
  'max_occurrence must be a positive number.' => 'max_occurrence must be a positive number.',
  'place must be a positive number.' => 'place must be a positive number.',
  'Field "[_1]" appears [_2] times around line [_3].Please remove all but [_4].' => 'Field "[_1]" appears [_2] times around line [_3].Please remove all but [_4].',
  '[_1] cannot be a subelement of [_2].' => '[_1] cannot be a subelement of [_2].',
          'Slug required for non-fixed (non-cover) story type.'

          'Cannot both delete and make primary a single output channel.'
          'Media [_1] saved and shelved.'
          'Media [_1] saved and moved to [_2].'
          'Media [_1] created and saved.'
          'Un-Associate'
          'Associate'
          'Preview in'
          'Parent cannot choose itself or its child as its parent. Try a different parent.'
          'The name [_1] is already used by another ???? in this destinantion'
          '[_1] stories published.'
          '[_1] media published.'
          'Category URI'
          'Story [_1] saved and shelved.'
          'Story [_1] saved and checked in to [_2].'
          'Story [_1] created and saved.'
          'Template [_1] saved and shelved.'
          'Template [_1] saved and moved to [_2].'
          '[_1] deployed.'
 = (
      'Hi [_1]!' => 'Olá [_1]!',
      'The URL you requested, <b>[_1]</b>, was not found on this server' => 'O endereço <b>[_1]</b> não foi encontrado no servidor',
      'You are about to permanently delete items! Do you wish to continue?', => 'Vai apagar elementos definitivamente. Confirma?',
      'Passwords must be at least [_1] characters!' => 'As passwords têm de ter no mínimo [_1] caracteres!',
      'Delete' => 'Apagar',
      'Edit'=>'Editar',
      'Notes'=>'Notas',
      'Priority'=>'Prioridade',
      'High'=>'Elevada',
      'Check In to [_1]'=>'Enviar para [_1]',
      'Name' => 'Nome',
      'Size' => 'Tamanho',
      'Required'=> 'Obrigatório',
      'Create a New Template' => 'Criar um Novo Template',
      'Name' => 'Nome',
      'No categories were found' => 'Não foram encontradas categorias' ,
      'View' => 'Ver',
      'Log' => 'Registo',
      'Checkout' => 'Checar para fora',
      'Title' => 'Titulo',
      'Cover Date' => 'Data da Capa',
      'Invalid username or password. Please try again.' => 'Utilizador ou password errada. Por favor tente de novo.',
      'CONTENT' => 'CONTEÚDO',
      'Fields' => 'Campos',
      'Description' => 'Descrição',
      'Dec'=>'Dez',
      'Feb'=>'Fev',
      'Month'=>'Mês',
      'Day'=>'Dia',
      'Category'=>'Categoria',
      'Find Templates' => 'Procurar Templates',
      'Template' => 'Modelo',
      'Clone' => 'Clone',
      'Cascade into Subcategories' => 'Cascade into Subcategories',
      'No help available for this topic.' => 'No help available for this topic.',
      'Published Version' => 'Published Version',
      'Deployed Version' => 'Deployed Version',
      'Needs to be Published' => 'Needs to be Published',
      'Needs to be Deployed' => 'Needs to be Deployed',
      'Field profile [_1] deleted.' => 'Field profile [_1] deleted.',
      'Field profile [_1] saved.' => 'Field profile [_1] saved.',
      'No file associated with media "[_1]". Skipping.',
      'Writing files to "[_1]" Output Channel.'
      'Distributing files.'
      'No output to preview.'
      'Cannot preview asset "[_1]" because there are no Preview Destinations associated with its output channels.'
      'Element must be associated with at least one site and one output channel.'
      'Include deleted' => 'Include deleted',
      'Reactivate' => 'Reactivate',
      'Subelement' => 'Subelement',
      'All Subelements' => 'All Subelements',
      'Code' => 'Code',
      'Code Select' => 'Code Select',
      'Invalid codeselect code (didn't return an array ref of even size)' => 'Invalid codeselect code (didn't return an array ref of even size)',

  );

=end comment

=cut

1;
__END__

=head1 AUTHOR

Gerfried Fuchs <alfie@users.sourceforge.net>

=head1 SEE ALSO

NONE

=cut

