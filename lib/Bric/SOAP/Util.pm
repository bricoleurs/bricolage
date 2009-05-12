package Bric::SOAP::Util;

###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Category;
use Bric::Biz::OutputChannel;
use Bric::Util::Fault qw(throw_ap);
use Bric::Util::Time qw(db_date local_date strfdate);
use Bric::Config qw(:time);
use Bric::App::Event    qw(log_event);

use XML::Simple qw(XMLin);

# XXX For some reason, Bricolage breaks using SAX. This keeps it happy. It'd
# be nice to fix this, as XML::LibXML + SAX is probably more efficient, but
# this will do for now.

$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                    category_path_to_id
                    output_channel_name_to_id
                    workflow_name_to_id
                    xs_date_to_db_date
                    db_date_to_xs_date
                    parse_asset_document
                    serialize_elements
                    deserialize_elements
                    load_ocs
                    site_to_id
                    resolve_relations
                   );

# set to 1 to see debugging output on STDERR
use constant DEBUG => 0;

=head1 Name

Bric::SOAP::Util - utility class for the Bric::SOAP classes

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::SOAP::Util qw(category_path_to_script)

  my $category_id = category_path_to_id($path);

=head1 Description

This module provides various utility methods of use throughout the
Bric::SOAP classes.

=cut

=head1 Interface

=head2 Exportable Functions

=over 4

=item $category_id = category_path_to_id($path)

Returns a category_id for the path specified or undef if none match.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub category_path_to_id {
    my ($pkg, $uri, $args) = @_;
    my ($cat_id) = Bric::Biz::Category->list_ids({
        uri => $uri,
        $args->{site_id} ? (site_id => $args->{site_id}) : ()
    });
    return $cat_id if defined $cat_id;
    my $site = $args->{site} || $args->{site_id}
      ? ', site => "' . ($args->{site} || $args->{site_id}) . '"'
      : '';
    throw_ap qq{$pkg\::list_ids: no category found matching }
      . qq{(category => "$uri"$site)};
}

=item $output_channel_id = output_channel_name_to_id($path)

Returns an output channel ID for an output channel name.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub output_channel_name_to_id {
    my ($pkg, $name, $args) = @_;
    my ($oc_id) = Bric::Biz::OutputChannel->list_ids({
        name => $name,
        $args->{site_id} ? (site_id => $args->{site_id}) : ()
    });
    return $oc_id if defined $oc_id;
    my $site = $args->{site} || $args->{site_id}
      ? ', site => "' . ($args->{site} || $args->{site_id}) . '"'
      : '';
    throw_ap qq{$pkg\::list_ids: no output channel found matching }
      . qq{(output_channel => "$name"$site)};
}

=item $workflow_id = workflow_name_to_id($path)

Returns a workflow ID for a workflow name.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub workflow_name_to_id {
    my ($pkg, $name, $args) = @_;
    my ($wf_id) = Bric::Biz::Workflow->list_ids({
        name => $name,
        $args->{site_id} ? (site_id => $args->{site_id}) : ()
    });
    return $wf_id if defined $wf_id;
    my $site = $args->{site} || $args->{site_id}
      ? ', site => "' . $args->{site} || $args->{site_id} . '"'
      : '';
    throw_ap qq{$pkg\::list_ids: no workflow found matching }
      . qq{(workflow => "$name"$site)};
}

=item $site_id = site_path_to_id($path)

Returns a site_id for the path specified or undef if none match.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub site_to_id {
    my ($pkg, $site) = @_;
    my ($site_id) = Bric::Biz::Site->list_ids({ name => $site });
    throw_ap(error => qq{$pkg\::list_ids: no site found matching (site => "$site")})
        unless defined $site_id;
    return $site_id;
}

=item $db_date = xs_date_to_db_date($xs_date)

Transforms an XML Schema dateTime format date to a database format
date.  Returns undef if the input date is invalid.

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

sub xs_date_to_db_date {
    my $xs = shift;

    # extract time-zone if present from end of ISO 8601 date
    $xs =~ s/(\D+)$//;
    my $tz = $1 && $1 ne 'Z' ? $1 : 'UTC';

    my $db = db_date($xs, undef, $tz);
    print STDERR "xs_date_to_db_date:\n  $xs\n  $db\n\n" if DEBUG;
    return $db;
}

=item $xs_date = db_date_to_xs_date($db_date)

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

=item $data = parse_asset_document($document, @extra_force_array)

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
                 forcearray    => [qw( contributor category output_channel
                                       keyword element_type element container
                                       data field story media template ),
                                   @extra_force_array
                                  ]
                );
}

