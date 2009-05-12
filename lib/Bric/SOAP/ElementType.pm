package Bric::SOAP::ElementType;

###############################################################################

use strict;
use warnings;

use Bric::Config qw(:mod_perl);
use Bric::Biz::ElementType;
use Bric::Biz::ATType;
use Bric::Biz::Site;
use Bric::App::Session qw(get_user_id);
use Bric::App::Authz   qw(chk_authz READ);
use Bric::App::Event   qw(log_event);
use Bric::Util::Fault  qw(throw_ap throw_dp);
use Bric::SOAP::Util   qw(parse_asset_document);
use Bric::Util::ApacheReq;

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 Name

Bric::SOAP::ElementType - SOAP interface to Bricolage element type definitions.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

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

  # set uri for Element type module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/ElementType');

  # get a list of all element types
  my $element_type_ids = $soap->list_ids()->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage element types.

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching element types and returns a
list of ids.  If no element types are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item key_name (M)

The element type's key name.

=item name (M)

The element type's name.

=item description (M)

The element type's description.

=item output_channel

The output channel for the element type.

=item output_channel_id

The ID of an output channel. Returned will be all ElementType objects that
contain this output channel. May use C<ANY> for a list of possible values.

=item field_name (M)

=item data_name (M)

The name of an ElementType::Parts::FieldType (field type) object. Returned will be
all ElementType objects that reference this particular field type object.

=item type

The element type's type.

=item type_id

Match elements of a particular attype.

=item active

Set to 0 to return inactive as well as active element types.

=item site_id

Match against the given site_id. May use C<ANY> for a list of possible values.

=item top_level

Boolean value for top-level (story type and media type) element types.

=item media

Boolean value for media element types.

=item paginated

Boolean value for paginated element types.

=item fixed_uri

Boolean value for fixed URI element types.

=item related_story

Boolean value for related story element types.

=item related_media

Boolean value for related media element types.

=item biz_class_id

The ID of a Bric::Util::Class object representing a business class. The ID
must be for a class object representing one of
L<Bric::Biz::Asset::Business::Story|Bric::Biz::Asset::Business::Story>,
L<Bric::Biz::Asset::Business::Media|Bric::Biz::Asset::Business::Media>, or one
of its subclasses.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

sub list_ids {
    my $self = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->list_ids() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::list_ids : unknown parameter \"$_\".")
          unless $self->is_allowed_param($_, 'list_ids');
    }

    # handle type => type__id mapping
    if (exists $args->{type}) {
        my ($type_id) = Bric::Biz::ATType->list_ids({ name => $args->{type} });
        throw_ap(error => __PACKAGE__ . "::list_ids : no type found matching " .
                   "(type => \"$args->{type}\")")
          unless defined $type_id;
        $args->{type__id} = $type_id;
        delete $args->{type};
    }

    # handle output_channel => output_channel__id mapping
    if (exists $args->{output_channel}) {
        my ($output_channel_id) = Bric::Biz::OutputChannel->list_ids({
            name => $args->{output_channel}
        });
        throw_ap(error => __PACKAGE__ . "::list_ids : no output_channel found matching "
                   . "(output_channel => \"$args->{output_channel}\")")
          unless defined $output_channel_id;

        $args->{output_channel_id} = $output_channel_id;
        delete $args->{output_channel};
    }

    my @list = Bric::Biz::ElementType->list_ids($args);

    print STDERR "Bric::Biz::Asset::Template->list_ids() called : ",
        "returned : ", Data::Dumper->Dump([\@list],['list'])
            if DEBUG;

    # name the results
    my @result = map { name(element_type_id => $_) } @list;

    # name the array and return
    return name(element_type_ids => \@result);
}

=item export

The export method retrieves a set of element types from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item element_type_id

Specifies a single element_type_id to be retrieved.

=item element_type_ids

Specifies a list of element_type_ids.  The value for this option should be an
array of interger "element_type_id" element types.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut


=item create

