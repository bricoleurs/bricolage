package Bric::SOAP::Story;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::AssetType;
use Bric::Biz::Category;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Biz::Workflow qw(STORY_WORKFLOW);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use XML::Writer;
use IO::Scalar;

use Bric::SOAP::Util qw(category_path_to_id 
			xs_date_to_db_date db_date_to_xs_date
			parse_asset_document
                        serialize_elements
                        deserialize_elements
		       );
use Bric::SOAP::Media;

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Story - SOAP interface to Bricolage stories.

=head1 VERSION

$Revision: 1.24 $

=cut

our $VERSION = (qw$Revision: 1.24 $ )[-1];

=head1 DATE

$Date: 2002-03-13 23:36:30 $

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

  # set uri for Story module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Story');

  # get a list of story_ids for published stories w/ "foo" in their title
  my $story_ids = $soap->list_ids(name(title          => '%foo%'), 
                                  name(publish_status => 1)     )->result;

  # export a story
  my $xml = $soap->export(name(story_id => $story_id)->result;

  # create a new story from an xml document
  my $story_ids = $soap->create(name(document => $xml_document))->result;

  # update an existing story from an xml document
  my $story_ids = $soap->create(name(document => $xml_document),
                                name(update_ids => 
                                     [ name(story_id => 1024) ]))->result;
  
=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage stories.

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the story database for matching stories and
returns a list of ids.  If no stories are found an empty list will be
returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item title (M)

The story's title.

=item description (M)

The story's description.

=item slug (M)

The story's slug.

=item category

A category containing the story, given as the complete category path
from the root.  Example: "/news/linux".

=item keyword (M)

A keyword associated with the story.

=item simple (M)

a single OR search that hits title, description, primary_uri
and keywords.

=item workflow

The name of the workflow containing the story.  (ex. Story)

=item no_workflow

Set to 1 to return only stories that are out of workflow.  This is
true after stories are published and until they are recalled into
workflow for editing.

=item primary_uri (M)

The primary uri of the story.

=item priority

The priority of the story.

=item publish_status

Stories that have been published have a publish_status of "1",
otherwise "0".  This value never changes after being turned on.  For a
more accurate read on a story's current status see no_workflow above.

=item element

The name of the top-level element for the story.  Also know as the
"Story Type".  This value corresponds to the element attribute on the
story element in the asset schema.

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

=item Order 

Specifies that the results be ordered by a particular property.

=item OrderDirection

The direction in which to order the records, either "ASC" for
ascending (the default) or "DESC" for descending.

=item Limit

A maximum number of objects to return. If not specified, all objects
that match the query will be returned.

=item Offset 

The number of objects to skip before listing the number of objects
specified by "Limit". Not used if "Limit" is not defined, and when
"Limit" is defined and "Offset" is not, no objects will be skipped.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(title description slug category 
				 keyword simple primary_uri priority
				 workflow no_workflow publish_status element
				 publish_date_start publish_date_end
				 cover_date_start cover_date_end
				 expire_date_start expire_date_end
				 Order OrderDirection Limit Offset);

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

    # no_workflow means workflow__id => undef
    if ($args->{no_workflow}) {
	$args->{workflow__id} = undef;
	delete $args->{no_workflow};
    }
        
    # handle element => element__id conversion
    if (exists $args->{element}) {
	my ($element_id) = Bric::Biz::AssetType->list_ids(
			      { name => $args->{element} });
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

    # perform list using existing Bricolage list_ids functionality
    my @list = Bric::Biz::Asset::Business::Story->list_ids($args);
    
    print STDERR "Bric::Biz::Asset::Business::Story->list_ids() called : ",
	"returned : ", Data::Dumper->Dump([\@list],['list'])
	    if DEBUG;
    
    # name the results
    my @result = map { name(story_id => $_) } @list;
    
    # name the array and return
    return name(story_ids => \@result);
}
}

=item export

The export method retrieves a set of stories from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item story_id

Specifies a single story_id to be retrieved.

=item story_ids

Specifies a list of story_ids.  The value for this option should be an
array of interger "story_id" elements.

=item export_related_media

If set to 1 any related media attached to the story will be included
in the exported document.  The story will refer to these included
media objects using the relative form of related-media linking.  (see
the XML Schema document in L<Bric::SOAP|Bric::SOAP> for
details)

