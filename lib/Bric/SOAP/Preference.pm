package Bric::SOAP::Preference;

###############################################################################

use strict;
use warnings;

use Bric::Util::Pref;

use Bric::App::Authz    qw(chk_authz READ CREATE);
use Bric::App::Event    qw(log_event);
use Bric::SOAP::Util    qw(parse_asset_document);
use Bric::Util::Fault   qw(throw_ap throw_dp throw_mni);

use List::Util;

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 Name

Bric::SOAP::Preference - SOAP interface to Bricolage preferences

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

  # set uri for Preference module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Preference');

  # get a list of all preference IDs
  my $ids = $soap->list_ids()->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage preferences.
Note that per-user preferences are not handled here (probably should be added
to the User module).

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching preferences and returns
a list of ids.  If none are found, an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The preference's name.

=item description (M)

The preference's description.

=item default (M)

The preference's default value. Note: for values listed as "Off" or "On"
in the UI, this will be "0" or "1".

=item value (M)

The preference's value. Note: for values listed as "Off" or "On"
in the UI, this will be "0" or "1". See C<val_name>.

=item val_name (M)

The name of the preference's value. This is what's displayed in the UI.
See C<value>.

=item manual

Boolean indicating whether a value can be manually entered by the user,
rather than selected from a list.

=item can_be_overridden

Boolean indicating whether or not users can override the global preference
value.

=item opt_type

The preference option type. Current possibilities are: select, radio, text.
(I think (from displayFormElement.mc) in principle also: password, textarea,
checkbox, single_rad, date; and codeselect could be easily added.
No preferences currently have any of these types, however.)

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

=item pref_id

Specifies a single pref to be retrieved.

=item pref_ids

Specifies a list of pref_ids.  The value for this option should be an
array of integer "pref_id" assets.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

=item create

This method is unavailable for preferences, since they aren't createable.

=cut

sub create {
    throw_mni error => __PACKAGE__ . " has no 'create' method.";
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

A list of "pref_id" integers for the assets to be updated.  These
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

Notes: Most information output by C<export> will be ignored on update.
For example, you can't change the list of possible values, or whether
a preference is "manual". Those are things that are hardcoded into
Bricolage. See the C<register_fields> call in
L<Bric::Util::Pref|Bric::Util::Pref> for which fields are "RDWR"
(currently C<value> and C<can_be_overridden>).

=cut

=item delete

This method is unavailable for preferences, since they aren't deleteable.

=cut

sub delete {
    throw_mni error => __PACKAGE__ . " has no 'delete' method.";
}

=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'pref' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        list_ids => { map { $_ => 1 } qw(name description default value val_name
                                         manual can_be_overridden opt_type) },
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

This method provides the meat of update().

=cut

sub load_asset {
    my ($pkg, $args) = @_;
    my $document     = $args->{document};
    my $data         = $args->{data};
    my %to_update    = map { $_ => 1 } @{$args->{update_ids}};
    my $module       = $pkg->module;

    # Parse and catch errors
    unless ($data) {
        eval { $data = parse_asset_document($document, $module, 'opt') };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no $module found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{$module};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # Loop over prefs, filling @ids
    my (@ids);

    foreach my $adata (@{ $data->{$module} }) {
        my $id = $adata->{id};

        # get object
        my $asset = $pkg->class->lookup({ id => $id });
        throw_ap(error => __PACKAGE__ . "::update : no $module found for \"$id\"")
          unless $asset;
        throw_ap(error => __PACKAGE__ . " : access denied.")
          unless chk_authz($asset, CREATE, 1);

        # Everything except value and can_be_overridden is ignored!
        # (See note to the update method.)
        $asset->set_can_be_overridden($adata->{can_be_overridden});

        my $opts = $asset->get_opts_href;
        # Make sure the value is allowed; or if it's fill-in-the-blank,
        # then let them put whatever they want
        if (exists $opts->{$adata->{value}} or $asset->get_manual) {
            $asset->set_value($adata->{value});
        } else {
            throw_dp error => __PACKAGE__ . " : invalid 'value' for id=$id.";
        }

        # Save
        $asset->save();
        log_event("$module\_save", $asset);

        push(@ids, $asset->get_id);
    }

    return name(ids => [ map { name("$module\_id" => $_) } @ids ]);
}


=item $pkg->serialize_asset( writer   => $writer,
                             pref_id  => $id,
                             args     => $args)

Serializes a single pref object into a <pref> pref
using the given writer and args.

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

    $writer->startTag($module, id => $id);

    $writer->dataElement(name        => $asset->get_name);
    $writer->dataElement(description => $asset->get_description);
    $writer->dataElement(can_be_overridden => ($asset->get_can_be_overridden ? 1 : 0));
    $writer->dataElement(opt_type    => $asset->get_opt_type);
    $writer->dataElement(manual      => ($asset->get_manual ? 1 : 0));
    $writer->dataElement(default     => $asset->get_default);
    $writer->dataElement(value       => $asset->get_value);
    # Use <opts>. Not exporting val_name makes it where the user only has
    # to update one thing, not to mention we only have to check one thing.
    # $writer->dataElement(val_name    => $asset->get_val_name);

    $writer->startTag('opts');
    my $opts = $asset->get_opts_href;
    foreach my $opt (sort { $opts->{$a} cmp $opts->{$b} } keys %$opts) {
        unless ($asset->get_manual) {
            # If it's fill-in-the-blank, options don't make sense
            $writer->startTag('opt');
            $writer->dataElement(value => $opt);
            $writer->dataElement(val_name => $opts->{$opt});
            $writer->endTag('opt');
        }
    }
    $writer->endTag('opts');

    $writer->endTag($module);
}

=back

=head1 Author

Scott Lanning <slanning@cpan.org>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>, L<Bric::SOAP::Asset|Bric::SOAP::Asset>

=cut

1;
