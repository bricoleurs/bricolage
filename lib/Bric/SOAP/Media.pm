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
use XML::Writer;
use IO::Scalar;
use Carp qw(croak);
use MIME::Base64;

use Bric::SOAP::Util qw(category_path_to_id 
			xs_date_to_pg_date pg_date_to_xs_date
			parse_asset_document
			serialize_elements
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

$Revision: 1.2 $

=cut

our $VERSION = (qw$Revision: 1.2 $ )[-1];

=head1 DATE

$Date: 2002-02-08 01:05:30 $

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

=item simple (M)

A single OR search that hits title, description and uri.

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

Notes: Some obvious options are missing - category, file_name and the
SQL tweaking paramters (Order, Limit, etc.) in Bric::SOAP::Story most
obviously.  We should add them to
Bric::Biz::Asset::Business::Media->list() and then support them here
too.

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(title description
				 simple uri priority
				 workflow element
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

=back

=head2 Private Class Methods

=over 4

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
	my $xs_date = pg_date_to_xs_date($date);
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