=item @related = serialize_elements(writer => $writer, object => $story, args => $args)

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
    my $element = $object->get_element;
    my %attr;
    if (my $related_story = $element->get_related_story) {
        $attr{related_story_id} = $related_story->get_id;
        if ($options{args}{export_related_stories}) {
            $attr{relative} = 1;
            push(@related, [ story => $attr{related_story_id} ]);
        }
    }
    if (my $related_media = $element->get_related_media) {
        $attr{related_media_id} = $related_media->get_id;
        if ($options{args}{export_related_media}) {
            $attr{relative} = 1;
            push(@related, [ media => $attr{related_media_id} ]);
        }
    }

    $writer->startTag("elements", %attr);
    my $elems = $element->get_elements;

    if (@$elems) {

        # Surely this should always start at 0, changing the order you get out
        # of the database can only be a bad idea.
        my $diff = 0;

        # first serialize all data elements
        foreach my $e (@$elems) {
            next if $e->is_container;
            push(@related, _serialize_element(
                writer       => $writer,
                element_type => $e,
                args         => $options{args},
                diff         => $diff,
            ));
        }

        # then all containers
        foreach my $e (@$elems) {
            next unless $e->is_container;
            push(@related, _serialize_element(
                writer       => $writer,
                element_type => $e,
                args         => $options{args},
                diff         => $diff,
            ));
        }
    }

    $writer->endTag("elements");
    return @related;
}

=item load_ocs($asset, $ocdata, $elem_ocs, $key, $update)

Sets the output channels on a business asset. If it's a new asset, all of the
output channels in the $ocdata array reference will be loaded into the
asset. If the asset is being updated, then C<load_ocs()> compares the output
channels in $ocdata to those in the asset and adds and removes the appropriate
output channels. The arguments are:

=over 4

=item C<$asset>

The business asset with which to associate the output channels.

=item C<$ocdata>

The array reference of output channels from the SOAP data, e.g.,
C<$data->{stories}{story}[0]{output_channels}{output_channel}.

=item C<$elem_type_ocs>

A hash reference of the output channels in the element type that define the asset
(i.e., the story element type or the media element type). The hash keys are
the output channel names, and the values are the corresponding output channel
objects.

=item C<$key>

The key name for the class of asset being updated, either "story" or "media".

=item C<$update>

Boolean value indicating whether C<$asset> is being updated or not.

=back

Throws: NONE

Side Effects: NONE

B<Notes:> Only call this function if there is output channel data to be
managed in the XML data. If there isn't, don't call this function, and the
output channels in an asset will be left unchanged.

=cut

sub load_ocs {
    my ($asset, $ocdata, $elem_ocs, $key, $update) = @_;
    # Note the current output channels.
    my %ocs =  map { $_->get_name => $_ } $asset->get_output_channels;

    # Update the output channels.
    foreach my $ocdata (@$ocdata) {
        # Construct the output channel.
        my $ocname = ref $ocdata ? $ocdata->{content} : $ocdata;
        my $oc = delete $ocs{$ocname};
        unless ($oc) {
            # We have to add the new output channel to the document. Grab the
            # OC object from the element type.
            $oc = $elem_ocs->{$ocname} or
              throw_ap(error => __PACKAGE__ . "::create : output channel matching " .
                         "(name => \"$ocname\") not allowed or cannot be found");
            $asset->add_output_channels($oc);
            log_event("${key}_add_oc", $asset,
                      { 'Output Channel' => $oc->get_name });
        }

        # Set the primary OC ID, if necessary.
        $asset->set_primary_oc_id($oc->get_id)
          if ref $ocdata and $ocdata->{primary};
    }

    # Delete any remaining output channels.
    foreach my $oc (values %ocs) {
        log_event("${key}_del_oc", $asset,
                  { 'Output Channel' => $oc->get_name });
        $asset->del_output_channels($oc->get_id);
    }
}

=item @relations = deseralize_elements(object => $story, data => $data,
                                       type   => 'story')

Loads an asset object with element type data from the data hash.  Calls
_deserialize_element recursively down through containers.

Throws: NONE

Side Effects: NONE

Notes:

=cut

sub deserialize_elements {
    my %options = @_;
    $options{element} = $options{object}->get_element;
    $options{site_id} = $options{object}->get_site_id;
    return _load_relateds(@options{qw(element data site_id)}),
      _deserialize_element(%options);
}

=back

=head2 Private Class Methods

=over 4

=item @related = _deserialize_element(element => $element, data => $data)

Deserializes a single element from <elements> data into $element.  Calls
recursively down through containers building up fixup data from
related objects in @related.

Throws: NONE

Side Effects: NONE

Notes: This method isn't checking compliance with the asset type
constraints in some cases.  After Bric::SOAP::Element is done I should
contain the kung-fu necessary for this task.

=cut

