package Bric::SOAP::Media;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Media;
use Bric::Biz::AssetType;
use Bric::Biz::Category;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Biz::Workflow qw(MEDIA_WORKFLOW);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use Bric::App::Event    qw(log_event);
use XML::Writer;
use IO::Scalar;
use MIME::Base64;

use Bric::SOAP::Util qw(category_path_to_id 
			xs_date_to_db_date db_date_to_xs_date
			parse_asset_document
			serialize_elements
                        deserialize_elements
		       );

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Media - SOAP interface to Bricolage media.

=head1 VERSION

$Revision: 1.12.2.4 $

=cut

our $VERSION = (qw$Revision: 1.12.2.4 $ )[-1];

=head1 DATE

$Date: 2002-11-06 20:09:21 $

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

  # set uri for Media module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Media');

  # get a list of media_ids for all Illustrations (a Media Type)
  my $media_ids = $soap->list_ids(name(element => 'Illustration'));

=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage media.

=cut

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching media and returns a list
of ids.  If no media is found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item title (M)

The media title.

=item description (M)

The media description.

=item uri (M)

The media uri.

=item file_name (M)

The name of the file inside the media object.

=item simple (M)

A single OR search that hits title, description and uri.

=item category

The category containing the story, given as the complete category path
from the root.  Example: "/news/linux".

=item workflow

The name of the workflow containing the media.  (ex. Media)

=item priority

The priority of the media object.

=item element

The name of the top-level element for the media.  Also know as the
"Media Type".  This value corresponds to the element attribute on the
media element in the asset schema.

=item publish_date_start

Lower bound on publishing date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item publish_date_end

Upper bound on publishing date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item cover_date_start

Lower bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item cover_date_end

Upper bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_start

Lower bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_end

Upper bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=back 4

Throws: NONE

Side Effects: NONE

Notes: Some options are missing - the SQL tweaking paramters (Order,
Limit, etc.) in Bric::SOAP::Story most obviously.  We should add them
to Bric::Biz::Asset::Business::Media->list() and then support them
here too.

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(title description file_name
				 simple uri priority publish_status
				 workflow element category
				 publish_date_start publish_date_end
				 cover_date_start cover_date_end
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

    # handle element => element__id conversion
    if (exists $args->{element}) {
	my ($element_id) = Bric::Biz::AssetType->list_ids(
			      { name => $args->{element}, media => 1 });
	die __PACKAGE__ . "::list_ids : no element found matching " .
	    "(element => \"$args->{element}\")\n"
		unless defined $element_id;
	$args->{element__id} = $element_id;
	delete $args->{element};
    }
    
    # handle category => category_id conversion
    if (exists $args->{category}) {
	my $category_id = category_path_to_id($args->{category});
	die __PACKAGE__ . "::list_ids : no category found matching " .
	    "(category => \"$args->{category}\")\n"
		unless defined $category_id;
	$args->{category__id} = $category_id;
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
    
    my @list = Bric::Biz::Asset::Business::Media->list_ids($args);
    
    print STDERR "Bric::Biz::Asset::Business::Media->list_ids() called : ",
	"returned : ", Data::Dumper->Dump([\@list],['list'])
	    if DEBUG;
    
    # name the results
    my @result = map { name(media_id => $_) } @list;
    
    # name the array and return
    return name(media_ids => \@result);
}
}

=item export

The export method retrieves a set of media from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item media_id

Specifies a single media_id to be retrieved.

=item media_ids

Specifies a list of media_ids.  The value for this option should be an
array of interger "media_id" elements.

=back 4

Throws: NONE

Side Effects: NONE

Notes: Bric::SOAP::Media->export doesn't provide equivalents to the
export_related_stories and export_related_media options in
Bric::SOAP::Story->export.  Related media and related stories will
always be returned with absolute id references.  If
you're... creative...  enough to be using related media and stories in
your Media types then you'll have to manually fetch the relations.

=cut

{
  # hash of allowed parameters
  my %allowed = map { $_ => 1 } qw(media_id media_ids);

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
    
    # media_id is sugar for a one-element media_ids arg
    $args->{media_ids} = [ $args->{media_id} ] if exists $args->{media_id};
    
    # make sure media_ids is an array
    die __PACKAGE__ . "::export : missing required media_id(s) setting.\n"
 	unless defined $args->{media_ids};
    die __PACKAGE__ . "::export : malformed media_id(s) setting.\n"
 	unless ref $args->{media_ids} and ref $args->{media_ids} eq 'ARRAY';
    
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
    
    
    # iterate through media_ids, serializing media objects as we go
    foreach my $media_id (@{$args->{media_ids}}) {	
	$pkg->_serialize_media(writer   => $writer, 
			       media_id => $media_id,
			       args     => $args);
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
contain at least one media object.

=back 4

Throws: NONE

Side Effects: NONE

Notes: The setting for publish_status in the incoming media is ignored
and always 0 for new media.

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

    # call _load_media
    return $pkg->_load_media($args);
}
}

