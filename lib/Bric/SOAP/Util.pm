package Bric::SOAP::Util;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::AssetType;
use Bric::Biz::Category;

use XML::Simple qw(XMLin);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
		    category_path_to_id 
		    xs_date_to_pg_date pg_date_to_xs_date
		    parse_asset_document
		    serialize_elements
		   );

=head1 NAME

Bric::SOAP::Util - utility class for the Bric::SOAP classes

=head1 VERSION

$Revision: 1.3 $

=cut

our $VERSION = (qw$Revision: 1.3 $ )[-1];

=head1 DATE

$Date: 2002-02-08 01:05:31 $

=head1 SYNOPSIS

  use Bric::SOAP::Util qw(category_path_to_script)

  my $category_id = category_path_to_id($path);

=head1 DESCRIPTION

This module provides various utility methods of use throughout the
Bric::SOAP classes.

=cut

=head1 INTERFACE

=head2 Exportable Functions

=over 4

=item * $category_id = category_path_to_id($path)

Returns a category_id for the path specified or undef if none match.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub category_path_to_id {
  my $path = shift;
  foreach my $cat (Bric::Biz::Category->list()) {
    return $cat->get_id if $cat->ancestry_path eq $path;
  }
  return undef;
}

=item * $pg_date = xs_date_to_pg_date($xs_date)

Transforms an XML Schema dateTime format date to a Postgres format
date.  Returns undef if the input date is invalid.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub xs_date_to_pg_date {
    my $xs = shift;

    my ($CC, $YY, $MM, $DD, $hh, $mm, $ss, $tz) = $xs =~
	/^(\d\d)(\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(.*)$/;
    return undef unless $CC;
    $tz = 'UTC' if defined $tz and $tz eq 'Z';
	
    return "${CC}${YY}-${MM}-${DD} ${hh}:${mm}:${ss}" .
	(defined $tz ? (' ' . $tz) : '');
}    

=item * $xs_date = pg_date_to_xs_date($pg_date)

Transforms an a Postgres format date into an XML Schema dataTime
format date.  Returns undef if the input date is invalid.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub pg_date_to_xs_date {
    my $pg = shift;

    my ($CC, $YY, $MM, $DD, $hh, $mm, $ss, $tz) =  $pg =~
	/^(\d\d)(\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)(.*)$/;
    return undef unless $CC;
	
    # translate timezone 
    if ($tz) {
	if ($tz eq "+00") {
	    $tz = 'Z';
	} elsif ($tz =~ /^\+\d\d$/) {
	    $tz .= ':00';
	}
    } else {
	$tz = "";
    }
	
    return "${CC}${YY}-${MM}-${DD}T${hh}:${mm}:${ss}$tz";
}

=item * $data = parse_asset_document($document)

Parses an XML asset document and returns a hash structure.  Inside the
hash singular elements are stored as keys with scalar values.
Potentially plural values are stored as array-ref values whether
they're present multiple times in the document or not.  This routine
dies on parse errors with information about the error.

At some point in the future this method will be augmented with XML
Schema validation.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub parse_asset_document {
    my $document = shift;

    return XMLin($document, 
		 keyattr       => [],
		 suppressempty => '',
		 forcearray    => [qw( contributor category
					keyword element container 
				       data story media )
				  ]
		);
}

=item @related = seralize_elements(writer => $writer, object => $story, args => $args)

Creates the <elements> structure for a Story or Media object given the
object and the args to export().  Returns a list of two-element arrays -
[ "media", $id ] or [ "story", $id ].  These are the related objects
serialized.

=cut

sub serialize_elements {
    my %options  = @_;
    my $writer   = $options{writer};
    my $object   = $options{object};
    my @related;

    # output element data
    $writer->startTag("elements");
    my $element = $object->get_tile();
    my @e = $element->get_elements;

    # first serialize all data elements
    foreach my $e (@e) {
	next if $e->is_container;
	push(@related, _serialize_tile(writer  => $writer,
				       element => $e,
				       args    => $options{args},
				      ));	  
    }

    # then all containers
    foreach my $e (@e) {
	next unless $e->is_container;
	push(@related, _serialize_tile(writer  => $writer,
				      element => $e,
				      args    => $options{args},
				     ));	  
    }
    $writer->endTag("elements");
   
    return @related;
}


=back

=head2 Private Class Methods

=over 4

=item @related = _serialize_tile(writer => $writer, element => $element, args => $args)

Serializes a single tile into the contents of an <elements> tag in the
media and story elements. It calls itself recursively on containers.
Returns a list of two-element arrays - [ "media", $id ] or [ "story",
$id ].  These are the related objects serialized.

=cut

sub _serialize_tile {
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
		push(@related, _serialize_tile(writer  => $writer,
					       element => $e,
					       args    => $options{args},
					      ));	  
	    }

	    # then all containers
	    foreach my $e (@e) {
		next unless $e->is_container;
		push(@related, _serialize_tile(writer  => $writer,
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
