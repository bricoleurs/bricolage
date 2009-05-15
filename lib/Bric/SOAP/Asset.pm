package Bric::SOAP::Asset;

###############################################################################

use strict;
use warnings;

use Bric::Config qw(:l10n);
use Bric::App::Authz  qw(chk_authz CREATE);
use Bric::Util::Fault qw(throw_ap throw_mni);
use Bric::App::Event  qw(log_event);
use Bric::App::Util   qw(get_package_name);
use Bric::SOAP::Util  qw(site_to_id output_channel_name_to_id);
use Bric::Util::Priv::Parts::Const qw(:all);

use IO::Scalar;

BEGIN {
    # XXX Turn off warnings so that we don't get XML::Writer's
    # Parameterless "use IO" deprecated warning.
    local $^W;
    require XML::Writer;
}

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 Name

Bric::SOAP::Asset - base class for SOAP "asset" classes

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Description

This module is the base class that for providing a SOAP interface for
manipulating Bricolage objects.

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching assets and returns a
list of ids.  If no assets are found an empty list will be returned.

Notes: You'll likely want to override this method unless your asset
is simple like MediaType.

=cut

sub list_ids {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'list_ids';
    my $module = $pkg->module;

    print STDERR __PACKAGE__ . "->$method() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::$method : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # handle site => site_id conversion
    $args->{site_id} = site_to_id(__PACKAGE__, delete $args->{site})
      if exists $args->{site};             # not everything has a <site>

    # handle output_channel => output_channel__id mapping
    $args->{output_channel_id} =
      output_channel_name_to_id(__PACKAGE__, delete $args->{output_channel}, $args)
      if exists $args->{output_channel};   # not everything has an <output_channel>

    $args->{active} = 1 unless exists $args->{active};
    my @ids = $pkg->class->list_ids($args);

    # name the results
    my @result = map { name("$module\_id" => $_) } @ids;

    # name the array and return
    return name("$module\_ids" => \@result);
}


=item export

The export method retrieves a set of assets from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned document.

Accepted paramters are:

=over 4

=item asset_id

Specifies a single asset_id to be retrieved. The name 'asset_id' will
actually be something like 'media_id'.

=item asset_ids

Specifies a list of asset_ids.  The value for this option should be an
array of integer "asset_id" assets. The name 'asset_ids' will
actually be something like 'media_ids'.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

sub export {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $module = $pkg->module;
    my $method = 'export';

    print STDERR "$pkg\->$method() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => "$pkg\::$method : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # sugar for one id
    $args->{"$module\_ids"} = [ $args->{"$module\_id"} ]
      if exists $args->{"$module\_id"};

    # make sure $module_ids is an array
    throw_ap(error => "$pkg\::$method : missing required $module\_id(s) setting.")
      unless defined $args->{"$module\_ids"};
    throw_ap(error => "$pkg\::$method : malformed $module\_id(s) setting.")
      unless ref $args->{"$module\_ids"} and ref $args->{"$module\_ids"} eq 'ARRAY';

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

    # iterate through ids, serializing objects as we go
    foreach my $id (@{$args->{"$module\_ids"}}) {
        $pkg->serialize_asset(writer         => $writer,
                              "$module\_id"  => $id,
                              args           => $args);
    }

    # end the assets category and end the document
    $writer->endTag("assets");
    $writer->end();
    $document_handle->close();

    # name, type and return
    Encode::_utf8_off($document) if ENCODE_OK;
    return name(document => $document)->type('base64');
}

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

sub create {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'create';

    print STDERR "$pkg\->$method() called : args : ",
      Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => "$pkg\::$method : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # make sure we have a document
    throw_ap(error => "$pkg\::$method : missing required document parameter.")
      unless $args->{document};

    # setup empty update_ids arg to indicate create state
    $args->{update_ids} = [];

    return $pkg->load_asset($args);
}


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

A list of "asset_id" integers for the assets to be updated.  These
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

sub update {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'update';

    print STDERR "$pkg\->$method() called : args : ",
      Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => "$pkg\::$method : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # make sure we have a document
    throw_ap(error => "$pkg\::$method : missing required document parameter.")
      unless $args->{document};

    # make sure we have an update_ids array
    throw_ap(error => "$pkg\::$method : missing required update_ids parameter.")
      unless $args->{update_ids};
    throw_ap(error => "$pkg\::$method : malformed update_ids parameter - must be an array.")
      unless ref $args->{update_ids} and ref $args->{update_ids} eq 'ARRAY';

    # unserialize the asset
    return $pkg->load_asset($args);
}


=item delete

The delete() method deletes assets.  It takes the following options:

=over 4

=item asset_id

Specifies a single asset ID to be deleted. The name 'asset_id'
will actually be something like 'mediatype_id'.

=item asset_ids

Specifies a list of asset IDs to delete. The name 'asset_ids'
will actually be something like 'mediatype_ids'.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: You'll likely want to override this method unless your asset
is simple like MediaType.

=cut

sub delete {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $module = $pkg->module;
    my $method = 'delete';

    print STDERR "$pkg\->$method() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => "$pkg\::$method : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # sugar for one id
    $args->{"$module\_ids"} = [ $args->{"$module\_id"} ]
        if exists $args->{"$module\_id"};

    # make sure asset_ids is an array
    throw_ap(error => "$pkg\::$method : missing required $module\_id(s) setting.")
      unless defined $args->{"$module\_ids"};
    throw_ap(error => "$pkg\::$method : malformed $module\_id(s) setting.")
      unless ref $args->{"$module\_ids"} and ref $args->{"$module\_ids"} eq 'ARRAY';

    # delete the asset
    foreach my $id (@{$args->{"$module\_ids"}}) {
        print STDERR "$pkg\->$method() : deleting $module\_id $id\n"
          if DEBUG;

        # lookup the asset
        my $asset = $pkg->class->lookup({ id => $id });
        throw_ap(error => "$pkg\::$method : no $module found for id \"$id\"")
          unless $asset;
        throw_ap(error => "$pkg\::$method : access denied for $module \"$id\".")
          unless chk_authz($asset, EDIT, 1);

        # delete the asset
        $asset->deactivate;
        $asset->save;
        log_event("$module\_deact", $asset);
    }
    return name(result => 1);
}

=item class

Return the package name used with lookup or list_ids.

=cut

sub class {
    my $pkg = shift;
    get_package_name($pkg->module);
}

=item module

Return the module name, that is the first argument passed to bric_soap.

=cut

sub module {
    throw_mni error => __PACKAGE__ . " subclasses must override the 'module' method";
}

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    throw_mni error => __PACKAGE__ . " subclasses must override the 'is_allowed_param' method";
}

=item $pkg->load_asset($args)

This method provides the meat of both create() and update(). It inputs XML.
The only difference between the two methods is that update_ids will be empty
on create().

=cut

sub load_asset {
    throw_mni error => __PACKAGE__ . " subclasses must override the 'load_asset' method";
}

=item $pkg->serialize_asset( writer    => $writer,
                             asset_id  => $id,
                             args      => $args)

Serializes a single asset into an XML element using
the given writer and args.

=cut

sub serialize_asset {
    throw_mni error => __PACKAGE__ . " subclasses must override the 'serialize_asset' method";
}


=back

=head1 Author

Scott Lanning <slanning@theworld.com>

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>

=cut

1;
