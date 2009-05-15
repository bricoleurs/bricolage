package Bric::SOAP;

require Bric; our $VERSION = Bric->VERSION;

# load em' up
use Bric::SOAP::Handler;
use Bric::SOAP::Story;
use Bric::SOAP::Media;
use Bric::SOAP::Template;
use Bric::SOAP::Workflow;
use Bric::SOAP::ATType;
use Bric::SOAP::Category;
use Bric::SOAP::MediaType;
use Bric::SOAP::Site;
use Bric::SOAP::Keyword;
use Bric::SOAP::User;
use Bric::SOAP::Desk;
use Bric::SOAP::ElementType;
use Bric::SOAP::OutputChannel;
use Bric::SOAP::ContribType;
use Bric::SOAP::Destination;
use Bric::SOAP::Preference;

1;
__END__

=head1 Name

Bric::SOAP - The Bricolage SOAP interface

=head1 Synopsis

  use Bric::SOAP;

=head1 Description

This module serves as a root class for the Bric::SOAP classes. It also
contains the functional and technical specifications for the Bricolage SOAP
interface.

=head1 Functional Specification

The Bricolage SOAP interface expose key Bricolage systems to automation. This
section describes intended functionality -- implementation details are
described below in the
L<Technical Specification section|"Technical Specification">.

=head2 Supported Functionality

The Bricolage SOAP interface supports the following features:

=over 4

=item Stories and Media

Clients can create new stories and media and update existing stories and media
in the system. Clients can also export existing stories and media in the
format accepted for creation. Finally, clients may delete stories or media.

=item Element Types

Clients can create, update, delete and export element types.

=item Templates

Clients can create, update, delete and export templates.

=item Workflow

Clients can move stories and media between desks. Clients can also publish
stories and media and deploy templates.

=back

=head2 Use Cases

The functionality described above exposes a great deal power.  Here
are some potential use cases:

=over 4

=item Importing Content From Legacy Systems

Using the Story and Media interfaces, content can be moved from legacy CMS
systems into Bricolage.

=item Automated Publishing

With access to workflow and publishing, one can write an auto-publishing
daemon that publishes a selection of stories on a schedule.

=item Story and Media Synchronization

It is often desirable to move stories and media between instances of
Bricolage. The SOAP interface can be used by a clients to automatically
synchronize stories and media in a group of Bricolage instances.
Synchronization can be made according to selection criteria similar to that
exposed by the C<list()> method in Bricolage classes.

=item Element and Template Distribution

A centrally-developed library of elements and templates has many advantages.
With the SOAP interface, one can automatically update Bricolage instances with
new versions of elements and templates.

=item XML Syndication

An XML syndication system can be written to pull stories from the SOAP
interface and transform them into the target XML DTD. Syndication can also
be accomplished using output channels and templates.

=back

=head1 Technical Specification

This section describes the implementation of the Bricolage SOAP functional
specification described above.

=head2 Technologies

=over 4

=item SOAP