sub _deserialize_element {
    my %options   = @_;
    my $element   = $options{element};
    my $data      = $options{data};
    my $object    = $options{object};
    my $type      = $options{type};
    my $site_id   = $options{site_id};
    my @relations;

    # Map out the existing elements.
    my (%containers, %fields);
    for my $e ($element->get_containers) {
        push @{ $containers{$e->get_element_type_id } ||= [] }, $e;
    }
    for my $e ($element->get_fields) {
        push @{ $fields{$e->get_field_type_id } ||= [] }, $e;
    }

    my @to_delete;

    # get lists of possible field and container element types that can be
    # added to this container element. Hash on names for quick lookups.
    my %valid_data      = map { $_->get_key_name => $_ }
        $element->get_element_type->get_field_types;
    my %valid_container = map { $_->get_key_name, $_  }
        $element->get_element_type->get_containers;

    # load data elements
    $data->{field} ||= $data->{data};
    if ($data->{field}) {
        foreach my $d (@{$data->{field}}) {
            my $key_name = $d->{type} || $d->{element};
            my $at = $valid_data{$key_name} or throw_ap(
                error => "Error loading data element '$key_name' for " .
                    $element->get_key_name .
                        ": cannot add field $key_name here."
            );

            my $content = '';
            if ($at->get_sql_type eq 'date') {
                $content = xs_date_to_db_date($d->{content})
                    if exists $d->{content};
            } else {
                $content = $d->{content} if exists $d->{content};
                my $maxlen = $at->get_max_length;
                if ($maxlen && length($content) > $maxlen) {
                    throw_ap(error => "Error loading data element '$key_name' for " .
                             $element->get_key_name .
                             ": content exceeds maximum length ($maxlen).");
                }
            }

            if ( my $f = shift @{ $fields{ $at->get_id } || [] } ) {
                $f->set_value( $content );
                $f->set_place( $d->{order} );
            } else {
                # add data to container
                $element->add_field(
                    $at,
                    $content,
                    $d->{order}
                );
            }
        }
    }

    # load containers
    if ($data->{container}) {
        foreach my $c (@{$data->{container}}) {
            my $key_name = $c->{element_type} || $c->{element};
            my $at = $valid_container{$key_name} or throw_ap(
                error => "Error loading container element for " .
                    $element->get_key_name .
                    " cannot add field $key_name here."
            );

            # setup container object
            my $container = shift @{ $containers{ $at->get_id } || [] }
                || $element->add_container($at);
            $container->set_place($c->{order});
            $container->set_displayed($c->{displayed} ? 1 : 0);
            $element->save; # I'm not sure why this is necessary after
                            # every add, but removing it causes errors

            # Deal with related media
            push @relations, _load_relateds($container, $c, $site_id);

            # recurse
            push @relations, _deserialize_element(
                element   => $container,
                site_id   => $site_id,
                data      => $c
            );
            # Log it.
            log_event("${type}_add_element", $object, {
                Element => $container->get_key_name
            }) if $type && $object;

        }
    }

    # Delete any leftovers.
    $element->delete_elements([
        map { @$_ } values %containers, values %fields
    ]);

    # make sure our object order is set properly [BUG 1397]
    my $element_list = $element->get_elements;
    $element->reorder_elements($element_list) if ($element_list->[0]);

    $element->save;
    return @relations;
}


sub _load_relateds {
    my ($container, $cdata, $site_id) = @_;
    my @relations;
    if ($cdata->{related_media_id}) {
        # store fixup information - the object to be updated
        # and the external id
        push(@relations, {
            container => $container,
            media_id  => $cdata->{related_media_id},
            relative  => $cdata->{relative} || 0
        });
    } elsif ($cdata->{related_media_uri}) {
        push @relations, {
            container => $container,
            media_uri => $cdata->{related_media_uri},
            site_id   => $cdata->{related_site_id} || $site_id,
        };
    }

    # Deal with related story.
    if ($cdata->{related_story_id}) {
        push(@relations, {
            container => $container,
            story_id  => $cdata->{related_story_id},
            relative  => $cdata->{relative} || 0
        });
    } elsif ($cdata->{related_story_uri}) {
        push @relations, {
            container => $container,
            story_uri => $cdata->{related_story_uri},
            site_id   => $cdata->{related_site_id} || $site_id,
        };
    }
    return @relations;
}


=item @related = _serialize_element(writer => $writer, element => $element, args => $args)

Serializes a single element into the contents of an <elements> tag in the
media and story elements. It calls itself recursively on containers.
Returns a list of two-element arrays - [ "media", $id ] or [ "story",
$id ].  These are the related objects serialized.

=cut

