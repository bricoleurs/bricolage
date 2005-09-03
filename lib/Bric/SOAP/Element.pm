package Bric::SOAP::Element;
###############################################################################

use strict;
use warnings;

use Bric::Biz::AssetType;
use Bric::Biz::ATType;
use Bric::Biz::OutputChannel;
use Bric::Biz::Site;
use Bric::App::Session qw(get_user_id);
use Bric::App::Authz   qw(chk_authz READ);
use Bric::App::Event   qw(log_event);
use Bric::Util::Fault  qw(throw_ap);
use Bric::SOAP::Util   qw(parse_asset_document);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Element - SOAP interface to Bricolage element type definitions.

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

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

  # set uri for Element type module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Element');

  # get a list of all element types
  my $element_type_ids = $soap->list_ids()->result;

=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage element types.

=cut

=head1 INTERFACE

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

=item type

The element type's type.

=item top_level

Set to 1 to return only top-level element types.

=item site

NOT YET IMPLEMENTED. COMING SOON.

=item active

Set to 0 to return inactive as well as active element types.

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
    }

    my @list = Bric::Biz::AssetType->list_ids($args);

    print STDERR "Bric::Biz::Asset::Formatting->list_ids() called : ",
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
                                         output_channel type top_level) },
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
        my ($type) = Bric::Biz::ATType->list({ name => $edata->{type} });
        throw_ap(error => __PACKAGE__ . " : no type found matching " .
                   "(type => \"$edata->{type}\")")
          unless defined $type;
        my $type_id = $type->get_id;

        # handler burner mapping
        my $burner;
        if ($edata->{burner} eq "Mason") {
            $burner = Bric::Biz::AssetType::BURNER_MASON;
        } elsif ($edata->{burner} eq "HTML::Template") {
            $burner = Bric::Biz::AssetType::BURNER_TEMPLATE;
        } else {
            throw_ap(error => __PACKAGE__ . "::export : unknown burner"
                       . "\"$edata->{burner}\" for element type \"$id\".");
        }

        # are we updating?
        my $update = exists $to_update{$id};

        # Convert the name to a key name, if needed.
        unless (defined $edata->{key_name}) {
            ($edata->{key_name} = lc $edata->{name}) =~ y/a-z0-9/_/cs;
            my $r = Apache::Request->instance(Apache->request);
            $r->log->warn("No key name in element type loaded via SOAP. "
                          . "Converted '$edata->{name}' to "
                          . "'$edata->{key_name}'");
        }

        # make sure this key name isn't already taken
        my @list = Bric::Biz::AssetType->list_ids({ key_name => $edata->{key_name},
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
            $element = Bric::Biz::AssetType->new({ type__id => $type_id });
        } else {
            # load element type
            $element = Bric::Biz::AssetType->lookup({ id => $id });
            throw_ap(error => __PACKAGE__ . "::update : unable to find element type \"$id\".")
              unless $element;

            # update type__id and zap cached type object (ugh)
            $element->_set(['type__id', '_att_obj'], [$type_id, undef]);

        }

        # set simple data
        $element->set_key_name($edata->{key_name});
        $element->set_name($edata->{name});
        $element->set_description($edata->{description});
        $element->set_burner($burner);

        if ($type->get_top_level) {
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
            # get key_name
            my $kn = ref $subdata ? $subdata->{content} : $subdata;

            # add name to fixup hash for this element type
            $fixup{$edata->{key_name}} = []
              unless exists $fixup{$edata->{key_name}};
            push @{$fixup{$edata->{key_name}}}, $kn;
        }

        # build hash of existing fields.
        my %old_data = map { $_->get_key_name => $_ } $element->get_data;
        my %updated_data;

        # find fields and instantiate new data element types
        my $place = 0;
        $edata->{fields} ||= {field => []};
        foreach my $field (@{$edata->{fields}{field}}) {
            $place++; # next!

            # Make sure we have a key name. It should be fine, since we
            # were using the key name for the name in 1.8 before we renamed
            # it "key_name" in 1.8.1.
            ($field->{key_name} = lc $field->{name}) =~ y/a-z0-9/_/cs
              unless defined $field->{key_name};

            # figure out sql_type.
            my $sql_type;
            if ($field->{type} eq 'date'){
                $sql_type = 'date';
            } elsif ($field->{type} eq 'textarea' or
                     (defined $field->{max_size} and
                      ($field->{max_size} == 0 or
                       $field->{max_size} > 1024))) {
                $sql_type = 'blob';
            } else {
                $sql_type = 'short';
            }

            # get a data object
            my $data;
            if ($old_data{$field->{key_name}}) {
                print STDERR __PACKAGE__ . "::update : ".
                    "Found old data object for $edata->{key_name} => ",
                        "$field->{key_name}.\n"
                            if DEBUG;
                $data = $old_data{$field->{key_name}};
                $data->set_key_name($field->{key_name});
                $data->set_required($field->{required});
                $data->set_quantifier($field->{repeatable});
                $data->set_sql_type($sql_type);
                $data->set_place($place);
                $data->set_publishable(1);
                $data->set_max_length($field->{max_size});
                $updated_data{$field->{key_name}} = 1;
            } else {
                # get a new data object
                print STDERR __PACKAGE__ . "::create : ".
                    "Creating new data object for $edata->{key_name} => ",
                        "$field->{key_name}.\n"
                            if DEBUG;
                $data = $element->new_data({
                    key_name    => $field->{key_name},
                    required    => $field->{required},
                    quantifier  => $field->{repeatable},
                    sql_type    => $sql_type,
                    place       => $place,
                    publishable => 1,
                    max_length  => $field->{max_size},
                });
            }

            # add default value attribute.
            # (strange, my eyes are itching...)
            $data->set_attr(html_info => $field->{default});

            # add meta data to value attribute.
            # (oh, god they burn!)
            $data->set_meta(html_info => disp      => $field->{label});
            $data->set_meta(html_info => value     => $field->{default});
            $data->set_meta(html_info => type      => $field->{type});
            $data->set_meta(html_info => length    => $field->{size});
            $data->set_meta(html_info => maxlength => $field->{max_size});
            $data->set_meta(html_info => rows      => $field->{rows});
            $data->set_meta(html_info => cols      => $field->{cols});
            $data->set_meta(html_info => multiple  => $field->{multiple});
            $data->set_meta(html_info => vals      => $field->{options});
            $data->set_meta(html_info => pos       => $place);
            log_event("element_type_data_add", $element, { Name => $field->{label} });
            log_event('element_type_data_new', $data);

            # (my eyes! they're on fire!  oh, sweet lord, why?  WHY
            # HAVE YOU DONE THIS TO ME?)
        }

        # if updating then data fields might need deleting
        if ($update) {
            my @deleted;
            foreach my $f (keys %old_data) {
                next if exists $updated_data{$f};
                push @deleted, $f;
                log_event("element_type_data_rem", $element, { Name => $f });
                log_event("element_type_data_deact", $old_data{$f});
            }

            if (@deleted) {
                print STDERR __PACKAGE__ . "::update : ".
                    "Deleting data fields $edata->{key_name} => ",
                        join(', ', @deleted), "\n"
                            if DEBUG;
                $element->del_data([ (map { $old_data{$_} } @deleted) ]);
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
        my ($element) = Bric::Biz::AssetType->list({key_name => $element_name});
        my @sub_ids;

        foreach my $sub_name (@{$fixup{$element_name}}) {
            my ($sub_id) = Bric::Biz::AssetType->list_ids({key_name => $sub_name});
            throw_ap(error => __PACKAGE__ . " : no subelement type found matching "
                       . "(subelement_type => \"$sub_name\") "
                       . "for element type \"$element_name\".")
              unless defined $sub_id;
            push @sub_ids, $sub_id;
        }
        $element->add_containers(\@sub_ids);
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

    my $element = Bric::Biz::AssetType->lookup({id => $element_id});
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

    # output burner.  It's unfortunate that this isn't a string.  This
    # is another piece of code that would need to be modified to add a
    # new burner...
    my $burner_id = $element->get_burner();
    if ($burner_id == Bric::Biz::AssetType::BURNER_MASON) {
        $writer->dataElement(burner => "Mason");
    } elsif ($burner_id == Bric::Biz::AssetType::BURNER_TEMPLATE) {
        $writer->dataElement(burner => "HTML::Template");
    } else {
        throw_ap(error => __PACKAGE__ . "::export : unknown burner \"$burner_id\""
                   . " for element type \"$element_id\".");
    }

    # get type name
    $writer->dataElement(type => $element->get_type_name);

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
        $writer->dataElement(subelement_type => $_->get_key_name);
    }
    $writer->endTag("subelement_types");

    # output fields
    $writer->startTag("fields");
    foreach my $data ($element->get_data) {
        my $meta = $data->get_meta('html_info');
        # print STDERR Data::Dumper->Dump([$meta, $data], [qw(meta data)])
        #    if DEBUG;

        # start <field>
        $writer->startTag("field");

        # required elements
        $writer->dataElement(type       => $meta->{type});
        $writer->dataElement(key_name   => $data->get_key_name);
        $writer->dataElement(label      => $meta->{disp});
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
    $writer->endTag('element_type');
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