=item export_related_stories

If set to 1 then the export will work recursively across related
stories.  If export_media is also set then media attached to related
stories will also be returned.  The story element will refer to the
included story objects using relative references (see the XML Schema
document in L<Bric::SOAP|Bric::SOAP> for details).

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(story_id story_ids 
				 export_related_media 
				 export_related_stories);

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

    # story_id is sugar for a one-element story_ids arg
    $args->{story_ids} = [ $args->{story_id} ] if exists $args->{story_id};

    # make sure story_ids is an array
    die __PACKAGE__ . "::export : missing required story_id(s) setting.\n"
	unless defined $args->{story_ids};
    die __PACKAGE__ . "::export : malformed story_id(s) setting.\n"
	unless ref $args->{story_ids} and ref $args->{story_ids} eq 'ARRAY';

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
		       

    # iterate through story_ids, serializing stories as we go, storing
    # media ids to serialize for later.
    my @story_ids = @{$args->{story_ids}};
    my @media_ids;
    my %done;
    while(my $story_id = shift @story_ids) {
      next if exists $done{$story_id}; # been here before?
      my @related = $pkg->_serialize_story(writer   => $writer, 
					   story_id => $story_id,
					   args     => $args);
      $done{$story_id} = 1;
      
      # queue up the related stories, story the media for later
      foreach my $obj (@related) {
	  push(@story_ids, $obj->[1]) if $obj->[0] eq 'story';
	  push(@media_ids, $obj->[1]) if $obj->[0] eq 'media';
      }
    }

    # serialize related media if we have any
    %done = ();
    foreach my $media_id (@media_ids) {
      next if $done{$media_id};
      Bric::SOAP::Media->_serialize_media(media_id => $media_id,
					  writer   => $writer,
					  args     => {});
      $done{$media_id} = 1;
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

The create will fail if your story element contains non-relative
related_story_ids or related_media_ids that do not refer to existing
stories or media in the system.

Returns a list of new story_ids and media_ids created in the order of
the assets in the document.

Available options:

=over 4

=item document (required)

The XML document containing objects to be created.  The document must
contain at least one story and may contain any number of related media
objects.

=back 4

Throws: NONE

Side Effects: NONE

Notes: The setting for publish_status in the incoming story is ignored
and always 0 for new stories.

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

    # call _load_stories
    return $pkg->_load_stories($args);
}
}

=item update

The update method updates stories using the data in an XML document
of the format created by export().  A common use of update() is to
export() a selected story, make changes to one or more fields and
then submit the changes with update(). 

Returns a list of new story_ids and media_ids updated or created in
the order of the assets in the document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one story and may contain any number of
related media objects.

=item update_ids (required)

A list of "story_id" integers for the assets to be updated.  These
must match id attributes on story elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=back 4

Throws: NONE

Side Effects: NONE

Notes: The setting for publish_status in a newly created story is
ignored and always 0 for new stories.  Updated stories do get
publish_status set from the document setting.

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

    # call _load_stories
    return $pkg->_load_stories($args);
}
}


=item delete

The delete() method deletes stories.  It takes the following options:

=over 4

=item story_id

Specifies a single story_id to be deleted.

=item story_ids

Specifies a list of story_ids to delete.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=back 4

=cut

# hash of allowed parameters
{
my %allowed = map { $_ => 1 } qw(story_id story_ids);

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

    # story_id is sugar for a one-element story_ids arg
    $args->{story_ids} = [ $args->{story_id} ] if exists $args->{story_id};

    # make sure story_ids is an array
    die __PACKAGE__ . "::delete : missing required story_id(s) setting.\n"
	unless defined $args->{story_ids};
    die __PACKAGE__ . "::delete : malformed story_id(s) setting.\n"
	unless ref $args->{story_ids} and ref $args->{story_ids} eq 'ARRAY';

    # delete the stories
    foreach my $story_id (@{$args->{story_ids}}) {
      print STDERR __PACKAGE__ . "->delete() : deleting story_id $story_id\n"
	if DEBUG;
      
      # first look for a checked out version
      my $story = Bric::Biz::Asset::Business::Story->lookup({ id => $story_id, checkout => 1 });
      unless ($story) {
	# settle for a non-checked-out version and check it out
	$story = Bric::Biz::Asset::Business::Story->lookup({ id => $story_id });
	die __PACKAGE__ . "::delete : no story found for id \"$story_id\"\n"
	  unless $story;
	die __PACKAGE__ . "::deleye : access denied for story \"$story_id\".\n"
	    unless chk_authz($story, CREATE, 1);

	$story->checkout({ user__id => get_user_id });
      }

      # deletion dance sampled from comp/widgets/workspace/callback.mc
      my $desk = $story->get_current_desk;
      $desk->checkin($story);
      $desk->remove_asset($story);
      $desk->save;
      $story->deactivate;
      $story->save;
    }

    return name(result => 1);
}
}

