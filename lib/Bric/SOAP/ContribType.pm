package Bric::SOAP::ContribType;

###############################################################################

use strict;
use warnings;

use Bric::Util::Grp::Person;
# See the Notes to `list' in Bric::Util::Grp
for (keys %{ Bric::Util::Grp::Person->get_supported_classes }) {
    eval "require $_";
}

use Bric::App::Authz    qw(chk_authz READ CREATE);
use Bric::App::Event    qw(log_event);
use Bric::SOAP::Util    qw(parse_asset_document);
use Bric::Util::Fault   qw(throw_ap throw_dp);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

# For consistency, this maps the "meta" names to names used by ElementType
my %FIELD_MAP = (
    disp => 'name',
    pos => 'place',
    type => 'widget_type',
    value => 'default_val',
    vals => 'options',
    multiple => 'multiple',
    length => 'length',
    maxlength => 'max_size',
    rows => 'rows',
    cols => 'cols',
    precision => 'precision',
);

=head1 Name

Bric::SOAP::ContribType - SOAP interface to Bricolage contributor types

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

  # set uri for ContribType module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/ContribType');

  # get a list of all contributor type IDs
  my $ids = $soap->list_ids()->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage contributor
types.

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching contributor types and returns
a list of ids.  If none are found, an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The contributor type's name.

=item description (M)

The contributor type's description.

=item active

Set false to return deleted contributor types.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

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

    # exclude 'All Contributors' (XXX: only part overridden from Asset.pm)
    $args->{secret} = 1;
    $args->{permanent} = 0;

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

=item contrib_type_id

Specifies a single contrib_type to be retrieved.

=item contrib_type_ids

Specifies a list of contrib_type_ids.  The value for this option should be an
array of integer "contrib_type_id" assets.

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

A list of "contrib_type_id" integers for the assets to be updated.  These
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

=item contrib_type_id

Specifies a single asset ID to be deleted.

=item contrib_type_ids

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

sub module { 'contrib_type' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        list_ids => { map { $_ => 1 } qw(name description active) },
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
        eval { $data = parse_asset_document($document,
                                            $module,
                                            'field_type',
                                        ) };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no $module found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{$module};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over contrib types, filling @ids
    my (@ids, %paths);

    foreach my $adata (@{ $data->{$module} }) {
        my $id = $adata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # get object
        my $asset;
        unless ($update) {
            # create empty contrib type
            $asset = $pkg->class->new();
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

        # set hellish fields...

        my $old_data = $asset->all_for_member_subsys;
        my %updated_data;

        my $place = 0;
        unless ($adata->{field_types}) {
            # Just in case there aren't any <field_type> elements
            $adata->{field_types} = {field_type => []};
        }

        # This is sorted according to 'place', but the actual number
        # isn't used, to prevent gaps and duplicates in the numbers
        foreach my $field (sort { $a->{place} <=> $b->{place} }
                             @{ $adata->{field_types}{field_type} })
        {
            $place++;

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
            # XXX: quadruplicated now... (cf. comp/widgets/profile/displayAttrs.mc,
            # lib/Bric/App/Callback/Profile/FormBuilder.pm,
            # lib/Bric/SOAP/ElementType.pm)
            if ($field->{widget_type} eq 'codeselect') {
                my $code = $field->{options};
                my $items = eval "$code";
                unless (ref $items eq 'ARRAY' and !(@$items % 2)) {
                    throw_dp "Invalid codeselect code (didn't return an array ref of even size)";
                }
            }

            my $aname = $field->{key_name};

            # Update or add the field
            # I don't see an "add_member_attr", so I assume this makes new ones
            $asset->set_member_attr({
                name => $aname,
                sql_type => $sql_type,
                value => $field->{default_val},
            });

            # Update the field's meta values
            for (qw(disp pos type vals multiple length maxlength rows cols precision)) {
                my ($fieldname, $value) = ($_, $field->{$FIELD_MAP{$_}});

                # XXX: I'm not sure if this is sufficient, in particular
                # if serialize_asset outputs a blank element for a meta attr
                # that simply didn't exist before, this will *create* it
                # with a blank value. I hope there isn't code somewhere that
                # checks for the (non)existence of certain attributes.
                if (exists $field->{$FIELD_MAP{$fieldname}}) {
                    # It's in the XML, so update or add
                    $asset->set_member_meta({
                        name => $aname,
                        field => $fieldname,
                        value => $value,
                    });
                } else {
                    # It's not in the XML, so delete it,
                    # after checking that it already exists
                    my $params = { name => $aname, field => $fieldname };
                    if ($asset->get_member_meta($params)) {
                        $asset->delete_member_meta($params);
                    }
                }
            }

            # Remember updated fields, so that below we can delete the other
            # ones that are gone
            if ($old_data->{$aname}) {
                $updated_data{$aname} = 1;
            }
        }

        # if updating then fields might need deleting
        if ($update) {
            my @deleted;
            foreach my $f (keys %$old_data) {
                next if exists $updated_data{$f};
                push @deleted, $f;
                $asset->delete_member_attr({ name => $f });
                log_event("$module\_unext", $asset, { Name => $f });
            }

            if (DEBUG && @deleted) {
                print STDERR __PACKAGE__ . "::update : ".
                    "Deleted field types $adata->{key_name} => ",
                        join(', ', @deleted), "\n";
            }
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
                             contrib_type_id  => $id,
                             args     => $args)

Serializes a single contrib_type object into a <contrib_type> contrib_type
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

    # write out simple attributes in schema order
    $writer->dataElement(name        => $asset->get_name);
    $writer->dataElement(description => $asset->get_description);

    # set active flag
    $writer->dataElement(active => ($asset->is_active ? 1 : 0));

    # output fields (tried to be consistent with ElementType.pm)
    # Note: c.f. comp/admin/profile/contrib_type/dhandler,
    # comp/widgets/profile/displayAttrs.mc, and
    # lib/Bric/App/Callback/Profile/FormBuilder.pm
    $writer->startTag("field_types");

    my $meta = $asset->all_for_member_subsys;

    foreach my $field_type (keys %$meta) {
        my $data = $meta->{$field_type}{meta};

        $writer->startTag("field_type");

        # required elements (XXX: I'm not sure if they should be optional?
        # Will it hurt to add extra attributes to fields?)
        $writer->dataElement(key_name => $field_type);
        $writer->dataElement($FIELD_MAP{value} => $meta->{$field_type}{value});
        $writer->dataElement($FIELD_MAP{multiple} => $data->{multiple}{value} ? 1 : 0);

        my @attrs = qw(disp pos type vals length maxlength rows cols precision);
        for (sort { $FIELD_MAP{$a} cmp $FIELD_MAP{$b} } @attrs) {
            $writer->dataElement($FIELD_MAP{$_} => $data->{$_}{value});
        }

        # end <field>
        $writer->endTag("field_type");
    }

    $writer->endTag("field_types");

    $writer->endTag($module);
}

=back

=head1 Author

Scott Lanning <slanning@cpan.org>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>, L<Bric::SOAP::Asset|Bric::SOAP::Asset>

=cut

1;
