package Bric::SOAP::Element;
###############################################################################

use strict;
use warnings;

use Bric::Biz::AssetType;
use Bric::Biz::ATType;
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

Bric::SOAP::Element - SOAP interface to Bricolage element definitions.

=head1 VERSION

$Revision: 1.14 $

=cut

our $VERSION = (qw$Revision: 1.14 $ )[-1];

=head1 DATE

$Date: 2003-09-16 14:09:32 $

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
        my ($type_id) = Bric::Biz::ATType->list_ids(
                                 { name => $args->{type} });
        throw_ap(error => __PACKAGE__ . "::list_ids : no type found matching " .
                   "(type => \"$args->{type}\")")
          unless defined $type_id;
        $args->{type__id} = $type_id;
        delete $args->{type};
    }

    # handle output_channel => output_channel__id mapping
    if (exists $args->{output_channel}) {
        my ($output_channel_id) = Bric::Biz::OutputChannel->list_ids(
                                { name => $args->{output_channel} });
        throw_ap(error => __PACKAGE__ . "::list_ids : no output_channel found matching "
                   . "(output_channel => \"$args->{output_channel}\")")
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
contain at least one element object.

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

The update method updates element using the data in an XML document of
the format created by export().  A common use of update() is to
export() a selected element object, make changes to one or more fields
and then submit the changes with update().

Returns a list of new ids created in the order of the assets in the
document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one element and may contain any number of
related element objects.

=item update_ids (required)

A list of "element_id" integers for the assets to be updated.  These
must match id attributes on element elements in the document.  If you
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

The delete() method deletes elements.  It takes the following options:

=over 4

=item element_id

Specifies a single element_id to be deleted.

=item element_ids

Specifies a list of element_ids to delete.

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

sub module { 'element' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        list_ids => { map { $_ => 1 } qw(name description output_channel type top_level) },
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

=item $pkg->_load_element($args)

This method provides the meat of both create() and update().  The only
difference between the two methods is that update_ids will be empty on
create().

=cut

sub load_asset {
    my ($pkg, $args) = @_;
    my $document     = $args->{document};
    my $data         = $args->{data};
    my %to_update    = map { $_ => 1 } @{$args->{update_ids}};

    # parse and catch erros
    unless ($data) {
        eval { $data = parse_asset_document($document,
                                            'output_channel',
                                            'subelement',
                                            'field',
                                           ) };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__ .
                   " : problem parsing asset document : no element found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{element};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over element, filling @element_ids
    my @element_ids;
    my %fixup;
    foreach my $edata (@{$data->{element}}) {
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
                       . "\"$edata->{burner}\" for element \"$id\".");
        }

        # are we updating?
        my $update = exists $to_update{$id};

        # make sure this name isn't already taken
        my @list = Bric::Biz::AssetType->list_ids({ name => $edata->{name},
                                                    active => 0 });
        if (@list) {
            throw_ap(error => "Unable to create element \"$id\" named \"$edata->{name}\" : "
                       . "that name is already taken.")
              unless $update;
            throw_ap(error => "Unable to update element \"$id\" to have name " .
                       "$edata->{name}\" : that name is already taken.")
              unless $list[0] == $id;
        }

        my $element;
        unless ($update) {
            # instantiate a new object
            $element = Bric::Biz::AssetType->new({ type__id => $type_id });
        } else {
            # load element
            $element = Bric::Biz::AssetType->lookup({ id => $id });
            throw_ap(error => __PACKAGE__ . "::update : unable to find element \"$id\".")
              unless $element;

            # update type__id and zap cached type object (ugh)
            $element->_set(['type__id', '_att_obj'], [$type_id, undef]);

        }

        # set simple data
        $element->set_key_name($edata->{name});
        $element->set_description($edata->{description});
        $element->set_burner($burner);

        # remove all output_channels if updating
        if ($update) {
            $element->delete_output_channels([$element->get_output_channels]);

            # save required here or we end up with an SQL error at the
            # end.  this seems to be because oc adds are done before
            # deletes in _sync_output_channels...
            $element->save;
        }

        if ($type->get_top_level) {

            # assign output_channels
            my @ocids;
            my $primary_ocid;
            foreach my $ocdata (@{$edata->{output_channels}{output_channel}}) {
                # get name
                my $name = ref $ocdata ? $ocdata->{content} : $ocdata;
                my ($output_channel_id) = Bric::Biz::OutputChannel->list_ids(
                                             {name => $name});
                throw_ap(error => __PACKAGE__ ."::create : no output_channel found"
                           . " matching (output_channel => \"$name\")")
                  unless defined $output_channel_id;

                push(@ocids, $output_channel_id);
                $primary_ocid = $output_channel_id 
                    if ref $ocdata and $ocdata->{primary};
            }

            # sanity checks
            throw_ap(error => __PACKAGE__ . " : no output_channels defined!")
              unless @ocids;
            throw_ap(error => __PACKAGE__ . " : no primary output_channel defined!")
              unless defined $primary_ocid;

            # add output_channels to element
            $element->add_output_channels(\@ocids);
            $element->set_primary_oc_id($primary_ocid);
        }


        # remove all sub-elements if updating
        $element->del_containers([ $element->get_containers ])
            if $update;

        # find sub-elements and stash them in the fixup array.  This
        # is done because an Element could refer to another Element in
        # the same asset document.
        $edata->{subelements} ||= {subelement => []};
        foreach my $subdata (@{$edata->{subelements}{subelement}}) {
            # get name
            my $name = ref $subdata ? $subdata->{content} : $subdata;

            # add name to fixup hash for this element
            $fixup{$edata->{name}} = [] unless exists $fixup{$edata->{name}};
            push @{$fixup{$edata->{name}}}, $name;
        }

        # build hash of old data
        my (%old_data, %updated_data);
        if ($update) {
            my @data = $element->get_data();
            foreach my $data (@data) {
                $old_data{$data->get_key_name} = $data;
            }
        }

        # find fields and instantiate new data elements
        my $place = 0;
        $edata->{fields} ||= {field => []};
        foreach my $field (@{$edata->{fields}{field}}) {
            $place++; # next!

            # figure out sql_type, from widgets/formBuilder/element.mc
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
            if ($update and exists $old_data{$field->{name}}) {
                print STDERR __PACKAGE__ . "::update : ".
                    "Found old data object for $edata->{name} => ",
                        "$field->{name}.\n"
                            if DEBUG;
                $data = $old_data{$field->{name}};
                $data->set_key_name($field->{name});
                $data->set_required($field->{required});
                $data->set_quantifier($field->{repeatable});
                $data->set_sql_type($sql_type);
                $data->set_place($place);
                $data->set_publishable(1);
                $data->set_max_length($field->{max_size});
                $updated_data{$field->{name}} = 1;
            } else {
                # get a new data object
                print STDERR __PACKAGE__ . "::create : ".
                    "Creating new data object for $edata->{name} => ",
                        "$field->{name}.\n"
                            if DEBUG;
                $data = $element->new_data(
                                     { name        => $field->{name},
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
            log_event("element_attr_add", $element, { Name => $field->{label} });

            # (my eyes! they're on fire!  oh, sweet lord, why?  WHY
            # HAVE YOU DONE THIS TO ME?)
        }

        # if updating then data fields might need deleting
        if ($update) {
            my @deleted;
            foreach my $f (keys %old_data) {
                next if exists $updated_data{$f};
                push @deleted, $f;
                log_event("element_attr_del", $element, { Name => $f });
            }

            if (@deleted) {
                print STDERR __PACKAGE__ . "::update : ".
                    "Deleting data fields $edata->{name} => ",
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
        log_event('element_' . ($update ? 'save' : 'new'), $element);

        # add to list of created elements
        push(@element_ids, $element->get_id);
    }

    # run through fixup attaching sub-elements
    foreach my $element_name (keys %fixup) {
        my ($element) = Bric::Biz::AssetType->list({name => $element_name});
        my @sub_ids;

        foreach my $sub_name (@{$fixup{$element_name}}) {
            my ($sub_id) = Bric::Biz::AssetType->list_ids({name => $sub_name});
            throw_ap(error => __PACKAGE__ . " : no subelement found matching "
                       . "(subelement => \"$sub_name\") "
                       . "for element \"$element_name\".")
              unless defined $sub_id;
            push @sub_ids, $sub_id;
        }
        $element->add_containers(\@sub_ids);
        $element->save;
    }

    return name(ids => [ map { name(element_id => $_) } @element_ids ]);
}

=item $pkg->_serialize_element(writer => $writer, element_id => $element_id, args => $args)

Serializes a single element object into a <element> element using
the given writer and args.

=cut

sub serialize_asset {
    my $pkg         = shift;
    my %options     = @_;
    my $element_id  = $options{element_id};
    my $writer      = $options{writer};

    my $element = Bric::Biz::AssetType->lookup({id => $element_id});
    throw_ap(error => __PACKAGE__ . "::export : element_id \"$element_id\" not found.")
      unless $element;

    throw_ap(error => __PACKAGE__ .
        "::export : access denied for element \"$element_id\".")
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
        throw_ap(error => __PACKAGE__ . "::export : unknown burner \"$burner_id\""
                   . " for element \"$element_id\".");
    }

    # get type name
    $writer->dataElement(type => $element->get_type_name);

    # set active flag
    $writer->dataElement(active => ($element->is_active ? 1 : 0));

    # set top_level stuff if top_level
    if ($element->get_top_level) {
        $writer->dataElement(top_level => 1);
        my ($site_id) = Bric::Biz::Site->list_ids({ element_id => $element_id });
        my $primary_oc_id = $element->get_primary_oc_id($site_id);
        $writer->startTag("output_channels");
        foreach my $oc ($element->get_output_channels) {
            $writer->dataElement(output_channel => $oc->get_name,
                                 ($oc->get_id == $primary_oc_id and
                                  (primary => 1))
                                );
        }
        $writer->endTag("output_channels");
    } else {
        $writer->dataElement(top_level => 0);
    }

    # output subelements
    $writer->startTag("subelements");
    foreach ($element->get_containers) {
        $writer->dataElement(subelement => $_->get_key_name);
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
        $writer->dataElement(name  => $data->get_key_name);
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
