package Bric::SOAP::Story;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::AssetType;
use Bric::Biz::Category;
use XML::Writer;
use IO::Scalar;

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 1;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Story - SOAP interface to Bricolage stories.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-01-11 22:55:18 $

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
exact string to match.

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
	Data::Dumper->Dump([$args],['args'])
		if DEBUG;
    
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
	# look through categories for one that matches.  might want to
	# find a more efficient method someday, although this is
	# unlikely to be a bottleneck.
	my $category_id;
	foreach my $cat (Bric::Biz::Category->list()) {
	    if ($cat->ancestry_path eq $args->{category}) {
		$category_id = $cat->get_id;
		last;
	    }
	}
	die __PACKAGE__ . "::list_ids : no category found matching " .
	    "(category => \"$args->{category}\")\n"
		unless defined $category_id;
	$args->{category_id} = $category_id;
	delete $args->{category};      
    }
    
    # translate dates into proper format
    for my $name (grep { /_date_/ } keys %$args) {
	print STDERR  __PACKAGE__ . "::list_ids : $name : $args->{$name}\n"
	    if DEBUG;
	
	my ($CC, $YY, $MM, $DD, $hh, $mm, $ss, $tz) =  $args->{$name} =~
	    /^(\d\d)(\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(.*)$/;
	die __PACKAGE__ . "::list_ids : bad date format for $name parameter " .
	    "\"$args->{$name}\" : must be proper XML Schema dateTime format.\n"
		unless $CC;
	$tz = 'UTC' if defined $tz and $tz eq 'Z';
	
	# format for postrges
	$args->{$name} = $CC . $YY . '-' . $MM . '-' . $DD . ' ' . 
	                 $hh . ':' . $mm . ':' . $ss . 
	                 (defined $tz ? (' ' . $tz) : '');
	
	print STDERR  __PACKAGE__ . "::list_ids : $name : $args->{$name}\n"
	    if DEBUG;
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

=item export_media

If set to 1 any related media attached to the story will be included
in the exported document.  The story will refer to these included
media objects using the relative form of related-media linking.  (see
the XML Schema document in L<Bric::SOAP|Bric::SOAP> for
details)

=item export_related

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
				 export_media export_related);

sub export {
    my $self = shift;
    our $ef;
    my $env = pop;
    my $args = $env->method || {};    
    
    print STDERR __PACKAGE__ . "->export() called : args : ", 
	Data::Dumper->Dump([$args],['args'])
		if DEBUG;
    
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
		       

    # iterate through story_ids, serializing as we go
    my @story_ids = @{$args->{story_ids}};
    while(my $story_id = shift @story_ids) {
	my $story = Bric::Biz::Asset::Business::Story->lookup({
                                               id => $story_id});
	die __PACKAGE__ . "::export : story_id \"$story_id\" not found.\n"
	    unless $story;
	  
	# open a story element
	$writer->startTag("story", 
			  id => $story_id, 
			  element => $story->get_element_name);
	
	# write out simple elements in schema order
	foreach my $e (qw(name description slug primary_uri
			  priority publish_status active   )) {
	    $writer->dataElement($e => $story->_get($e));
	}

	# close the story
	$writer->endTag("story");
    }

    # end the assets element and end the document
    $writer->endTag("assets");
    $writer->end();
    $document_handle->close();

    # name, type and return
    return name(document => $document)->type('base64');   
}
}

=item import

The import method creates new objects using the data contained in an
XML document of the format created by export().  Returns 1 on success.

Available options:

=over 4

=item document (required)

The XML document containing objects to be imported.  The document must
contain at least one story and may contain any number of related media
objects.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=item update

The update method updates stories using the data in an XML document
of the format created by export().  A common use of update() is to
export() a selected story, make changes to one or more fields and
then submit the changes with update(). 

Returns "1" on success, "0" on failure.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be imported can be found.  The
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

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
