package Bric::SOAP::OutputChannel;

use strict;
use warnings;

use Bric::Biz::OutputChannel qw(:all);
use Bric::Biz::Site;

use Bric::App::Authz    qw(chk_authz READ CREATE);
use Bric::App::Event    qw(log_event);
use Bric::SOAP::Util    qw(parse_asset_document site_to_id);
use Bric::Util::Fault   qw(throw_ap);
use List::Util          qw(first);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;


=head1 Name

Bric::SOAP::OutputChannel - SOAP interface to Bricolage output channels

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

  # set uri for OutputChannel module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/OutputChannel');

  # get a list of all output channels
  my $ids = $soap->list_ids()->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage output channels.

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching output channels and returns a
list of ids.  If no output channels are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The output channel's name.

=item description (M)

The output channel's description.

=item site

The output channel's site.

=item protocol

The output channel's protocol.

=item filename

The output channel's filename.

=item file_ext

The output channel's file extension.

=item use_slug

Boolean; by default returns all output channels.

=item active

Boolean; set false to return deleted output channels.

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

    # handle site => site_id conversion
    # XXX: why don't Story.pm, etc. delete $args->{site} here?
    $args->{site_id} = site_to_id(__PACKAGE__, delete($args->{site}))
      if exists $args->{site};

    $args->{active} = 1 unless exists $args->{active};

    # name the results
    my @ids = $pkg->class->list_ids($args);
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

=item output_channel_id

Specifies a single output_channel_id to be retrieved.

=item output_channel_ids

Specifies a list of output_channel_ids.  The value for this option should
be an array of integer "output_channel_id" assets.

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

A list of "output_channel_id" integers for the assets to be updated.  These
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

=item output_channel_id

Specifies a single asset ID to be deleted.

=item output_channel_ids

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

sub module { 'output_channel' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        list_ids => { map { $_ => 1 } qw(name description site protocol
                                         filename file_ext burner
                                         use_slug active) },
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
        eval { $data = parse_asset_document($document, $module, 'include') };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no $module found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{$module};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over element types, filling @ids
    my (@ids, %paths);

    foreach my $adata (@{ $data->{$module} }) {
        my $id = $adata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # get object
        my $asset;
        unless ($update) {
            # create empty element type
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
        $asset->set_protocol($adata->{protocol});
        $asset->set_filename($adata->{filename});
        $asset->set_file_ext($adata->{file_ext});
        $asset->set_uri_format($adata->{uri_format});
        $asset->set_fixed_uri_format($adata->{fixed_uri_format});

        # set URI case
        if ($adata->{uri_case} =~ /^lower/i) {
            $asset->set_uri_case(LOWERCASE);
        } elsif ($adata->{uri_case} =~ /^upper/i) {
            $asset->set_uri_case(UPPERCASE);
        } else {
            $asset->set_uri_case(MIXEDCASE);
        }

        # set use_slug
        if ($adata->{use_slug}) {
            $asset->use_slug_on();
        } else {
            $asset->use_slug_off();
        }

        # Set burner.
        my $burners = Bric::Biz::OutputChannel->my_meths->{burner}->{props}{vals};
        my $burner  = first { $_->[1] eq $adata->{burner} } @$burners;
        throw_ap __PACKAGE__ . qq{:update : No such burner "$adata->{burner}" }
            . q{--Maybe it hasn't been installed?}
            unless $burner;
        $asset->set_burner($burner->[0]);

        # change site to ID
        my $site_ids = Bric::Biz::Site->list_ids({name => $adata->{site}});
        $asset->set_site_id($site_ids->[0]);  # there will only be one anyway

        # set includes
        if ($update) {
            # XXX: for some reason, del_includes with no arguments
            # doesn't delete anything, though its docs say it should
            # delete all the includes (the code (del_objs) doesn't
            # seem to indicate it would delete anything, actually...)
            # (See also: User.pm contacts - I think this is a bug
            # in del_objs)
            my @includes = $asset->get_includes;
            $asset->del_includes(@includes);
            $asset->save;
        }
        if ($adata->{includes} and $adata->{includes}{include}) {
            my @includes = ();
            foreach my $idata (@{ $adata->{includes}{include} }) {
                unless (ref $idata) {
                    # if there's no attribute, $idata is a scalar
                    throw_ap error => __PACKAGE__ . ": include \"$idata\" missing "
                      . "required 'site' attribute.";
                }
                my $include_name = $idata->{content};
                my $site_name = $idata->{site};
                my $sids = Bric::Biz::Site->list_ids({name => $site_name});
                my $oc_obj = Bric::Biz::OutputChannel->lookup({
                    name => $include_name,
                    site_id => $sids->[0],  # there will only be one anyway
                });
                push @includes, $oc_obj;
            }
            $asset->set_includes(@includes);
        }

        # Active?
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
                             output_channel_id  => $id,
                             args          => $args)

Serializes a single output channel object into an <output_channel> using
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

    # open output_channel element
    $writer->startTag($module, id => $id);

    # write out attributes in schema order
    $writer->dataElement(name             => $asset->get_name);
    $writer->dataElement(description      => $asset->get_description);
    $writer->dataElement(protocol         => $asset->get_protocol);
    $writer->dataElement(filename         => $asset->get_filename);
    $writer->dataElement(file_ext         => $asset->get_file_ext);
    $writer->dataElement(uri_format       => $asset->get_uri_format);
    $writer->dataElement(fixed_uri_format => $asset->get_fixed_uri_format);

    my %cases = (
        MIXEDCASE() => 'Mixed Case',
        LOWERCASE() => 'Lowercase',
        UPPERCASE() => 'Uppercase',
    );
    $writer->dataElement(uri_case => $cases{$asset->get_uri_case});
    $writer->dataElement(use_slug => ($asset->can_use_slug ? 1 : 0));

    my $burn_get = Bric::Biz::OutputChannel->my_meths->{burner_name}{get_meth};
    $writer->dataElement(burner => $burn_get->($asset));

    my $site = Bric::Biz::Site->lookup({id => $asset->get_site_id});
    $writer->dataElement(site => $site->get_name);

    $writer->startTag('includes');
    foreach my $oc ($asset->get_includes) {
        my $name = $oc->get_name;
        my $siteobj = Bric::Biz::Site->lookup({id => $oc->get_site_id});
        my $sitename = $siteobj->get_name;
        # output channels are uniquely specified by name and site
        $writer->dataElement(include => $name,
                             site => $sitename);
    }
    $writer->endTag('includes');

    # set active flag
    $writer->dataElement(active => ($asset->is_active ? 1 : 0));

    # close the output_channel element
    $writer->endTag($module);
}

=back

=head1 Author

Scott Lanning <lannings@who.int>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>, L<Bric::SOAP::Asset|Bric::SOAP::Asset>

=cut

1;
