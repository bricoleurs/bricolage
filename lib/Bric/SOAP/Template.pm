package Bric::SOAP::Template;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Formatting;
use Bric::Biz::AssetType;
use Bric::Biz::Category;
use Bric::Biz::Workflow qw(TEMPLATE_WORKFLOW);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use IO::Scalar;
use XML::Writer;
use Bric::Biz::Person::User;

use Bric::SOAP::Util qw(category_path_to_id 
			xs_date_to_db_date db_date_to_xs_date
			parse_asset_document
		       );

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

# this is needed by Template.pl so it can test create() and update()
# without damaging the system.
use constant ALLOW_DUPLICATE_TEMPLATES => 0;

=head1 NAME

Bric::SOAP::Template - SOAP interface to Bricolage templates.

=head1 VERSION

$Revision: 1.11.2.1 $

=cut

our $VERSION = (qw$Revision: 1.11.2.1 $ )[-1];

=head1 DATE

$Date: 2002-10-28 18:53:45 $

=head1 SYNOPSIS

  use SOAP::Lite;
  import SOAP::Data 'name';

  # setup soap object to login with
  my $soap = new SOAP::Lite
    uri      => 'http://bricolage.sourceforge.net/Bric/SOAP/Auth',
    readable => DEBUG;
  $soap->proxy('http://localhost/soap',
               cookie_jar => HTTP::Cookies->new(ignore_discard => 1));
  # login
  $soap->login(name(username => USER), 
	       name(password => PASSWORD));

  # set uri for Template module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Template');

  # get a list of template_ids in the root category
  my $template_ids = $soap->list_ids(name(category => '/'))->result;
  
=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage templates.

=cut

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the story database for matching templates and
returns a list of ids.  If no templates are found an empty list will be
returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item element (M)

The template's element name.

=item file_name (M)

The template's file_name.

=item output_channel

The output channel for the template.

=item category

A category containing the story, given as the complete category path
from the root.  Example: "/news/linux".

=item workflow

The name of the workflow containing the template.

=item simple (M)

a single OR search that hits element and filename.

=item priority

The priority of the template.

=item publish_status

Stories that have been published have a publish_status of "1",
otherwise "0".

=item deploy_date_start

Lower bound on deploy date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item deploy_date_end

Upper bound on deploy date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_start

Lower bound on expire date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_end

Upper bound on expire date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=back 4

Throws: NONE

Side Effects: NONE

Notes: SQL tweaking paramters (Order, Limit, etc.) as in Bric::SOAP::Story
are not available here. We should add them to
Bric::Biz::Asset::Formatting->list() and then support them here too.

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(element file_name output_channel
				 category workflow simple
				 priority publish_status element
				 deploy_date_start deploy_date_end
				 expire_date_start expire_date_end);

sub list_ids {
    my $self = shift;
    my $env = pop;
    my $args = $env->method || {};    
    
    print STDERR __PACKAGE__ . "->list_ids() called : args : ", 
	Data::Dumper->Dump([$args],['args']) if DEBUG;
    
    # check for bad parameters
    for (keys %$args) {
	die __PACKAGE__ . "::list_ids : unknown parameter \"$_\".\n"
	    unless exists $allowed{$_};
    }
    
    # handle workflow => workflow__id mapping
    if (exists $args->{workflow}) {
	my ($workflow_id) = Bric::Biz::Workflow->list_ids(
			        { name => $args->{workflow} });
	die __PACKAGE__ . "::list_ids : no workflow found matching " .
	    "(workflow => \"$args->{workflow}\")\n"
		unless defined $workflow_id;
	$args->{workflow__id} = $workflow_id;
	delete $args->{workflow};
    }

    # handle output_channel => output_channel__id mapping
    if (exists $args->{output_channel}) {
	my ($output_channel_id) = Bric::Biz::OutputChannel->list_ids(
			        { name => $args->{output_channel} });
	die __PACKAGE__ . "::list_ids : no output_channel found matching " .
	    "(output_channel => \"$args->{output_channel}\")\n"
		unless defined $output_channel_id;
	$args->{output_channel__id} = $output_channel_id;
	delete $args->{output_channel};
    }
    
    # handle category => category_id conversion
    if (exists $args->{category}) {
	my $category_id = category_path_to_id($args->{category});
	die __PACKAGE__ . "::list_ids : no category found matching " .
	    "(category => \"$args->{category}\")\n"
		unless defined $category_id;
	$args->{category_id} = $category_id;
	delete $args->{category};      
    }
    
    # translate dates into proper format
    for my $name (grep { /_date_/ } keys %$args) {
	my $date = xs_date_to_db_date($args->{$name});
	die __PACKAGE__ . "::list_ids : bad date format for $name parameter " .
	    "\"$args->{$name}\" : must be proper XML Schema dateTime format.\n"
		unless defined $date;
	$args->{$name} = $date;
    }

    # element is name for templates
    $args->{name} = delete $args->{element}
      if exists $args->{element};
    
    my @list = Bric::Biz::Asset::Formatting->list_ids($args);
    
    print STDERR "Bric::Biz::Asset::Formatting->list_ids() called : ",
	"returned : ", Data::Dumper->Dump([\@list],['list'])
	    if DEBUG;
    
    # name the results
    my @result = map { name(template_id => $_) } @list;
    
    # name the array and return
    return name(template_ids => \@result);
}
}

