package Bric::SOAP::Util;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Category;
use Bric::Util::Time qw(db_date local_date strfdate);

use XML::Simple qw(XMLin);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
		    category_path_to_id 
		    xs_date_to_db_date db_date_to_xs_date
		    parse_asset_document
		    serialize_elements
		    deserialize_elements
		   );

# set to 1 to see debugging output on STDERR
use constant DEBUG => 0;

=head1 NAME

Bric::SOAP::Util - utility class for the Bric::SOAP classes

=head1 VERSION

$Revision: 1.11.2.1 $

=cut

our $VERSION = (qw$Revision: 1.11.2.1 $ )[-1];

=head1 DATE

$Date: 2002-10-25 22:54:03 $

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
  my $end;

  # get the directory name off the path end to limit the search
  if ($path eq '/') {
      $end = "";
  } else {
      ($end) = $path =~ m!/([^/]+)$!;
  }

  foreach my $cat (Bric::Biz::Category->list({ directory => $end })) {
    return $cat->get_id if $cat->ancestry_path eq $path;
  }
  return undef;
}

=item * $db_date = xs_date_to_db_date($xs_date)

Transforms an XML Schema dateTime format date to a database format
date.  Returns undef if the input date is invalid.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub xs_date_to_db_date {
    my $xs = shift;

    # extract time-zone if present from end of ISO 8601 date
    my ($tz) = $xs =~ /([A-Za-z]+)$/;
    $tz = 'UTC' unless defined $tz and $tz ne 'Z';
	
    my $db = db_date($xs, undef, $tz);
    print STDERR "xs_date_to_db_date:\n  $xs\n  $db\n\n" if DEBUG;
    return $db;
}    

=item * $xs_date = db_date_to_xs_date($db_date)

Transforms a database format date into an XML Schema dataTime format
date.  Returns undef if the input date is invalid.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub db_date_to_xs_date {
    my $db = shift;
    my $xs = strfdate(local_date($db, "epoch"), "%G-%m-%dT%TZ", 1);
    print STDERR "db_date_to_xs_date:\n  $db\n  $xs\n\n" if DEBUG;
    return $xs;
}

=item * $data = parse_asset_document($document, @extra_force_array)

Parses an XML asset document and returns a hash structure.  Inside the
hash singular elements are stored as keys with scalar values.
Potentially plural values are stored as array-ref values whether
they're present multiple times in the document or not.  This routine
dies on parse errors with information about the error.

After the document parameter you can pass extra items for the
force_array XML::Simple option.

At some point in the future this method will be augmented with XML
Schema validation.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub parse_asset_document {
    my $document = shift;
    my @extra_force_array = @_;

    return XMLin($document, 
		 keyattr       => [],
		 suppressempty => '',
		 forcearray    => [qw( contributor category
	                               keyword element container 
				       data story media template ),
				   @extra_force_array
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


=item @relations = deseralize_elements(object => $story, data => $data)

Loads an asset object with element data from the data hash.  Calls
_deserialize_tile recursively down through containers.

Throws: NONE

Side Effects: NONE

Notes:

=cut

sub deserialize_elements {
    my %options = @_;
    my $object = $options{object};

    return _deserialize_tile(element   => $object->get_tile,
			     data      => $options{data});
}


=back

=head2 Private Class Methods

=over 4

=item @related = _deserialize_tile(element => $element, data => $data)

Deserializes a single tile from <elements> data into $element.  Calls
recursively down through containers building up fixup data from
related objects in @related.

Throws: NONE

Side Effects: NONE

Notes: This method isn't checking compliance with the asset type
constraints in some cases.  After Bric::SOAP::Element is done I should
contain the kung-fu necessary for this task.

=cut

sub _deserialize_tile {
    my %options   = @_;
    my $element   = $options{element};
    my $data      = $options{data}; 
    my @relations;
	
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
	    $element->add_data($at, 
			       exists $d->{content} ? $d->{content} : '',
			       $d->{order});
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
	    

	    # deal with related stories and media
	    if ($c->{related_media_id}) {
		# store fixup information - the object to be updated
		# and the external id
		push(@relations, { container => $container, 
				   media_id  => $c->{related_media_id},
				   relative  => $c->{relative} || 0 });
	    } elsif ($c->{related_story_id}) {
		push(@relations, { container => $container, 
				   story_id  => $c->{related_story_id}, 
				   relative  => $c->{relative} || 0 });
	    }

	    # recurse
	    push @relations, _deserialize_tile(element   => $container,
					       data      => $c);
	}
    }
    return @relations;
}



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
		push(@related, [ media => $attr{related_media_id} ]);
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
