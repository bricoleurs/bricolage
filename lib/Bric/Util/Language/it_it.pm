package Bric::Util::Language::it_it;

=encoding utf8

=head1 Name

Bric::Util::Language::it_it - Bricolage Italian translation

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

In F<bricolage.conf>:

  LANGUAGE = it_it

=head1 Description

Bricolage Italian translation.

=cut

use strict;
use utf8;
use base qw(Bric::Util::Language);

use constant key => 'it_it';

our %Lexicon = (
    'Jan' => 'Gen',
    'Feb' => 'Feb',
    'Mar' => 'Mar',
    'Apr' => 'Apr',
    'May' => 'Mag',
    'Jun' => 'Giu',
    'Jul' => 'Lug',
    'Aug' => 'Ago',
    'Sep' => 'Set',
    'Oct' => 'Ott',
    'Nov' => 'Nov',
    'Dec' => 'Dic',
    'High'=> 'Alta',
    'Medium High' => 'Medio Alta',
    'Normal'  => 'Normale',
    'Medium Low' => 'Media Bassa',
    'Low'     => 'Bassa',
    'EXISTING DESTINATIONS' => 'DESTINAZIONI ESISTENTI',
    'SUBMIT' => 'INVIA',
    'Cover Date' => 'Data di pubblicazione della cover',
    'Rows' => 'Righe',
    'Preference "[_1]" updated.' => 'Preferenze "[_1]" aggiornate.',
    'Login "[_1]" is already in use. Please try again.' => 'Il login "[_1]" ‚Ã‚¨ gi‚Ã‚  attivo. prova di nuovo.',
    'Add a New User' => 'Aggiungi un nuovo utente',
    'Un-relate' => 'Annulla collegamento',
    'Media "[_1]" published.' => 'Media "[_1]" publicato.',
    'Contributors' => 'Collaboratori',
    'Contributors disassociated.' => 'Collaboratori disassociati.',
    'The name "[_1]" is already used by another Source.' => 'Il nome "[_1]" j‚Ã‚¨ gia in uso',
    'Name is required.' => 'Nome richiesto.',
    'Destination profile "[_1]" saved.' => 'Profilo di destinazione "[_1]" salvato.',
    'Manager' => 'Manager',
    'CONTACTS' => 'LISTA DI CONTATTI',
    'URI' => 'URI',
    'New' => 'Nuovo',
    'Destination not specified' => 'Destinazione non specificata',
    'An error occurred while processing your request:' => 'Si ‚Ã‚¨ verificato un errore durante l\'esecuzione della tua richiesta:',
    '404 NOT FOUND' => '404 - File non trovato',
    'URL' => 'URL',
    'An error occurred.' => 'Si ‚Ã‚¨ verificato un errore.',
    'Sort By' => 'Ordina per',
    'Template "[_1]" saved.' => 'Template "[_1]" salvato.',
    'The URL you requested, <b>[_1]</b>, was not found on this server' => 'L\'URL richiesto, <b>[_1]</b>, non ‚Ã‚¨ disponibile',
    'Members' => 'Membri',
    'Deploy' => 'Implementare',
    'Delete this Category and All its Subcategories' => 'Cancella questa categoria e le SottoCategorie collegate',
    'Cannot move [_1] asset "[_2]" while it is checked out' => 'Non ‚Ã‚¨ possibile spostare l\'asset [_1] perch‚Ã‚© ‚Ã‚¨ riservato.',
    'Move to Desk' => 'Muovi verso il desk',
    'Job profile "[_1]" deleted.' => 'Job Profile "[_1]" cancellato.',
    'Category "[_1]" added.' => 'Categoria "[_1]" aggiunta.',
    'Story "[_1]" deleted.' => 'Storia "[_1]" cancellata.',
    'No elements have been added.' => 'Non ‚Ã‚¨ stato aggiunto alcun elemento.',
    'Name' => 'Nome',
    'My Workspace' => 'Area di lavoro personale',
    'Passwords cannot have spaces at the beginning!' => 'Le passowrd non possono avere spazi bianchi al loro inizio!',
    'Order' => 'Ordinamento',
    'Workflow profile "[_1]" deleted.' => 'Workflow profile "[_1]" cancellato.',
    'Media "[_1]" reverted to V.[_2]' => 'Media "[_1]" ritornato a V. [_2]',
    'EXISTING MEDIA TYPES' => 'TIPI DI MEDIA ESISTENTI',
    'Job Manager' => 'Job MAnager',
    'Current Output Channels' => 'Canali di Distribuzione Presenti',
    'Media Type Manager' => 'Media Type Manager',
    'Alert Type Manager' => 'Alert Type Manager',
    'Story "[_1]" reverted to V.[_2].' => 'Storia "[_1]" ritornato a V. [_2].',
    'Grant the members of the following groups permission to access the members of the "[_1]" group.' => 'Consenti ai membri dei seguenti gruppi permessi di accesso ai membri del gruppo [_1].',
    'Error' => 'Errore',
    'Previews' => 'Preview',
    'Add a New Element' => 'Aggiungi un nuovo elemento',
    'Available Output Channels' => 'Canali di Distribuzione Disponibili',
    'Server profile "[_1]" saved.' => 'Profilo del server "[_1]" salvato.',
    'Story "[_1]" saved and checked in to "[_2]".' => 'Storia "[_1]" salvato e resa disponibile a "[_2]".',
    'Simple Search' => 'Ricerca Semplice',
    'Element Type Manager' => 'Element Type Manager',
    'No templates were found' => 'Nessun template trovato',
    'Group profile "[_1]" deleted.' => 'Profilo di gruppo "[_1]" cancellato.',
    'The name "[_1]" is already used by another Element Type.' => 'Il nome "[_1]" ‚Ã‚¨ gi‚Ã‚  usato da un altro Tipo di Elemento.',
    'Permissions saved.' => 'Permessi salvati',
    'Story "[_1]" saved and moved to "[_2]".' => 'Storia "[_1]" salvato e spostato in "[_2]".',
    'Template Name' => 'Nome del Template',
    'You are about to permanently delete items! Do you wish to continue?' => 'Stai per cancellare definitivamente questi oggetti! Vuoi continuare?',
    'Delete this Element' => 'cancella questo elemento',
    'all' => 'tutti',
    'Yes' => 'Si',
    'Choose a Related Story' => 'Scegli un Storia correlato',
    'Repeatable' => 'Ripetibile',
    'You must supply a value for ' => 'Devi fornire un valore per ',
    'Create a New Media' => 'Creare un nuovo Media',
    'Custom Fields' => 'Campi personalizzati',
    'No contributors defined' => 'Nessun collaboratore definito',
    'Teaser' => 'Teaser',
    'Resources' => 'Risorse',
    'Check In' => 'Check In',
    'Recipients' => 'Destinatari',
    'Note saved.' => 'Nota salvata.',
    'Field Elements' => 'Field Elements',
    'View' => 'Vista',
    'Contributor Types' => 'Tipi di Collaboratori',
    'Media "[_1]" check out canceled.' => 'check out del Media "[_1]" cancellato.',
    'Move to' => 'Muovi verso',
    'Expire Date incomplete.' => 'Data di Scadenza incompleta.',
    'EXISTING SOURCES' => 'FONTI ESISTENTI',
    '[quant,$quant,Contributors] [_1] [quant,$quant,disassociated].' => 'Collaboratore(i) [_1] disassociato(i).',
    'Primary Output Channel' => 'Canale di Distribuzione Primario',
    'Preferences' => 'Preferenze',
    'Login "[_1]" contains invalid characters.' => 'Il login "[_1]" contiene caratteri non validi.',
    'Columns' => 'Colonne',
    'Type' => 'Tipo',
    'Subelements' => 'Subelemento',
    'You must supply a unique name for this role!' => 'Devi attribuire un nome univoco per questo ruolo!',
    'Find Media' => 'Cerca i Media',
    'Find Stories' => 'Cerca gli Articoli',
    'Find Templates' => 'Cerca i Template',
    'Warning: object "[_1]" had no associated desk.‚  It has been assigned to the "[_2]" desk.' => 'Attenzione: l\'oggetto "[_1]" non ha nessun desk associato. E\' stato assegnato al desk "[_2]".',
    'Add a New Destination' => 'Crea una nuova destinazione',
    'Password contains illegal preceding or trailing spaces. Please try again.' => 'La password contiene spazi non consenti al suo inizio o alla fine. Riprova.',
    'Publishes' => 'Pubblica',
    'Text Area' => '‚Ãrea di Testo',
    'Workflow Manager' => 'Workflow Manager',
    'Please select a primary category.' => 'Per favore scegli una categoria primaria.',
    'Please select a primary output channel.' => 'Per favore scegli una canale di distribuzione primario',
    'Role' => 'Ruolo',
    'Note' => 'Nota',
    'Existing Subelements' => 'Subelementi Esistenti',
    'Desk profile "[_1]" deleted from all workflows.' => 'Profilo del Desk "[_1]" cancellato da tutti i‚Â‚  workflow.',
    'Permission to checkout "[_1]" denied.' => 'Permesso negato. checkout non effettuabile',
    'Story "[_1]" check out canceled.' => 'Check out della storia "[_1]" annullato.',
    'Pre' => 'Pre',
    'Slug must conform to URI character rules.' => 'l\'identificato dell\'URL (slug) deve seguire le regole di formattazione degli URI.',
    'Check In to Edit' => 'Rendere Disponibile all\'Editing',
    'No related Stories' => 'Nessun Storia Correlato',
    'The name "[_1]" is already used by another Workflow.' => 'Il nome "[_1]" ‚Ã‚¨ gi‚Ã‚  usato da un altro Workflow.',
    'Login cannot be blank. Please enter a login.' => 'Il login non pu‚Ã‚² essere vuoto. Per favore inserite un altro login.',
    'Label' => 'Etichetta',
    'Output Channel profile "[_1]" saved.' => 'Profilo del Canale di Distribuzione "[_1]" salvato.',
    'Move Assets' => 'Muovi gli asset',
    'Category "[_1]" cannot be deleted.' => 'La categoria "[_1]" non pu‚Ã‚² essere cancellata.',
    'EXISTING ELEMENTS' => 'ELEMENTI ESISTENTI',
    'Log' => 'Log',
    'Year' => 'Anno',
    'Template "[_1]" check out canceled.' => 'Check Out del template "[_1]" cancellato.',
    'No output channels were found' => 'Nessun Canale di Distribuzione disponibile',
    'Events' => 'Eventi',
    'Existing roles' => 'Ruoli Esistenti',
    'Choose Subelements' => 'Scegli i Subelementi',
    'Please check the URL and try again. If you feel you have reached this page as a result of a server error or other bug, please notify the server administrator. Be sure to include as much detail as possible, including the type of browser, operating system, and the steps leading up to your arrival here.' => 'Verificate l\'URL e riprovate. Se pensare di aver raggiunto questa pagina a causa di un baco o server error, notificatelo all\'amministratore di sistema includendo la maggior parte di dettagli possibili (browser, sistema operativo) e i passaggi che vi hanno condotto all\'errore.',
    'Using Bricolage without JavaScript can result in corrupt data and system instability. Please activate JavaScript in your browser before continuing.' => 'Utilizzare Bricolage senza JavaScript pu‚Ã‚² condurre a errori sui dati e instabilit‚Ã‚ . Attivate JavaScript nel browser prima di continuare.',
    'Welcome to Bricolage.' => 'Benvenuto in Bricolage.',
    'Contributor Roles' => 'Ruoli dei Collaboratori',
    'Active' => 'Attivo',
    'Active Media' => 'Media Attivi',
    'Active Templates' => 'Template Attivi',
    'Cannot publish checked-out media "[_1]"' => 'Non ‚Ã‚¨ possibile pubblicare il media "[_1]" in check out',
    'Allow multiple' => 'Permetti multipli',
    'Category tree' => 'Albero delle Categorie',
    'Users' => 'Utenti',
    'Content Type' => 'Tipo de Contenuto',
    'Title' => 'Titolo',
    'Group profile "[_1]" saved.' => 'Profilo di Gruppo "[_1]" salvato.',
    'No file has been uploaded' => 'Nessun file ‚Ã‚¨ stato uploadato',
    'Select Role' => 'Seleziona il Ruolo',
    'Caption' => 'Titolo',
    'Login must be at least [_1] characters.' => 'il login deve avere almeno [_1] caratteri.',
    'Passwords do not match!‚Â‚  Please re-enter.' => 'La passoword non corrisponde. Riprova.',
    'The name "[_1]" is already used by another Output Channel.' => 'Il nome "[_1]"‚Â‚  ‚Ã‚¨ gi‚Ã‚  in uso per un altro Canale di Distribuzione.',
    'No groups were found' => 'Nessun gruppo trovato',
    'No elements were found' => 'Nessun elemento trovato',
    'Media Type profile "[_1]" saved.' => 'Profilo Media Type "[_1]" salvato.',
    'Currently Related Story' => 'Articoli Correlati',
    'Roles' => 'Ruoli',
    'Size' => 'Dimensione',
    'Add a New Contributor Type' => 'Aggiungi un Nuovo Tipo di Collaboratore',
    'No workflows were found' => 'Nessun workflow trovato',
    'No' => 'No',
    'Destinations' => 'Destinazioni',
    'Advanced Search' => 'Ricerca Avanzata',
    'Add' => 'Aggiungi',
    'Publish Desk' => 'Publish Desk',
    'The cover date has been reverted to [_1], as it caused this story to have a URI conflicting with that of story \'[_2].' => 'La data della cover ‚Ã‚¨ stata modificata in [_1], perch‚Ã‚© in conflitto con quella dell\'Storia [_2].',
    'Add a New Alert Type' => 'Creare un nuovo tipo di Alert',
    'Start Desk' => 'Desk Iniziale',
    'Template compile failed: [_1]' => 'Compilazione del template abortita: [_1]',
    'Statistics' => 'Statistiche',
    'Group cannot be deleted.' => 'Il Gruppo non pu‚Ã‚² essere cancellato.',
    'Page' => 'Pagina',
    'User Override' => 'Entra come utente',
    'Delete this Desk from all Workflows' => 'Cancella questo Desk da tutti i Workflow',
    'Required' => 'Obbligatorio',
    'Or Pick a Type' => 'Scegli per Tipo',
    'By Last' => 'Dall\'ultimo al primo',
    'TEMPLATES FOUND' => 'TEMPLATE TROVATI',
    'Source profile "[_1]" saved.' => 'Source profile "[_1]" salvato.',
    'Media "[_1]" saved and moved to "[_2]".' => 'Media "[_1]" salvato e spostato in "[_2]".',
    'The "[_1]" field type already exists. Please try another key name.' => 'L\'attributo "[_1]" esiste gi‚Ã‚ . Per favora prova con un altro nome.',
    'User profile "[_1]" deleted.' => 'Profilo Utente "[_1]" cancellato.',
    '[_1] Field Text' => '[_1] Campo di Testo',
    'Sources' => 'Fonti',
    'Usernames must be at least 6 characters!' => 'Il nome utente deve essere di almeno 6 caratteri!',
    'Old password' => 'Vecchia Password',
    'Delete' => 'Cancellare',
    'No elements are present.' => 'Nessun elemento presente.',
    'Add a New Workflow' => 'Crea un nuovo Workflow',
    'No categories were found' => 'Nessuna categoria presente',
    'Cannot publish checked-out story "[_1]"' => 'Non ‚Ã‚¨ possibile pubblicare la Storia in check out "[_1]"',
    'Grant "[_1]" members permission to access assets in these workflows.' =>
      'Consenti ai membri del gruppo [_1] l\'accesso agli asset di questo workflow.',
   'Choose Related Media' => 'Scegli i Media Correlati',
   'Output Channels' => 'Canali di distribuzione',
   'Passwords must be at least [_1] characters!' => 'La password deve contenere almeno [_1] caratteri!',
   'Invalid date value for "[_1]" field.' => 'Valore di data non valido per il campo "[_1]".',
   'Keywords saved.' => 'Parole Chiave salvate',
   'No stories were found' => 'Nessuna storia trovata',
   'Add a New Element Type' => 'Aggiungi un nuovo Tipo di Elemento',
   'Create a New Story' => 'Crea una Nuova Storia',
   'Priority' => 'Priorit‚Ã‚ ',
   'Add a New Source' => 'Aggiungi una Nuova Fonte',
   'Pending ' => 'Sospesa',
   'Destination Manager' => 'Destination Manager',
   'Login and Password' => 'Login e Password',
   'No media types were found' => 'Nessun Tipo di Media trovato',
   'All Contributors' => 'Tutti i Collaboratori',
   'All Categories' => 'Tutti i Categorie',
   'Element Type profile "[_1]" deleted.' => 'Profilo di Tipo di Elemento "[_1]" salvato.',
   'User Manager' => 'User Manager',
   'Contributor profile "[_1]" saved.' => 'Profilo di Collaboratore "[_1]" salvato.',
   'Alert Types' => 'Tipi di Avvisi',
   'No destinations were found' => 'Nessuna Destinazione trovata',
   'Add a New Group' => 'Creare un Nuovo Gruppo',
   'Properties' => 'Propriet‚Ã‚ ',
   'Create a New Template' => 'Creare un Nuovo Template',
   'Profile' => 'Profilo',
   'Contributor "[_1]" disassociated.' => 'Collaboratori "[_1]" Disassociati.',
   'Workflow' => 'Workflow',
   'Media Type' => 'Tipo di Media',
   'Media Type Element' => 'Tipo di Media',
   'Select Desk' => 'Seleziona il Desk',
   'Download' => 'Download',
   'Fields' => 'Campi',
   'Jobs' => 'Jobs',
   'Content' => 'Contenuto',
   'The name "[_1]" is already used by another Media Type.' => 'il nome "[_1]" ‚Ã‚¨ gi‚Ã‚  in uso per un altro Tipo di Media.',
   'Current Version' => 'Versione Corrente',
   'Create a New Category' => 'Creare un Nuova Categoria',
   'First' => 'Nome',
   'URI "[_1]" is already in use. Please try a different directory name or parent category.' => 'URI "[_1]" gi‚Ã‚  in uso Per favore utilizza un nome di categoria o \'parent\' differente.',
   'Related Media' => 'Media Correlato',
   'Month' => 'Mese',
   'Story "[_1]" saved.' => 'Storia "[_1]" salvata.',
   'Changes not saved: permission denied.' => 'Modifiche non salvate: Permesso negato.',
   'The category was not added, as it would have caused a URI clash with story [_1].' => 'Non ‚Ã‚¨ stato possibile aggiungere la categoria perch‚Ã‚© in conflitto di URI con la Storia [_1].',
   'Directory name "[_1]" contains invalid characters. Please try a different directory name.' => 'Il nome di directory "[_1]" contiene caratteri non validi. Ritenta con un nome differente.',
   'Group Type' => 'Tipo di Gruppo',
   'Default Value' => 'Valore predefinito',
   'Desk Permissions' => 'Permessi del Desk',
   'STORY INFORMATION' => 'INFORMAZIONI SULLA STORIA',
   'Grant "[_1]" members permission to access assets on these desks.' => 'Consenti ai membri del gruppo [_1] accesso ai materiali di questo desk.',
   'Manage' => 'Gestire',
   'A template already exists for the selected output channel, category, element and burner you selected.  You must delete the existing template before you can add a new one.' => 'Esiste giÃ  un template attivo per questo canale di distribuzione, categoria, elemento e burner selezionato. Cancellate il template esistente per poterne aggiungere uno nuovo.',
   'Select' => 'Selezionare',
   'Separator String' => 'Separatore',
   'Position' => 'Posizione',
   'Options, Label' => 'Opzioni, Etichetta',
   'Grant "[_1]" members permission to access assets in these categories.' => 'Consenti ai membri del gruppo [_1] accesso ai materiali di queste categorie.',
   'Scheduled Time' => 'Data Prefissata',
   'At least one extension is required.' => 'Devi indicare almeno un estensione.',
   'My Alerts' => 'Avvisi personali',
   'Categories' => 'Categorie',
   'Cover Date incomplete.' => 'Data di pubblicazione incompleta.',
   'Available Groups' => 'Gruppi disponibili',
   'File Name' => 'Nome di File',
   'Cannot auto-publish related media "[_1]" because it is checked out' => 'Non ‚Ã‚¨ possibile pubblicare in automatico il media correlato "[_1]" perch‚Ã‚© l\'elemento ‚Ã‚¨ in checkout.',
   'Last Name' => 'Cognome',
   'Object Group Permissions' => 'Permessi per i Tipi di Oggetti',
   'Invalid username or password. Please try again.' => 'Username o password non validi. Per favore riprova.',
   'This day does not exist! Your day is changed to the' => 'Data Inesistente! data modificata in',
   'ADVANCED SEARCH' => 'RICERCA AVANZATA',
   'Text box' => 'Text box',
   'The slug has been reverted to [_1], as the slug [_2] caused this story to have a URI conflicting with that of story [_3].' => 'Identificatore di URI [_2] modificato in [_1], perch‚Ã‚© in conflitto con l\'URI della storia [_3].',
   'Value Name' => 'Valore',
   'Expire' => 'Scadenza',
   'Element Manager' => 'Element Manager',
   'Words' => 'Parole',
   'First Name' => 'Nome',
   'You have not been granted <b>[_1]</b> access to the <b>[_2]</b> [_3]' => 'Accesso Negato di <b>[_1]</b> a <b>[_2]</b> [_3]',
   'Group Manager' => 'Group Manager',
   'Story Type' => 'Tipo di Storia',
   'Story Type Element' => 'Tipo di Storia',
   'Separator Changed.' => 'Separatore Modificato.',
   'The slug, category and cover date you selected would have caused this story to have a URI conflicting with that of story [_1].' => 'L\'identificatore di URL (slug), categoria e data di pubblicazione selezionati per la Storia sono in conflitto con l\'URI della storia [_1].',
   'All Elements' => 'Tutti gli Elementi',
   'No alert types were found' => 'Nessun Tipo di Avviso trovato',
   'PROPERTIES' => 'PROPRIETA\'',
   'NAME' => 'NOME',
   'All Groups' => 'Tutti i Gruppi',
   'Add to Include' => 'Aggiungere per Includere',
   'Element "[_1]" deleted.' => 'Elemento "[_1]" cancellato.',
   'Publish Date' => 'Data di Pubblicazione',
   'No keywords defined.' => 'Nessuna parola chiave definita.',
   'Add a New Desk' => 'Aggiungi un Nuovo Desk',
   'Delete this Profile' => 'Cancella questo Profilo',
   'No sources were found' => 'Nessuna fonte trovata',
   '"[_1]" Elements saved.' => '"[_1]" Elementi Salvati.',
   'Login ' => 'Nome Utente',
   'Element "[_1]" saved.' => 'Elemento "[_1]" salvato.',
   'Characters' => 'Caratteri',
   'Workflow profile "[_1]" saved.' => 'Profilo Workflow "[_1]" salvato.',
   'Category Permissions' => 'Permessi delle Categorie',
   'Last' => 'Ultimo',
   'Warning! Bricolage is designed to run with JavaScript enabled.' => 'Attenzione! Bricolage ‚Ã‚¨ progettato per funzionare con javascript attivato.',
   'Add to Element' => 'Aggiungere all\'Elemento',
   'Passwords must match!' => 'La Password deve corrospondere!',
   'The URI of this media conflicts with that of [_1].  Please change the category, file name, or slug.' => 'L\'URI di questo media ‚Ã‚¨ in conflitto con [_1]. Per favore modifica la categoria, il nome del file o lo slug.',
   'PREFERENCES' => 'PREFERENZE',
   'Workflows' => 'Workflow',
   'Check In to Publish' => 'Rendere Disponibile alla pubblicazione',
   'Fixed' => 'URL Fisso',
   'Deployed Date' => 'Data di Implementazione',
   'Generic' => 'Generico',
   'You must select an Element or check the &quot;Generic&quot; check box.' => 'Devi selezionare un elemento o selezionare il check box &quot;Generico&quot;.',
   'By Source name' => 'Per nome della Fonte',
   'No contributor types were found' => 'Nessun Tipo di collaboratore trovato',
   'Redirecting to preview.' => 'Redirezionare al preview.',
   '[_1] recipients changed.' => '[_1] destinatari modificati.',
   'Add a New Output Channel' => 'Aggiungi un nuovo Canale di Distribuzione',
   'EXISTING CATEGORIES' => 'CATEGORIE ESISTENTI',
   'Add a New Media Type' => 'Creare un Nuovo Tipo di Media',
   'Contacts' => 'Contatti',
   'Warning! State inconsistent: Please use the buttons provided by the application rather than the \'Back\'/\'Forward\' buttons.' => 'Attenzione! Stato inconsistente: Per favore usate i pulsanti presenti nell\'applicazione e non quelli del browser \'Back\'/\'Forward\'.',
   'Grant "[_1]" members permission to access the members of these groups.' => 'Consenti ai membri del gruppo [_1] l\'accesso ai membri di questi gruppi.',
   'Check In Assets' => 'Rendere disponibili i Materiali',
   'No contributors defined.' => 'Nessun collaboratore definito',
   'No media were found' => 'Nessun media trovato',
   'Invalid password. Please try again.' => 'Password non valida. Per favore riprova.',
   'Current Groups' => 'Gruppi Correnti',
   'The slug can only contain alphanumeric characters (A-Z, 0-9, - or _)!' => 'L\'identificatore di URL (slug) pu‚Ã‚² contenere solo caratteri alfanumerici (A-Z, 0-9, - ou _)!',
   'Media Type profile "[_1]" deleted.' => 'Profilo di Tipo di Media "[_1]" salvato.',
   'Server profile "[_1]" deleted.' => 'Profilo Server "[_1]" salvato.',
   'Member Type  ' => 'Tipo di Membro',
   'Admin' => 'Admin',
   'Select an Event Type' => 'Seleziona un Tipo di Evento',
   'Extension' => 'Estensione',
   'Day' => 'Giorno',
   'Template "[_1]" deleted.' => 'Template "[_1]" cancellato.',
   'Job profile "[_1]" saved.' => 'Job Profile "[_1]" salvato.',
   'Add a New Category' => 'Aggiungere una Nuova Categoria',
   'No users were found' => 'Nessun Utente trovato',
   'Destination profile "[_1]" deleted.' => 'Profilo di Destinazione "[_1]" cancellato.',
   ' contains illegal characters!' => ' contiene caratteri non permessi!',
   'Contributor profile "[_1]" deleted.' => 'Profilo di Collaboratore "[_1]" cancellato.',
   'Category profile "[_1]" saved.' => 'Profilo di Categoria "[_1]" salvato.',
   'Media "[_1]" saved.' => 'Media "[_1]" salvato.',
   'Output Channel' => 'Canale di Distribuzione',
   'Event Type' => 'Tipo di Evento',
   'Switch Roles' => 'Cambia i Ruoli',
   'File Path' => 'Percorso File',
   'Output Channel profile "[_1]" deleted.' => 'Profilo del Canale de Distribuzione "[_1]" salvato.',
   'Add New Field' => 'Aggiungi un Nuovo Campo',
   'Story "[_1]" published.' => 'Storia "[_1]" pubblicata.',
   'Passwords cannot have spaces at the end!' => 'Le password non possono avere spazi alla fine!',
   'PENDING JOBS' => 'JOBS SOSPESI',
   'Category "[_1]" disassociated.' => 'Categoria "[_1]" disassociata.',
   'Source name' => 'Nome della fonte',
   'Category profile "[_1]" and all its categories deleted.' => 'Profilo di categoria "[_1]" e sue categorie cancellate.',
   'MEDIA FOUND' => 'MEDIA TROVATI',
   'Permission Denied' => 'Accesso Negato',
   'Source' => 'Fonte',
   'This story has not been assigned to a category.' => 'La Storia non ‚Ã‚¨ stata assegnata ad alcuna categoria.',
   'Source profile "[_1]" deleted.' => 'Profilo di fonte "[_1]" cancellato.',
   'Stories in this category' => 'Storie presenti in questacategoria',
   'Contributor Type Manager' => 'Manager dei Tipi di Collaboratori',
   'Publish' => 'Pubblicare',
   'EXISTING ELEMENT TYPES' => 'TIPI DI ELEMENTI ESISTENTI',
   'Problem deleting "[_1]"' => 'Problemi nel cancellare "[_1]".',
   'Element Type profile "[_1]" saved.' => 'Profilo di Tipo di Elemento "[_1]" salvato.',
   'No element types were found' => 'Nessun tipo di elemento trovato',
   'Related Story' => 'Storie Correlate',
   'Category profile "[_1]" deleted.' => 'Profilo di categoria "[_1]" cancellato.',
   'Media "[_1]" deleted.' => 'Media "[_1]" cancellato.',
   'EXISTING USERS' => 'UTENTI PRESENTI',
   'Category Assets' => 'Materiali di Categoria',
   'Category Manager' => 'Category Manager',
   'New password' => 'Nuova password',
   'Workflow Permissions' => 'Permessi del Workflows',
   'Organization' => 'Organizzazione',
   'New Role Name' => 'Nuovo Ruolo',
   'Current Note' => 'Nota Corrente',
   'Group Label' => 'Etichetta di gruppo',
   'Prefix' => 'Titolo',
   'Scheduler' => 'Pianificare',
   'Owner' => 'Proprietario',
   'to' => 'a',
   'Problem adding "[_1]"' => 'Problema nella creazione di [_1].',
   'Preference Manager' => 'Preference Manager',
   'SEARCH' => 'RICERCA',
   'Source Manager' => 'Source Manager',
   'Extensions' => 'Estensioni',
   'EXISTING OUTPUT CHANNELS' => 'CANALI DI DISTRIBUZIONE',
   'No existing notes.' => 'Nessuna nota presente',
   'Invalid page request' => 'Richiesta di Pagina non valida',
   'Group Memberships' => 'Gruppi Associati',
   'Permission to delete "[_1]" denied.' => 'Permesso di cancellare "[_1]" negato.',
   'Template Includes' => 'Template Include',
   'Published Version' => 'Versione Pubblicata',
   'Cannot cancel "[_1]" because it is currently executing.' => 'Non ‚Ã‚¨ possibile cancellare "[_1]" perch‚Ã‚© in esecuzione.',
   'Check In to [_1]' => 'Render disponibile a [_1]',
   'Check Out' => 'Check Out',
   'Element' => 'Elemento',
   'Please select a story type.' => 'Per favore scegliete un Tipo di Storia.',
   'Edit' => 'Editare',
   'No jobs were found' => 'Nessun Job presente',
   'Post' => 'Post',
   'STORIES FOUND' => 'STORIE TROVATE',
    'STORIES' => 'ARTICOLI',
    'PROPERTIES' => 'PROPRIETA',
   'Media "[_1]" saved and checked in to "[_2]".' => 'Media "[_1]" salvato e reso disponibile a "[_2]".',
   'Maximum size' => 'Dimensione Massima',
   'Relate' => 'Correlare',
   'Choose Contributors' => 'Scegli i Collaboratori',
   'ID' => 'ID',
   'Expire Date' => 'Data di Scadenza',
   'Existing Notes' => 'Note Esistenti',
    'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec' => 'Gen Feb Mar Apr Mag Giu Lug Ago Set Ott Nov Dic',
   'Check In to' => 'Render dispobile a',
   'one per line' => 'uno per riga',
   'Repeat new password' => 'Ripeti la nuova password',
    'ADMIN' => 'AMMINISTRAZIONE',
    'SYSTEM' => 'SISTEMA',
    'PUBLISHING' => 'PUBBLICAZIONE',
    'DISTRIBUTION' => 'DISTRIBUIZIONE',
    'Description' => 'Descrizione',
   '_AUTO' => 1,
);