Bricolage provides a SOAP 1.1 compatible interface. See
L<http://www.w3.org/TR/SOAP> for the SOAP specification. The SOAP server uses
use the SOAP::Lite (L<http://www.soaplite.com>) for its SOAP implementation.
Clients may use any SOAP 1.1 compatible library, although only SOAP::Lite
clients have been tested during development.

=item XML Schema

The format of XML documents used by the SOAP interface are specified in XML
Schema format. See L<http://www.w3.org/XML/Schema> for more information on
this format. The schema is L<provided below|"XML Schema For Asset Documents">.

=back

=head2 Modules

The following modules support the SOAP interface. See the documentation for
each module for interface details, including XML Schemas and SOAP client
examples.

=over 4

=item L<Bric::SOAP::Handler|Bric::SOAP::Handler>

This module provides the Apache/mod_perl SOAP handler. It is responsible for
dispatching requests to individual Bric::SOAP modules.

=item L<Bric::SOAP::Auth|Bric::SOAP::Auth>

Handles authentication for SOAP clients. Authentication will be cookie-based --
clients can call a C<login()> function and get an HTTP cookie to use with
calls to the other SOAP interfaces.

=item L<Bric::SOAP::Story|Bric::SOAP::Story>

Provides query, export, update, create, and delete for Story objects.

=item L<Bric::SOAP::Media|Bric::SOAP::Media>

Provides query, export, update, create, and delete for Media objects.

=item L<Bric::SOAP::Template|Bric::SOAP::Template>

Provides query, export, update, create, and delete for Templates.

=item L<Bric::SOAP::ElementType|Bric::SOAP::Element>

Provides query, export, update, create, and delete for Element types.

=item L<Bric::SOAP::Category|Bric::SOAP::Category>

Provides query, export, update, create, and delete for Category objects.

=item L<Bric::SOAP::MediaType|Bric::SOAP::MediaType>

Provides query, export, update, create, and delete for MediaType objects.

=item L<Bric::SOAP::Site|Bric::SOAP::Site>

Provides query, export, update, create, and delete for Site objects.

=item L<Bric::SOAP::Keyword|Bric::SOAP::Keyword>

Provides query, export, update, create, and delete for Keyword objects.

=item L<Bric::SOAP::User|Bric::SOAP::User>

Provides query, export, update, create, and delete for User objects.

=item L<Bric::SOAP::Desk|Bric::SOAP::Desk>

Provides query, export, update, create, and delete for Desk objects.

=item L<Bric::SOAP::Workflow|Bric::SOAP::Workflow>

Provides the ability to move Story, Media and Template objects between
desks. Also provides checkin, checkout, publish, and deploy.
And now list_ids, export, create, update, and delete.

=item L<Bric::SOAP::ATType|Bric::SOAP::ATType>

Provides query, export, update, create, and delete for Element Type Set objects.

=item L<Bric::SOAP::OutputChannel|Bric::SOAP::OutputChannel>

Provides query, export, update, create, and delete for OutputChannel objects.

=item L<Bric::SOAP::ContribType|Bric::SOAP::ContribType>

Provides query, export, update, create, and delete for ContribType objects.

=item L<Bric::SOAP::Destination|Bric::SOAP::Destination>

Provides query, export, update, create, and delete for Destination objects.

=item L<Bric::SOAP::Preference|Bric::SOAP::Preference>

Provides query, export, update, create, and delete for Preference objects.

=back

=head2 SOAP Details

All of the Bricolage SOAP modules described above share a common SOAP
serialization strategy described here.

=over 4

=item Namespace

The namespace for all Bric::SOAP calls is:

  http://bricolage.sourceforge.net

To specify a module within that namespace, append the pieces as path
components. For example, to call methods in Bric::SOAP::Story use the
namespace:

  http://bricolage.sourceforge.net/Bric/SOAP/Story

For the SOAP::Lite users in the audience, this is the "uri" setting.

=item Parameters

All Bric::SOAP methods use a named-parameter style call syntax. This syntax is
mapped to XML elements where the name is the name of the element and the value
is the value contained inside the element. For example, a Perl call like:

   Bric::SOAP::Story->list_ids({ title => '%foo%', publish_status => 1 });

Is called through SOAP as:

  <SOAP-ENV:Body>
    <namesp2:list_ids
     xmlns:namesp2="http://bricolage.sourceforge.net/Bric/SOAP/Story">
      <title xsi:type="xsd:string">%foo%</title>
      <publish_status xsi:type="xsd:int">1</publish_status>
    </namesp2:list_ids>
  </SOAP-ENV:Body>

SOAP::Lite clients can generate this call using C<SOAP::Data::name()> to name
the parameters:

  import SOAP::Data 'name';
  my $result = $soap->list_ids(name(title          => '%foo%'),
                               name(publish_status => 1)       );

In most cases, Perl doesn't distinguish between strings and numbers. When
writing a SOAP client you should feel free to type your parameters in whatever
way makes most sense in your implementation language.

=item Return Values

All Bric::SOAP methods return a single named parameter. If a method needs to
return multiple values then a SOAP array is returned containing the values.
For example, C<< Bric::SOAP::Story->list_ids() >> returns a list of story IDs
in this structure:

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

SOAP::Lite clients can access this return value as an array reference:

  my $story_ids = $response->result;
  foreach my $id (@$story_ids) {
      frobnicate($id);
  }

=item XML Document Encoding

The Bric::SOAP system uses complete XML documents as parameters and return
values to many methods (C<create()> and C<export()>, for example). These
documents must be encoded in Base64 for performance reasons. See the
PERFORMANCE section of the L<SOAP::Lite|SOAP::Lite> documentation for a full
explanation of why this is necessary. This is not a limitation of SOAP::Lite
in particular but the explanation is particularly lucid.

For SOAP::Lite clients, generating Base64 parameters is very easy:

   my $document = name(document => $xml)->type('base64');

And on decoding, returned base64 will be done automatically.

The XML Schema for these documents is included below.

=item Error Handling

Errors are returned as SOAP faults using fault strings produced by the method
called. If you use SOAP::Lite as your client library you can check for errors
using the C<fault()> method and access the error message with
C<faultstring()>:

  my $response = $soap->list_ids(...);
  die "SOAP Error: " . $response->faultstring if $response->fault;

=item XML Schema For Asset Documents

This is the XML Schema for asset documents used in the Bricolage SOAP
interface.

The XSD source:

 <?xml version="1.0" encoding="UTF-8"?>
 <xs:schema targetNamespace="http://bricolage.sourceforge.net/assets.xsd" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://bricolage.sourceforge.net/assets.xsd" elementFormDefault="qualified" attributeFormDefault="unqualified">
   <xs:element name="assets">
     <xs:annotation>
       <xs:documentation>a set of Bricolage assets</xs:documentation>
     </xs:annotation>
     <xs:complexType mixed="0">
       <xs:sequence maxOccurs="unbounded">
         <xs:element ref="story" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="media" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="template" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="element_type" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="category" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="media_type" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="site" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="keyword" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="desk" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="user" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="element_type_set" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="output_channel" minOccurs="0" maxOccurs="unbounded" />
         <xs:element ref="workflow" minOccurs="0" maxOccurs="unbounded" />
       </xs:sequence>
     </xs:complexType>
   </xs:element>
   <xs:element name="story">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="site">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
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
             <xs:documentation>omitted if no expire date</xs:documentation>
           </xs:annotation>
         </xs:element>
         <xs:element name="first_publish_date" type="xs:dateTime" minOccurs="0">
           <xs:annotation>
             <xs:documentation>omitted if not published</xs:documentation>
           </xs:annotation>
         </xs:element>
         <xs:element name="publish_date" type="xs:dateTime" minOccurs="0">
           <xs:annotation>
             <xs:documentation>omitted if not published</xs:documentation>
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
         <xs:element name="output_channels" minOccurs="0">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="output_channel" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:simpleContent>
                     <xs:extension base="xs:string">
                       <xs:attribute name="site" type="xs:string" use="required"/>
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
               <xs:element name="field" minOccurs="0" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:simpleContent>
                     <xs:extension base="xs:string">
                       <xs:attribute name="field_type" type="xs:string" use="required"/>
                       <xs:attribute name="order" type="xs:int" use="required"/>
                     </xs:extension>
                   </xs:simpleContent>
                 </xs:complexType>
               </xs:element>
               <xs:element name="container" type="container_type" minOccurs="0" maxOccurs="unbounded"/>
             </xs:sequence>
             <xs:attribute name="related_story_id" type="xs:int" use="optional"/>
             <xs:attribute name="related_story_uri" type="xs:int" use="optional"/>
             <xs:attribute name="related_media_id" type="xs:int" use="optional"/>
             <xs:attribute name="related_media_uri" type="xs:int" use="optional"/>
             <xs:attribute name="related_site_id" type="xs:int" use="optional"/>
             <xs:attribute name="relative" type="xs:boolean" use="optional"/>
             <xs:attribute name="displayed" type="xs:boolean" use="optional"/>
           </xs:complexType>
         </xs:element>
       </xs:sequence>
       <xs:attribute name="element_type" type="xs:string" use="required"/>
       <xs:attribute name="alias_id" type="xs:string" use="required"/>
       <xs:attribute name="id" type="xs:int" use="required"/>
       <xs:attribute name="uuid" type="xs:string" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="media">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="site">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
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
             <xs:documentation>omitted if no expire date</xs:documentation>
           </xs:annotation>
         </xs:element>
         <xs:element name="publish_date" type="xs:dateTime" minOccurs="0">
           <xs:annotation>
             <xs:documentation>omitted if not published</xs:documentation>
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
               <xs:element name="field" minOccurs="0" maxOccurs="unbounded">
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
               <xs:element name="media_type">
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
                       <xs:maxLength value="2147483647"/>
                   </xs:restriction>
                 </xs:simpleType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
       </xs:sequence>
       <xs:attribute name="element_type" type="xs:string" use="required"/>
       <xs:attribute name="alias_id" type="xs:string" use="required"/>
       <xs:attribute name="id" type="xs:int" use="required"/>
       <xs:attribute name="uuid" type="xs:string" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="template">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="site">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="element_type">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="type">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="20"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
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
             <xs:documentation>omitted if no expire date</xs:documentation>
           </xs:annotation>
         </xs:element>
         <xs:element name="deploy_date" type="xs:dateTime" minOccurs="0">
           <xs:annotation>
             <xs:documentation>omitted if not deployed</xs:documentation>
           </xs:annotation>
         </xs:element>
         <xs:element name="data" type="xs:base64Binary" minOccurs="0"/>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="element_type">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="key_name">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
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
         <xs:element name="top_level" type="xs:boolean"/>
         <xs:element name="paginated" type="xs:boolean"/>
         <xs:element name="fixed_uri" type="xs:boolean"/>
         <xs:element name="related_story" type="xs:boolean"/>
         <xs:element name="related_media" type="xs:boolean"/>
         <xs:element name="displayed" type="xs:boolean"/>
         <xs:element name="is_media" type="xs:boolean"/>
         <xs:element name="biz_class">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="128"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
         <xs:element name="sites" minOccurs="0">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="site" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:simpleContent>
                     <xs:extension base="xs:string">
                       <xs:attribute name="primary_oc" type="xs:string" />
                     </xs:extension>
                   </xs:simpleContent>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
         <xs:element name="output_channels" minOccurs="0">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="output_channel" maxOccurs="unbounded">
                 <xs:simpleType>
                   <xs:restriction base="xs:string"/>
                 </xs:simpleType>
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
         <xs:element name="subelement_types">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="subelement_type" minOccurs="0" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:sequence>
                     <xs:element name="key_name" type="xs:string" />
                     <xs:element name="min_occur" type="xs:int" minOccurs="0"/>
                     <xs:element name="max_occur" type="xs:int" minOccurs="0"/>
                     <xs:element name="place" type="xs:int" minOccurs="0"/>
                   </xs:sequence>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
         <xs:element name="field_types">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="field_type" minOccurs="0" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:sequence>
                     <xs:element name="key_name" type="xs:string"/>
                     <xs:element name="name" type="xs:string"/>
                     <xs:element name="description" type="xs:string"/>
                     <xs:element name="required" type="xs:boolean"/>
                     <xs:element name="repeatable" type="xs:boolean"/>
                     <xs:element name="autopopulated" type="xs:boolean"/>
                     <xs:element name="multiple" type="xs:boolean" minOccurs="0"/>
                     <xs:element name="max_size" type="xs:int" minOccurs="0"/>
                     <xs:element name="widget_type" type="xs:string"/>
                     <xs:element name="default_val" type="xs:string"/>
                     <xs:element name="options" type="xs:string" minOccurs="0"/>
                     <xs:element name="length" type="xs:int" minOccurs="0"/>
                     <xs:element name="rows" type="xs:int" minOccurs="0"/>
                     <xs:element name="cols" type="xs:int" minOccurs="0"/>
                     <xs:element name="precision" type="xs:int" minOccurs="0"/>
                     <xs:element name="active" type="xs:boolean"/>
                     <xs:element name="min_occur" type="xs:int" minOccurs="0"/>
                     <xs:element name="max_occur" type="xs:int" minOccurs="0"/>
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
   <xs:element name="category">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="site">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="name">
           <xs:simpleType>
             <xs:restriction base="xs:string"/>
           </xs:simpleType>
         </xs:element>
         <xs:element name="description">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="path">
           <xs:simpleType>
             <xs:restriction base="xs:string"/>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
         <xs:element name="adstring">
           <xs:simpleType>
             <xs:restriction base="xs:string"/>
           </xs:simpleType>
         </xs:element>
         <xs:element name="adstring2">
           <xs:simpleType>
             <xs:restriction base="xs:string"/>
           </xs:simpleType>
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
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="media_type">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="name">
           <xs:simpleType>
             <xs:restriction base="xs:string"/>
           </xs:simpleType>
         </xs:element>
         <xs:element name="description">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
         <xs:element name="exts">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="ext" type="xs:string" minOccurs="0" maxOccurs="unbounded">
                 <xs:annotation>
                   <xs:documentation>This is just a list of extensions.</xs:documentation>
                 </xs:annotation>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="site">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="name">
           <xs:simpleType>
             <xs:restriction base="xs:string"/>
           </xs:simpleType>
         </xs:element>
         <xs:element name="description">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="domain_name">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="keyword">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="name">
           <xs:simpleType>
             <xs:restriction base="xs:string"/>
           </xs:simpleType>
         </xs:element>
         <xs:element name="screen_name">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="sort_name">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="desk">
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
         <xs:element name="publish" type="xs:boolean"/>
         <xs:element name="active" type="xs:boolean"/>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="user">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="prefix">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="32"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="fname">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="mname">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="lname">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="suffix">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="32"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="login">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="128"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="password">
           <xs:simpleType>
             <xs:annotation>
               <xs:documentation>password isn't implemented yet</xs:documentation>
             </xs:annotation>
             <xs:restriction base="xs:string">
               <xs:maxLength value="32"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
         <xs:element name="contacts">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="contact" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:simpleContent>
                     <xs:extension base="xs:string">
                       <xs:attribute name="type" type="xs:string" use="required"/>
                     </xs:extension>
                   </xs:simpleContent>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="element_type_set">
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
         <xs:element name="top_level" type="xs:boolean"/>
         <xs:element name="paginated" type="xs:boolean"/>
         <xs:element name="fixed_url" type="xs:boolean"/>
         <xs:element name="related_story" type="xs:boolean"/>
         <xs:element name="related_media" type="xs:boolean"/>
         <xs:element name="is_media" type="xs:boolean"/>
         <xs:element name="biz_class">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="128"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="output_channel">
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
         <xs:element name="protocol">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="16"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="pre_path">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="post_path">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="filename">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="32"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="file_ext">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="32"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="uri_format">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="fixed_uri_format">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="uri_case">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="16"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="use_slug" type="xs:boolean"/>
         <xs:element name="site">
           <xs:simpleType>
             <xs:restriction base="xs:string"/>
           </xs:simpleType>
         </xs:element>
         <xs:element name="includes">
           <xs:annotation>
             <xs:documentation>A list of output channels for template includes.
             </xs:documentation>
           </xs:annotation>
           <xs:complexType>
             <xs:sequence>
               <xs:element name="include" minOccurs="0" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:simpleContent>
                     <xs:extension base="xs:string">
                       <xs:attribute name="site" type="xs:string" use="required" />
                     </xs:extension>
                   </xs:simpleContent>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="contrib_type">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="name">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>    <!-- \d grp -->
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="description">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>   <!-- \d grp -->
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
         <xs:element name="field_types">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="field_type" minOccurs="0" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:sequence>
                     <!-- returned by $ct->all_for_member_subsys,
                          \d attr_grp_meta for max lengths (2048)
                          (need to make element ref restricting to 2048, use here) -->
                     <xs:element name="key_name" type="xs:string"/>
                     <xs:element name="default_val" type="xs:string"/>
                     <xs:element name="multiple" type="xs:boolean" minOccurs="0"/> <!-- minOccurs? -->
                     <xs:element name="cols" type="xs:int" minOccurs="0"/>
                     <xs:element name="length" type="xs:int" minOccurs="0"/>
                     <xs:element name="max_size" type="xs:int" minOccurs="0"/>
                     <xs:element name="name" type="xs:string"/>
                     <xs:element name="options" type="xs:string" minOccurs="0"/>
                     <xs:element name="place" type="xs:int"/>
                     <xs:element name="precision" type="xs:int" minOccurs="0"/>
                     <xs:element name="rows" type="xs:int" minOccurs="0"/>
                     <xs:element name="widget_type" type="xs:string"/>
                   </xs:sequence>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="dest">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="name">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>    <!-- \d server_type -->
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
         <xs:element name="move_method">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="128"/>    <!-- \d class (disp_name) -->
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="can_copy" type="xs:boolean"/>
         <xs:element name="can_publish" type="xs:boolean"/>
         <xs:element name="can_preview" type="xs:boolean"/>
         <xs:element name="site" type="xs:string" />    <!-- \d site -->
         <xs:element name="output_channels">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="output_channel" minOccurs="0" maxOccurs="unbounded">
                 <xs:simpleType>
                   <xs:restriction base="xs:string">
                     <xs:maxLength value="64"/>    <!-- \d output_channel -->
                   </xs:restriction>
                 </xs:simpleType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
         <xs:element name="actions">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="action" minOccurs="0" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:sequence>
                     <!-- These are only when type="Email".
                          XXX: don't know how to properly constrain this -->
                     <xs:element name="from" type="xs:string" minOccurs="0"/>
                     <xs:element name="to" type="xs:string" minOccurs="0"/>
                     <xs:element name="cc" type="xs:string" minOccurs="0"/>
                     <xs:element name="bcc" type="xs:string" minOccurs="0"/>
                     <xs:element name="subject" type="xs:string" minOccurs="0"/>
                     <xs:element name="content_type" type="xs:string" minOccurs="0"/>
                     <xs:element name="handle_text" type="xs:string" minOccurs="0"/>
                     <xs:element name="handle_other" type="xs:string" minOccurs="0"/>
                   </xs:sequence>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
             <xs:attribute name="type" type="xs:string" use="required"/>  <!-- restriction? -->
             <xs:attribute name="order" type="xs:int" use="required"/>
           </xs:complexType>
         </xs:element>
         <xs:element name="servers">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="server" minOccurs="0" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:sequence>
                     <xs:element name="host_name" type="xs:string" />
                     <xs:element name="os" type="xs:string" />
                     <xs:element name="doc_root" type="xs:string" />
                     <xs:element name="login" type="xs:string" />
                     <xs:element name="password" type="xs:string" />
                     <xs:element name="cookie" type="xs:string" />
                     <xs:element name="active" type="xs:boolean" />
                   </xs:sequence>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
             <xs:attribute name="type" type="xs:string" use="required"/>  <!-- restriction? -->
             <xs:attribute name="order" type="xs:int" use="required"/>
           </xs:complexType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="pref">
     <xs:complexType>
       <xs:sequence>
         <xs:element name="name">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>    <!-- \d pref -->
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
         <xs:element name="can_be_overridden" type="xs:boolean"/>
         <xs:element name="opt_type">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="16"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="manual" type="xs:boolean"/>
         <xs:element name="default">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="value">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="256"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="opts">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="opt" minOccurs="0" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:sequence>
                     <xs:element name="value">
                       <xs:simpleType>
                         <xs:restriction base="xs:string">
                           <xs:maxLength value="256"/>     <!-- \d pref_opt -->
                         </xs:restriction>
                       </xs:simpleType>
                     </xs:element>
                     <xs:element name="val_name">
                       <xs:simpleType>
                         <xs:restriction base="xs:string">
                           <xs:maxLength value="256"/>
                         </xs:restriction>
                       </xs:simpleType>
                     </xs:element>
                   </xs:sequence>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>
   <xs:element name="workflow">
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
         <xs:element name="site">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:maxLength value="64"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="type">
           <xs:simpleType>
             <xs:restriction base="xs:string">
               <xs:enumeration value="Story"/>
               <xs:enumeration value="Media"/>
               <xs:enumeration value="Template"/>
             </xs:restriction>
           </xs:simpleType>
         </xs:element>
         <xs:element name="active" type="xs:boolean"/>
         <xs:element name="desks">
           <xs:complexType>
             <xs:sequence>
               <xs:element name="desk" maxOccurs="unbounded">
                 <xs:complexType>
                   <xs:simpleContent>
                     <xs:extension base="xs:string">
                       <xs:attribute name="start" type="xs:boolean" use="optional"/>
                       <xs:attribute name="publish" type="xs:boolean" use="optional"/>
                     </xs:extension>
                   </xs:simpleContent>
                 </xs:complexType>
               </xs:element>
             </xs:sequence>
           </xs:complexType>
         </xs:element>
       </xs:sequence>
       <xs:attribute name="id" type="xs:int" use="required"/>
     </xs:complexType>
   </xs:element>

   <xs:complexType name="container_type" mixed="0">
     <xs:annotation>
       <xs:documentation>An element data container - a recursive type.</xs:documentation>
     </xs:annotation>
     <xs:sequence>
       <xs:element name="field_type" minOccurs="0" maxOccurs="unbounded">
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
     <xs:attribute name="related_story_uri" type="xs:int" use="optional"/>
     <xs:attribute name="related_media_id" type="xs:int" use="optional"/>
     <xs:attribute name="related_media_uri" type="xs:int" use="optional"/>
     <xs:attribute name="related_site_id" type="xs:int" use="optional"/>
     <xs:attribute name="relative" type="xs:boolean" use="optional"/>
     <xs:attribute name="displayed" type="xs:boolean" use="optional"/>
   </xs:complexType>
 </xs:schema>

=back

=head2 Example Asset Documents

Here's a simple story with some keywords and no contributors:

  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>

  <assets xmlns="http://bricolage.sourceforge.net/assets.xsd">
   <story id="1024" uuid="0C071854-03E7-11DA-B4F2-BC394F2854A1" element="Book Review">
    <site>Default Site</site>
    <name>Story One</name>
    <description>a description of story one</description>
    <slug>one</slug>
    <primary_uri>/2004/02/22/one</primary_uri>
    <priority>3</priority>
    <publish_status>0</publish_status>
    <active>1</active>
    <source>Internal</source>
    <cover_date>2004-02-22T22:18:00Z</cover_date>
    <categories>
     <category primary="1">/</category>
    </categories>
    <output_channels>
     <output_channel primary="1">Web</output_channel>
    </output_channels>
    <keywords>
     <keyword>key one</keyword>
     <keyword>key two</keyword>
    </keywords>
    <contributors></contributors>
    <elements>
     <data order="2" element="deck">deck one</data>
     <container order="3" element="page">
    <data order="0" element="paragraph">para one</data>
    <data order="1" element="paragraph">para two</data>
    <container order="2" element="inset">
     <data order="0" element="copy">inset copy</data>
    </container>
     </container>
    </elements>
   </story>
  </assets>

=head2 Example Clients

=over 4

=item Command-Line Client

This script -- F<bric_soap> -- provides command-line access to all available
SOAP methods. For more information read the C<bric_soap> manual by running:

  bric_soap --man

or, if Bricolage's bin directory isn't in your path:

  /usr/local/bricolage/bin/bric_soap --man

=item Auto-Publisher

A script that publishes a set of stories based on a simple criteria entered on
the command line. Designed to be used in cron jobs..

See F<bric_republish> in F<bin/> for an implementation that republishes
already published stories. More general automated publishing can be performed
through F<bric_soap>.

=item Dev Sync Tool

A script that grabs the element tree and templates from a source server and
updates a list of target servers to match.

See F<bric_dev_sync> in F<bin/> for a complete implementation.

=back

=head1 See Also

L<Bric::SOAP::Handler|Bric::SOAP::Handler>

L<Bric::SOAP::Auth|Bric::SOAP::Auth>

L<Bric::SOAP::Story|Bric::SOAP::Story>

L<Bric::SOAP::Media|Bric::SOAP::Media>

L<Bric::SOAP::Template|Bric::SOAP::Template>

L<Bric::SOAP::Workflow|Bric::SOAP::Workflow>

L<Bric::SOAP::Element|Bric::SOAP::Element>

L<Bric::SOAP::Category|Bric::SOAP::Category>

L<Bric::SOAP::MediaType|Bric::SOAP::MediaType>

L<Bric::SOAP::Site|Bric::SOAP::Site>

L<Bric::SOAP::Keyword|Bric::SOAP::Keyword>

L<Bric::SOAP::User|Bric::SOAP::User>

L<Bric::SOAP::Desk|Bric::SOAP::Desk>

L<Bric::SOAP::ATType|Bric::SOAP::ATType>

L<Bric::SOAP::OutputChannel|Bric::SOAP::OutputChannel>

L<Bric::SOAP::ContribType|Bric::SOAP::ContribType>

L<Bric::SOAP::Destination|Bric::SOAP::Destination>

L<Bric::SOAP::Preference|Bric::SOAP::Preference>

L<bric_soap|bric_soap>

L<bric_dev_sync|bric_dev_sync>

L<bric_republish|bric_republish>

=head1 Author

Sam Tregar <stregar@about-inc.com>

=cut
