package Bric::Util::Language::pt_pt;


=head1 NAME

Bric::Util::Language::pt_pt - Bricolage Portuguese translation

=head1 VERSION

Release Version: 1.5.1 -- Development Track for 1.6.0

File (CVS) Version:

$Revision: 1.11 $

=cut

our $VERSION = "1.5.1";

=head1 DATE

$Date: 2003-03-15 05:16:21 $

=head1 SYNOPSIS

  use base qw( Bric );

=head1 DESCRIPTION

Translation to Portuguese using Lang::Maketext.

=cut

@ISA = qw(Bric::Util::Language);

use constant key => 'pt_pt';

%Lexicon =
  (

# Date
   'Jan' => 'Jan',
   'Feb' => 'Fev',
   'Mar' => 'Mar',
   'Apr' => 'Abr',
   'May' => 'Mai',
   'Jun' => 'Jun',
   'Jul' => 'Jul',
   'Aug' => 'Ago',
   'Sep' => 'Set',
   'Oct' => 'Out',
   'Nov' => 'Nov',
   'Dec' => 'Dez',
   'Day' => 'Dia',
   'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec' =>
   'Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez',
   'Month' => 'Mês',

# Time
   'Date'=>'Data',
   'Hour'=> 'Hora',
   'Minute'=>'Minuto',
   'Second'=>'Segundo',

# Priotity
   'High'=> 'Alta',
   'Low'     => 'Baixa',
   'Medium High' => 'Média Alta',
   'Medium Low' => 'Média Baixa',
   'Normal'  => 'Normal',

# Areas
   'Alert Type Manager' => 'Gestão de Tipos de Alerta',
   'Category Manager' => 'Gestão de Categorias',
   'Contributor Type Manager ' => 'Gestão de Tipos de Colaborador',
   'Contributor Type Manager' => 'Gestão de Tipos de Utilizador',
   'Current Output Channels' => 'Canais de Distribuição Correntes',
   'Destination Manager' => 'Gestão de Destinos',
   'Element Manager' => 'Gestão de Elementos',
   'Element Type Manager' => 'Gestão de Tipos de Elementos',
   'Group Manager' => 'gestão de Grupos',
   'Job Manager' => 'Gestão de Tarefas',
   'Manager' => 'Gestão',
   'Media Gallery' => 'Galeria de Media',
   'Media Type Manager' => 'Gestão de Tipos de Media',
   'Preference Manager ' => 'Gestão de Preferências',
   'Source Manager '           => 'Gestão de Fontes',
   'Source Manager' => 'Gestão de Fontes',
   'User Manager' => 'Gestão de Utilizadores',
   'Workflow Manager '         => 'Gestão de Workflows',
   'Workflow Manager' => 'Getsão de Workflows',
   'Workspace For Bricolage Administrator' => 'Área de trabalho do Gestor Bricolage',

# Interface Objects
   'Checkbox'  => 'Checkbox',
   'Columns' => 'Colunas',
   'Custom Fields' => 'Campos Personalizados',
   'Page' => 'Página',
   'Pulldown'  => 'Selecção',
   'Radio Buttons' => 'Botões tipo Rádio',
   'Rows' => 'Linhas',
   'Size' => 'Tamanho',
   'Template' => 'Modelo',
   'Text Area' => 'Área de Texto',
   'Workflows' => 'Workflows',
   '[_1] Field Text' => '[_1] Campo de Texto',

# General Information
   '&quot;Story&quot;' => '&quot;Artigo&quot;',
   '&quot;Template&quot;' => '&quot;Modelo&quot;',
   'ADMIN' => 'GESTÃO',
   'ADVANCED SEARCH' => 'PESQUISA AVANÇADA',
   'Actions' => 'Acções',
   'Active' => 'Activo',
   'Admin' => 'Administração',
   'Advanced Search' => 'Pesquisa Avançada',
   'Alert Types' => 'Tipos de Alerta',
   'All Contributors' => 'Todos os Colaboradores',
   'All Elements' => 'Todos os Elementos',
   'All Groups' => 'Todos os Grupos',
   'All' => 'Tudo',
   'Asset Type' => 'Tipo de Material',
   'Available Groups' => 'Grupos Disponíveis',
   'Available Output Channels' => 'Canais de Distribuição Disponíveis',
   'By Last' => 'Por Apelido',
   'CONTACTS' => 'CONTACTOS',
   'Caption' => 'Designação',
   'Categories' => 'Categorias',
   'Category Assets' => 'Materiais da Categoria',
   'Category tree' => 'Árvore de Categorias',
   'Category' => 'Categoria',
   'Characters' => 'Caracteres',
   'Contacts' => 'Contactos',
   'Content Type' => 'Tipo de Conteúdo',
   'Content' => 'Conteúdo',
   'Contributor Roles' => 'Papéis do Colaborador',
   'Contributor Types' => 'Tipos de Colaborador',
   'Contributors' => 'Colaboradores',
   'Copy' => 'Copiar',
   'Cover Date' => 'Data da Página de Destaques',
   'Current Groups' => 'Grupos Actuais',
   'Current Note' => 'Anotação actual',
   'Current Version' => 'Versão Actual',
   'Currently Related Story' => 'Relações Actuais',
   'DISTRIBUTION' => 'DISTRIBUIÇÃO',
   'Data Elements' => 'Elementos de Dados',
   'Default Value' => 'Valor por defeito',
   'Deployed Date' => 'Data de Entrega',
   'Description' => 'Descrição',
   'Desk Permissions' => 'Permissões para as Áreas',
   'Desks' => 'Áreas',
   'Destinations' => 'Destinos',
   'Download' => 'Download',
   'Element Profile' => 'Perfil de Elemento',
   'Element Types' => 'Tipos de Elementos',
   'Element' => 'Elemento',
   'Elements' => 'Elementos',
   'Error' => 'Erro',
   'Event Type' => 'Tipo de evento',
   'Events' => 'Eventos',
   'Existing Notes' => 'Anotações Existentes',
   'Existing Subelements' => 'Subelementos Existentes',
   'Existing roles' => 'Funções Existentes',
   'Expiration' => 'Expiração',
   'Expire Date' => 'Data de Fim',
   'Extension' => 'Extensão',
   'Extensions' => 'Extensões',
   'Fields' => 'Campos',
   'File Name' => 'Nome do Ficheiro',
   'File Path' => 'Caminho para o Ficheiro',
   'First Name' => 'Nome',
   'First' => 'Nome',
   'Fixed' => 'URL Fixo',
   'Generic' => 'Genérico',
   'Group Type' => 'Tipo de Grupo',
   'Groups' => 'Grupos',
   'ID' => 'ID',
   'Information' => 'Informação',
   'Jobs' => 'Tarefas',
   'Label' => 'Rótulo',
   'Last Name' => 'Apelido',
   'Last' => 'Apelido',
   'Legal'=>'Legal',
   'Log' => 'Registos',
   'Login ' => 'Nome de utilizador',
   'Login and Password' => 'Login e Password',
   'Maximum size' => 'Tamanho máximo',
   'Media Profile' => 'Perfil de Media',
   'Media Type' => 'Tipo de Media',
   'Media Types' => 'Tipos de Media',
   'Member Type  ' => 'Tipo de Membro',
   'Members' => 'Membros',
   'My Alerts' => 'Alertas pessoais',
   'My Workspace' => 'Área de Trabalho pessoal',
   'NAME' => 'NOME',
   'Name' => 'Nome',
   'Never' => 'Nunca',
   'New Role Name' => 'Nome da Nova Função',
   'New password' => 'Nova password',
   'New' => 'Novo',
   'No' => 'Não',
   'Normal'=>'Normal',
   'Note saved.' => 'Anotação guardada.',
   'Note' => 'Anotação',
   'Notes' => 'Notas',
   'Old password' => 'Password antiga',
   'Option, Label' => 'Opção, Etiqueta',
   'Options, Label' => 'Opções, Rótulo',
   'Order' => 'Ordenação',
   'Organization' => 'Organização',
   'Output Channel' => 'Canal de Distribuição',
   'Output Channels' => 'Canais de Distribuição ',
   'Owner' => 'Proprietário',
   'PREFERENCES' => 'PREFERÊNCIAS',
   'PROPERTIES' => 'PROPRIEDADES',
   'PUBLISHING' => 'PUBLICAÇÃO',
   'Password' => 'Palavra-chave',
   'Pending ' => 'Pendentes',
   'Position' => 'Posição',
   'Post' => 'Pós',
   'Pre' => 'Pré',
   'Preferences' => 'Preferências',
   'Prefix' => 'Título',
   'Previews' => 'Previsualiza',
   'Primary Category' => 'Categoria Principal',
   'Primary Output Channel' => 'Canal de Distribuição Primário',
   'Priority' => 'Prioridade',
   'Profile' => 'Perfil',
   'Properties' => 'Propriedades',
   'Publish Date' => 'Data de Publicação',
   'Publish Desk' => 'Área de Publicação',
   'Publishes' => 'Publica',
   'Recipients' => 'Destinatários',
   'Related Media' => 'Media Relacionado',
   'Related Story' => 'Artigo Relacionado',
   'Repeatable' => 'Repetível',
   'Required' => 'Obrigatório',
   'Resources' => 'Recursos',
   'Role' => 'Função',
   'Roles' => 'Papéis',
   'STORIES' => 'ARTIGOS',
   'SYSTEM' => 'SISTEMA',
   'Separator String' => 'Separador',
   'Simple Search' => 'Pesquisa Simples',
   'Slug' => 'Identificador',
   'Source name' => 'Nome da fonte',
   'Source' => 'Fonte',
   'Sources' => 'Fontes',
   'Start Desk' => 'Área Inicial',
   'Statistics' => 'Estatísticas',
   'Story Type' => 'Tipo de Artigo',
   'Subelements' => 'Subelementos',
   'Teaser' => 'Teaser',
   'Template Name' => 'Nome do Template',
   'Text box' => 'Caixa de texto',
   'Title' => 'Título',
   'Trail' => 'Trilha',
   'Type' => 'Tipo',
   'URI' => 'URI',
   'URL' => 'URL',
   'Username' => 'Nome de Utilizador',
   'Users' => 'Utilizadores',
   'Value Name' => 'Preferência',
   'Version' => 'Versão',
   'Words' => 'Palavras',
   'Workflow Permissions' => 'Permissões para Workflows',
   'Year' => 'Ano',
   'Yes' => 'Sim',
   '_AUTO' => 1,
   'all' => 'todos',
   'one per line' => 'uma por linha',
   'to' => 'para',

# Action Commands
   'Add New Field' => 'Criar Novo Campo',
   'Add a New Alert Type' => 'Criar Novo Tipo de Alerta',
   'Add a New Category' => 'Criar Nova Categoria',
   'Add a New Contributor Type' => 'Criar Novo Tipo de Colaborador',
   'Add a New Desk' => 'Criar Nova Área',
   'Add a New Destination' => 'Criar Novo Destino',
   'Add a New Element Type' => 'Criar Novo Tipo de Elemento',
   'Add a New Element' => 'Criar Novo Elemento',
   'Add a New Group' => 'Criar Novo Grupo',
   'Add a New Media Type' => 'Criar Novo Tipo de Media',
   'Add a New Output Channel' => 'Criar Novo Canal de Distribuição',
   'Add a New Source' => 'Criar Nova Fonte',
   'Add a New Workflow' => 'Criar Novo Workflow',
   'Add to Element' => 'Adicionar ao Elemento',
   'Add to Include' => 'Adicionar para Incluir',
   'Add' => 'Adicionar',
   'Allow multiple' => 'Permitir múltiplos',
   'Check In Assets' => 'Disponibilizar Materiais',
   'Check In to Edit' => 'Disponibilizar para Edição',
   'Check In to Publish' => 'Disponibilizar para Publicar',
   'Check In to' => 'Tornar disponível para',
   'Check In' => 'Disponibilizar',
   'Check Out' => 'Reservar',
   'Choose Contributors' => 'Escolher Colaboradores',
   'Choose Related Media' => 'Escolher Media Relacionados',
   'Choose Subelements' => 'Escolher subelementos',
   'Create a New Category' => 'Criar Nova Categoria',
   'Create a New Media' => 'Criar Novo Medium',
   'Create a New Story' => 'Criar Novo Artigo',
   'Create a New Template' => 'Criar Novo Template',
   'Delete this Desk from all Workflows' =>
     'Apagar esta Área de todos os Workflows',
   'Delete this Element' => 'apagar este Elemento',
   'Delete this Profile' => 'Apagar este Perfil',
   'Delete' => 'Apagar',
   'Deploy' => 'Entregar',
   'Download' => 'Receber',
   'Edit' => 'Editar',
   'Expire' => 'Expirar',
   'Find Media' => 'Encontrar Media',
   'Find Stories' => 'Encontrar Artigos',
   'Find Templates' => 'Encontrar Modelos',
   'Manage' => 'Gerir',
   'Move Assets' => 'Mover Materiais',
   'Move to' => 'Mover para',
   'New Media ' => 'Novo Media ',
   'New Media' => 'Novo Media',
   'New Story' => 'Novo Artigo',
   'New Template' => 'Novo Template',
   'Publish' => 'Publicar',
   'Relate' => 'Relacionar',
   'Repeat new password' => 'Repetir nova password',
   'SEARCH' => 'PESQUISAR',
   'SUBMIT' => 'SUBMETER',
   'Scheduler' => 'Planear',
   'Select Desk' => 'Seleccionar Área',
   'Select Role' => 'Seleccionar Função',
   'Select an Event Type' => 'Seleccionar Tipo de Evento',
   'Select' => 'Seleccionar',
   'Sort By' => 'Ordenar Por',
   'Submit' => 'Submeter',
   'Switch Roles' => 'Mudar Funções',
   'Upload a file' => 'Enviar um ficheiro',
   'User Override' => 'Entrar como',
   'View' => 'Ver',

# Info Messages
   'Active Media' => 'Media Activos',
   'Active Stories' => 'Artigos Activos',
   'Active Templates' => 'Modelos Activos',
   'Add a New User' => 'Criar Novo Utilizador',

   'An active template already exists for the selected output channel, category, element and burner you selected.  You must delete the existing template before you can add a new one.' =>
     'Já existe um template activo para o canal de distribuição, categoria, elemento e burner que assinalou. Tem de apagar o temp+late existtente para poder adicionar um novo.',

   'At least one extension is required.' =>
     'Tem de indicar pelo menos uma extensão.',
   'By Source name' => 'Por nome de Fonte',
   'Cannot auto-publish related media [_1] because it is checked out' =>
     'Não é possível fazer publicação automética de media porque este elemento está reservado.',
   'Cannot publish [_1]  because it is checked out' =>
     'Não é possível publicar [_1] enquanto está reservado.',
   'Cannot publish checked-out media [_1]' =>
     'Não é possível publicar o medium reservado [_1]',
   'Cannot publish checked-out story [_1]' =>
     'Não é possível publicar o artigo reservado [_1]',
   'Category Permissions' => 'Permissões para categorias',
   'Category [_1] added.' => 'Categoria [_1] adicionada.',
   'Category [_1] disassociated.' => 'Categoria [_1] desassociada.',
   'Category profile [_1] and all its categories deleted.' => 
     'Perfil da categoria [1] e todas as suas categorias apagados.',
   'Category profile [_1] deleted.' => 'Perfil da categoria [_1] apagado.',
   'Category profile [_1] saved.' => 'Perfil de categoria [_1] guardado.',
   'Contributor [_1] disassociated.' => 'Colaborador [_1] desassociado.',
   'Contributor profile [_1] deleted.' => 'Perfil de colaborador [_1] apagado.',
   'Contributor profile [_1] saved.' => 'Perfil de colaborador [_1] guardado.',
   'Contributors disassociated.' => 'Colaboradores desassociados.',
   'Cover Date incomplete.' => 'Data de Destaque incompleta.',
   'Delete this Category and All its Subcategories' =>
     'Apagar esta Categoria e Todas as suas Subcategorias',
   'Desk profile [_1] deleted from all workflows.' =>
     'Perfil de área [_1] apagado de todos os workflows.',
   'Destination not specified' => 'Destino não especificado',
   'Destination profile [_1] deleted.' => 'Perfil de destino [_1] apagado.',
   'Destination profile [_1] saved.' => 'Perfil de destino [_1] guardado.',
   'EXISTING CATEGORIES' => 'CATEGORIAS EXISTENTES',
   'EXISTING DESTINATIONS' => 'DESTINOS EXISTENTES',
   'EXISTING ELEMENT TYPES' => 'TIPOS DE ELEMENTO EXISTENTES',
   'EXISTING ELEMENTS' => 'ELEMENTOS EXISTENTES',
   'EXISTING MEDIA TYPES' => 'TIPOS DE MEDIA EXISTENTES',
   'EXISTING OUTPUT CHANNELS' => 'CANAIS DE DISTRIBUIÇÃO EXISTENTES',
   'EXISTING SOURCES' => 'FONTES EXISTENTES',
   'EXISTING USERS' => 'UTILIZADORES EXISTENTES',
   'Element Type profile [_1] deleted.' =>
     'Perfil de tipo de Elemento [_1] apagado.',
   'Element Type profile [_1] saved.' =>
     'Perfil de Tipo de Elemento [_1] guardado.',
   'Element [_1] deleted.' => 'Elemento [_1] apagado.',
   'Element [_1] saved.' => 'Elemento guardado.',
   'Expire Date incomplete.' => 'Data de Fim incompleta.',
   'Grant [_1] members permission to access assets in these categories.' =>
     'Dar aos membros do grupo [_1] permissão para aceder aos materiais destas categorias.',
   'Grant [_1] members permission to access assets in these workflows.' =>
     'Dar aos membros do grupo [_1] permissões para aceder aos materiais destes workflows.',
   'Grant [_1] members permission to access assets on these desks.' =>
     'Dar aos membros do grupo [_1] acesso aos materiais nestas secretárias.',
   'Grant [_1] members permission to access the members of these groups.' =>
     'Dar aos membros do grupo [_1] permissões para aceder aos membros destes grupos.',

   'Grant the members of the following groups permission to access the members of the [_1] group.' =>
     'Dar aos membros dos sgeuintes grupos permissão para aceder aos membros do grupo [_1].',

   'Group cannot be deleted' => 'O grupo não pode ser apagado',
   'Group profile [_1] saved.' => 'Perfil de grupo [_1] guardado.',
   'Group Label' => 'Designação do Grupo',
   'Group Memberships' => 'Grupos Associados',
   'Job profile [_1] deleted.' => 'Perfil de tarefa [_1] apagado.',
   'Job profile [_1] saved.' => 'Perfil de tarefa [_1] guardado.',
   'Keywords saved.' => 'Plavras-chave guardadas.',
   'MEDIA FOUND' => 'MEDIA ENCONTRADOS',
   'Media Found' => 'Media Encontrados',
   'Media Type profile [_1] deleted.' => 'Perfil de Tipo de Media [_1] apagado.',
   'Media Type profile [_1] saved.' => 'Perfil de Tipo de Media [_1] guardado.',
   'Media [_1]  published.' => 'Medium [_1] publicado.',
   'Media [_1] check out canceled.' => 'Reserva do medium [_1] cancelada.',
   'Media [_1] deleted.' => 'Medium [_1] apagado.',
   'Media [_1] published.' => 'Medium [_1] publicado.',
   'Media [_1] reverted to V.[_2]' => 'Medium [_1] revertido para v. [_2]',
   'Media [_1] saved and checked in to [_2].' =>
     'Medium [_1] guardado e disponibilizado para [_2].',
   'Media [_1] saved and moved to [_2].' => 'Medium [_1] guardado e movido para [_2].',
   'Media [_1] saved.' => 'Medium [_1] guardado.',
   'Name is required.' => 'Tem de colocar o nome.',
   'No alert types were found' => 'Não foram encontrados tipos de alerta',
   'No categories were found' => 'Não foram encontradas categorias',
   'No contributor types were found' => 'Não foram encontrados tipos de colaborador',
   'No contributors defined' => 'Não há colaboradores definidos',
   'No contributors defined.' => 'Não há colaboradores definidos',
   'No destinations were found' => 'Não foram encontrados destinos',
   'No elements are present.' => 'Não há elementos presentes.',
   'No elements have been added.' => 'Não foram adicionados elementos.',
   'No elements were found' => 'Não foram encontrados elementos',
   'No file has been uploaded' => 'Não foi feito upload de nenhum ficheiro',
   'No groups were found' => 'Não foram encontrados grupos',
   'No keywords defined.' => 'Não há palavras-chave definidas.',
   'No media types were found' => 'Não foram encontrados tipos de media',
   'No media were found' => 'Não foram encontrados media',
   'No output channels were found' => 'Não foram encontrados canais de distribuição',
   'No related Stories' => 'Não há relações',
   'No sources were found' => 'Não foram encontradas fontes',
   'No stories were found' => 'Não foram encontrados artigos',
   'No templates were found' => 'Não foram encontrados templates',
   'No users were found' => 'Não foram encontrados utilizadores',
   'No workflows were found' => 'Não foram encontrados workflows',
   'Object Group Permissions' => 'Permissões para Tipos de Objectos',
   'Output Channel profile [_1] deleted.' =>
     'Perfil de Canal de Distribuição [_1] apagado.',
   'Output Channel profile [_1] saved.' =>
     'Perfil de Canal de Distribuição [_1] guardado.',
   'PENDING JOBS' => 'TAREFAS PENDENTES',
   'Passwords must match!' => 'Tem de indicar a mesma password!',
   'Permissions saved.' => 'Permissões guardadas',
   'Preference [_1] updated.' => 'Preferência [_1] actualizada.',
   'Published Version' => 'Versão Publicada',
   'Redirecting to preview.' => 'A redireccionar para previsualização.',
   'STORIES FOUND' => 'ARTIGOS ENCONTRADOS',
   'STORIES FOUND' => 'ARTIGOS ENCONTRADOS',
   'STORY INFORMATION' => 'INFORMAÇÃO SOBRE O ARTIGO',
   'Scheduled Time' => 'Data agendada',
   'Separator Changed.' => 'Separador Alterado.',
   'Server profile [_1] deleted.' => 'Perfil de servidor [_1] apagado.',
   'Server profile [_1] saved.' => 'Perfil de servidor [_1] guardado.',
   'Slug must conform to URI character rules.' =>
     'O identificador do URL deve seguir as regras de caracteres dos URIs.',
   'Source profile [_1] deleted.' => 'Perfil de fonte [_1] apagado.',
   'Source profile [_1] saved.' => 'Perfil de fonte [_1] guardado.',
   'Stories in this category' => 'Artigos nesta categoria',
   'Story [_1] check out canceled.' => 'Reserva do artigo [-1] cancelada.',
   'Story [_1] deleted.' => 'Artigo [_1] apagado.',
   'Story [_1] published.' => 'Artigo [_1] publicado.',
   'Story [_1] reverted to V.[_2].' => 'Artigo [_1] revertido para v. [_2].',
   'Story [_1] saved and moved to [_2].' =>
     'Artigo [_1] guardado e movido para [_2]',
   'Story [_1] saved, checked in to [_2].' =>
     'Artigo [_1] guardado e disponibilizado para [_1].',
   'Story [_1] saved.' => 'Artigo [_1] guardado.',
   'TEMPLATES FOUND' => 'TEMPLATES ENCONTRADOS',
   'TEMPLATES FOUND' => 'TEMPLATES ENCONTRADOS',
   'Template Includes' => 'Inclusão de Modelos',
   'Template [_1] check out canceled.' => 'Reserva do template [_1] cancelada.',
   'Template [_1] deleted.' => 'Template [_1] apagado.',
   'Template [_1] saved iand checked in to [_2].' =>
     'Template [_1] disponibilizado para a secretária [_2].',
   'Template [_1] saved.' => 'Template [_1] guardado.',
   'Templates Found' => 'Modelos Encontrados',

   'The category was not added, as it would have caused a URI clash with story [_1].' =>
     'A categoria não foi adicionada, uma vez que teria provocado um conflito de URI com o artigo [_1].',

   'The slug can only contain alphanumeric characters (A-Z, 0-9, - or _)!' =>
     'O identificador no URL só pode conter caracteres alfanuméricos (A-Z, 0-9, - ou _)!',

   'The slug has been reverted to [_1], as the slug [_2] caused this story to have a URI conflicting with that of story [_3].' =>
     'O identificador do url foi revertido para [-1], uma vez que o identificador [_2] fez com que este artigo tivesse um URI que entra em conflito com o do artigo [_3].',

   'The slug, category and cover date you selected would have caused this story to have a URI conflicting with that of story [_1].' =>
     'O identificador de URL, categoria e data de publicação que seleccionou teriam causado um conflito entre o URI deste artigo e o do artigo [_1].',

   'This day does not exist! Your day is changed to the' =>
     'Esta data não existe! A data foi alterada para',
   'Un-relate' => 'Anular relação',
   'User profile [_1] deleted.' => 'Perfil de utilizador [_1] apagado.',
   'Welcome to [_1]' => 'Bem-vindo ao sistema [_1]',
   'Workflow profile [_1] deleted.' => 'Perfil de workflow [_1] apagado.',
   'Workflow profile [_1] saved.' => 'Perfil de workflow [_1] guardado.',
   'You have not been granted <b>[_1]</b> access to the <b>[_2]</b> [_3]' =>
     'Não tem acesso de <b>[_1]</b> a <b>[_3]</b> [_2]',
   'You must select an Element or check the &quot;Generic&quot; check box.' =>
     'Tem de seleccionar um Elemento ou assinalar a check box &quot;Genérico&quot;.',
   '[_1] Elements saved.' => '[_1] Elements Guardados.',
   '[_1] recipients changed.' => '[_1] destinatários alterados.',
   '[quant,$quant,Contributors] [_1] [quant,$quant,disassociated].' =>
     'Colaboradore(s) [_1] desassociado(s).',

# System Requests Messages
   'Choose a Related Story' => 'Escolher Artigo Relacionado',
   'Move to Desk' => 'Mover para a Área',
   'Or Pick a Type' => 'Ou Escolha por Tipo',
   'Passwords cannot have spaces at the beginning!' =>
     'As passwords não podem ter espaços no início!',

   'Please check the URL and try again. If you feel you have reached this page as a result of a server error or other bug, please notify the server administrator. Be sure to include as much detail as possible, including the type of browser, operating system, and the steps leading up to your arrival here.' =>
     'Por favor verifique o URL e volte a tentar. Caso pense que chegou a esta página em resultado de um erro de servidor ou outra falha, por favor notifique o administrador do sistema. Inclua o máximo de informação possível, incluindo o tipo de browser, sistema operativo, e os passos que percorreu até chegar aqui.',

   'Please log in:' => 'Por favor, introduza o Nome de Utilizador e Palavra-chave',
   'Please select a primary category.' =>
     'Por favor seleccione uma categoria primária.',
   'Please select a story type.' => 'Por favor seleccione um tipo de artigo.',
   'The name [_1] is already used by another [_2].' =>
     'O nome [_1] já está a ser usado por outro [_2].',
   'You are about to permanently delete items! Do you wish to continue?' =>
     'Irá apagar definitivamente estes itens! Quer continuar?',
   'You must supply a value for ' => 'Tem de indicar um valor para ',

  # Error Messages
   '404 NOT FOUND' => '404 - página não encontrada',
   'An [_1] attribute already exists. Please try another name.' =>
     'Já existe um atributo [_1]. Por favor tente outro nome.',
   'An error occurred while processing your request:' =>
     'Ocorreu um erro ao processar o seu pedido:',
   'An error occurred.' => 'Ocorreu um erro.',
   'Cannot cancel [_1] because it is currently executing.' =>
     'Não é possível cancelar [_1] porque está neste momento a ser executado.',
   'Cannot move [_1] asset \'[_2]\' while it is checked out' =>
     'Não é possível mover o material [_1] enquanto está reservado.',
   'Category [_1] cannot be deleted.' =>
     'A categoria [_1] não pode ser apagada.',
   'Changes not saved: permission denied.' =>
     'As alterações não foram guardadas: permissão negada.',
   'Check In to [_1]' => 'Disponibilizar para [_1]',

   'Directory name [_1] contains invalid characters. Please try a different directory name.' =>
     'O nome de directório [_1] contém caracteres inválidos. por favor tente um nome de directório diferente.',

   'Group profile [_1] deleted.' =>
     'O perfil de grupo [_1] não pode ser apagado.',
   'Invalid date value for [_1] field.' =>
     'Valor inválido para a data no campo [_1].',
   'Invalid page request' => 'Pedido de página inválido',
   'Invalid password. Please try again.' =>
     'Password inválida. Por favor volte a tentar.',
   'Invalid username or password. Please try again.' =>
     'Nome de utilizador e palavra-passe inválidos. Por favor volte a tentar.',
   'Login [_1] contains invalid characters.' =>
     'O login [_1] contém caracteres inválidos.',
   'Login [_1] is already in use. Please try again.' =>
     'O login [_1] já está a ser utilizado. POr avor volte a tentar.',
   'Login cannot be blank. Please enter a login.' =>
     'Os dados de login não podem estar em branco. Por favor insira o login.',
   'Login must be at least [_1] characters.' =>
     'O login tem de ter pelo menos [_1] caracteres.',
   'No element types were found' => 'Não foram encontrados tipos de elementos',
   'No existing notes.' => 'Não há anotações.',
   'No jobs were found' => 'Não foram encontradas tarefas',
   'Password contains illegal preceding or trailing spaces. Please try again.' =>
     'A password contém espaços no início ou a eio que não são permitidos. Por favor volte a tentar.',
   'Passwords cannot have spaces at the end!' =>
     'As passwords não podem ter espaços no final!',
   'Passwords do not match!  Please re-enter.' =>
     'As passwords não são iguais. Por favor volte a introduzi-la.',
   'Passwords must be at least [_1] characters!' =>
     'As passwords têm de ter pelo menos [_1] caracteres!',
   'Permission Denied' => 'Acesso não-permitido',
   'Permission to checkout [_1] denied' =>
     'Permissão para reservar [_1] negada.',
   'Permission to delete [_1] denied.' =>
     'Não está autorizado a apagar [_1].',
   'Problem adding [_1]' => 'Problemas ao criar [_1].',
   'Problem deleting [_1]' => 'Problemas ao apagar [_1].',
   'Template compile failed: [_1]' =>
     'Compilação do template falhou: [_1]',

   'The URI of this media conflicts with that of [_1]. Please change the category, file name, or slug.' =>
     'O URI deste medium entra em conflito com o de [_1]. Por favor altere a categoria, nome de ficheiro ou identificador no URL.',

   'The URL you requested, <b>[_1]</b>, was not found on this server' =>
     'O URL que pediu, <b>[_1]</b>, não foi encontrado no servidor',

   'The cover date has been reverted to [_1], as it caused this story to have a URI conflicting with that of story \'[_2].' =>
     'A data de destaque foi alterada para [_1], uma vez que deu origem a um URI que entra em conflito com o do artigo [_2].',

   'The name [_1] is already used by another Element Type.' =>
     'O nome [_1] já está a ser usado por outro Tipo de Elemento.',
   'The name [_1] is already used by another Media Type.' =>
     'O nome [_1] já está a ser utilizado por outro Tipo de Media.',
   'The name [_1] is already used by another Output Channel.' =>
     'O nome [_1] já está a ser usado por outro Canal de Distribuição.',
   'The name [_1] is already used by another Source.' =>
     'O nome [_1] já está a ser usada',
   'The name [_1] is already used by another Workflow.' =>
     'O nome [_1] já está a ser usado por outro Workflow.',
   'This story has not been assigned to a category.' =>
     'Este artigo não foi atribuído a uma categoria.',

   'URI [_1] is already in use. Please try a different directory name or parent category.' =>
     'O URI [_1] já está a ser usado. Por favor tente um nome de categoria ou \'parent\' diferente.',

   'Usernames must be at least 6 characters!' =>
     'Os nomes de utilizador têm de ter pelo menos 6 caracteres!',

   'Using Bricolage without JavaScript can result in corrupt data and system instability. Please activate JavaScript in your browser before continuing.' =>
     'Utilizar o Bricolage sem JavaScript pode levar a corrupção de dados e instabilidade do sistema. por favor active o JavaScript do seu browser antes de continuar.',

   'You must supply a unique name for this role!' =>
     'Tem de atribuir um nome único a esta função!',
   '[_1] cannot be deleted' => '[_1] não pode ser apagado',
   'contains illegal characters!' => ' contém caracteres não-permitidos!',

# Warnings
   'Warning! Bricolage is designed to run with JavaScript enabled.' =>
     'Atenção! O Bricolage está concebido para ser utilizado com JavaScript activado.',

   'Warning! State inconsistent: Please use the buttons provided by the application rather than the \'Back\'/\'Forward\' buttons.' =>
     'Atenção! Situação inconsistente: Por favor utilize os botões disponíveis na aplicação e não os botões \'Back\'/\'Forward\' (\'Avançar\'/\'Retroceder\').',

   'Warning: [_1] object \'[_2]\' had no associated workflow.  It has been assigned to the \'[_3]\' workflow.' =>
     'Aviso: o objecto [_1] \'[_2]\' não tem workflow associado. Foi atribuído ao workflow \'[_3]\'.',

   'Warning: object [_1]\' had no associated desk.  It has been assigned to the [_2]\' desk.' =>
     'Aviso: o objecto [_1]\' não tem secretária associada. Foi atribuído à secretária [_2]\'.',
   '_AUTO' => 1,
  );

=head2 To translate

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
      'All Sites' => 'All Sites',
      'Value of [_1] cannot be empty' => 'Value of [_1] cannot be empty',
      'A site with the [_1] '[_2]' already exists' =>
        'A site with the [_1] '[_2]' already exists'
  );

=cut

1;
__END__

=head1 AUTHOR

ClE<aacute>udio Valente <cvalente@co.sapo.pt>

=head1 SEE ALSO

NONE

=cut

