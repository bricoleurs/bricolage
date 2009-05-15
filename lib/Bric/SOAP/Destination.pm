package Bric::SOAP::Destination;

###############################################################################

use strict;
use warnings;

use Bric::Biz::OutputChannel;
use Bric::Dist::Server;
use Bric::Dist::ServerType;
use Bric::Dist::Action::Email;

use Bric::App::Authz  qw(chk_authz READ CREATE);
use Bric::App::Event  qw(log_event);
use Bric::App::Util   qw(get_package_name);
use Bric::Biz::Site;
use Bric::SOAP::Util  qw(parse_asset_document site_to_id output_channel_name_to_id);
use Bric::Util::DBI   qw(ANY);
use Bric::Util::Fault qw(throw_ap);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;


=head1 Name

Bric::SOAP::Destination - SOAP interface to Bricolage destinations

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

  # set uri for Destination module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Destination');

  # get a list of all destination IDs
  my $ids = $soap->list_ids()->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage destinations.

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching destinations and returns a
list of ids.  If no destinations are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The destination's name.

=item description (M)

The destination's description.

=item move_method

The destination's move method, like FTP or File System.

=item site

The destination's site name.

=item output_channel

A name of an output channel associated with the destination.

=item can_copy

A boolean indicating whether the 'Copy Resources' checkbox is checked.

=item can_publish

A boolean indicating whether the 'Publishes' checkbox is checked.

=item can_preview

A boolean indicating whether the 'Previews' checkbox is checked.

=item active

A boolean; set false to return deleted destinations.

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

=item dest_id

Specifies a single dest_id to be retrieved.

=item dest_ids

Specifies a list of dest_ids.  The value for this option should be an
array of integer "dest_id" assets.

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

A list of "dest_id" integers for the assets to be updated.  These
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

=item dest_id

Specifies a single asset ID to be deleted.

=item dest_ids

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