The create method creates new objects using the data contained in an
XML document of the format created by export().

Returns a list of new ids created in the order of the assets in the
document.

Available options:

=over 4

=item document (required)

The XML document containing objects to be created.  The document must
contain at least one element type object.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: You cannot directly set the top_level setting.  This value is
ignored on update and create; instead it is taken from the type
setting.

=cut


=item update

The update method updates element type using the data in an XML document of
the format created by export().  A common use of update() is to
export() a selected element type object, make changes to one or more fields
and then submit the changes with update().

Returns a list of new ids created in the order of the assets in the
document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one element types and may contain any number of
related element type objects.

=item update_ids (required)

A list of "element_type_id" integers for the assets to be updated.  These
must match id attributes on element type elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: You cannot directly update the top_level setting.  This value
is ignored on update and create; instead it is taken from the type
setting.

=cut


=item delete

The delete() method deletes element types.  It takes the following options:

=over 4

=item element_type_id

Specifies a single element_type_id to be deleted.

=item element_type_ids

Specifies a list of element_type_ids to delete.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut


=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'element_type' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    print STDERR "Checking for $method($param) in $pkg\n" if DEBUG;
    my $allowed = {
        list_ids => { map { $_ => 1 } qw(key_name name description active
                                         output_channel output_channel_id
                                         type type_id field_name data_name
                                         site_id top_level media
                                         paginated fixed_uri related_story
                                         related_media biz_class_id) },
        export   => { map { $_ => 1 } ("$module\_id", "$module\_ids") },
        create   => { map { $_ => 1 } qw(document) },
        update   => { map { $_ => 1 } qw(document update_ids) },
        delete   => { map { $_ => 1 } ("$module\_id", "$module\_ids") },
    };

    return exists($allowed->{$method}->{$param});
}


=back

=head2 Private Class Methods

=over 4

=item $pkg->load_asset($args)

This method provides the meat of both create() and update().  The only
difference between the two methods is that update_ids will be empty on
create().

=cut

