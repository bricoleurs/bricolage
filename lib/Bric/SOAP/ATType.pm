package Bric::SOAP::ATType;

###############################################################################

use strict;
use warnings;

use Bric::Biz::ATType;
use Bric::Util::Class;

use Bric::App::Authz    qw(chk_authz READ CREATE);
use Bric::App::Event    qw(log_event);
use Bric::SOAP::Util    qw(parse_asset_document);
use Bric::Util::Fault   qw(throw_ap);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;


=head1 Name

Bric::SOAP::ATType - SOAP interface (deprecated) to Bricolage element type sets

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

  # set uri for ATType set module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/ATType');

  # get a list of all element type sets
  my $ids = $soap->list_ids()->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage element type sets.
This interface is deprecated and will be removed in version 1.12.

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching element type sets set and returns a
list of ids.  If no element type sets are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The element type set's name.

=item description (M)

The element type set's description.

=item top_level

Boolean; return all top level element type sets.

=item paginated

Boolean; return all paginated element type sets.

=item fixed_url

Boolean; return all fixed URL element type sets.

=item related_story

Boolean; return all related story element type sets.

=item related_media

Boolean; return all related media element type sets.

=item media

Boolean; return all media element type sets.

=item active

Set false to return deleted element type sets.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut


=item export

The export method retrieves a set of assets from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned document.

Accepted paramters are:

=over 4

=item element_type_id

Specifies a single element_type_id to be retrieved.

=item element_type_ids

Specifies a list of element_type_ids.  The value for this option should be an
array of integer "element_type_id" assets.

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

Returns a list of new ids created in the order of the assets in the document.

Available options:

=over 4

=item document (required)

The XML document containing objects to be created.  The document must
contain at least one asset object.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

=item update

The update method updates an asset using the data in an XML document of
the format created by export().  A common use of update() is to
export() a selected object, make changes to one or more fields
and then submit the changes with update().

Returns a list of new ids created in the order of the assets in the
document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one asset and may contain any number
of related asset objects.

=item update_ids (required)

A list of "element_type_id" integers for the assets to be updated.  These
must match id attributes on asset elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

=item delete

The delete() method deletes assets.  It takes the following options:

=over 4

=item element_type_id

Specifies a single asset ID to be deleted.

=item element_type_ids

Specifies a list of asset IDs to delete.

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

sub module { 'element_type_set' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        list_ids => { map { $_ => 1 } qw(name description top_level paginated
                                         fixed_url related_story related_media
                                         media active) },
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
    my $module       = $pkg->module;

    # parse and catch errors
    unless ($data) {
        eval { $data = parse_asset_document($document, $module, 'ext') };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no $module found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{$module};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over element type sets, filling @ids
    my (@ids, %paths);

    foreach my $adata (@{ $data->{$module} }) {
        my $id = $adata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # get object
        my $asset;
        unless ($update) {
            # create empty element type set
            $asset = $pkg->class->new;
            throw_ap(error => __PACKAGE__ . " : failed to create empty $module object.")
              unless $asset;
            print STDERR __PACKAGE__ . " : created empty module object\n"
                if DEBUG;
        } else {
            # updating
            $asset = $pkg->class->lookup({ id => $id });
            throw_ap(error => __PACKAGE__ . "::update : no $module found for \"$id\"")
              unless $asset;
        }
        throw_ap(error => __PACKAGE__ . " : access denied.")
          unless chk_authz($asset, CREATE, 1);

        # set simple fields
        $asset->set_name($adata->{name});
        $asset->set_description($adata->{description});

        # set boolean fields
        $asset->set_top_level($adata->{top_level} ? 1 : 0);
        $asset->set_paginated($adata->{paginated} ? 1 : 0);
        $asset->set_fixed_url($adata->{fixed_url} ? 1 : 0);
        $asset->set_related_story($adata->{related_story} ? 1 : 0);
        $asset->set_related_media($adata->{related_media} ? 1 : 0);
        $asset->set_media($adata->{is_media} ? 1 : 0);

        # change business class to ID
        my $class = Bric::Util::Class->lookup({pkg_name => $adata->{biz_class}});
        $asset->set_biz_class_id($class->get_id);

        # active?
        if ($adata->{active}) {
            $asset->activate();
        } else {
            $asset->deactivate();
        }

        # save
        $asset->save();
        log_event("$module\_" . ($update ? 'save' : 'new'), $asset);

        # all done
        push(@ids, $asset->get_id);
    }

    return name(ids => [ map { name("$module\_id" => $_) } @ids ]);
}


=item $pkg->serialize_asset( writer        => $writer,
                             elementtype_id  => $id,
                             args          => $args)

Serializes a single element type set object into an <elementtype> using
the given writer and args.

=cut

sub serialize_asset {
    my $pkg         = shift;
    my %options     = @_;
    my $module      = $pkg->module;
    my $id          = $options{"$module\_id"};
    my $writer      = $options{writer};

    my $asset = $pkg->class->lookup({id => $id});
    throw_ap(error => __PACKAGE__ . "::export : $module\_id \"$id\" not found.")
      unless $asset;

    throw_ap(error => __PACKAGE__ .
               "::export : access denied for $module \"$id\".")
      unless chk_authz($asset, READ, 1);

    # open element_type_set element
    $writer->startTag($module, id => $id);

    # write out simple attributes in schema order
    $writer->dataElement(name        => $asset->get_name);
    $writer->dataElement(description => $asset->get_description);

    # write out boolean fields
    $writer->dataElement(top_level     => ($asset->get_top_level ? 1 : 0));
    $writer->dataElement(paginated     => ($asset->get_paginated ? 1 : 0));
    $writer->dataElement(fixed_url     => ($asset->get_fixed_url ? 1 : 0));
    $writer->dataElement(related_story => ($asset->get_related_story ? 1 : 0));
    $writer->dataElement(related_media => ($asset->get_related_media ? 1 : 0));
    $writer->dataElement(is_media      => ($asset->get_media ? 1 : 0));

    # change business class to ID
    my $class = Bric::Util::Class->lookup({id => $asset->get_biz_class_id});
    $writer->dataElement(biz_class     => $class->get_pkg_name);

    # set active flag
    $writer->dataElement(active => ($asset->is_active ? 1 : 0));

    # close the element_type_set element
    $writer->endTag($module);
}

=back

=head1 Author

Scott Lanning <lannings@who.int>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>, L<Bric::SOAP::Asset|Bric::SOAP::Asset>

=cut

1;