=back

=head2 Private Class Methods

=over 4

=item $pkg->_load_stories($args)

This method provides the meat of both create() and update().  The only
difference between the two methods is that update_ids will be empty on
create().

=cut

sub _load_stories {
    my ($pkg, $args) = @_;
    my $document = $args->{document};
    my %to_update = map { $_ => 1 } @{$args->{update_ids}};

    # parse and catch erros
    my $data;
    eval { $data = parse_asset_document($document) };
    die __PACKAGE__ . " : problem parsing asset document : $@\n"
	if $@;
    die __PACKAGE__ . " : problem parsing asset document : no stories found!\n"
	unless ref $data and ref $data eq 'HASH' and exists $data->{story};
    print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;

    # loop over stories, filling in %story_ids and @relations
    my (%story_ids, @story_ids, @relations);
    foreach my $sdata (@{$data->{story}}) {
	my $id = $sdata->{id};

	# are we updating?
	my $update = exists $to_update{$id};	

	# setup init data for create
	my %init;

	# get user__id from Bric::App::Session
	$init{user__id} = get_user_id;
	
	# get element__id from story element
	($init{element__id}) = Bric::Biz::AssetType->list_ids(
                                 { name => $sdata->{element} });
	die __PACKAGE__ . "::create : no element found matching " .
	    "(element => \"$sdata->{element}\")\n"
		unless defined $init{element__id};

	# get source__id from source
	($init{source__id}) = Bric::Biz::Org::Source->list_ids(
                                 { source_name => $sdata->{source} });
	die __PACKAGE__ . "::create : no source found matching " .
	    "(source => \"$sdata->{source}\")\n"
		unless defined $init{source__id};

	# get base story object
	my $story;
	unless ($update) {
	    # create empty story
	    $story = Bric::Biz::Asset::Business::Story->new(\%init);
	    die __PACKAGE__ . "::create : failed to create empty story object."
		unless $story;
	    print STDERR __PACKAGE__ . "::create : created empty story object\n"
		if DEBUG;

	    # is this is right way to check create access for stories?
	    die __PACKAGE__ . " : access denied.\n"
		unless chk_authz($story, CREATE, 1);

	} else {
	    # updating - first look for a checked out version
	    $story = Bric::Biz::Asset::Business::Story->lookup({ id => $id,
								 checkout => 1
							       });
	    if ($story) {
		# make sure it's ours
		die __PACKAGE__ . 
		    "::update : story \"$id\" is checked out to another user.\n"
			unless $story->get_user__id == get_user_id;
		die __PACKAGE__ . " : access denied.\n"
		    unless chk_authz($story, CREATE, 1);
	    } else {
		# try a non-checked out version
		$story = Bric::Biz::Asset::Business::Story->lookup({ id => $id });
		die __PACKAGE__ . "::update : no story found for \"$id\"\n"
		    unless $story;
		die __PACKAGE__ . " : access denied.\n"
		    unless chk_authz($story, CREATE, 1);

	        # FIX: race condition here - between lookup and checkout 
                #      someone else could checkout...

		# check it out 
		$story->checkout( { user__id => get_user_id });
		$story->save();
	    }

	    # update %init fields
	    $story->set_element__id($init{element__id});
	    $story->set_source__id($init{source__id});    
	}

	# set simple fields
	my @simple_fields = qw(name description slug primary_uri
			       priority);
	$story->_set(\@simple_fields, [ @{$sdata}{@simple_fields} ]);

	# avoid setting publish_status on create
	$story->set_publish_status($sdata->{publish_status}) if $update;

	# assign dates 
	for my $name qw(cover_date expire_date publish_date) {
	    my $date = $sdata->{$name};
	    next unless $date; # skip missing date
	    my $db_date = xs_date_to_db_date($date);
	    die __PACKAGE__ . "::export : bad date format for $name : $date\n"
		unless defined $db_date;
	    $story->_set([$name],[$db_date]);
	}

	# remove all categories if updating
	$story->delete_categories([ $story->get_categories ])
	    if $update;

	# assign categories
	my @cids;
	my $primary_cid;
	foreach my $cdata (@{$sdata->{categories}{category}}) {
	    # get cat id
	    my $path = ref $cdata ? $cdata->{content} : $cdata;
	    my $category_id = category_path_to_id($path);
	    die __PACKAGE__ . "::create : no category found matching " .
		"(category => \"$path\")\n"
		    unless defined $category_id;
	    
	    push(@cids, $category_id);
	    $primary_cid = $category_id 
		if ref $cdata and $cdata->{primary};
	}
	
	# sanity checks
	die __PACKAGE__ . "::create : no categories defined!"
	    unless @cids;
	die __PACKAGE__ . "::create : no primary category defined!"
	    unless defined $primary_cid;
	    
	# add categories to story
	$story->add_categories(\@cids);	
	$story->set_primary_category($primary_cid);

	# remove all keywords if updating
	$story->delete_keywords([ $story->get_keywords ])
	    if $update and $story->get_keywords;
	
	# add keywords, if we have any
	if ($sdata->{keywords} and $sdata->{keywords}{keyword}) {

	    # collect keyword objects
	    my @kws;
	    foreach (@{$sdata->{keywords}{keyword}}) {
		my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
		$kw ||= Bric::Biz::Keyword->new({ name => $_})->save;
		push @kws, $kw;
	    }

	    # add keywords to the story
	    $story->add_keywords(\@kws);
	}

	# remove all contributors if updating
	$story->delete_contributors([ $story->get_contributors ])
	    if $update and $story->get_contributors;

	# add contributors, if any
	if ($sdata->{contributors} and $sdata->{contributors}{contributor}) {
	    foreach my $c (@{$sdata->{contributors}{contributor}}) {
		my %init = (fname => $c->{fname}, 
			    mname => $c->{mname},
			    lname => $c->{lname});
		my ($contrib) = 
		    Bric::Util::Grp::Parts::Member::Contrib->list(\%init);
		die __PACKAGE__ . "::create : no contributor found matching " .
		    "(contributer => " . 
			join(', ', map { "$_ => $c->{$_}" } keys %$c)
		    unless defined $contrib;
		$story->add_contributor($contrib, $c->{role});
	    }
	}

	# save the story in an inactive state.  this is necessary to
	# allow element addition - you can't add elements to an
	# unsaved story, strangely.
	$story->deactivate;
	$story->save;

	# updates are in-place, no need to futz with workflows and desks
	my $desk;
	unless ($update) {
	    # find a suitable workflow and desk for the story.  Might be
	    # nice if Bric::Biz::Workflow->list took a type key...
	    foreach my $workflow (Bric::Biz::Workflow->list()) {
		if ($workflow->get_type == STORY_WORKFLOW) {
		    $story->set_workflow_id($workflow->get_id());
		    $desk = $workflow->get_start_desk;
		    $desk->accept({'asset' => $story});
		    last;
		}
	    }
	}

	# add element data
	push @relations, 
	    deserialize_elements(object => $story,
				 data   => $sdata->{elements} || {});

	# save the story and desk after activating if desired
	$story->activate if $sdata->{active};
	$desk->save unless $update;
	$story->save;

	# checkin and save again for good luck
	$story->checkin();
	$story->save();

	# all done, setup the story_id
	push(@story_ids, $story_ids{$id} = $story->get_id);
    }

    # if we have any media objects, create them
    my (%media_ids, @media_ids);
    if ($data->{media}) {	
	@media_ids = Bric::SOAP::Media->_load_media({ data       => $data,
				                      internal   => 1,
						      upload_ids => []    });

	# correlate to relative ids
	for (0 .. $#media_ids) {
	    $media_ids{$data->{media}[$_]{id}} = $media_ids[$_];
	}	
    }

    # resolve relations
    foreach my $r (@relations) {
	if ($r->{relative}) {
	    # handle relative links
	    if ($r->{story_id}) {
		die __PACKAGE__ . 
		    " : Unable to find related story by relative id ". 
			"\"$r->{story_id}\""
			    unless exists $story_ids{$r->{story_id}};
		$r->{container}->
		    set_related_instance_id($story_ids{$r->{story_id}});
	    } else {
		die __PACKAGE__ . 
		    " : Unable to find related media by relative id ". 
			"\"$r->{media_id}\""
			    unless exists $media_ids{$r->{media_id}};
		$r->{container}->
		    set_related_media($media_ids{$r->{media_id}});
	    }
	} else {
	    # handle absolute links
	    if ($r->{story_id}) {
		die __PACKAGE__ . " : related story_id \"$r->{story_id}\" ".
		    "not found.\n"
			unless Bric::Biz::Asset::Business::Story->lookup(
                                                  {id => $r->{story_id}});
		$r->{container}->set_related_instance_id($r->{story_id});
	    } else {
		die __PACKAGE__ . " : related media_id \"$r->{media_id}\" ".
		    "not found.\n"
			unless Bric::Biz::Asset::Business::Media->lookup(
                                                  {id => $r->{media_id}});
		$r->{container}->set_related_media($r->{media_id});
	    }
	}
	$r->{container}->save;
    }
    
    return name(ids => [ 
			map { name(story_id => $_) } @story_ids,
			map { name(media_id => $_) } @media_ids 
		       ]);
}