sub load_asset {
    my ($pkg, $args) = @_;
    my $document     = $args->{document};
    my $data         = $args->{data};
    my %to_update    = map { $_ => 1 } @{$args->{update_ids}};

    # parse and catch errors
    unless ($data) {
        eval { $data = parse_asset_document($document,
                                            'output_channel',
                                            'site',
                                            'subelement_type',
                                            'field',
                                            'field_type',
                                           ) };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__ .
                   " : problem parsing asset document : no element type found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{element_type};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over element type, filling @element_ids
    my @element_ids;
    my %fixup;
   foreach my $edata (@{$data->{element_type}}) {
        my $id = $edata->{id};

        # handle type => type__id mapping
        my $type_id = undef;
        if ($edata->{type}) {
            my ($type) = Bric::Biz::ATType->list({ name => $edata->{type} });
            throw_ap(error => __PACKAGE__ . " : no type found matching " .
                         "(type => \"$edata->{type}\")")
                unless defined $type;
            $type_id = $type->get_id;
        }

        # are we updating?
        my $update = exists $to_update{$id};

        # Convert the name to a key name, if needed.
        unless (defined $edata->{key_name}) {
            ($edata->{key_name} = lc $edata->{name}) =~ y/a-z0-9/_/cs;
            my $r = Bric::Util::ApacheReq->instance;
            $r->log->warn("No key name in element type loaded via SOAP. "
                          . "Converted '$edata->{name}' to "
                          . "'$edata->{key_name}'");
        }

        # make sure this key name isn't already taken
        my @list = Bric::Biz::ElementType->list_ids({ key_name => $edata->{key_name},
                                                    active => 0 });
        if (@list) {
            throw_ap "Unable to create element type \"$id\" key named "
              . "\"$edata->{key_name}\": that key name is already taken."
              unless $update;
            throw_ap "Unable to update element type \"$id\" to have key name " .
              "$edata->{key_name}\" : that name is already taken."
              unless $list[0] == $id;
        }

        my $element;
        unless ($update) {
            # instantiate a new object
            $element = Bric::Biz::ElementType->new({ type_id => $type_id });
        } else {
            # load element type
            $element = Bric::Biz::ElementType->lookup({ id => $id });
            throw_ap(error => __PACKAGE__ . "::update : unable to find element type \"$id\".")
              unless $element;

            # update type__id and zap cached type object (ugh)
            $element->_set(['type_id', '_att_obj'], [$type_id, undef])
                if defined $element->get_type_id;
        }

        # set simple data
        $element->set_key_name($edata->{key_name});
        $element->set_name($edata->{name});
        $element->set_description($edata->{description});

        # set boolean fields
        $element->set_top_level($edata->{top_level} ? 1 : 0);
        $element->set_paginated($edata->{paginated} ? 1 : 0);
        $element->set_fixed_uri($edata->{fixed_uri} ? 1 : 0);
        $element->set_related_story($edata->{related_story} ? 1 : 0);
        $element->set_related_media($edata->{related_media} ? 1 : 0);
        $element->set_displayed($edata->{displayed} ? 1 : 0);
        $element->set_media($edata->{is_media} ? 1 : 0);

        # change business class to ID
        my $class = Bric::Util::Class->lookup({pkg_name => $edata->{biz_class}});
        $element->set_biz_class_id($class->get_id);

        if ($element->is_top_level) {
            my (%sites, @ocs, $have_ocs);
            my %ocmap = map { $_->get_id => $_ } $element->get_output_channels;

            # assign sites
            foreach my $sitedata (@{$edata->{sites}{site}}) {
                # get site ID
                my $name = ref $sitedata ? $sitedata->{content} : $sitedata;
                unless ($sites{$name}) {
                    (my $look = $name) =~ s/([_%\\])/\\$1/g;
                    my $site = Bric::Biz::Site->lookup({ name => $look });
                    throw_ap __PACKAGE__ ."::create : no site found"
                      . " matching (site => \"$name\")"
                      unless defined $site;
                    $sites{$name} = $site->get_id;
                }

                # Add the site.
                $element->add_site($sites{$name});

                # get primary OC ID
                my $primary_oc_name = $sitedata->{primary_oc}
                    if ref $sitedata and $sitedata->{primary_oc};
                throw_ap __PACKAGE__ . " : no primary output_channel defined"
                         . " for site '$name'!"
                  unless defined $primary_oc_name;

                my ($primary_oc_id) = Bric::Biz::OutputChannel->list_ids
                  ({ name => $primary_oc_name });
                throw_ap __PACKAGE__ ."::create : no primary output_channel found"
                         . " matching (primary_oc => \"$name\")"
                  unless defined $primary_oc_id;

                # Set the primary output channel for this site.
                $element->set_primary_oc_id($primary_oc_id, $sites{$name});
            }

            throw_ap __PACKAGE__ . " : no sites defined!"
              unless %sites;

            # assign output_channels
            foreach my $ocdata (@{$edata->{output_channels}{output_channel}}) {
                # get OC ID
                my $name = ref $ocdata ? $ocdata->{content} : $ocdata;
                (my $look = $name) =~ s/([_%\\])/\\$1/g;
                my $oc = Bric::Biz::OutputChannel->lookup
                  ({ name => $look, site_id => $sites{$ocdata->{site}} })
                  or throw_ap __PACKAGE__ ."::create : no output_channel found"
                         . " matching (output_channel => \"$name\")";

                # Add this output channel to the list of OCs we'll need to add
                # to this element type only if it wasn't already an element type.
                if (delete $ocmap{$oc->get_id}) {
                    $have_ocs = 1;
                } else {
                    push @ocs, $oc;
                }
            }

            throw_ap __PACKAGE__ . " : no output channels defined!"
              unless @ocs || $have_ocs;

            # Delete whatever output channels are left that are no longer
            # a part of this element type.
            $element->delete_output_channels([values %ocmap])
              if $update;
            # add output_channels to element type
            $element->add_output_channels(\@ocs);
        }

        # remove all subelement types if updating
        $element->del_containers([ $element->get_containers ])
            if $update;

        # find subelement types and stash them in the fixup array.  This
        # is done because an Element Type could refer to another Element Type in
        # the same document.
        $edata->{subelement_types} ||= {subelement_type => []};
        foreach my $subdata (@{$edata->{subelement_types}{subelement_type}}) {
            # get key_name and other attributes
            my ($kn, $elem_min, $elem_max, $place);
            if (ref $subdata && exists $subdata->{key_name}) {
                ($kn, $elem_min, $elem_max, $place) = @{$subdata}
                    {qw(key_name min_occur max_occur place)};
            } else {
                $kn = ref $subdata ? $subdata->{content} : $subdata;
                # TODO Something smarter with the default place number
                ($elem_min, $elem_max, $place) = (0, 0, 0);
            }
            
            # add name to fixup hash for this element type
            $fixup{$edata->{key_name}} = []
              unless exists $fixup{$edata->{key_name}};
            push @{$fixup{$edata->{key_name}}}, 
                [ $kn, $elem_min, $elem_max, $place ];
        }

        # build hash of existing fields.
        my %old_data = map { $_->get_key_name => $_ } $element->get_field_types;
        my %updated_data;

        # find fields and instantiate new data element types
        my $place = 0;
        unless ($edata->{field_types}) {
            if ($edata->{fields}) {
                $edata->{field_types} = delete $edata->{fields};
                $edata->{field_types}{field_type}
                    = delete $edata->{field_types}{field};
            } else {
                $edata->{field_types} = {field_type => []};
            }
        }

        foreach my $field (@{$edata->{field_types}{field_type}}) {
            $place++; # next!

            # Make sure we have a key name. It should be fine, since we
            # were using the key name for the name in 1.8 before we renamed
            # it "key_name" in 1.8.1.
            ($field->{key_name} = lc $field->{name}) =~ y/a-z0-9/_/cs
              unless defined $field->{key_name};

            # figure out sql_type.
            my $sql_type;
            if ($field->{widget_type} eq 'date'){
                $sql_type = 'date';
            } elsif ($field->{widget_type} eq 'textarea' or
                     (defined $field->{max_size} and
                      ($field->{max_size} == 0 or
                       $field->{max_size} > 1024))) {
                $sql_type = 'blob';
            } else {
                $sql_type = 'short';
            }

            # Verify the code if it's a codeselect
            # XXX: triplicated now... (cf. comp/widgets/profile/displayAttrs.mc
            # and lib/Bric/App/Callback/Profile/FormBuilder.pm)
            if ($field->{widget_type} eq 'codeselect') {
                my $code = $field->{options};
                my $items = eval "$code";
                unless (ref $items eq 'ARRAY' and !(@$items % 2)) {
                    throw_dp "Invalid codeselect code (didn't return an array ref of even size)";
                }
            }

            # get a data object
            my $data;
            if ($data = $old_data{$field->{key_name}}) {
                print STDERR __PACKAGE__ . "::update : ".
                    "Found old data object for $edata->{key_name} => ",
                     "$field->{key_name}.\n"
                     if DEBUG;
                $data->set_key_name(    $field->{key_name});
                $data->set_name(        $field->{name}        || $field->{label});
                $data->set_description( $field->{description});
                $data->set_min_occurrence( $field->{min_occur} || 0 );
                $data->set_max_occurrence( $field->{max_occur} || 0 );
                $data->set_sql_type(    $sql_type);
                $data->set_place(       $place);
                $data->set_max_length(  $field->{max_size});
                $data->set_widget_type( $field->{widget_type} || $field->{type});
                $data->set_default_val( $field->{default_val} || $field->{val});
                $data->set_length(      $field->{length}      || $field->{size} || 0);
                $data->set_rows(        $field->{rows});
                $data->set_cols(        $field->{cols});
                $data->set_multiple(    $field->{multiple}    || 0);
                $data->set_vals(        $field->{options});
                $field->{active} ? $data->activate : $data->deactivate;
                $updated_data{$field->{key_name}} = 1;
            } else {
                # get a new data object
                print STDERR __PACKAGE__ . "::create : ".
                    "Creating new data object for $edata->{key_name} => ",
                        "$field->{key_name}.\n"
                            if DEBUG;
                $data = $element->new_field_type({
                    key_name      => $field->{key_name},
                    name          => $field->{name}        || $field->{label},
                    description   => $field->{description},
                    min_occurrence => $field->{min_occur} || 0,
                    max_occurrence => $field->{max_occur} || 0,
                    sql_type      => $sql_type,
                    place         => $place,
                    max_length    => $field->{max_size},
                    widget_type   => $field->{widget_type} || $field->{type},
                    default_val   => $field->{defaul_val}  || $field->{value},
                    length        => $field->{length}      || $field->{size} || 0,
                    rows          => $field->{rows}        || 0,
                    cols          => $field->{cols}        || 0,
                    multiple      => $field->{multiple}    || 0,
                    vals          => $field->{options},
                    active        => $field->{active},
                });
            }
        }

        # if updating then data fields might need deleting
        if ($update) {
            my @deleted;
            foreach my $f (keys %old_data) {
                next if exists $updated_data{$f};
                push @deleted, $f;
                log_event("field_type_rem", $element, { Name => $f });
                log_event("field_type_deact", $old_data{$f});
            }

            if (@deleted) {
                print STDERR __PACKAGE__ . "::update : ".
                    "Deleting data fields $edata->{key_name} => ",
                        join(', ', @deleted), "\n"
                            if DEBUG;
                $element->del_field_types([ (map { $old_data{$_} } @deleted) ]);
            }

            $_->save for (map { $old_data{$_} } keys %updated_data);
        }

        # activate or inactive?
        $edata->{active} ? $element->activate : $element->deactivate;

        # all done
        $element->save;
        log_event('element_type_' . ($update ? 'save' : 'new'), $element);

        # add to list of created element types
        push(@element_ids, $element->get_id);
    }

    # run through fixup attaching subelement types
    foreach my $element_name (keys %fixup) {
        my ($element) = Bric::Biz::ElementType->list({key_name => $element_name});

        foreach my $sub_elem_array (@{$fixup{$element_name}}) {
            my ($sub_name, $sub_min, $sub_max, $sub_place) = @$sub_elem_array;
            my ($sub_id) = Bric::Biz::ElementType->list_ids({key_name => $sub_name});
            throw_ap(error => __PACKAGE__ . " : no subelement type found matching "
                       . "(subelement_type => \"$sub_name\") "
                       . "for element type \"$element_name\".")
              unless defined $sub_id;
              $element->add_container($sub_id);
              $element->save;
              
              # Now set the subelement stuff
              # Note: We need to get it so a subelement is returned
              my ($sub_elem) = $element->get_containers($sub_id);
              $sub_elem->set_min_occurrence($sub_min || 0);
              $sub_elem->set_max_occurrence($sub_max || 0);
              $sub_elem->set_place($sub_place);
              $sub_elem->save;
              
        }
        $element->save;
    }

    return name(ids => [ map { name(element_type_id => $_) } @element_ids ]);
}

=item $pkg->serialize_asset(writer => $writer, element_type_id => $element_id, args => $args)

Serializes a single element type object into a C<< <element_type> >> element using
the given writer and args.

=cut

sub serialize_asset {
    my $pkg         = shift;
    my %options     = @_;
    my $element_id  = $options{element_type_id};
    my $writer      = $options{writer};

    my $element = Bric::Biz::ElementType->lookup({id => $element_id});
    throw_ap(error => __PACKAGE__ . "::export : element_type_id \"$element_id\" not found.")
      unless $element;

    throw_ap(error => __PACKAGE__ .
        "::export : access denied for element type \"$element_id\".")
      unless chk_authz($element, READ, 1);

    # open a element_type element
    $writer->startTag('element_type', id => $element_id);

    # write out simple elements in schema order
    foreach my $e (qw(key_name name description)) {
        $writer->dataElement($e => $element->_get($e));
    }

    # Output boolean attributes.
    $writer->dataElement(paginated     => ($element->get_paginated ? 1 : 0));
    $writer->dataElement(fixed_uri     => ($element->get_fixed_uri ? 1 : 0));
    $writer->dataElement(related_story => ($element->get_related_story ? 1 : 0));
    $writer->dataElement(related_media => ($element->get_related_media ? 1 : 0));
    $writer->dataElement(displayed     => ($element->get_displayed ? 1 : 0));
    $writer->dataElement(is_media      => ($element->get_media ? 1 : 0));

    # change business class to ID
    my $class = Bric::Util::Class->lookup({id => $element->get_biz_class_id});
    $writer->dataElement(biz_class     => $class->get_pkg_name);

    # set active flag
    $writer->dataElement(active => ($element->is_active ? 1 : 0));

    # set top_level stuff if top_level
    if ($element->get_top_level) {
        $writer->dataElement(top_level => 1);

        $writer->startTag('sites');
        my $sites = Bric::Biz::Site->href({ element_id => $element_id });
        foreach my $site (values %$sites) {
            my $primary_oc_id = $element->get_primary_oc_id($site->get_id);
            my $primary_oc = Bric::Biz::OutputChannel->lookup({ id => $primary_oc_id });
            $writer->dataElement(site => $site->get_name,
                                 primary_oc => $primary_oc->get_name);
        }
        $writer->endTag('sites');

        $writer->startTag("output_channels");
        foreach my $oc ($element->get_output_channels) {
            $writer->dataElement(output_channel => $oc->get_name,
                                 site => $sites->{$oc->get_site_id}->get_name);
        }
        $writer->endTag("output_channels");
    } else {
        $writer->dataElement(top_level => 0);
    }

    # output subelements
    $writer->startTag("subelement_types");
    foreach ($element->get_containers) {
        $writer->startTag("subelement_type");
        $writer->dataElement(key_name => $_->get_key_name);
        $writer->dataElement(min_occur => $_->get_min_occurrence);
        $writer->dataElement(max_occur => $_->get_max_occurrence);
        $writer->dataElement(place => $_->get_place);
        $writer->endTag("subelement_type");
    }
    $writer->endTag("subelement_types");

    # output fields (XXX: keep in sync with ContribType.pm)
    $writer->startTag("field_types");
    foreach my $data ($element->get_field_types) {
        # start <field>
        $writer->startTag("field_type");

        # required elements
        $writer->dataElement( key_name    => $data->get_key_name           );
        $writer->dataElement( name        => $data->get_name               );
        $writer->dataElement( description => $data->get_description        );
        $writer->dataElement( min_occur   => $data->get_min_occurrence     );
        $writer->dataElement( max_occur   => $data->get_max_occurrence     );
        $writer->dataElement( autopopulated => $data->get_autopopulated ? 1 : 0 );
        $writer->dataElement( place       => $data->get_place              );
        $writer->dataElement( widget_type => $data->get_widget_type        );
        $writer->dataElement( default_val => $data->get_default_val        );
        $writer->dataElement( options     => $data->get_vals               );
        $writer->dataElement( multiple    => $data->get_multiple   ? 1 : 0 );
        $writer->dataElement( length      => $data->get_length             );
        $writer->dataElement( max_size    => $data->get_max_length         );
        $writer->dataElement( rows        => $data->get_rows               );
        $writer->dataElement( cols        => $data->get_cols               );
        $writer->dataElement( precision   => $data->get_precision          );
        $writer->dataElement( active      => $data->get_active     ? 1 : 0 );

        # end <field>
        $writer->endTag("field_type");
    }

    $writer->endTag("field_types");


    # close the element
    $writer->endTag('element_type');
}

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>

=cut

1;