# I was going to call it 'destination', because 'dest' might be confused
# with 'desk'; but, in addition to requiring overriding the `class' method
# (which is trivial), it'd also require overriding for example the `delete'
# method *only* because the event name for that is called "dest_deact",
# which in Bric::SOAP::Asset is gotten as "$module\_deact".
sub module { 'dest' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        list_ids => { map { $_ => 1 } qw(name description move_method
                                         can_copy can_publish can_preview
                                         site output_channel active) },
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
                                            'output_channel', 'action', 'server') };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no $module found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{$module};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over destinations, filling @ids
    my (@ids);

    foreach my $adata (@{ $data->{$module} }) {
        my $id = $adata->{id};

        # Are we updating?
        my $update = exists $to_update{$id};

        # Get object
        my $asset;
        if ($update) {
            # Updating
            $asset = $pkg->class->lookup({ id => $id });
            throw_ap(error => __PACKAGE__ . "::update : no $module found for \"$id\"")
              unless $asset;
        } else {
            # Create empty destination
            $asset = $pkg->class->new();
            throw_ap(error => __PACKAGE__ . " : failed to create empty $module object.")
              unless $asset;
            print STDERR __PACKAGE__ . " : created empty module object\n"
                if DEBUG;

            $id = $asset->get_id;
        }
        throw_ap(error => __PACKAGE__ . " : access denied.")
          unless chk_authz($asset, CREATE, 1);

        # Set move method if: it's not set, or it's different
        # (see "Side Effects" in Bric::Biz::ServerType _get_mover_class)
        if (! $asset->get_move_method
              or $adata->{move_method} ne $asset->get_move_method)
        {
            # first check that it's a valid move_method
            my %move_methods = map { $_ => 1 } Bric::Dist::ServerType->list_move_methods;
            throw_ap(error => __PACKAGE__ . ' : '
                       . $adata->{move_method} . ' is not a valid move method.')
              unless exists $move_methods{$adata->{move_method}};

            # then set, save, and re-instantiate
            $asset->set_move_method($adata->{move_method});
            if ($update) {
                $asset->save();
                $asset = Bric::Dist::ServerType->lookup({ id => $id });
            }
        }

        # Site
        my $site_id = site_to_id(__PACKAGE__, $adata->{site});
        $asset->set_site_id($site_id);

        # Make sure name isn't already taken for this site
        my $name = $adata->{name};
        my $st = Bric::Dist::ServerType->lookup({name => $name, site_id => $site_id});
        throw_ap(error => __PACKAGE__
                   . " : destination already exists with name '$name' for site_id '$site_id'.")
          if defined $st and $st->get_id != $id;

        # Set simple attributes
        $asset->set_name($adata->{name});
        $asset->set_description($adata->{description});

        # Set booleans
        $adata->{can_copy}    ? $asset->copy       : $asset->no_copy;
        $adata->{can_publish} ? $asset->on_publish : $asset->no_publish;
        $adata->{can_preview} ? $asset->on_preview : $asset->no_preview;
        $asset->save();   # XXX: otherwise, these don't stick......

        # In case these are empty..
        foreach my $array (qw(output_channel action server)) {
            unless ($adata->{$array . 's'}) {
                $adata->{$array . 's'} = { $array => [] };
            }
        }

        # Output channels
        my %old = map { $_->get_id => $_ } $asset->get_output_channels;
        my %new = map {
            my $oc = Bric::Biz::OutputChannel->lookup({name => $_, site_id => $site_id});
            throw_ap(error => __PACKAGE__
                       . " : no output channel with name '$_' for site_id '$site_id'.")
              unless defined $oc;
            $oc->get_id => $oc;
        } @{ $adata->{output_channels}{output_channel} };

        # add the OCs that are new
        my @add = map { $new{$_} } grep { ! exists $old{$_} } keys %new;
        $asset->add_output_channels(@add) if @add;
        # remove the OCs that are gone
        my @del = map { $old{$_} } grep { ! exists $new{$_} } keys %old;
        $asset->del_output_channels(@del) if @del;


        # Actions
        # remove them all - I did this because I thought juggling
        # everything would be too difficult (c.f. output channels,
        # which are unordered, don't have potentially multiple
        # objects of the same "type", and exist independently of dests
        # so they're just associated not created)
        @del = $asset->get_actions;
        $asset->del_actions(@del);

        # add the current ones
        # (order is done this way to prevent gaps/duplicates in numbers)
        my $order = 1;
        foreach my $action (sort { $a->{order} <=> $b->{order} }
                              @{ $adata->{actions}{action} })
        {
            # create new action, set common attributes
            my $new_action = $asset->new_action({ type => $action->{type} });
            $new_action->set_ord($order++);

            # take care of additional attributes, if any
            if ($new_action->has_more) {
                if ($new_action->get_type eq 'Email') {
                    foreach my $attr (qw(from to cc bcc subject content_type
                                         handle_text handle_other))
                    {
                        my $method = "set_$attr";
                        my $val = $action->{$attr};

                        my $meths = Bric::Dist::Action::Email->my_meths;
                        if ($meths->{$attr}{props}{type} eq 'select') {
                            # handle_text, handle_other...
                            my %nums = map { @$_ }
                              reverse @{ $meths->{$attr}{props}{vals} };
                            $val = $nums{$val};
                        }
                        $new_action->$method($val);
                    }
                }
            }

            $new_action->save();
        }


        # Servers
        # XXX: $asset->get_server only gets active ones...
        %old = map { $_->get_host_name => $_ }
          Bric::Dist::Server->list({ server_type_id => $id });

        # add the current ones
        foreach my $server (@{ $adata->{servers}{server} }) {
            my $host = $server->{host_name};
            my $server_obj;
            if (exists $old{$host}) {
                # update old
                $server_obj = $old{$host};
                foreach my $attr (qw(host_name os doc_root login password cookie)) {
                    my $method = "set_$attr";
                    $server_obj->$method($server->{$attr});
                }
            } else {
                # create new
                $server_obj = $asset->new_server({
                    host_name => $server->{host_name},
                    os        => $server->{os},
                    doc_root  => $server->{doc_root},
                    login     => $server->{login},
                    password  => $server->{password},
                    cookie    => $server->{cookie},
                });
            }
            $server->{active} ? $server_obj->activate() : $server_obj->deactivate();
            $server_obj->save();
        }

        # remove old ones
        %new = map { $_->{host_name} => 1 } @{ $adata->{servers}{server} };
        @del = map { $old{$_} } grep { ! exists $new{$_} } keys %old;
        $asset->del_servers(@del) if @del;


        # Save the destination
        $asset->save();
        log_event("$module\_" . ($update ? 'save' : 'new'), $asset);

        push(@ids, $asset->get_id);
    }

    return name(ids => [ map { name("$module\_id" => $_) } @ids ]);
}