sub _serialize_element {
    my %options  = @_;
    my $element  = $options{element_type};
    my $writer   = $options{writer};
    my $diff     = $options{diff} || 0;
    my @related;

    if ($element->is_container) {
        my %attr = (
            element_type => $element->get_key_name,
            order   => $element->get_place - $diff,
            displayed => $element->get_displayed,
        );

        my @e = $element->get_elements();

        # look for related stuff and tag relative if we'll include in
        # the assets dump.
        if (my $related_asset = $element->get_related_story) {
            my $id = $related_asset->get_id;
            if ($options{args}{use_related_uri}) {
                $attr{related_story_uri} = $related_asset->get_uri;
                $attr{related_site_id} = $related_asset->get_site_id;
            } else {
                $attr{related_story_id} = $id
            }
            if ($options{args}{export_related_stories}) {
                $attr{relative} = 1;
                push(@related, [ story => $id ]);
            }
        }
        if (my $related_asset = $element->get_related_media) {
            my $id = $related_asset->get_id;
            if ($options{args}{use_related_uri}) {
                $attr{related_media_uri} = $related_asset->get_uri;
                $attr{related_site_id} = $related_asset->get_site_id;
            } else {
                $attr{related_media_id} = $id
            }
            if ($options{args}{export_related_media}) {
                $attr{relative} = 1;
                push(@related, [ media => $id ]);
            }
        }

        if (@e) {
            # recurse over contained elements
            $writer->startTag("container", %attr);

            # first serialize all data elements
            foreach my $e (@e) {
                next if $e->is_container;
                push(@related, _serialize_element(
                    writer  => $writer,
                    element_type => $e,
                    args    => $options{args},
                ));
            }

            # then all containers
            foreach my $e (@e) {
                next unless $e->is_container;
                push(@related, _serialize_element(
                    writer       => $writer,
                    element_type => $e,
                    args         => $options{args},
                ));
            }

            $writer->endTag("container");
        } else {
            # produce clean empty tag
            $writer->emptyTag("container", %attr);
        }
    } else {
        my $data;

        if ($element->get_sql_type eq 'date') {
            # get date data and format for output
            $data = $element->get_value(ISO_8601_FORMAT);
            $data = db_date_to_xs_date($data) if $data;
        } else {
            $data = $element->get_value();
        }

        if (defined $data and length $data) {
            $writer->dataElement(
                field       => $data,
                type => $element->get_key_name,
                order       => $element->get_place - $diff,
            );
        } else {
            $writer->emptyTag(
                'field',
                type => $element->get_key_name,
                order       => $element->get_place - $diff,
            );
        }
    }

    return @related;
}

sub resolve_relations {
    my ($story_ids, $media_ids) = (shift, shift);
    foreach my $rel (@_) {
        if ($rel->{relative}) {
            # handle relative links
            if ($rel->{story_id}) {
                throw_ap(error => __PACKAGE__ .
                           " : Unable to find related story by relative id " .
                           "\"$rel->{story_id}\"")
                  unless exists $story_ids->{$rel->{story_id}};
                $rel->{container}->
                    set_related_story_id($story_ids->{$rel->{story_id}});
            }
            if ($rel->{media_id}) {
                throw_ap(error => __PACKAGE__ .
                           " : Unable to find related media by relative id " .
                           "\"$rel->{media_id}\"")
                  unless exists $media_ids->{$rel->{media_id}};
                $rel->{container}->
                    set_related_media($media_ids->{$rel->{media_id}});
            }
        } else {
            # handle absolute links
            if ($rel->{story_id}) {
                throw_ap(error => __PACKAGE__ . " : related story_id \"$rel->{story_id}\""
                           . " not found.")
                  unless Bric::Biz::Asset::Business::Story->list_ids({
                      id => $rel->{story_id}
                  });
                $rel->{container}->set_related_story_id($rel->{story_id});
            } elsif ($rel->{story_uri}) {
                my ($sid) = Bric::Biz::Asset::Business::Story->list_ids({
                    primary_uri => $rel->{story_uri},
                    site_id     => $rel->{site_id},
                });
                throw_ap(error => __PACKAGE__ . qq{ : related story_uri "$rel->{story_uri}"}
                           . qq{ not found in site "$rel->{site_id}"}) unless $sid;
                $rel->{container}->set_related_story_id($sid);
            }
            if ($rel->{media_id}) {
                throw_ap(error => __PACKAGE__ . " : related media_id \"$rel->{media_id}\""
                           . " not found.")
                  unless Bric::Biz::Asset::Business::Media->list_ids({
                      id => $rel->{media_id}
                  });
                $rel->{container}->set_related_media($rel->{media_id});
            } elsif ($rel->{media_uri}) {
                my ($mid) = Bric::Biz::Asset::Business::Media->list_ids({
                    uri     => $rel->{media_uri},
                    site_id => $rel->{site_id},
                });
                throw_ap(error => __PACKAGE__ . qq{ : related media_uri "$rel->{media_uri}"}
                           . qq{ not found in site "$rel->{site_id}"}) unless $mid;
                $rel->{container}->set_related_media($mid);
            }
        }
        $rel->{container}->save;
    }
}


=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>

=cut

1;
