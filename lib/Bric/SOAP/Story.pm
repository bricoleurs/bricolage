package Bric::SOAP::Story;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::AssetType;
use Bric::Biz::Category;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Biz::Workflow qw(STORY_WORKFLOW);
use Bric::App::Session qw(:user);
use XML::Writer;
use IO::Scalar;
use Carp qw(croak);

use Bric::SOAP::Util qw(category_path_to_id 
			xs_date_to_pg_date pg_date_to_xs_date
			parse_asset_document
		       );

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Story - SOAP interface to Bricolage stories.

=head1 VERSION

$Revision: 1.7 $

=cut

our $VERSION = (qw$Revision: 1.7 $ )[-1];

=head1 DATE

$Date: 2002-01-31 01:02:33 $

=head1 SYNOPSIS

  use SOAP::Lite;
  import SOAP::Data 'name';

  # FIX: add connection details

  # get a list of story_ids for published stories with "foo" in their
  # title
  my $story_ids = $soap->list_ids(name(title          => '%foo%'), 
                                  name(publish_status => 1)     )->result;

  # FIX: add more examples  

=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage stories.

=cut

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

=item primary_uri (M)

The primary uri of the story.

=item priority

The priority of the story.

=item publish_status

Stories that have been published have a publish_status of "1",
otherwise "0".

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
				 workflow publish_status element
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
	my $date = xs_date_to_pg_date($args->{$name});
	die __PACKAGE__ . "::list_ids : bad date format for $name parameter " .
	    "\"$args->{$name}\" : must be proper XML Schema dateTime format.\n"
		unless defined $date;
	$args->{$name} = $date;
    }
    
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
    our $ef;
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

    # FIX: call out to serialize media here...

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

Returns a list of new ids created in the order of the assets in the
document.

Available options:

=over 4

=item document (required)

The XML document containing objects to be createed.  The document must
contain at least one story and may contain any number of related media
objects.

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
    our $ef;
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
    my $document = $args->{document};
    die __PACKAGE__ . "::create : missing required document parameter.\n"
      unless $document;

    # parse and catch erros
    my $data;
    eval { $data = parse_asset_document($document) };
    die __PACKAGE__ . "::create : problem parsing asset document : $@\n"
	if $@;
    die __PACKAGE__ . "::create : problem parsing asset document : no stories found!\n"
	unless ref $data and ref $data eq 'HASH' and exists $data->{story};
    print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;

    # loop over stories, filling in %story_ids and %relations
    my (%story_ids, @story_ids, %relations);
    foreach my $sdata (@{$data->{story}}) {
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

	# create empty story
	my $story = Bric::Biz::Asset::Business::Story->new(\%init);
	die __PACKAGE__ . "::create : failed to create empty story object."
	    unless $story;
	print STDERR __PACKAGE__ . "::create : created empty story object\n"
	    if DEBUG;

	# set simple fields
	my @simple_fields = qw(name description slug primary_uri
			       priority publish_status);
	$story->_set(\@simple_fields, [ @{$sdata}{@simple_fields} ]);

	# activate?
	$sdata->{active} ? $story->activate : $story->deactivate;

	# assign dates 
	for my $name qw(cover_date expire_date publish_date) {
	    my $date = $sdata->{$name};
	    next unless $date; # skip missing date
	    my $pg_date = xs_date_to_pg_date($date);
	    die __PACKAGE__ . "::export : bad date format for $name : $date\n"
		unless defined $pg_date;
	    $story->_set([$name],[$pg_date]);
	}

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

	# find a suitable workflow and desk for the story.  Might be
	# nice if Bric::Biz::Workflow->list took a type key...
	my $desk;
	foreach my $workflow (Bric::Biz::Workflow->list()) {
	    if ($workflow->get_type == STORY_WORKFLOW) {
		$story->set_workflow_id($workflow->get_id());
		$desk = $workflow->get_start_desk;
		$desk->accept({'asset' => $story});
		last;
	    }
	}

	# add element data
	if ($sdata->{elements}) {
	    $pkg->_load_element(element   => $story->get_tile, 
				data      => $sdata->{elements},
			        relations => \%relations);
	} else {
	    # load an empty set to create a really empty story
	    $pkg->_load_element(element   => $story->get_tile, 
				data      => {});
	}

	# save the story and desk after activating if desired
	$story->activate if $sdata->{active};
	$desk->save;
	$story->save;

	# this is what story_prof does - skipping this step results in
	# a story unstuck in time with version set to 0
	$story->checkin();
	$story->save();
	$story->checkout( { user__id => get_user_id });
	$story->save();

	# all done, setup the story_id
	push(@story_ids, $story_ids{$sdata->{id}} = $story->get_id);
    }
    
    return name(ids => [ map { name(id => $_) } @story_ids ]);
}
}

=item update

The update method updates stories using the data in an XML document
of the format created by export().  A common use of update() is to
export() a selected story, make changes to one or more fields and
then submit the changes with update(). 

Returns "1" on success, "0" on failure.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one story and may contain any number of
related media objects.

=item ids (required)

A list of "id" integers for the assets to be updated.  You must
provide exactly as many ids as there are assets in your document.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

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

=head2 Private Class Methods

=over 4

=item $pkg->_load_element(element   => $element,
			  data      => $sdata->{elements},
			  relations => \%relations);_load_container

