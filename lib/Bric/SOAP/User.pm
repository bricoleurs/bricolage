package Bric::SOAP::User;

###############################################################################

use strict;
use warnings;

use Bric::Biz::Contact;
use Bric::Biz::Person::User;

use Bric::App::Authz    qw(chk_authz READ CREATE);
use Bric::App::Cache;
use Bric::App::Event    qw(log_event);
use Bric::SOAP::Util    qw(parse_asset_document);
use Bric::Util::Fault   qw(throw_ap);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;


=head1 Name

Bric::SOAP::User - SOAP interface to Bricolage users

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

  # set uri for User module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/User');

  # get a list of all user IDs
  my $ids = $soap->list_ids()->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage users.

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching users and returns a
list of ids.  If no users are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item prefix (M)

The user's prefix.

=item lname (M)

The user's last name.

=item fname (M)

The user's first name.

=item mname (M)

The user's middle name.

=item suffix (M)

The user's suffix.

=item login (M)

The user's login.

=item active

Set false to return deleted users.

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

=item user_id

Specifies a single user_id to be retrieved.

=item user_ids

Specifies a list of user_ids.  The value for this option should be an
array of integer "user_id" assets.

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

A list of "user_id" integers for the assets to be updated.  These
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

=item user_id

Specifies a single asset ID to be deleted.

=item user_ids

Specifies a list of asset IDs to delete.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: updates the last-modified user time in the cache
so that the UI reloads the users (unless you're a deleted user :).

Notes: NONE

=cut

sub delete {
    my $self = shift;
    my @deleted = $self->SUPER::delete(@_);
    my $cache = Bric::App::Cache->new;
    $cache->set_lmu_time;
    return @deleted;
}

=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'user' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        # XXX: should add grp (grp_id) to list_ids
        list_ids => { map { $_ => 1 } qw(prefix lname fname mname suffix login active) },
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
        eval { $data = parse_asset_document($document, $module, 'contact') };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no $module found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{$module};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over users, filling @ids
    my (@ids, %paths);

    my %contact_types = map { $_ => 1 } Bric::Biz::Contact->list_types;
    my $cache = Bric::App::Cache->new;

    foreach my $adata (@{ $data->{$module} }) {
        my $id = $adata->{id};

        # are we updating?
        my $update = $id && exists $to_update{$id};

        # get object
        my $asset;
        unless ($update) {
            # create empty user
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
        $asset->set_prefix($adata->{prefix});
        $asset->set_fname($adata->{fname});
        $asset->set_mname($adata->{mname});
        $asset->set_lname($adata->{lname});
        $asset->set_suffix($adata->{suffix});
        $asset->set_login($adata->{login});
        # XXX: currently not possible to change password

        # set contacts
        if ($update) {
            # XXX: for some reason, del_contacts with no arguments
            # doesn't delete anything, though its docs say it should
            # delete all the contacts (the code (del_objs) doesn't
            # seem to indicate it would delete anything, actually...)
            my @contacts = $asset->get_contacts;
            $asset->del_contacts(@contacts);
            $asset->save;
        }
        foreach my $udata (@{ $adata->{contacts}{contact} }) {
            unless (ref $udata) {
                # if there's no attribute, $udata is a scalar (type name)
                throw_ap error => __PACKAGE__ . ": contact \"$udata\" missing "
                  . "required 'type' attribute.";
            }
            my $value = $udata->{content};
            my $type = $udata->{type};
            unless (exists $contact_types{$type}) {
                throw_ap error => __PACKAGE__ . ": invalid contact type \"$type\".";
            }
            my $contact = $asset->new_contact($type, $value);
        }

        # save
        $asset->save();
        log_event("$module\_" . ($update ? 'save' : 'new'), $asset);

        # clear workflow caches for the UI
        foreach my $gid ($asset->get_grp_ids) {
            $cache->set("__WORKFLOWS__$gid", 0)
              if $cache->get("__WORKFLOWS__$gid");
        }

        # all done
        push(@ids, $asset->get_id);
    }

    # clear site cache, update last-modified user time for the UI
    $cache->set('__SITES__', 0);
    $cache->set_lmu_time;

    return name(ids => [ map { name("$module\_id" => $_) } @ids ]);
}


=item $pkg->serialize_asset( writer   => $writer,
                             user_id  => $id,
                             args     => $args)

Serializes a single user object into a <user> user using
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

    # open user element
    $writer->startTag($module, id => $id);

    # write out simple attributes in schema order
    $writer->dataElement(prefix => $asset->get_prefix);
    $writer->dataElement(fname  => $asset->get_fname);
    $writer->dataElement(mname  => $asset->get_mname);
    $writer->dataElement(lname  => $asset->get_lname);
    $writer->dataElement(suffix => $asset->get_suffix);
    $writer->dataElement(login  => $asset->get_login);
    # XXX: currently not possible to change password
    $writer->dataElement(password => '');
    $writer->dataElement(active => ($asset->is_active ? 1 : 0));

    # contacts
    $writer->startTag('contacts');
    my @contacts = $asset->get_contacts;
    foreach my $contact (@contacts) {
        my $type = $contact->get_type;
        my $value = $contact->get_value;
        $writer->dataElement(contact => $value, type => $type);
    }
    $writer->endTag('contacts');

    # close user element
    $writer->endTag($module);
}

=back

=head1 Author

Scott Lanning <lannings@who.int>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>, L<Bric::SOAP::Asset|Bric::SOAP::Asset>

=cut

1;
