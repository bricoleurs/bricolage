package Bric::SOAP::Category;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Category;
use Bric::Biz::Keyword;
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use IO::Scalar;
use XML::Writer;

use Bric::SOAP::Util qw(parse_asset_document);

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Element - SOAP interface to Bricolage element definitions.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-03-08 06:35:43 $

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

  # set uri for Category module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Category');

  # get a list of all categories
  my $category_ids = $soap->list_ids()->result;
  
=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage categories.

=cut

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching categories and returns a
list of ids.  If no categories are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The category's name.

=item directory (M)

The category's directory, the last element in the path.

=item path

The category's complete path from the root.

=item parent

The category's parent, complete path from the root.

=item active

Set false to return deleted categories.

=back 4

Throws: NONE

Side Effects: NONE

Notes: Neither parent searches nor path searches may be combined with
other searches.  This is because the underlying list() method does not
support them directly.  Instead they are emulated at the SOAP level
and as such do not benefit from SQL's OR of search parameters.  This
should be fixed by adding them to the underlying list().

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(name directory path parent active);

sub list_ids {
    my $self = shift;
    my $env = pop;
    my $args = $env->method || {};    
    my @cat_ids;
    
    print STDERR __PACKAGE__ . "->list_ids() called : args : ", 
	Data::Dumper->Dump([$args],['args']) if DEBUG;
    
    # check for bad parameters
    for (keys %$args) {
	die __PACKAGE__ . "::list_ids : unknown parameter \"$_\".\n"
	    unless exists $allowed{$_};
    }
    
    # check for path or parent combined with other searches
    die __PACKAGE__ . "::list_ids : illegal combination of parent search ".
	"with other search terms.\n"
	    if $args->{parent} and keys(%$args) > 1;
    die __PACKAGE__ . "::list_ids : illegal combination of path search ".
	"with other search terms.\n"
	    if $args->{path} and keys(%$args) > 1;

    # perform emulated searches
    if ($args->{parent} or $args->{path}) {
	my $to_find = $args->{parent} ? $args->{parent} : $args->{path};
	my $return_children = exists $args->{parent};

	my @list = Bric::Biz::Category->list();
	foreach my $cat (@list) {
	    if ($cat->ancestry_path eq $to_find) {
		if ($return_children) {
		    push(@cat_ids, map { $_->get_id } $cat->children);
		} else {
		    push(@cat_ids, $cat->get_id);
		}
	    }
	}

    } else { 
	# normal searches pass through to list
    	@cat_ids = map { $_->get_id } Bric::Biz::Category->list($args);
    }
    
    
    # name the results
    my @result = map { name(category_id => $_) } @cat_ids;
    
    # name the array and return
    return name(category_ids => \@result);
}
}

=item export

The export method retrieves a set of categories from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item category_id

Specifies a single category_id to be retrieved.

=item category_ids

Specifies a list of category_ids.  The value for this option should be an
array of interger "category_id" categories.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(category_id category_ids);

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
    
    # category_id is sugar for a one-category category_ids arg
    $args->{category_ids} = [ $args->{category_id} ] 
      if exists $args->{category_id};
    
    # make sure category_ids is an array
    die __PACKAGE__ . "::export : missing required category_id(s) setting.\n"
 	unless defined $args->{category_ids};
    die __PACKAGE__ . "::export : malformed category_id(s) setting.\n"
 	unless ref $args->{category_ids} and 
	    ref $args->{category_ids} eq 'ARRAY';
    
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
    
    
    # iterate through category_ids, serializing category objects as we go
    foreach my $category_id (@{$args->{category_ids}}) {	
      $pkg->_serialize_category(writer      => $writer, 
				category_id  => $category_id,
				args        => $args);
  }
    
    # end the assets category and end the document
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

=item $pkg->_serialize_category(writer => $writer, category_id => $category_id, args => $args)

Serializes a single category object into a <category> category using
the given writer and args.

=cut

sub _serialize_category {
    my $pkg         = shift;
    my %options     = @_;
    my $category_id  = $options{category_id};
    my $writer      = $options{writer};

    my $category = Bric::Biz::Category->lookup({id => $category_id});
    die __PACKAGE__ . "::export : category_id \"$category_id\" not found.\n"
	unless $category;

    die __PACKAGE__ . 
	"::export : access denied for category \"$category_id\".\n"
	    unless chk_authz($category, READ, 1);
    
    # open a category category
    $writer->startTag("category", id => $category_id);

    # write out simple categories in schema order
    $writer->dataElement(name        => $category->get_name());
    $writer->dataElement(description => $category->get_description());
    
    # write out path
    $writer->dataElement(path => $category->ancestry_path);
    
    # set active flag
    $writer->dataElement(active => ($category->is_active ? 1 : 0));

    # output adstrings
    $writer->dataElement(adstring => $category->get_ad_string);
    $writer->dataElement(adstring2 => $category->get_ad_string2);

    # output keywords
    $writer->startTag("keywords");
    foreach my $k ($category->keywords) {
	$writer->dataElement(keyword => $k->get_name);
    }
    $writer->endTag("keywords");

    # close the category
    $writer->endTag("category");    
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