Loads a container element with data from the data hash.  Calls
recursively down through containers.  Fills in a relations hash as it
goes containing data to fixup related media and related stories.  Dies
if it finds bad data.

Throws: NONE

Side Effects: NONE

Notes: This method isn't checking compliance with the asset type
constraints in some cases.  After Bric::SOAP::Element is done I should
contain the kung-fu necessary for this task.

=cut

sub _load_element {
    my $pkg       = shift;
    my %options   = @_;
    my $element   = $options{element};
    my $data      = $options{data}; 
    my $relations = $options{relations};
	
    # sanity check
    croak("Called _load_element on none container!")
	unless $element->is_container;
    
    # make sure we have an empty element - Story->new() helpfully (?)
    # creates empty data elements for required elements.
    if (my @e = $element->get_elements) {
	$element->delete_tiles(\@e);
	$element->save; # required for delete to "take"
    }

    # get lists of possible data types and possible containers that
    # can be added to this element.  Hash on names for quick lookups.
    my %valid_data      = map { ($_->get_name, $_) }
	$element->get_possible_data();
    my %valid_container = map { ($_->get_name, $_) } 
	$element->get_possible_containers();

    # load data elements
    if ($data->{data}) {
	foreach my $d (@{$data->{data}}) {
	    my $at = $valid_data{$d->{element}};
	    die "Error loading data element for " . 
		$element->get_element_name .
		    " cannot add data element $d->{element} here.\n"
			unless $at;

	    # add data to container
	    $element->add_data($at, $d->{content}, $d->{order});
	    $element->save; # I'm not sure why this is necessary after
                            # every add, but removing it causes errors
	}
    }	    

    # load containers
    if ($data->{container}) {
	foreach my $c (@{$data->{container}}) {
	    my $at = $valid_container{$c->{element}};
	    die "Error loading container element for " . 
		$element->get_element_name .
		    " cannot add data element $c->{element} here.\n"
			unless $at;

	    # setup container object
	    my $container = $element->add_container($at);
	    $container->set_place($c->{order});
	    $element->save; # I'm not sure why this is necessary after
                            # every add, but removing it causes errors
	    
	    # recurse
	    $pkg->_load_element(element   => $container,
				data      => $c,
				relations => $relations);
	}
    }				
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
	my $xs_date = pg_date_to_xs_date($date);
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


    # output element data
    $writer->startTag("elements");
    my $element = $story->get_tile();
    my @e = $element->get_elements;

    # first serialize all data elements
    foreach my $e (@e) {
	next if $e->is_container;
	push(@related, $pkg->_serialize_tile(writer  => $writer,
					     element => $e,
					     args    => $options{args},
					    ));	  
    }

    # then all containers
    foreach my $e (@e) {
	next unless $e->is_container;
	push(@related, $pkg->_serialize_tile(writer  => $writer,
					     element => $e,
					     args    => $options{args},
					    ));	  
    }
    $writer->endTag("elements");
    
    # close the story
    $writer->endTag("story");    
    
    return @related;
}

=item @related = $pkg->_serialize_tile(writer => $writer, element => $element, args => $args)

Serializes a single tile, called recursively on containers.  Returns a
list of two-element arrays - [ "media", $id ] or [ "story", $id ].
These are the related media objects serialized.

=cut

sub _serialize_tile {
    my $pkg      = shift;
    my %options  = @_;
    my $element  = $options{element};
    my $writer   = $options{writer};
    my @related;
    
    if ($element->is_container) {
	my %attr  = (element => $element->get_element_name,
		     order   => $element->get_place);
	my @e = $element->get_elements();
	
	# look for related stuff and tag relative if we'll include in
	# the assets dump.
	my ($related_story, $related_media);
	if ($related_story = $element->get_related_story) {
	    $attr{related_story_id} = $related_story->get_id;
	    if ($options{args}{export_related_stories}) {
		$attr{relative} = 1;
		push(@related, [ story => $attr{related_story_id} ]);
	    }
	} elsif ($related_media = $element->get_related_media) {
	    $attr{related_media_id} = $related_media->get_id;
	    if ($options{args}{export_related_media}) {
		$attr{relative} = 1;
		push(@related, [ media => $attr{related_story_id} ]);
	    }
	}
	
	if (@e) {
	    # recurse over contained elements
	    $writer->startTag("container", %attr);

	    # first serialize all data elements
	    foreach my $e (@e) {
		next if $e->is_container;
		push(@related, $pkg->_serialize_tile(writer  => $writer,
						     element => $e,
						     args    => $options{args},
						    ));	  
	    }

	    # then all containers
	    foreach my $e (@e) {
		next unless $e->is_container;
		push(@related, $pkg->_serialize_tile(writer  => $writer,
						     element => $e,
						     args    => $options{args},
						    ));	  
	    }

	    $writer->endTag("container");
	} else {
	    # produce clean empty tag
	    $writer->emptyTag("container", %attr);
	}
    } else {
	# data elements
	my $data = $element->get_data;
	if (defined $data and length $data) {
	    $writer->dataElement("data", $data,
				 element => $element->get_element_name,
				 order   => $element->get_place);
	} else {
	    $writer->emptyTag("data", 
			      element => $element->get_element_name,
			      order   => $element->get_place);
	}
    }

    return @related;
}


=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