=item update

The update method updates media using the data in an XML document of
the format created by export().  A common use of update() is to
export() a selected media object, make changes to one or more fields
and then submit the changes with update().

Returns a list of new ids created in the order of the assets in the
document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one media and may contain any number of
related media objects.

=item update_ids (required)

A list of "media_id" integers for the assets to be updated.  These
must match id attributes on media elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=back 4

Throws: NONE

Side Effects: NONE

NNotes: The setting for publish_status for new media is ignored and
always 0 for new stories.  Updated media do get their publish_status
set from the incoming document.

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

    # call _load_media
    return $pkg->_load_media($args);
}
}


=item delete

The delete() method deletes media.  It takes the following options:

=over 4

=item media_id

Specifies a single media_id to be deleted.

=item media_ids

Specifies a list of media_ids to delete.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

# hash of allowed parameters
{
my %allowed = map { $_ => 1 } qw(media_id media_ids);

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

    # media_id is sugar for a one-element media_ids arg
    $args->{media_ids} = [ $args->{media_id} ] if exists $args->{media_id};

    # make sure media_ids is an array
    die __PACKAGE__ . "::delete : missing required media_id(s) setting.\n"
      unless defined $args->{media_ids};
    die __PACKAGE__ . "::delete : malformed media_id(s) setting.\n"
      unless ref $args->{media_ids} and ref $args->{media_ids} eq 'ARRAY';

    # delete the media
    foreach my $media_id (@{$args->{media_ids}}) {
        print STDERR __PACKAGE__ . "->delete() : deleting media_id $media_id\n"
          if DEBUG;

        # first look for a checked out version
        my $media = Bric::Biz::Asset::Business::Media->lookup({ id => $media_id,
                                                                checkout => 1 });
        unless ($media) {
            # settle for a non-checked-out version and check it out
            $media = Bric::Biz::Asset::Business::Media->lookup({ id => $media_id });
            die __PACKAGE__ . "::delete : no media found for id \"$media_id\"\n"
              unless $media;
            die __PACKAGE__ . "::delete : access denied for media \"$media_id\".\n"
              unless chk_authz($media, CREATE, 1);
            $media->checkout({ user__id => get_user_id });
            log_event("media_checkout", $media);
        }

        # Remove the media from any desk it's on.
        if (my $desk = $media->get_current_desk) {
            $desk->checkin($media);
            $desk->remove_asset($media);
            $desk->save;
        }

        # Remove the media from workflow.
        if ($media->get_workflow_id) {
            $media->set_workflow_id(undef);
            log_event("media_rem_workflow", $media);
        }

        # Deactivate the media and save it.
        $media->deactivate;
        $media->save;
        log_event("media_deact", $media);
    }

    return name(result => 1);
}
}

=back 4

=head2 Private Class Methods

=over 4

=item $pkg->_load_media($args)

This method provides the meat of both create() and update().  The only
difference between the two methods is that update_ids will be empty on
create().

=cut