=item @related = $pkg->_serialize_story(writer => $writer, story_id => $story_id, args => $args)

Serializes a single story into a <story> element using the given
writer and args.  Returns a list of two-element arrays - [ "media",
$id ] or [ "story", $id ].  These are the related media objects
serialized.

=cut

sub _serialize_story {
    my $pkg      = shift;
    my %options  = @_;
    my $story_id = $options{story_id};
    my $writer   = $options{writer};
    my @related;

    my $story = Bric::Biz::Asset::Business::Story->lookup({id => $story_id});
    die __PACKAGE__ . "::export : story_id \"$story_id\" not found.\n"
	unless $story;

    die __PACKAGE__ . "::export : access denied for story \"$story_id\".\n"
	unless chk_authz($story, READ, 1);
    
    # open a story element
    $writer->startTag("story", 
		      id => $story_id, 
		      element => $story->get_element_name);
    
    # write out simple elements in schema order
    foreach my $e (qw(name description slug primary_uri
		      priority publish_status )) {
	$writer->dataElement($e => $story->_get($e));
    }
    
    # set active flag
    $writer->dataElement(active => ($story->is_active ? 1 : 0));
    
    # get source name
    my $src = Bric::Biz::Org::Source->lookup({
					      id => $story->get_source__id });
    die __PACKAGE__ . "::export : unable to find source\n"
	unless $src;
    $writer->dataElement(source => $src->get_source_name);
    
    # get dates and output them in dateTime format
    for my $name qw(cover_date expire_date publish_date) {
	my $date = $story->_get($name);
	next unless $date; # skip missing date
	my $xs_date = db_date_to_xs_date($date);
	die __PACKAGE__ . "::export : bad date format for $name : $date\n"
	    unless defined $xs_date;
	$writer->dataElement($name, $xs_date);

    }
    
    # output categories
    $writer->startTag("categories");
    my $cat = $story->get_primary_category();
    $writer->dataElement(category => $cat->ancestry_path, primary => 1);
    foreach $cat ($story->get_secondary_categories) {
	$writer->dataElement(category => $cat->ancestry_path);
    }
    $writer->endTag("categories");

    # output keywords
    $writer->startTag("keywords");
    foreach my $k ($story->get_keywords) {
	$writer->dataElement(keyword => $k->get_name);
    }
    $writer->endTag("keywords");

    # output contributors
    $writer->startTag("contributors");
    foreach my $c ($story->get_contributors) {
	my $p = $c->get_person;
	$writer->startTag("contributor");
	$writer->dataElement(fname  => $p->get_fname);
	$writer->dataElement(mname  => $p->get_mname);
	$writer->dataElement(lname  => $p->get_lname);
	$writer->dataElement(type   => $c->get_grp->get_name);
	$writer->dataElement(role   => $story->get_contributor_role($c));
	$writer->endTag("contributor");
    }
    $writer->endTag("contributors");

    # output elements
    @related = serialize_elements(writer => $writer, 
				  args   => $options{args},
				  object => $story);
    
    # close the story
    $writer->endTag("story");    
    
    return @related;
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
