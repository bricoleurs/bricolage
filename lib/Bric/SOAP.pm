package Bric::SOAP;

our $VERSION = (qw$Revision: 1.17 $ )[-1];

# load em' up
use Bric::SOAP::Handler;
use Bric::SOAP::Story;
use Bric::SOAP::Media;
use Bric::SOAP::Template;
use Bric::SOAP::Workflow;

1;
__END__

=head1 NAME

Bric::SOAP - The Bricolage SOAP interface

=head1 VERSION

$Revision: 1.17 $

=head1 DATE

$Date: 2002-02-28 19:37:37 $

=head1 SYNOPSIS

  use Bric::SOAP;

=head1 DESCRIPTION

This module serves as a root class for the Bric::SOAP classes.  It
also contains the functional and technical specifications for the
Bricolage SOAP interface.

=head1 Functional Specification

The Bricolage SOAP interface will expose key Bricolage systems to
automation.  This section describes intended functionality -
implementation details are described below in the Technical
Specification section.

=head2 Supported Functionality

The Bricolage SOAP interface will support the following features: 

=over 4

=item * Stories and Media

Clients will be able to create new stories and media into the system.
Additionally, it will possible to update existing stories and media.
Clients will be able to export existing stories and media in the
format accepted for creation.  Finally, clients may delete stories or
media.

=item * Elements

Clients will be able to create, update, delete and export element
definitions.

=item * Templates

Clients will be able to create, update, delete and export templates.

=item * Workflow

Clients will be able to move stories and media between desks.  Clients
will be able to publish stories and media.  Clients will be able to
deploy templates.

=back

=head2 Use Cases

The functionality described above exposes a great deal power.  Here
are some potential use cases:

=over 4

=item * Importing Content From Legacy Systems

Using the Story and Media interfaces content can be moved from legacy
CMS systems into Bricolage.

=item * Automated Publishing

With access to workflow and publishing it will be simple to write an
auto-publishing daemon that publishes a selection of stories on a
schedule.

=item * Story and Media Synchronization

It is often desirable to move stories and media between instances of
Bricolage.  The SOAP interface could be used by a clients that
automatically synchronize stories in a group of Bricolage instances,
perhaps by category or some other selection criteria.

=item * Element and Template Distribution

A centrally-developed library of elements and templates has many
advantages.  With the SOAP interface it will be possible to
automatically update Bricolage instances with new versions of elements
and templates.

=item * XML Syndication

An XML syndication system could be written to pull stories from the
SOAP interface and transform them into the target XML DTD.
Syndication could also be accomplished using Output Channels and
templates.

=back

=head1 Technical Specification

This section describes the implementation of the Bricolage SOAP
functional specification described above.

=head2 Technologies

=over 4

=item SOAP