=item export

The export method retrieves a set of templates from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item template_id

Specifies a single template_id to be retrieved.

=item template_ids

Specifies a list of template_ids.  The value for this option should be an
array of interger "template_id" elements.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(template_id template_ids);

sub export {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};    
    
    print STDERR __PACKAGE__ . "->export() called : args : ", 
 	Data::Dumper->Dump([$args],['args']) if DEBUG;
    
    # check for bad parameters
    for (keys %$args) {
 	die __PACKAGE__ . "::export : unknown parameter \"$_\".\n"
 	    unless exists $allowed{$_};
    }
    
    # template_id is sugar for a one-element template_ids arg
    $args->{template_ids} = [ $args->{template_id} ] 
      if exists $args->{template_id};
    
    # make sure template_ids is an array
    die __PACKAGE__ . "::export : missing required template_id(s) setting.\n"
 	unless defined $args->{template_ids};
    die __PACKAGE__ . "::export : malformed template_id(s) setting.\n"
 	unless ref $args->{template_ids} and ref $args->{template_ids} eq 'ARRAY';
    
    # setup XML::Writer
    my $document        = "";
    my $document_handle = new IO::Scalar \$document;
    my $writer          = XML::Writer->new(OUTPUT      => $document_handle,
 					   DATA_MODE   => 1,
 					   DATA_INDENT => 1);
    
    # open up an assets document, specifying the schema namespace
    $writer->xmlDecl("UTF-8", 1);
    $writer->startTag("assets", 
 		      xmlns => 'http://bricolage.sourceforge.net/assets.xsd');
    
    
    # iterate through template_ids, serializing template objects as we go
    foreach my $template_id (@{$args->{template_ids}}) {	
      $pkg->_serialize_template(writer      => $writer, 
				template_id => $template_id,
				args        => $args);
    }
    
    # end the assets element and end the document
    $writer->endTag("assets");
    $writer->end();
    $document_handle->close();
    
    # name, type and return
    return name(document => $document)->type('base64');   
}
}

=item create

The create method creates new objects using the data contained in an
XML document of the format created by export().

Returns a list of new ids created in the order of the assets in the
document.

Available options:

=over 4

=item document (required)

The XML document containing objects to be created.  The document must
contain at least one template object.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

# hash of allowed parameters
{
my %allowed = map { $_ => 1 } qw(document);

sub create {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};    
    
    print STDERR __PACKAGE__ . "->create() called : args : ", 
      Data::Dumper->Dump([$args],['args']) if DEBUG;
    
    # check for bad parameters
    for (keys %$args) {
	die __PACKAGE__ . "::create : unknown parameter \"$_\".\n"
	    unless exists $allowed{$_};
    }

    # make sure we have a document
    die __PACKAGE__ . "::create : missing required document parameter.\n"
      unless $args->{document};

    # setup empty update_ids arg to indicate create state
    $args->{update_ids} = [];

    # call _load_template
    return $pkg->_load_template($args);
}
}

=item update

The update method updates template using the data in an XML document of
the format created by export().  A common use of update() is to
export() a selected template object, make changes to one or more fields
and then submit the changes with update().

Returns a list of new ids created in the order of the assets in the
document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one template and may contain any number of
related template objects.

=item update_ids (required)

