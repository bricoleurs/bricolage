package Bric::SOAP::Desk;

###############################################################################

use strict;
use warnings;

use Bric::Biz::Workflow::Parts::Desk;
use Bric::Biz::Workflow;

use Bric::App::Authz    qw(chk_authz READ CREATE EDIT);
use Bric::App::Event    qw(log_event);
use Bric::SOAP::Util    qw(parse_asset_document);
use Bric::Util::Fault   qw(throw_ap);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;


=head1 Name

Bric::SOAP::Desk - SOAP interface to Bricolage desks

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

  # set uri for Desk module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Desk');

  # get a list of all desk IDs
  my $ids = $soap->list_ids()->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage desks.

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching desks and returns a
list of ids.  If no desks are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The desk's name.

=item description

The desk's description.

=item publish

Set true to return only publish desks, or false to return
only non-publish desks. Returns all desks by default.

=item active

Set false to return deleted desks. Returns only active
desks by default.

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

=item desk_id

Specifies a single desk_id to be retrieved.

=item desk_ids

Specifies a list of desk_ids.  The value for this option should be an
array of integer "desk_id" assets.

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

A list of "desk_id" integers for the assets to be updated.  These
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

=item desk_id

Specifies a single asset ID to be deleted.

=item desk_ids

Specifies a list of asset IDs to delete.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

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

    # delete the desks
    foreach my $id (@{$args->{"$module\_ids"}}) {
        print STDERR "$pkg\->$method() : deleting $module\_id $id\n"
          if DEBUG;

        # lookup the desk
        my $desk = $pkg->class->lookup({ id => $id });
        throw_ap(error => "$pkg\::$method : no $module found for id \"$id\"")
          unless $desk;
        throw_ap(error => "$pkg\::$method : access denied for $module \"$id\".")
          unless chk_authz($desk, EDIT, 1);

        # don't delete desks with assets still on them
        my @assets = $desk->assets;
        throw_ap(error => "$pkg\::$method : can't delete desk with assets "
                   . "for $module \"$id\".")
          if @assets;

        # remove desk from all its workflows
        my @workflows = Bric::Biz::Workflow->list({ desk_id => $id });
        foreach my $wf (@workflows) {
            $wf->del_desk([$id]);
            $wf->save;
        }

        # delete the desk
        $desk->deactivate;
        $desk->save;
        log_event("$module\_deact", $desk);
    }
    return name(result => 1);
}

=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'desk' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        list_ids => { map { $_ => 1 } qw(name description publish active) },
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
        eval { $data = parse_asset_document($document, $module) };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no $module found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{$module};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over desks, filling @ids
    my (@ids, %paths);

    foreach my $adata (@{ $data->{$module} }) {
        my $id = $adata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # get object
        my $asset;
        unless ($update) {
            # create empty desk
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
        if ($adata->{publish}) {
            $asset->make_publish_desk;
        } else {
            $asset->make_regular_desk;
        }

        # save
        $asset->save();
        log_event("$module\_" . ($update ? 'save' : 'new'), $asset);

        # all done
        push(@ids, $asset->get_id);
    }

    return name(ids => [ map { name("$module\_id" => $_) } @ids ]);
}


=item $pkg->serialize_asset( writer   => $writer,
                             desk_id  => $id,
                             args     => $args)

Serializes a single desk object into a <desk> desk using
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

    # open desk element
    $writer->startTag($module, id => $id);

    # write out simple attributes in schema order
    $writer->dataElement(name        => $asset->get_name);
    $writer->dataElement(description => $asset->get_description);
    $writer->dataElement(publish     => ($asset->can_publish ? 1 : 0));
    $writer->dataElement(active      => ($asset->is_active ? 1 : 0));

    # close desk element
    $writer->endTag($module);
}

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

Scott Lanning <lannings@who.int>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>, L<Bric::SOAP::Asset|Bric::SOAP::Asset>,
L<Bric::Biz::Workflow::Parts::Desk|Bric::Biz::Workflow::Parts::Desk>

=cut

1;