Bricolage will provide a SOAP 1.1 compatible interface.  See
http://www.w3.org/TR/SOAP for the SOAP specification.  The SOAP server
will use the SOAP::Lite ( http://www.soaplite.com ) implementation.
Clients may use any SOAP 1.1 compatible library although only
SOAP::Lite clients will be tested during development.

=item XML Schema

The format of XML documents used by the SOAP interface will be
specified in XML Schema format.  See http://www.w3.org/XML/Schema for
more information.  A first draft of the XML Schema for asset documents
is included below.

=back

=head2 Modules

The following modules will be created to support the SOAP interface.
See the documentation for each module for interface details including
XML Schemas and SOAP client examples.

=over 4

=item L<Bric::SOAP::Handler|Bric::SOAP::Handler>

This module provides the Apache/mod_perl SOAP handler.  It is
responsible for dispatching requests to individual Bric::SOAP modules.

=item L<Bric::SOAP::Auth|Bric::SOAP::Auth>

Handles authentication for SOAP clients.  Authentication will be
cookie-based - clients will call a login() function and get an HTTP
cookie to use with calls to the other SOAP interfaces.

=item L<Bric::SOAP::Story|Bric::SOAP::Story>

Provides query, export, update, create and delete for Story objects.

=item L<Bric::SOAP::Media|Bric::SOAP::Media>

Provides query, export, update, create and delete for Media objects.

=item L<Bric::SOAP::Template|Bric::SOAP::Template>

Provides query, export, update, create and delete for Templates.

=item Bric::SOAP::Element B<[Not Yet Implemented]>

Provides query, export, update, create and delete for Element definitions.

=item Bric::SOAP::Category B<[Not Yet Implemented]>

Provides query, export, update, create and delete for Category objects.

=item L<Bric::SOAP::Workflow|Bric::SOAP::Workflow>

Provides the ability to move Story, Media and Formatting objects
between desks, publish and deploy.

=back

=head2 SOAP Details

All the Bric::SOAP::* modules share a common SOAP serialization strategy
described here.

=head3 Namespace

The namespace for all Bric::SOAP calls is:

  http://bricolage.sourceforge.net

To specify a module within that namespace, append the pieces as path
components.  For example, to call methods in Bric::SOAP::Story use the
namespace:

  http://bricolage.sourceforge.net/Bric/SOAP/Story

For the SOAP::Lite users in the audience, this is the "uri" setting.

=head3 Parameters

All Bric::SOAP::* methods use a named-parameter style call.  This is
mapped to XML elements where the name is the name of the element and
the value is the value contained inside the element.  For example, a
Perl call like:

   Bric::SOAP::Story->list_ids(title => '%foo%', publish_status => 1);

Is called through SOAP as:

  <SOAP-ENV:Body>
    <namesp2:list_ids 
     xmlns:namesp2="http://bricolage.sourceforge.net/Bric/SOAP/Story">
      <title xsi:type="xsd:string">%foo%</title>
      <publish_status xsi:type="xsd:int">1</publish_status>
    </namesp2:list_ids>
  </SOAP-ENV:Body>

SOAP::Lite clients can generate this call using SOAP::Data::name() to
name the parameters:

  import SOAP::Data 'name';
  my $result = $soap->list_ids(name(title          => '%foo%'), 
                               name(publish_status => 1)       );

In most cases Perl doesn't distinguish between strings and numbers.
When writing a SOAP client you should feel free to type your
parameters in whatever way makes most sense in your implementation
language.

=head3 Return Values

All Bric::SOAP methods return a single named parameter.  If a method
needs to return multiple values then a SOAP array is returned
containing the values.  For example, Bric::SOAP::Story->list_ids()
returns a list of story ids in this structure:

  <namesp2:list_idsResponse 
   xmlns:namesp2="http://bricolage.sourceforge.net/Bric/SOAP/Story">
    <story_ids SOAP-ENC:arrayType="xsd:int[4]" xsi:type="SOAP-ENC:Array">
       <story_id xsi:type="xsd:int">1027</story_id>
       <story_id xsi:type="xsd:int">1028</story_id>
       <story_id xsi:type="xsd:int">1029</story_id>
       <story_id xsi:type="xsd:int">1030</story_id>
    </story_ids>
  </namesp2:list_idsResponse>

And an empty response returns an empty array:

  <namesp1:list_idsResponse 
   xmlns:namesp1="http://bricolage.sourceforge.net/Bric/SOAP/Story">
    <story_ids SOAP-ENC:arrayType="xsd:ur-type[0]" xsi:type="SOAP-ENC:Array"/>
  </namesp1:list_idsResponse>

SOAP::Lite clients can access this return as an array ref:

  my $story_ids = $response->result;
  foreach my $id (@$story_ids) {
    frobnicate($id);
  }

=head3 XML Document Encoding

The Bric::SOAP system uses complete XML documents as parameters and
return values to many methods (create() and export(), for example).
These documents must be encoded in Base64 for performance reasons.
See the PERFORMANCE section of the L<SOAP::Lite|SOAP::Lite>
documentation for a full explanation of why this is neccessary.  This
is not a limitation of SOAP::Lite in particular but the explanation is
particularily lucid.

For SOAP::Lite clients generating Base64 parameters is very easy:

   my $document = name(document => $xml)->type('base64');

And on decoding returned base64 will be done automatically.

The XML Schema for these documents is included below.

=head3 Error Handling

Errors are returned as SOAP faults using fault strings produced by the
method called.  If you use SOAP::Lite as your client library you can
check for errors using the fault() method and access the error message
with faultstring():

  my $response = $soap->list_ids(...);
  die "SOAP Error: " . $response->faultstring if $response->fault;

=head2 XML Schema For Asset Documents

This is the XML Schema for asset documents used in the Bricolage SOAP
interface.  A pretty-printed version complete with colorful graphs
generated by XMLSpy can be found at:

   http://bricolage.thepirtgroup.com/soap_schema/assets.html

The XSD source:

 <?xml version="1.0" encoding="UTF-8"?>
 <xs:schema targetNamespace="http://bricolage.sourceforge.net/assets.xsd" xmlns="http://bricolage.sourceforge.net/assets.xsd" xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">
   <xs:element name="assets">
     <xs:annotation>
       <xs:documentation>a set of Bricolage assets</xs:documentation>
     </xs:annotation>
     <xs:complexType mixed="0">
       <xs:sequence maxOccurs="unbounded">
	 <xs:element name="story" minOccurs="0" maxOccurs="unbounded">
	   <xs:complexType>
	     <xs:sequence>
	       <xs:element name="name">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="256"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="description">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="1024"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="slug">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="64"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="primary_uri">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="128"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="priority">
		 <xs:simpleType>
		   <xs:restriction base="xs:int">
		     <xs:minInclusive value="1"/>
		     <xs:maxInclusive value="5"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="publish_status" type="xs:boolean"/>
	       <xs:element name="active" type="xs:boolean"/>
	       <xs:element name="source">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="128"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="cover_date" type="xs:dateTime"/>
	       <xs:element name="expire_date" type="xs:dateTime" minOccurs="0">
		 <xs:annotation>
		   <xs:documentation>ommited if no expire date</xs:documentation>
		 </xs:annotation>
	       </xs:element>
	       <xs:element name="publish_date" type="xs:dateTime" minOccurs="0">
		 <xs:annotation>
		   <xs:documentation>ommited if not published</xs:documentation>
		 </xs:annotation>
	       </xs:element>
	       <xs:element name="categories">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="category" maxOccurs="unbounded">
		       <xs:complexType>
			 <xs:simpleContent>
			   <xs:extension base="xs:string">
			     <xs:attribute name="primary" type="xs:boolean" use="optional"/>
			   </xs:extension>
			 </xs:simpleContent>
		       </xs:complexType>
		     </xs:element>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	       <xs:element name="keywords">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="keyword" type="xs:string" minOccurs="0" maxOccurs="unbounded">
		       <xs:annotation>
			 <xs:documentation>This is just a list of keyword names. if we ever start using the full capabilities of Bric::Biz::Keyword then this will need expansion.  It would probably make sense to do a Bric::SOAP::Keyword in that case.</xs:documentation>
		       </xs:annotation>
		     </xs:element>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	       <xs:element name="contributors">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="contributor" minOccurs="0" maxOccurs="unbounded">
		       <xs:annotation>
			 <xs:documentation>This is incomplete...  Either this element should be expanded to properly serialize all the available contributor data or it should reference a top-level contributor element serviced by Bric::SOAP::Contrib.</xs:documentation>
		       </xs:annotation>
		       <xs:complexType>
			 <xs:sequence>
			   <xs:element name="fname" type="xs:string"/>
			   <xs:element name="mname" type="xs:string"/>
			   <xs:element name="lname" type="xs:string"/>
			   <xs:element name="type" type="xs:string"/>
			   <xs:element name="role" type="xs:string"/>
			 </xs:sequence>
		       </xs:complexType>
		     </xs:element>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	       <xs:element name="elements">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="data" minOccurs="0" maxOccurs="unbounded">
		       <xs:complexType>
			 <xs:simpleContent>
			   <xs:extension base="xs:string">
			     <xs:attribute name="element" type="xs:string" use="required"/>
			     <xs:attribute name="order" type="xs:int" use="required"/>
			   </xs:extension>
			 </xs:simpleContent>
		       </xs:complexType>
		     </xs:element>
		     <xs:element name="container" type="container_type" minOccurs="0" maxOccurs="unbounded"/>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	     </xs:sequence>
	     <xs:attribute name="element" type="xs:string" use="required"/>
	     <xs:attribute name="id" type="xs:int" use="required"/>
	   </xs:complexType>
	 </xs:element>
	 <xs:element name="media" minOccurs="0" maxOccurs="unbounded">
	   <xs:complexType>
	     <xs:sequence>
	       <xs:element name="name">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="256"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="description">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="1024"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="uri">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="128"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="priority">
		 <xs:simpleType>
		   <xs:restriction base="xs:int">
		     <xs:minInclusive value="1"/>
		     <xs:maxInclusive value="5"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="publish_status" type="xs:boolean"/>
	       <xs:element name="active" type="xs:boolean"/>
	       <xs:element name="source">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="128"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="cover_date" type="xs:dateTime"/>
	       <xs:element name="expire_date" type="xs:dateTime" minOccurs="0">
		 <xs:annotation>
		   <xs:documentation>ommited if no expire date</xs:documentation>
		 </xs:annotation>
	       </xs:element>
	       <xs:element name="publish_date" type="xs:dateTime" minOccurs="0">
		 <xs:annotation>
		   <xs:documentation>ommited if not published</xs:documentation>
		 </xs:annotation>
	       </xs:element>
	       <xs:element name="category" type="xs:string"/>
	       <xs:element name="contributors">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="contributor" minOccurs="0" maxOccurs="unbounded">
		       <xs:annotation>
			 <xs:documentation>This is incomplete...  Either this element should be expanded to properly serialize all the available contributor data or it should reference a top-level contributor element serviced by Bric::SOAP::Contrib.</xs:documentation>
		       </xs:annotation>
		       <xs:complexType>
			 <xs:sequence>
			   <xs:element name="fname" type="xs:string"/>
			   <xs:element name="mname" type="xs:string"/>
			   <xs:element name="lname" type="xs:string"/>
			   <xs:element name="type" type="xs:string"/>
			   <xs:element name="role" type="xs:string"/>
			 </xs:sequence>
		       </xs:complexType>
		     </xs:element>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	       <xs:element name="elements">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="data" minOccurs="0" maxOccurs="unbounded">
		       <xs:complexType>
			 <xs:simpleContent>
			   <xs:extension base="xs:string">
			     <xs:attribute name="element" type="xs:string" use="required"/>
			     <xs:attribute name="order" type="xs:int" use="required"/>
			   </xs:extension>
			 </xs:simpleContent>
		       </xs:complexType>
		     </xs:element>
		     <xs:element name="container" type="container_type" minOccurs="0" maxOccurs="unbounded"/>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	       <xs:element name="file" minOccurs="0">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="name">
		       <xs:simpleType>
			 <xs:restriction base="xs:string">
			   <xs:maxLength value="256"/>
			 </xs:restriction>
		       </xs:simpleType>
		     </xs:element>
		     <xs:element name="size">
		       <xs:simpleType>
			 <xs:restriction base="xs:integer">
			   <xs:minInclusive value="0"/>
			   <xs:maxInclusive value="9999999999"/>
			 </xs:restriction>
		       </xs:simpleType>
		     </xs:element>
		     <xs:element name="data">
		       <xs:simpleType>
			 <xs:restriction base="xs:base64Binary">
			   <xs:minLength value="0"/>
			   <xs:maxLength value="9999999999"/>
			 </xs:restriction>
		       </xs:simpleType>
		     </xs:element>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	     </xs:sequence>
	     <xs:attribute name="element" type="xs:string" use="required"/>
	     <xs:attribute name="id" type="xs:int" use="required"/>
	   </xs:complexType>
	 </xs:element>
	 <xs:element name="template" minOccurs="0" maxOccurs="unbounded">
	   <xs:complexType>
	     <xs:sequence>
	       <xs:element name="element">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="64"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="generic" type="xs:boolean"/>
	       <xs:element name="file_name">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="256"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="description">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="1024"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="priority">
		 <xs:simpleType>
		   <xs:restriction base="xs:int">
		     <xs:minInclusive value="1"/>
		     <xs:maxInclusive value="5"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="deploy_status" type="xs:boolean"/>
	       <xs:element name="active" type="xs:boolean"/>
	       <xs:element name="category" type="xs:string"/>
	       <xs:element name="output_channel" type="xs:string"/>
	       <xs:element name="expire_date" type="xs:dateTime" minOccurs="0">
		 <xs:annotation>
		   <xs:documentation>ommited if no expire date</xs:documentation>
		 </xs:annotation>
	       </xs:element>
	       <xs:element name="deploy_date" type="xs:dateTime" minOccurs="0">
		 <xs:annotation>
		   <xs:documentation>ommited if not deployed</xs:documentation>
		 </xs:annotation>
	       </xs:element>
	       <xs:element name="data" type="xs:base64Binary" minOccurs="0"/>
	     </xs:sequence>
	     <xs:attribute name="id" type="xs:int" use="required"/>
	   </xs:complexType>
	 </xs:element>
	 <xs:element name="element" minOccurs="0" maxOccurs="unbounded">
	   <xs:complexType>
	     <xs:sequence>
	       <xs:element name="name">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="64"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="description">
		 <xs:simpleType>
		   <xs:restriction base="xs:string">
		     <xs:maxLength value="256"/>
		   </xs:restriction>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="burner">
		 <xs:simpleType>
		   <xs:restriction base="xs:string"/>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="type">
		 <xs:simpleType>
		   <xs:restriction base="xs:string"/>
		 </xs:simpleType>
	       </xs:element>
	       <xs:element name="output_channels" minOccurs="0">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="output_channel" maxOccurs="unbounded">
		       <xs:complexType>
			 <xs:simpleContent>
			   <xs:extension base="xs:string">
			     <xs:attribute name="primary" type="xs:boolean" use="optional"/>
			   </xs:extension>
			 </xs:simpleContent>
		       </xs:complexType>
		     </xs:element>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	       <xs:element name="subelements">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="subelement" minOccurs="0" maxOccurs="unbounded">
		       <xs:simpleType>
			 <xs:restriction base="xs:string">
			   <xs:maxLength value="64"/>
			 </xs:restriction>
		       </xs:simpleType>
		     </xs:element>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	       <xs:element name="fields">
		 <xs:complexType>
		   <xs:sequence>
		     <xs:element name="field" minOccurs="0" maxOccurs="unbounded">
		       <xs:complexType>
			 <xs:sequence>
			   <xs:element name="type" type="xs:string"/>
			   <xs:element name="name" type="xs:string"/>
			   <xs:element name="label" type="xs:string"/>
			   <xs:element name="required" type="xs:boolean"/>
			   <xs:element name="repeatable" type="xs:boolean"/>
			   <xs:element name="default" type="xs:string" minOccurs="0"/>
			   <xs:element name="options" type="xs:string" minOccurs="0"/>
			   <xs:element name="multiple" type="xs:boolean" minOccurs="0"/>
			   <xs:element name="size" type="xs:int" minOccurs="0"/>
			   <xs:element name="max_size" type="xs:int" minOccurs="0"/>
			   <xs:element name="rows" type="xs:int" minOccurs="0"/>
			   <xs:element name="cols" type="xs:int" minOccurs="0"/>
			 </xs:sequence>
		       </xs:complexType>
		     </xs:element>
		   </xs:sequence>
		 </xs:complexType>
	       </xs:element>
	     </xs:sequence>
	     <xs:attribute name="id" type="xs:integer" use="required"/>
	   </xs:complexType>
	 </xs:element>
       </xs:sequence>
     </xs:complexType>
   </xs:element>
   <xs:complexType name="container_type" mixed="0">
     <xs:annotation>
       <xs:documentation>An element data container - a recursive type.</xs:documentation>
     </xs:annotation>
     <xs:sequence>
       <xs:element name="data" minOccurs="0" maxOccurs="unbounded">
	 <xs:complexType>
	   <xs:simpleContent>
	     <xs:extension base="xs:string">
	       <xs:attribute name="element" type="xs:string" use="required"/>
	       <xs:attribute name="order" type="xs:int" use="required"/>
	     </xs:extension>
	   </xs:simpleContent>
	 </xs:complexType>
       </xs:element>
       <xs:element name="container" minOccurs="0" maxOccurs="unbounded">
	 <xs:complexType>
	   <xs:complexContent>
	     <xs:extension base="container_type"/>
	   </xs:complexContent>
	 </xs:complexType>
       </xs:element>
     </xs:sequence>
     <xs:attribute name="element" type="xs:string" use="required"/>
     <xs:attribute name="order" type="xs:int" use="required"/>
     <xs:attribute name="related_story_id" type="xs:int" use="optional"/>
     <xs:attribute name="related_media_id" type="xs:int" use="optional"/>
     <xs:attribute name="relative" type="xs:boolean" use="optional"/>
   </xs:complexType>
 </xs:schema>


=head2 Example Asset Documents

Here's a simple story with some keywords and no contributors:

 <?xml version="1.0" encoding="UTF-8" standalone="yes"?>

 <assets xmlns="http://bricolage.sourceforge.net/assets.xsd">
  <story id="1024" element="Story">
   <name>Story One</name>
   <description>a description of story one</description>
   <slug>one</slug>
   <primary_uri>/2002/01/29/one</primary_uri>
   <priority>3</priority>
   <publish_status>0</publish_status>
   <active>1</active>
   <source>Internal</source>
   <cover_date>2002-01-29T20:02:00Z</cover_date>
   <categories>
    <category primary="1">/</category>
   </categories>
   <keywords>
    <keyword>key one</keyword>
    <keyword>key two</keyword>
   </keywords>
   <contributors></contributors>
   <elements>
    <data order="1" element="Deck">deck one</data>
    <container order="1" element="Page">
     <data order="1" element="Paragraph">para one</data>
     <data order="2" element="Paragraph">para two</data>
     <container order="1" element="Inset">
      <data order="1" element="Copy">inset copy</data>
     </container>
    </container>
   </elements>
  </story>
 
=head2 Example Clients

A few example clients will be developed.

=over 4

=item Command-Line Client

This script - bric_soap - will provide command-line access to all
available SOAP methods.  For more information read the bric_soap
manual by running:

  bric_soap --man

or, if Bricolage's bin directory isn't in your path:

  /usr/local/bricolage/bin/bric_soap --man

=item Auto-Publisher

A script that publishes a set of stories based on a simple criteria
entered on the command line.  Will be designed to be used from cron.

B<NOT YET IMPLEMENTED>

=item Dev Sync Tool

A script that grabs the element tree and templates from a source
server and updates a list of target servers to match.

B<NOT YET IMPLEMENTED>

=item Story Migration Tool

A script that copies stories and all their dependencies (media, other
stories) from one bricolage sever to another.

B<NOT YET IMPLEMENTED>

=back

=head1 SEE ALSO

L<Bric::SOAP::Handler|Bric::SOAP::Handler>

L<Bric::SOAP::Auth|Bric::SOAP::Auth>

L<Bric::SOAP::Story|Bric::SOAP::Story>

L<Bric::SOAP::Media|Bric::SOAP::Media>

L<Bric::SOAP::Template|Bric::SOAP::Template>

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=cut