=item $pkg->serialize_asset( writer   => $writer,
                             dest_id  => $id,
                             args     => $args)

Serializes a single destination object into a <destination> destination using
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

    # open destination element
    $writer->startTag($module, id => $id);

    # write out simple attributes in schema order
    $writer->dataElement(name        => $asset->get_name);
    $writer->dataElement(description => $asset->get_description);
    $writer->dataElement(move_method => $asset->get_move_method);
    $writer->dataElement(can_copy    => ($asset->can_copy ? 1 : 0));
    $writer->dataElement(can_publish => ($asset->can_publish ? 1 : 0));
    $writer->dataElement(can_preview => ($asset->can_preview ? 1 : 0));

    # Write out the name of the site.
    my $site = Bric::Biz::Site->lookup({ id => $asset->get_site_id });
    $writer->dataElement(site => $site->get_name);

    # Write out the output channels
    $writer->startTag('output_channels');
    foreach my $oc ($asset->get_output_channels) {
        $writer->dataElement(output_channel => $oc->get_name);
    }
    $writer->endTag('output_channels');

    # Actions
    $writer->startTag('actions');
    foreach my $action (sort { $a->get_ord <=> $b->get_ord } $asset->get_actions) {
        $writer->startTag('action', type => $action->get_type,
                                    order => $action->get_ord);
        # XXX: Email (or others in future) has more attributes.
        # I have no idea how to handle this variability cleanly...
        my $pkg = ref $action;
        if ($pkg->has_more) {
            if ($pkg eq 'Bric::Dist::Action::Email') {
                my $meths = $pkg->my_meths;
                foreach my $attr (qw(from to cc bcc subject content_type
                                     handle_text handle_other))
                {
                    my $method = "get_$attr";
                    my $val = $action->$method;
                    if ($meths->{$attr}{props}{type} eq 'select') {
                        # handle_text, handle_other - get displayed values
                        my %labels = map { @$_ } @{ $meths->{$attr}{props}{vals} };
                        # XXX: get_* apparently aren't defined initially...
                        $val = (defined $val && exists $labels{$val})
                          ? $labels{$val} : $labels{$meths->{$attr}{props}{vals}->[0][0]};
                    }
                    $writer->dataElement($attr => $val);
                }

            }
        }
        $writer->endTag('action');
    }
    $writer->endTag('actions');

    # Servers
    $writer->startTag('servers');
    # don't use $asset->get_servers here, b/c it only returns active ones
    foreach my $server (Bric::Dist::Server->list({server_type_id => $id})) {
        $writer->startTag('server');

        foreach my $attr (qw(host_name os doc_root login password cookie active)) {
            my $method = ($attr eq 'active') ? 'is_active' : "get_$attr";
            my $val = $server->$method;
            if ($attr eq 'password') {
                # don't show password...
                $val = '';
            } elsif ($attr eq 'active') {
                $val = $val ? 1 : 0;
            }
            $writer->dataElement($attr => $val);
        }

        $writer->endTag('server');
    }
    $writer->endTag('servers');

    $writer->dataElement(active => ($asset->is_active ? 1 : 0));

    # close destination element
    $writer->endTag($module);
}

=back

=head1 Author

Scott Lanning <slanning@cpan.org>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>, L<Bric::SOAP::Asset|Bric::SOAP::Asset>

=cut

1;