A list of "template_id" integers for the assets to be updated.  These
must match id attributes on template elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=back 4

Throws: NONE

Side Effects: NONE

Notes: Due to the way Bric::Biz::Asset::Formatting->new() works it
isn't possible to fully update file_name.  To change it you need to
update it indirectly by changing category, element and the file_name
extension.  This should be fixed.

=cut

# hash of allowed parameters
{
my %allowed = map { $_ => 1 } qw(document update_ids);

sub update {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};    
    
    print STDERR __PACKAGE__ . "->update() called : args : ", 
      Data::Dumper->Dump([$args],['args']) if DEBUG;
    
    # check for bad parameters
    for (keys %$args) {
	die __PACKAGE__ . "::update : unknown parameter \"$_\".\n"
	    unless exists $allowed{$_};
    }

    # make sure we have a document
    die __PACKAGE__ . "::update : missing required document parameter.\n"
      unless $args->{document};

    # make sure we have an update_ids array
    die __PACKAGE__ . "::update : missing required update_ids parameter.\n"
      unless $args->{update_ids};
    die __PACKAGE__ . 
	"::update : malformed update_ids parameter - must be an array.\n"
	    unless ref $args->{update_ids} and 
                   ref $args->{update_ids} eq 'ARRAY';

    # call _load_template
    return $pkg->_load_template($args);
}
}

=item delete

The delete() method deletes templates.  It takes the following options:

=over 4

=item template_id

Specifies a single template_id to be deleted.

=item template_ids

Specifies a list of template_ids to delete.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

# hash of allowed parameters
{
my %allowed = map { $_ => 1 } qw(template_id template_ids);

sub delete {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};    
    
    print STDERR __PACKAGE__ . "->delete() called : args : ", 
	Data::Dumper->Dump([$args],['args']) if DEBUG;
    
    # check for bad parameters
    for (keys %$args) {
	die __PACKAGE__ . "::delete : unknown parameter \"$_\".\n"
	    unless exists $allowed{$_};
    }

    # template_id is sugar for a one-element template_ids arg
    $args->{template_ids} = [ $args->{template_id} ] 
	if exists $args->{template_id};

    # make sure template_ids is an array
    die __PACKAGE__ . "::delete : missing required template_id(s) setting.\n"
	unless defined $args->{template_ids};
    die __PACKAGE__ . "::delete : malformed template_id(s) setting.\n"
	unless ref $args->{template_ids} and 
	       ref $args->{template_ids} eq 'ARRAY';

    # delete the template
    foreach my $template_id (@{$args->{template_ids}}) {
	print STDERR __PACKAGE__ . 
	    "->delete() : deleting template_id $template_id\n"
		if DEBUG;
      
	# first look for a checked out version
	my $template = Bric::Biz::Asset::Formatting->lookup(
				{ id => $template_id, checkout => 1 });
	unless ($template) {
	    # settle for a non-checked-out version and check it out
	    $template = Bric::Biz::Asset::Formatting->lookup(
				           {id => $template_id});
	    die __PACKAGE__ . 
		"::delete : no template found for id \"$template_id\"\n"
		    unless $template;
	    die __PACKAGE__ . 
		"::delete : access denied for template \"$template_id\".\n"
		    unless chk_authz($template, CREATE, 1);
	    
	    $template->checkout({ user__id => get_user_id });
	}
	
	# deletion dance sampled from widgets/workspace/callback.mc
	my $desk = $template->get_current_desk;
	$desk->checkin($template);
	$desk->remove_asset($template);
	$desk->save;
	$template->deactivate;
	$template->save;
    }
    
    return name(result => 1);
}
}

=back 4

=head2 Private Class Methods

=over 4

=item $pkg->_load_template($args)

This method provides the meat of both create() and update().  The only
difference between the two methods is that update_ids will be empty on
create().

=cut