=begin comment

To translate:
  "Delete this Story" => "Delete this Story",
  "Delete this Media" => "Delete this Media",
  "Delete this Template" => "Delete this Template",
  "Delete this Category" => "Delete this Category",
  "Delete this Contributor Type" => "Delete this Contributor Type",
  "Delete this Contributor" => "Delete this Contributor",
  "Delete this Element Type" => "Delete this Element Type",
  "Delete this Keyword" => "Delete this Keyword",
  "Delete this Media Type" => "Delete this Media Type", 
  "Delete this Output Channel" => "Delete this Output Channel",
  "Delete this Source" => "Delete this Source",
  "Delete this Workflow" => "Delete this Workflow",
  "All jobs" => "All jobs",
  "Today's jobs" => "Today's jobs",
  "Future jobs" => "Future jobs",
  "Expire jobs" => "Expire jobs",
  "Failed jobs" => "Failed jobs",
  "My jobs" => "My jobs",
  'Shelve'
  'and Shelve'
  'and'
  'Slug required for non-fixed (non-cover) story type.'
  '[quant,_1,Day]' => '[quant,_1,Day,Days,None]',

  'Cannot both delete and make primary a single output channel.'
  'Media "[_1]" saved and shelved.'
  'Media "[_1]" created and saved.'
  'Un-Associate'
  'Associate'
  'Preview in'
  'Parent cannot choose itself or its child as its parent. Try a different parent.'
  'Category URI'
  'Story "[_1]" saved and shelved.'
  'Story "[_1]" created and saved.'
  'Template "[_1]" saved and shelved.'
  'Template "[_1]" saved and moved to "[_2]".'
  'No media file is associated with asset "[_1]", so none will be distributed.'
  'Cannot publish asset "[_1]" to "[_2]" because there are no Destinations associated with this output channel.'
  'Warning:  Use of element\'s \'name\' field is deprecated for use with element method \'get_container\'.  Please use the element\'s \'key_name\' field instead.'
  'Warning:  Use of element\'s \'name\' field is deprecated for use with element method \'get_value\'.  Please use the element\'s \'key_name\' field instead.'
  'You must be an administrator to use this function.'
  'Template deployed.'
  '[quant,_1,Template] deployed.'
  'Cannot auto-publish related story "[_1]" because it is checked out.'
  'Cannot publish media "[_1]" because it is checked out.'
  'Cannot publish story "[_1]" because it is checked out.'
  'Bad element name "[_1]". Did you mean "[_2]"?'
  'Field "[_1]" appears more than once but it is not a repeatable element.  Please remove all but one.'
  'Note: Field element "[_1]" is required and cannot be completely removed.  Will delete all but one.'
  'Note: Container element "[_1]" removed in bulk edit but will not be deleted.'
  'Cannot create an alias to a media in the same site.'
  'Cannot create an alias to a story in the same site.'
  '[quant,_1,Alert] acknowledged.'
  'Warning: object "[_1]" had no associated workflow.  It has been assigned to the "[_2]" workflow.'
  'Warning: object "[_1]" had no associated workflow.  It has been assigned to the "[_2]" workflow. This change also required that this object be moved to the "[_3]" desk.'
  'Action profile "[_1]" deleted.'
  'Action profile "[_1]" saved.'
  'Alert Type profile "[_1]" deleted.'
  'Alert Type profile "[_1]" saved.'
  'The name "[_1]" is already used by another Alert Type.'
  'The name "[_1]" is already used by another Desk.'
  'The name "[_1]" is already used by another Destination.'
  'You cannot remove all Sites.'
  'The key name "[_1]" is already used by another ???.'
  '[quant,_1,Contributor] "[_2]" associated.'
  'Extension "[_1]" ignored.'
  'Extension "[_1]" is already used by media type "[_2]".'
  'The name "[_1]" is already used by another Server in this Destination.'
  'You must select an Element.'
  'New passwords do not match. Please try again.'
  'User profile "[_1]" saved.'
  'Site profile "[_1]" deleted.'
  'Site profile "[_1]" saved.'

  'Workspace for [_1]' => 'Translate me!'
  'No file associated with media "[_1]". Skipping.'
  'Writing files to "[_1]" Output Channel.'
  'Distributing files.'
  'No output to preview.'
  'Cannot preview asset "[_1]" because there are no Preview Destinations associated with its output channels.'
  'Element must be associated with at least one site and one output channel.'
  'First Published' => 'First Published',
  '[_1] Site [_2] Permissions' => '[_1] [_2] Permissions', # Site Category Permissions
  'Object Groups' => 'Object Groups',
  '[_1] Site Categories' => '[_1] Site Categories',
  'You do not have permission to override user "[_1]"' => 'You do not have permission to override user "[_1]"'
  'Not defined.' => 'Not defined.',
  'Milliseconds' => 'Milliseconds',
  'Microseconds' => 'Microseconds',
  'Not defined.' => 'Not defined.',
  "You do not have sufficient permission to create a media document for this site" => "You do not have sufficient permission to create a media document for this site"
  'The primary category cannot be deleted.' => 'The primary category cannot be deleted.',
  'Cannot make a dissociated category the primary category.' => 'Cannot make a dissociated category the primary category.'
  'Related [_1] "[_2]" is not activate. Please relate another [_1].' => 'Related [_1] "[_2]" is not activate. Please relate another [_1].'
  'Cannot auto-publish related $rel_disp_name "[_1]" because it is not on a publish desk.' => 'Cannot auto-publish related $rel_disp_name "[_1]" because it is not on a publish desk.'
  'The URI "[_1]" is not unique. Please change the cover date, output channels, slug, or categories as necessary to make the URIs unique.' => 'The URI "[_1]" is not unique. Please change the cover date, output channels, slug, or categories as necessary to make the URIs unique.'
  'Name "[_1]" is not a valid media name. The name must be of the form "type/subtype".' => 'Name "[_1]" is not a valid media name. The name must be of the form "type/subtype".',
  'Include deleted' => 'Include deleted',
  'Reactivate' => 'Reactivate',
  'All Subelements' => 'All Subelements',
      'Code' => 'Code',
      'Code Select' => 'Code Select',
      'Invalid codeselect code (didn't return an array ref of even size)' => 'Invalid codeselect code (didn't return an array ref of even size)',
  'The error message is available below. No further execution attempts will be made on this job unless you check the "Reset this Job" checkbox below.' => 'The error message is available below. No further execution attempts will be made on this job unless you check the "Reset this Job" checkbox below.',
  'Job "[_1]" has been reset.' => 'Job "[_1]" has been reset.',
  '[quant,_1,media,media] published.' => '[quant,_1,media,media] published.',
  '[quant,_1,media,media] expired.' => '[quant,_1,media,media] expired.',
  '[quant,_1,story,stories] published.' => '[quant,_1,story,stories] published.',
  '[quant,_1,story,stories] expired.' => '[quant,_1,story,stories] expired.',
  'No context for content beginning at line [_1].' => 'No context for content beginning at line [_1].',
  'No such field "[_1]" at line [_2]. Did you mean "[_3]"?' => 'No such field "[_1]" at line [_2]. Did you mean "[_3]"?',
  'No such subelement "[_1]" at line [_2]. Did you mean "[_3]"?' => 'No such subelement "[_1]" at line [_2]. Did you mean "[_3]"?',
  'Unknown tag "[_1]" at line [_2].' => 'Unknown tag "[_1]" at line [_2].',
  'No such site "[_1]" at line [_2].'=> 'No such site "[_1]" at line [_2].',
  'No such URI "[_1]" in site "[_2]" at line [_3].' => 'No such URI "[_1]" in site "[_2]" at line [_3].',
  'No story document found for UUID "[_1]" at line [_2].' => 'No story document found for UUID "[_1]" at line [_2].',
  'No media document found for UUID "[_1]" at line [_2].' => 'No media document found for UUID "[_1]" at line [_2].',
  'No story document found for ID "[_1]" at line [_2].' => 'No story document found for ID "[_1]" at line [_2].',
  'No media document found for ID "[_1]" at line [_2].' => 'No media document found for ID "[_1]" at line [_2].',
  'No story document found for URI "[_1]" at line [_2].' => 'No story document found for URI "[_1]" at line [_2].',
  'No media document found for URI "[_1]" at line [_2].' => 'No media document found for URI "[_1]" at line [_2].',
  'D (for Deployed)'  => 'D',
  'P (for Published)' => 'P',
  'Field "[_1]" cannot be added. There are already [quant,_2,field,fields] of this type, with a max of [_3].' => 'Field â€œ[_1]â€ cannot be added. There are already [quant,_2,field,fields] of this type, with a max of [_3].',
  'Element "[_1]" cannot be added. There are already [quant,_2,element,elements] of this type, with a max of [_3].' => 'Element â€œ[_1]â€ cannot be added. There are already [quant,_2,element,elements] of this type, with a max of [_3].',
  'Field "[_1]" cannot be deleted. There must be at least [quant,_2,field,fields] of this type.' => 'Field â€œ[_1]â€ cannot be deleted. There must be at least [quant,_2,field,fields] of this type.',
  'Element "[_1]" cannot be deleted. There must be at least [quant,_2,element,elements] of this type.' => 'Element â€œ[_1]â€ cannot be deleted. There must be at least [quant,_2,element,elements] of this type.',
  'Field "[_1]" appears [_2] times around line [_3]. Please remove all but [_4].' => 'Field â€œ[_1]â€ appears [quant,_2,time,times] around line [_3]. Please remove all but [_4].',
  'min_occurrence must be a positive number.' => 'min_occurrence must be a positive number.',
  'max_occurrence must be a positive number.' => 'max_occurrence must be a positive number.',
  'Min and max occurrence must be a positive numbers.' => 'Min and max occurrence must be a positive numbers.',
  'place must be a positive number.' => 'place must be a positive number.',
  '[_1] cannot be a subelement of [_2].' => '[_1] cannot be a subelement of [_2].',
  'You cannot add a note to "[_1]" because it is not checked out to you' => 'You cannot add a note to "[_1]" because it is not checked out to you',
  'Could not create a thumbnail for [_1]: [_2]' => 'Could not create a thumbnail for [_1]: [_2]',
  'Toggle "[_1]"' => 'Toggle ü[_1]ý',
  'Could not create keyword, "[_1]", as you have not been granted permission to create new keywords.' => 'Could not create keyword, "[_1]", as you have not been granted permission to create new keywords.',
  'Paste ([_1])' => 'Paste ([_1])', # As in Copy/Paste
  'You do not have [_1] access to any desks in the "[_2]" workflow' => 'You do not have [_1] access to any desks in the "[_2]" workflow'

=end comment

=cut

1;

__END__

=head1 Author

Marco Ghezzi <marcog@metafora.it>

=head1 See Also

L<Bric::Util::Language|Bric::Util::Language>

L<Bric::Util::Language::en_us|Bric::Util::Language::en_us>

L<Bric::Util::Language::de_de|Bric::Util::Language::de_de>

=cut
