package Bric::SOAP::Element;
###############################################################################

use strict;
use warnings;

use Bric::Biz::AssetType;
use Bric::Biz::ATType;
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use IO::Scalar;
use XML::Writer;

use Bric::SOAP::Util qw(parse_asset_document);

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 1;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Element - SOAP interface to Bricolage element definitions.

=head1 VERSION

$Revision: 1.2 $

=cut

our $VERSION = (qw$Revision: 1.2 $ )[-1];

=head1 DATE

$Date: 2002-03-02 08:43:18 $

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

  # set uri for Element module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Element');

  # get a list of all elements
  my $element_ids = $soap->list_ids()->result;
  
=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage elements.

=cut

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching elements and returns a
list of ids.  If no elements are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The element's name.

=item description (M)

The element's description.

=item output_channel

The output channel for the element.

=item type

The element's type.

=item top_level

set to 1 to return only top-level elements

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(name description output_channel
				 type top_level);

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
    
    # handle type => type__id mapping
    if (exists $args->{type}) {
	my ($type_id) = Bric::Biz::ATType->list_ids(
				 { name => $args->{type} });
	die __PACKAGE__ . "::list_ids : no type found matching " .
	    "(type => \"$args->{type}\")\n"
		unless defined $type_id;
	$args->{type__id} = $type_id;
	delete $args->{type};
    }

    # handle output_channel => output_channel__id mapping
    if (exists $args->{output_channel}) {
	my ($output_channel_id) = Bric::Biz::OutputChannel->list_ids(
			        { name => $args->{output_channel} });
	die __PACKAGE__ . "::list_ids : no output_channel found matching " .
	    "(output_channel => \"$args->{output_channel}\")\n"
		unless defined $output_channel_id;

	# strangely, AssetType->list() calls this output_channel, not
	# output_channel__id like the rest of Bric
	$args->{output_channel} = $output_channel_id;
    }
    
    my @list = Bric::Biz::AssetType->list_ids($args);
    
    print STDERR "Bric::Biz::Asset::Formatting->list_ids() called : ",
	"returned : ", Data::Dumper->Dump([\@list],['list'])
	    if DEBUG;
    
    # name the results
    my @result = map { name(element_id => $_) } @list;
    
    # name the array and return
    return name(element_ids => \@result);
}
}

=item export

The export method retrieves a set of elements from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item element_id

Specifies a single element_id to be retrieved.

=item element_ids

Specifies a list of element_ids.  The value for this option should be an
array of interger "element_id" elements.

=back 4

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(element_id element_ids);

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
    
    # element_id is sugar for a one-element element_ids arg
    $args->{element_ids} = [ $args->{element_id} ] 
      if exists $args->{element_id};
    
    # make sure element_ids is an array
    die __PACKAGE__ . "::export : missing required element_id(s) setting.\n"
 	unless defined $args->{element_ids};
    die __PACKAGE__ . "::export : malformed element_id(s) setting.\n"
 	unless ref $args->{element_ids} and ref $args->{element_ids} eq 'ARRAY';
    
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
    
    
    # iterate through element_ids, serializing element objects as we go
    foreach my $element_id (@{$args->{element_ids}}) {	
      $pkg->_serialize_element(writer      => $writer, 
			       element_id  => $element_id,
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

=back

=head2 Private Class Methods

=over 4

=item $pkg->_serialize_element(writer => $writer, element_id => $element_id, args => $args)

Serializes a single element object into a <element> element using
the given writer and args.

=cut

sub _serialize_element {
    my $pkg         = shift;
    my %options     = @_;
    my $element_id  = $options{element_id};
    my $writer      = $options{writer};

    my $element = Bric::Biz::AssetType->lookup({id => $element_id});
    die __PACKAGE__ . "::export : element_id \"$element_id\" not found.\n"
	unless $element;

    die __PACKAGE__ . 
	"::export : access denied for element \"$element_id\".\n"
	    unless chk_authz($element, READ, 1);
    
    # open a element element
    $writer->startTag("element", id => $element_id);

    # write out simple elements in schema order
    foreach my $e (qw(name description)) {
	$writer->dataElement($e => $element->_get($e));
    }
    
    # output burner.  It's unfortunate that this isn't a string.  This
    # is another piece of code that would need to be modified to add a
    # new burner...
    my $burner_id = $element->get_burner();
    if ($burner_id == Bric::Biz::AssetType::BURNER_MASON) {
	$writer->dataElement(burner => "Mason");
    } elsif ($burner_id == Bric::Biz::AssetType::BURNER_TEMPLATE) {
	$writer->dataElement(burner => "HTML::Template");
    } else {
	die __PACKAGE__ . "::export : unknown burner \"$burner_id\" ".
	    "for element \"$element_id\".\n";
    }

    # get type name
    $writer->dataElement(type => $element->get_type_name);
    
    # set active flag
    $writer->dataElement(active => ($element->is_active ? 1 : 0));

    # set top_level stuff if top_level
    if ($element->get_top_level) {
	$writer->dataElement(top_level => 1);
	$writer->startTag("output_channels");
	foreach my $oc ($element->get_output_channels) {
	    $writer->dataElement(output_channel => $oc->get_name);
	}
	$writer->endTag("output_channels");
    } else {
	$writer->dataElement(top_level => 0);
    }
    
    # output subelements
    $writer->startTag("subelements");
    foreach ($element->get_containers) {
	$writer->dataElement(subelement => $_->get_name);
    }
    $writer->endTag("subelements");

    # output fields
    $writer->startTag("fields");
    foreach my $data ($element->get_data) {
	my $meta = $data->get_meta('html_info');
	# print STDERR Data::Dumper->Dump([$meta, $data], [qw(meta data)]) 
	#    if DEBUG;

	# start <field>
	$writer->startTag("field");

	# required elements
	$writer->dataElement(type  => $meta->{type});
	$writer->dataElement(name  => $data->get_name);
	$writer->dataElement(label => $meta->{disp});
	$writer->dataElement(required   => $data->get_required   ? 1 : 0);
	$writer->dataElement(repeatable => $data->get_quantifier ? 1 : 0);
	
	# optional elements
	$writer->dataElement(default  => $meta->{value}) 
	    if defined $meta->{value}    and length $meta->{value};
	$writer->dataElement(options  => $meta->{vals})  
	    if defined $meta->{vals}     and length $meta->{vals};
	$writer->dataElement(multiple => $meta->{multiple} ? 1 : 0)  
	    if defined $meta->{multiple} and length $meta->{multiple};
	$writer->dataElement(size     => $meta->{length})
	    if defined $meta->{length}   and length $meta->{length};
	$writer->dataElement(max_size => $data->get_max_length)
	    if $data->get_max_length;
	$writer->dataElement(rows     => $meta->{rows}) 
	    if defined $meta->{rows}     and length $meta->{rows};
	$writer->dataElement(cols     => $meta->{cols}) 
	    if defined $meta->{cols}     and length $meta->{cols};

	# end <field>
	$writer->endTag("field");
    }

    $writer->endTag("fields");


    # close the element
    $writer->endTag("element");    
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