sub _load_template {
    my ($pkg, $args) = @_;
    my $document     = $args->{document};
    my $data         = $args->{data};
    my %to_update    = map { $_ => 1 } @{$args->{update_ids}};

    # parse and catch erros
    unless ($data) {
	eval { $data = parse_asset_document($document) };
	die __PACKAGE__ . " : problem parsing asset document : $@\n"
	    if $@;
	die __PACKAGE__ . 
	    " : problem parsing asset document : no template found!\n"
		unless ref $data and ref $data eq 'HASH' 
		    and exists $data->{template};
	print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over template, filling @template_ids
    my @template_ids;
    foreach my $tdata (@{$data->{template}}) {
	my $id = $tdata->{id};

	# are we updating?
	my $update = exists $to_update{$id};	

	# setup init data for create
	my %init;

	# get user__id from Bric::App::Session
	$init{user__id} = get_user_id;
	
	# handle output_channel => output_channel__id mapping
	($init{output_channel__id}) = Bric::Biz::OutputChannel->list_ids(
				      { name => $tdata->{output_channel} });
	die __PACKAGE__ . " : no output_channel found matching ".
	    "(output_channel => \"$tdata->{output_channel}\")\n"
		unless defined $init{output_channel__id};

	# figure out file_type
	if ($tdata->{file_name} =~ /\.(\w+)$/) {
	    $init{file_type} = $1;
	} elsif ($tdata->{file_name} =~ /autohandler$/) {
	    $init{file_type} = 'mc';
	} else {
	    die __PACKAGE__ . 
		" : unable to determine file_type for file_name " .
		    \"$tdata->{file_name}\".\n";
	}

	# get element and name for asset type unless this generic
	unless ($tdata->{generic}) {
	    my ($element) = Bric::Biz::AssetType->list(
			  { name => $tdata->{element}[0] });
	    die __PACKAGE__ . " : no element found matching " .
		"(element => \"$tdata->{element}[0]\")\n"
		    unless defined $element;
	    $init{element__id} = $element->get_id;
	    $init{name}        = $element->get_name;
	}

	# assign catgeory_id (not category__id, for some reason...)
	$init{category_id} = category_path_to_id($tdata->{category}[0]);
	die __PACKAGE__ . " : no category found matching " .
	    "(category => \"$tdata->{category}[0]\")\n"
		unless defined $init{category_id};

	# setup data
	if ($tdata->{data}[0]) {
	    $init{data}    = MIME::Base64::decode_base64($tdata->{data}[0]);
	} else {
	    $init{data}    = '';
	}

	# mix in dates 
	for my $name qw(expire_date deploy_date) {
	    my $date = $tdata->{$name};
	    next unless $date; # skip missing date
	    my $db_date = xs_date_to_db_date($date);
	    die __PACKAGE__ . "::export : bad date format for $name : $date\n"
		unless defined $db_date;
	    $init{$name} = $db_date;
	}
	
	# setup simple fields
	$init{priority}    = $tdata->{priority};
	$init{description} = $tdata->{description};

	# get base template object
	my $template;
	unless ($update) {
	    # create empty template
	    $template = Bric::Biz::Asset::Formatting->new(\%init);
	    die __PACKAGE__ .
		"::create : failed to create empty template object.\n"
		    unless $template;
	    print STDERR __PACKAGE__ . 
		"::create : created empty template object\n"
		    if DEBUG;

	    # is this is right way to check create access for template?
	    die __PACKAGE__ . " : access denied.\n"
		unless chk_authz($template, CREATE, 1);

	    # check that there isn't already an active template with the same
	    # output channel and file_name (which is composed of category,
	    # file_type and element name).
	    my $found_dup = 0;
	    my $file_name  = $template->get_file_name;
	    my @list = Bric::Biz::Asset::Formatting->list_ids(
			      { output_channel__id => $init{output_channel__id},
				file_name => $file_name      });
	    if (@list) {
		$found_dup = 1;
	    } else {
		# Arrgh.  This is the only way to search all checked out
		# formatting assets.  According to Garth this isn't a
		# problem...  I'd like to show him this code sometime and see
		# if he still thinks so!
		my @user_ids = Bric::Biz::Person::User->list_ids({});
		foreach my $user_id (@user_ids) {
		    @list = Bric::Biz::Asset::Formatting->list_ids(
			   { output_channel__id => $init{output_channel__id},
			     file_name          => $file_name,
			     user__id           => $user_id   });
		    if (@list) {
			$found_dup = 1;
			last;
		    }
		}
	    }
	    
	    die __PACKAGE__ . "::create : found duplicate template for ".
		"file_name \"$file_name\" and " .
		    "output channel \"$tdata->{output_channel}\".\n"
			if $found_dup and not ALLOW_DUPLICATE_TEMPLATES;

	} else {
	    # updating - first look for a checked out version
	    $template = Bric::Biz::Asset::Formatting->lookup({ id => $id,
                          				       checkout => 1
							     });
	    if ($template) {
		# make sure it's ours
		die __PACKAGE__ . "::update : template \"$id\" ".
		    "is checked out to another user: ", 
			$template->get_user__id, ".\n"
			    if defined $template->get_user__id and
				$template->get_user__id != get_user_id;
		die __PACKAGE__ . " : access denied.\n"
		    unless chk_authz($template, CREATE, 1);
	    } else {
		# try a non-checked out version
		$template = Bric::Biz::Asset::Formatting->lookup({id => $id});
		die __PACKAGE__ . "::update : no template found for \"$id\"\n"
		    unless $template;
		die __PACKAGE__ . " : access denied.\n"
		    unless chk_authz($template, CREATE, 1);

	        # FIX: race condition here - between lookup and checkout 
                #      someone else could checkout...

		# check it out 
		$template->checkout( { user__id => get_user_id });
		$template->save();
	    }

	    # update %init fields
	    $template->_set([keys(%init)],[values(%init)]);
	}

	# need a save here to get the desk stuff working
	$template->deactivate;
	$template->save;

	# updates are in-place, no need to futz with workflows and desks
	my $desk;
	unless ($update) {
	    # find a suitable workflow and desk for the template.  Might be
	    # nice if Bric::Biz::Workflow->list took a type key...
	    foreach my $workflow (Bric::Biz::Workflow->list()) {
		if ($workflow->get_type == TEMPLATE_WORKFLOW) {
		    $template->set_workflow_id($workflow->get_id());
		    $desk = $workflow->get_start_desk;
		    $desk->accept({'asset' => $template});
		    last;
		}
	    }
	}

	# save the template and desk after activating if desired
	$template->activate if $tdata->{active};
	$desk->save unless $update;
	$template->save;

	# checkin and save again for good luck
	$template->checkin();
	$template->save();

	# all done, setup the template_id
	push(@template_ids, $template->get_id);
    }

    return name(ids => [ map { name(template_id => $_) } @template_ids ]);
}

=item $pkg->_serialize_template(writer => $writer, template_id => $template_id, args => $args)

Serializes a single template object into a <template> element using
the given writer and args.

=cut

sub _serialize_template {
    my $pkg         = shift;
    my %options     = @_;
    my $template_id = $options{template_id};
    my $writer      = $options{writer};

    my $template = Bric::Biz::Asset::Formatting->lookup({id => $template_id});
    die __PACKAGE__ . "::export : template_id \"$template_id\" not found.\n"
	unless $template;

    die __PACKAGE__ . 
	"::export : access denied for template \"$template_id\".\n"
	    unless chk_authz($template, READ, 1);
    
    # open a template element
    $writer->startTag("template", id => $template_id);

    # write out element, known to bric as "name" and save it for later
    my $name = $template->get_name;
    $writer->dataElement(element => $name);

    # oh, god, I feel so dirty.  This is the only way to decide
    # if a template object is "generic".
    if ($name eq 'autohandler' or $name eq 'category') {
	$writer->dataElement(generic => 1);
    } else {
	$writer->dataElement(generic => 0);
    }
    
    # write out simple elements in schema order
    foreach my $e (qw(file_name description priority deploy_status)) {
	$writer->dataElement($e => $template->_get($e));
    }
    
    # set active flag
    $writer->dataElement(active => ($template->is_active ? 1 : 0));

    # output category
    $writer->dataElement(category => $template->get_category->ancestry_path);
    
    # get output channel
    my $oc = Bric::Biz::OutputChannel->lookup({
			id => $template->get_output_channel__id });
    die __PACKAGE__ . "::export : unable to find output channel\n"
	unless $oc;
    $writer->dataElement(output_channel => $oc->get_name);
    
    # get dates and output them in dateTime format
    for my $name qw(expire_date deploy_date) {
	my $date = $template->_get($name);
	next unless $date; # skip missing date
	my $xs_date = db_date_to_xs_date($date);
	die __PACKAGE__ . "::export : bad date format for $name : $date\n"
	    unless defined $xs_date;
	$writer->dataElement($name, $xs_date);
    }

    # output data
    my $data = $template->get_data;
    $writer->dataElement(data => MIME::Base64::encode_base64($data,''))
	if $data;

    # close the template
    $writer->endTag("template");    
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