sub _load_media {
    my ($pkg, $args) = @_;
    my $document = $args->{document};
    my $data     = $args->{data};
    my %to_update = map { $_ => 1 } @{$args->{update_ids}};

    # parse and catch erros
    unless ($data) {
	eval { $data = parse_asset_document($document) };
	die __PACKAGE__ . " : problem parsing asset document : $@\n"
	    if $@;
	die __PACKAGE__ . 
	    " : problem parsing asset document : no media found!\n"
		unless ref $data and ref $data eq 'HASH' and exists $data->{media};
	print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over media, filling in @media_ids
    my @media_ids;
    foreach my $mdata (@{$data->{media}}) {
	my $id = $mdata->{id};

	# are we updating?
	my $update = exists $to_update{$id};	

	# setup init data for create
	my %init;

	# get user__id from Bric::App::Session
	$init{user__id} = get_user_id;
	
	# get element object for asset type
	($init{element__id}) = Bric::Biz::AssetType->list_ids(
                                 { name => $mdata->{element}, media => 1 });
	die __PACKAGE__ . "::create : no media element found matching " .
	    "(element => \"$mdata->{element}\")\n"
		unless defined $init{element__id};

	# get source__id from source
	($init{source__id}) = Bric::Biz::Org::Source->list_ids(
                                 { source_name => $mdata->{source} });
	die __PACKAGE__ . "::create : no source found matching " .
	    "(source => \"$mdata->{source}\")\n"
		unless defined $init{source__id};

	# setup simple fields
	$init{priority} = $mdata->{priority};
	$init{name}     = $mdata->{name};

	# mix in dates 
	for my $name qw(cover_date expire_date publish_date) {
	    my $date = $mdata->{$name};
	    next unless $date; # skip missing date
	    my $db_date = xs_date_to_db_date($date);
	    die __PACKAGE__ . "::export : bad date format for $name : $date\n"
		unless defined $db_date;
	    $init{$name} = $db_date;
	}

	# assign catgeory__id
	$init{category__id} = category_path_to_id($mdata->{category}[0]);
	die __PACKAGE__ . "::create : no category found matching " .
	    "(category => \"$mdata->{category}[0]\")\n"
		unless defined $init{category__id};
	
	# get base media object
	my $media;
	unless ($update) {
	    # create empty media
	    $media = Bric::Biz::Asset::Business::Media->new(\%init);
	    die __PACKAGE__ . "::create : failed to create empty media object."
		unless $media;
	    print STDERR __PACKAGE__ . "::create : created empty media object\n"
		if DEBUG;

	    # is this is right way to check create access for media?
	    die __PACKAGE__ . " : access denied.\n"
		unless chk_authz($media, CREATE, 1);

	} else {
	    # updating - first look for a checked out version
	    $media = Bric::Biz::Asset::Business::Media->lookup({ id => $id,
								 checkout => 1
							       });
	    if ($media) {
		# make sure it's ours
		die __PACKAGE__ . 
		    "::update : media \"$id\" is checked out to another user.\n"
			unless $media->get_user__id == get_user_id;
		die __PACKAGE__ . " : access denied.\n"
		    unless chk_authz($media, CREATE, 1);
	    } else {
		# try a non-checked out version
		$media = Bric::Biz::Asset::Business::Media->lookup({ id => $id });
		die __PACKAGE__ . "::update : no media found for \"$id\"\n"
		    unless $media;
		die __PACKAGE__ . " : access denied.\n"
		    unless chk_authz($media, CREATE, 1);

	        # FIX: race condition here - between lookup and checkout 
                #      someone else could checkout...

		# check it out 
		$media->checkout( { user__id => get_user_id });
		$media->save();
	    }

	    # update %init fields
	    $media->_set([keys(%init)],[values(%init)]);
	}
	
	# set simple fields
	my @simple_fields = qw(description uri);
	$media->_set(\@simple_fields, [ @{$mdata}{@simple_fields} ]);

	# avoid setting publish_status on create
	$media->set_publish_status($mdata->{publish_status}) if $update;

	# remove all contributors if updating
	$media->delete_contributors([ $media->get_contributors ])
	    if $update and $media->get_contributors;

	# add contributors, if any
	if ($mdata->{contributors} and $mdata->{contributors}{contributor}) {
	    foreach my $c (@{$mdata->{contributors}{contributor}}) {
		my %init = (fname => $c->{fname}, 
			    mname => $c->{mname},
			    lname => $c->{lname});
		my ($contrib) = 
		    Bric::Util::Grp::Parts::Member::Contrib->list(\%init);
		die __PACKAGE__ . "::create : no contributor found matching " .
		    "(contributer => " . 
			join(', ', map { "$_ => $c->{$_}" } keys %$c)
		    unless defined $contrib;
		$media->add_contributor($contrib, $c->{role});
	    }
	}

	# deal with file data if we have one	
	if ($mdata->{file}) {
	    my $filename = $mdata->{file}{name};
	    my $size     = $mdata->{file}{size};
	    my $data     = MIME::Base64::decode_base64($mdata->{file}{data}[0]);
	    my $fh       = new IO::Scalar \$data;
	    
	    # upload the file into the media object
	    $media->upload_file($fh, $filename);
	    $media->set_size($size);

	    # lookup MediaType by extension, if we have one
	    my ($ext) = $filename =~ /\.(.*)$/;
	    my $media_type;
	    $media_type = Bric::Util::MediaType->lookup({'ext' => $ext})
		if $ext;
	    $media->set_media_type_id($media_type ? $media_type->get_id : 0);
	} else {
	    # clear the media object by uploading an empty file - this
	    # is functionality that isn't actually supported by
	    # Bricolage.  We should add a Media->delete_file() method at
	    # some point and use it here.
	    my $data = "";
	    my $fh  = new IO::Scalar \$data;
	    $media->upload_file($fh, "empty");
	    $media->set_size(0);
	    $media->set_media_type_id(0);
	}

        # make sure this media won't create a duplicate URI
        die __PACKAGE__ . "::create : unable to create media, URI '"
          . $media->get_uri . "' is already taken.\n"
            if $media->check_uri;

	# save the media in an inactive state.  this is necessary to
	# allow element addition - you can't add elements to an
	# unsaved media, strangely.
	$media->deactivate;
	$media->save;

	# updates are in-place, no need to futz with workflows and desks
	my $desk;
	unless ($update) {
	    # find a suitable workflow and desk for the media.
            my $workflow = (Bric::Biz::Workflow->list
                            ({ type => MEDIA_WORKFLOW }))[0];
            $media->set_workflow_id($workflow->get_id());
            $desk = $workflow->get_start_desk;
            $desk->accept({'asset' => $media});
	}

	# add element data
	deserialize_elements(object => $media,
			     data   => $mdata->{elements} || {});

	# save the media and desk after activating if desired
	$media->activate if $mdata->{active};
	$desk->save unless $update;
	$media->save;

	# checkin and save again for good luck
	$media->checkin();
	$media->save();

	# all done, setup the media_id
	push(@media_ids, $media->get_id);
    }

    # return a SOAP structure unless this is an internal call
    unless ($args->{internal}) {
	return name(ids => [ map { name(media_id => $_) } @media_ids ]);
    }
    return @media_ids;
}


=item $pkg->_serialize_media(writer => $writer, media_id => $media_id, args => $args)

Serializes a single media object into a <media> element using the given
writer and args. 

=cut

sub _serialize_media {
    my $pkg      = shift;
    my %options  = @_;
    my $media_id = $options{media_id};
    my $writer   = $options{writer};

    my $media = Bric::Biz::Asset::Business::Media->lookup({id => $media_id});
    die __PACKAGE__ . "::export : media_id \"$media_id\" not found.\n"
	unless $media;

    die __PACKAGE__ . "::export : access denied for media \"$media_id\".\n"
	unless chk_authz($media, READ, 1);
    
    # open a media element
    $writer->startTag("media", 
		      id => $media_id, 
		      element => $media->get_element_name);
    
    # write out simple elements in schema order
    foreach my $e (qw(name description uri
		      priority publish_status )) {
	$writer->dataElement($e => $media->_get($e));
    }
    
    # set active flag
    $writer->dataElement(active => ($media->is_active ? 1 : 0));
    
    # get source name
    my $src = Bric::Biz::Org::Source->lookup({
					      id => $media->get_source__id });
    die __PACKAGE__ . "::export : unable to find source\n"
	unless $src;
    $writer->dataElement(source => $src->get_source_name);
    
    # get dates and output them in dateTime format
    for my $name qw(cover_date expire_date publish_date) {
	my $date = $media->_get($name);
	next unless $date; # skip missing date
	my $xs_date = db_date_to_xs_date($date);
	die __PACKAGE__ . "::export : bad date format for $name : $date\n"
	    unless defined $xs_date;
	$writer->dataElement($name, $xs_date);
    }
    
    # output categories
    $writer->dataElement(category => $media->get_category->ancestry_path);

    # output contributors
    $writer->startTag("contributors");
    foreach my $c ($media->get_contributors) {
	my $p = $c->get_person;
	$writer->startTag("contributor");
	$writer->dataElement(fname  => $p->get_fname);
	$writer->dataElement(mname  => $p->get_mname);
	$writer->dataElement(lname  => $p->get_lname);
	$writer->dataElement(type   => $c->get_grp->get_name);
	$writer->dataElement(role   => $media->get_contributor_role($c));
	$writer->endTag("contributor");
    }
    $writer->endTag("contributors");

    # output elements, ignore related media
    serialize_elements(writer => $writer, 
		       args   => \%options,
		       object => $media);
    
    # output file if we've got one
    my $file_name = $media->get_file_name;    
    if ($file_name) {
	$writer->startTag("file");
	$writer->dataElement(name => $file_name);
	$writer->dataElement(size => $media->get_size);
	
	# read in file data
	my $fh   = $media->get_file;
	my $data = join('',<$fh>);
	$writer->dataElement(data => MIME::Base64::encode_base64($data,''));
	close $fh;

	$writer->endTag("file");
    }
    

    # close the media
    $writer->endTag("media");    
}


=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
