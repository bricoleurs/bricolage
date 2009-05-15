package Bric::SOAP::Media;

###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Media;
use Bric::Biz::ElementType;
use Bric::Biz::Category;
use Bric::Biz::Site;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Biz::Workflow qw(MEDIA_WORKFLOW);

use Bric::Util::Fault   qw(throw_ap);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ CREATE);
use Bric::App::Event    qw(log_event);
use Bric::Util::Priv::Parts::Const qw(:all);

use Bric::SOAP::Util qw(category_path_to_id
                        output_channel_name_to_id
                        workflow_name_to_id
                        site_to_id
                        xs_date_to_db_date
                        db_date_to_xs_date
                        parse_asset_document
                        serialize_elements
                        deserialize_elements
                        resolve_relations
                        load_ocs
                       );

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 Name

Bric::SOAP::Media - SOAP interface to Bricolage media.

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

  # set uri for Media module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Media');

  # get a list of media_ids for all Illustrations (a Media Type)
  my $media_ids = $soap->list_ids(name(element => 'Illustration'));

=head1 Description

This module provides a SOAP interface to manipulating Bricolage media.

=cut

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching media and returns a list
of ids.  If no media is found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item title (M)

The media title.

=item description (M)

The media description.

=item uri (M)

The media uri.

=item file_name (M)

The name of the file inside the media object.

=item simple (M)

A single OR search that hits title, description and uri.

=item category

The category containing the media, given as the complete category path
from the root.  Example: "/news/linux".

=item workflow

The name of the workflow containing the media.  (ex. Media)

=item priority

The priority of the media object.

=item element

The name of the top-level element for the media.  Also know as the
"Media Type".  This value corresponds to the element attribute on the
media element in the asset schema.

=item site

The name of the site which the story is in.

=item publish_date_start

Lower bound on publishing date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item publish_date_end

Upper bound on publishing date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item first_publish_date_start

Lower bound on the first date a media document was published. Given in XML
Schema dateTime format (CCYY-MM-DDThh:mm:ssTZ).

=item first_publish_date_end

Upper bound on the first date a media document was published. Given in XML
Schema dateTime format (CCYY-MM-DDThh:mm:ssTZ).

=item cover_date_start

Lower bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item cover_date_end

Upper bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_start

Lower bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_end

Upper bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item element_key_name (M)

The key name of the top-level element for the media document. This is more
accurate than the C<element> parameter, since there can be multiple elements
with the same name.

=item unexpired

Set to a true value to get a list of only unexpired stories.

=item subelement_key_name (M)

The key name for a container element that's a subelement of a media document.

=item data_text (M)

Text stored in the fields of the media document element or any of its
subelements. Only fields that use the "short" storage type will be searched.

=item output_channel

The name of an ouput channel that stories must be associated with.

=item keyword (M)

A keyword associated with a media document.

=item contrib_id

A Bricolage contributor object ID. Only stories associated with that
contributor will have their IDs listed.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: In addition to the parameters listed above, you can use most of the
parameters listed in the documentation for the list method in
Bric::Biz::Asset::Business::Media.

=cut

sub list_ids {
    my $self = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'list_ids';

    print STDERR __PACKAGE__ . "->list_ids() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::list_ids : unknown parameter \"$_\".")
          unless $self->is_allowed_param($_, $method);
    }

    # handle site => site_id conversion
    $args->{site_id} = site_to_id(__PACKAGE__, $args->{site})
      if exists $args->{site};

    # handle workflow => workflow__id mapping
    $args->{workflow_id} =
      workflow_name_to_id(__PACKAGE__, delete $args->{workflow}, $args)
      if exists $args->{workflow};

    # handle output_channel => output_channel__id mapping
    $args->{output_channel_id} =
      output_channel_name_to_id(__PACKAGE__, delete $args->{output_channel}, $args)
      if exists $args->{output_channel};

    # handle category => category_id conversion
    $args->{category_id} =
      category_path_to_id(__PACKAGE__, delete $args->{category}, $args)
      if exists $args->{category};

    # handle element => element_id conversion
    $args->{element_type} = $args->{element} if exists $args->{element};
    if (exists $args->{element_type}) {
        my ($element_id) = Bric::Biz::ElementType->list_ids({
            key_name => $args->{element_type},
            media => 1,
        });
        throw_ap(error => __PACKAGE__ . "::list_ids : no element found matching "
                   . "(element => \"$args->{element_type}\")")
          unless defined $element_id;
        $args->{element_type_id} = $element_id;
        delete $args->{element_type};
    }

    # translate dates into proper format
    for my $name (grep { /_date_/ } keys %$args) {
        my $date = xs_date_to_db_date($args->{$name});
        throw_ap(error => __PACKAGE__ . "::list_ids : bad date format for $name"
                   . " parameter \"$args->{$name}\" : must be proper XML Schema"
                   . " parameter dateTime format.")
          unless defined $date;
        $args->{$name} = $date;
    }

    my @list = Bric::Biz::Asset::Business::Media->list_ids($args);

    print STDERR "Bric::Biz::Asset::Business::Media->list_ids() called : ",
        "returned : ", Data::Dumper->Dump([\@list],['list'])
            if DEBUG;

    # name the results
    my @result = map { name(media_id => $_) } @list;

    # name the array and return
    return name(media_ids => \@result);
}

=item export

The export method retrieves a set of media from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item media_id

Specifies a single media_id to be retrieved.

=item media_ids

Specifies a list of media_ids.  The value for this option should be an
array of interger "media_id" elements.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: Bric::SOAP::Media->export doesn't provide equivalents to the
export_related_stories and export_related_media options in
Bric::SOAP::Story->export.  Related media and related stories will
always be returned with absolute id references.  If
you're... creative...  enough to be using related media and stories in
your Media types then you'll have to manually fetch the relations.

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
contain at least one media object.

=item workflow

Specifies the initial workflow the story is to be created in

=item desk

Specifies the initial desk the story is to be created on

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: The setting for publish_status in the incoming media is ignored
and always 0 for new media.

New stories are put in the first "media workflow" unless you pass in
the --workflow option. The start desk of the workflow is used unless
you pass the --desk option.

=cut


=item update

The update method updates media using the data in an XML document of
the format created by export().  A common use of update() is to
export() a selected media object, make changes to one or more fields
and then submit the changes with update().

Returns a list of new ids created in the order of the assets in the
document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one media and may contain any number of
related media objects.

=item update_ids (required)

A list of "media_id" integers for the assets to be updated.  These
must match id attributes on media elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=item workflow

Specifies the workflow to move the media to

=item desk

Specifies the desk to move the media to

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: The setting for publish_status for new media is ignored and
always 0 for new stories.  Updated media do get their publish_status
set from the incoming document.

=cut


=item delete

The delete() method deletes media.  It takes the following options:

=over 4

=item media_id

Specifies a single media_id to be deleted.

=item media_ids

Specifies a list of media_ids to delete.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

# hash of allowed parameters
sub delete {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'delete';

    print STDERR __PACKAGE__ . "->delete() called : args : ",
      Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::delete : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # media_id is sugar for a one-element media_ids arg
    $args->{media_ids} = [ $args->{media_id} ] if exists $args->{media_id};

    # make sure media_ids is an array
    throw_ap(error => __PACKAGE__ . "::delete : missing required media_id(s) setting.")
      unless defined $args->{media_ids};
    throw_ap(error => __PACKAGE__ . "::delete : malformed media_id(s) setting.")
      unless ref $args->{media_ids} and ref $args->{media_ids} eq 'ARRAY';

    # delete the media
    foreach my $media_id (@{$args->{media_ids}}) {
        print STDERR __PACKAGE__ . "->delete() : deleting media_id $media_id\n"
          if DEBUG;

        # first look for a checked out version
        my $media = Bric::Biz::Asset::Business::Media->lookup({ id => $media_id,
                                                                checkout => 1 });
        unless ($media) {
            # settle for a non-checked-out version and check it out
            $media = Bric::Biz::Asset::Business::Media->lookup({ id => $media_id });
            throw_ap(error => __PACKAGE__ . "::delete : no media found for id \"$media_id\"")
              unless $media;
            throw_ap(error => __PACKAGE__ . "::delete : access denied for media \"$media_id\".")
              unless chk_authz($media, EDIT, 1);
            $media->checkout({ user__id => get_user_id });
            log_event("media_checkout", $media);
        }

        # Remove the media from any desk it's on.
        if (my $desk = $media->get_current_desk) {
            $desk->checkin($media);
            $desk->remove_asset($media);
            $desk->save;
        }

        # Remove the media from workflow.
        if ($media->get_workflow_id) {
            $media->set_workflow_id(undef);
            log_event("media_rem_workflow", $media);
        }

        # Deactivate the media and save it.
        $media->deactivate;
        $media->save;
        log_event("media_deact", $media);
    }

    return name(result => 1);
}

=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'media' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

my $allowed = {
    list_ids => { map { $_ => 1 } qw(title description file_name simple uri
                                     priority publish_status workflow element
                                     category publish_date_start
                                     publish_date_end first_publish_date_start
                                     first_publish_date_end cover_date_start
                                     cover_date_end expire_date_start
                                     expire_date_end site alias_id
                                     element_key_name unexpired data_text
                                     output_channel keyword contrib_id
                                     subelement_key_name Order OrderDirection
                                     Offset Limit),
                  grep { /^[^_]/}
                    keys %{ Bric::Biz::Asset::Business::Media->PARAM_WHERE_MAP }
                },
    export   => { map { $_ => 1 } map { module() . "_$_" }  qw(id ids) },
    create   => { map { $_ => 1 } qw(document workflow desk) },
    update   => { map { $_ => 1 } qw(document update_ids workflow desk) },
};

$allowed->{delete} = $allowed->{export};

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
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
    my $data     = $args->{data};
    my %to_update = map { $_ => 1 } @{$args->{update_ids}};

    unless ($data) {
        # parse and catch errors
        eval { $data = parse_asset_document($args->{document}) };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__ .
                   " : problem parsing asset document : no media found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{media};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # Determine workflow and desk for media
    my ($workflow, $desk, $no_wf_or_desk_param);
    $no_wf_or_desk_param = ! (exists $args->{workflow} || exists $args->{desk});
    if (exists $args->{workflow}) {
        (my $look = $args->{workflow}) =~ s/([_%\\])/\\$1/g;
        $workflow = Bric::Biz::Workflow->lookup({ name => $look })
          || throw_ap error => "workflow '" . $args->{workflow} . "' not found!";
    }

    if (exists $args->{desk}) {
        (my $look = $args->{desk}) =~ s/([_%\\])/\\$1/g;
        $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ name => $look })
          || throw_ap error => "desk '" . $args->{desk} . "' not found!";
    }

    # loop over media, filling in @media_ids and @relations.
    my (%media_ids, @media_ids, %melems, @relations);
    foreach my $mdata (@{delete $data->{media}}) {
        my $id = $mdata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # are we aliasing?
        my $aliased = exists($mdata->{alias_id}) && $mdata->{alias_id} && ! $update
          ? Bric::Biz::Asset::Business::Media->lookup({
              id => $media_ids{$mdata->{alias_id}} || $mdata->{alias_id}
            })
          : undef;

        # setup init data for create
        my %init;

        # get user__id from Bric::App::Session
        $init{user__id} = get_user_id;

        # Get the site ID.
        $mdata->{site} = 'Default Site' unless exists $mdata->{site};
        $init{site_id} = site_to_id(__PACKAGE__, $mdata->{site});

        $mdata->{element_type} = delete $mdata->{element}
            if exists $mdata->{element};
        if (exists $mdata->{element_type} and not $aliased) {
            unless ($melems{$mdata->{element_type}}) {
                my $e = (Bric::Biz::ElementType->list({
                    key_name => $mdata->{element_type},
                    media    => 1,
                }))[0] or throw_ap(
                    error => __PACKAGE__ .
                      "::create : no media element found " .
                      "matching (element_type => \"$mdata->{element_type}\")"
                );
                $melems{$mdata->{element_type}} = [
                    $e->get_id,
                    { map { $_->get_name => $_ } $e->get_output_channels }
                ];
            }

            # get element object for asset type
            $init{element_type_id} = $melems{$mdata->{element_type}}->[0];

        } elsif ($aliased) {
            # It's an alias.
            $init{alias_id} = $mdata->{alias_id};
        } else {
            # It's bogus.
            throw_ap(error => __PACKAGE__ . "::create: No media element or alias ID found");
        }

        # get source__id from source
        ($init{source__id}) = Bric::Biz::Org::Source->list_ids
          ({ source_name => $mdata->{source} });
        throw_ap(error => __PACKAGE__ . "::create : no source found matching " .
                   "(source => \"$mdata->{source}\")")
          unless defined $init{source__id};

        # setup simple fields
        $init{priority} = $mdata->{priority};
        $init{name}     = $mdata->{name};

        # mix in dates
        $mdata->{publish_date} ||= $mdata->{first_publish_date}
            if $mdata->{first_publish_date};
        for my $name qw(cover_date expire_date publish_date first_publish_date) {
            my $date = $mdata->{$name};
            if ($date) {
                throw_ap error => __PACKAGE__ . "::create : $name must be undefined if publish_status is false"
                    if not $mdata->{publish_status} and $name =~ /publish/;

                my $db_date = xs_date_to_db_date($date);
                throw_ap(error => __PACKAGE__ . "::export : bad date format for $name : $date")
                    unless defined $db_date;
                $init{$name} = $db_date;
            } else {
                throw_ap error => __PACKAGE__ . "::create : $name must be defined if publish_status is true"
                    if $mdata->{publish_status} and $name =~ /publish/;
            }
        }

        # assign catgeory__id
        $init{category__id} =
          category_path_to_id(__PACKAGE__, $mdata->{category}[0], \%init)
          unless defined $init{category__id};

        # Determine workflow and desk.
        unless ($update && $no_wf_or_desk_param) {
            unless (exists $args->{workflow}) {  # already done above
                $workflow = (Bric::Biz::Workflow->list({
                    type => MEDIA_WORKFLOW,
                    site_id => $init{site_id}
                }))[0];
            }

            unless (exists $args->{desk}) {  # already done above
                $desk = $workflow->get_start_desk;
            }
        }

        # get base media object
        my $media;
        unless ($update) {
            # create empty media
            # XXX Put in supplied UUID?
            $media = Bric::Biz::Asset::Business::Media->new(\%init);
            throw_ap(error => __PACKAGE__ . "::create : failed to create empty media object.")
              unless $media;
            print STDERR __PACKAGE__ . "::create : created empty media object\n"
                if DEBUG;

            # Check permissions. The start desk group applies to the permissions.
            throw_ap(error => __PACKAGE__ . " : access denied.")
              unless chk_authz($media, CREATE, 1, $desk->get_asset_grp);
            if ($aliased) {
                # Log that we've created an alias.
                my $origin_site = Bric::Biz::Site->lookup
                  ({ id => $aliased->get_site_id });
                log_event("media_alias_new", $media,
                          { 'From Site' => $origin_site->get_name });
                my $site = Bric::Biz::Site->lookup({ id => $init{site_id} });
                log_event("media_aliased", $aliased,
                          { 'To Site' => $site->get_name });
            } else {
                # Log that we've created a new media asset.
                log_event('media_new', $media);
            }

        } else {
            # updating - first look for a checked out version
            $media = Bric::Biz::Asset::Business::Media->lookup({ id => $id,
                                                                 checkout => 1
                                                               });
            if ($media) {
                # make sure it's ours
                throw_ap(error => __PACKAGE__ .
                           "::update : media \"$id\" is checked out to another user.")
                  unless $media->get_user__id == get_user_id;
                throw_ap(error => __PACKAGE__ . " : access denied.")
                  unless chk_authz($media, EDIT, 1);
            } else {
                # try a non-checked out version
                $media = Bric::Biz::Asset::Business::Media->lookup({ id => $id });
                throw_ap(error => __PACKAGE__ . "::update : no media found for \"$id\"")
                  unless $media;
                throw_ap(error => __PACKAGE__ . " : access denied.")
                  unless chk_authz($media, RECALL, 1);

                # FIX: race condition here - between lookup and checkout
                #      someone else could checkout...

                # check it out
                $media->checkout( { user__id => get_user_id });
                $media->save();
                log_event('media_checkout', $media);
            }

            # Make sure that the UUID hasn't changed.
            if (exists $mdata->{uuid}) {
                throw_ap __PACKAGE__ . "::update: media \"$id\" has a different UUID"
                  if $media->get_uuid ne $mdata->{uuid};
            }

            # update %init fields
            delete @init{qw(element_id alias_id)};
            $media->_set([keys(%init)],[values(%init)]);
        }

        # set simple fields
        my @simple_fields = qw(description uri);
        $media->_set(\@simple_fields, [ @{$mdata}{@simple_fields} ]);

        # almost totally ignoring whatever publish_status is set to
        if ($update) {
            if ($media->get_publish_date or $media->get_first_publish_date) {
                # some publish date is set, so it must've been published
                $media->set_publish_status(1);
            } else {
                $media->set_publish_status($mdata->{publish_status});
            }
        } else {
            # creating, so can't have published it yet
            $media->set_publish_status(0);
        }

        # remove all contributors if updating
        unless ($aliased) {
            if ($update) {
                if (my $contribs = $media->get_contributors) {
                    $media->delete_contributors($contribs);
                    foreach my $contrib (@$contribs) {
                        log_event('media_del_contrib', $media,
                                  { Name => $contrib->get_name });
                    }
                }
            }

            # add contributors, if any
            if ($mdata->{contributors} and $mdata->{contributors}{contributor}) {
                my %grps;
                foreach my $c (@{$mdata->{contributors}{contributor}}) {
                    (my $look = $c->{type}) =~ s/([_%\\])/\\$1/g;
                    my $grp = $grps{$c->{type}} ||=
                      Bric::Util::Grp::Person->lookup({ name => $look })
                      or throw_ap __PACKAGE__ . "::create: No contributor type found "
                      . "matching (type => $c->{type})";
                    my %init = (grp   => $grp,
                                fname => $c->{fname},
                                mname => $c->{mname},
                                lname => $c->{lname});
                    my ($contrib) =
                      Bric::Util::Grp::Parts::Member::Contrib->list(\%init);
                    throw_ap(error => __PACKAGE__ . "::create : no contributor found matching "
                               . "(contributor => "
                               . join(', ', map { "$_ => $c->{$_}" } keys %$c))
                      unless defined $contrib;
                $media->add_contributor($contrib, $c->{role});
                    log_event('media_add_contrib', $media,
                              { Name => $contrib->get_name });
                }
            }

            # deal with file data if we have one
            if ($mdata->{file}) {
                my $filename = $mdata->{file}{name};
                my $size     = $mdata->{file}{size};
                my $data     = MIME::Base64::decode_base64($mdata->{file}{data}[0]);
                my $fh       = new IO::Scalar \$data;

                # empty or non-numeric size causes an SQL error
                throw_ap(error => __PACKAGE__ .
                           "::create : bad data found in file size element.")
                  unless defined $size and $size =~ /^\d+$/;

                # new objects must be saved to have an id
                $media->save;

                # Upload the file into the media object; let it figure out the
                # media type.
                $media->upload_file($fh, @{$mdata->{file}}{qw(name media_type size)});
                log_event('media_upload', $media);
            } else {
                # clear the media object by uploading an empty file - this
                # is functionality that isn't actually supported by
                # Bricolage.  We should add a Media->delete_file() method at
                # some point and use it here.
                my $data = "";
                my $fh  = new IO::Scalar \$data;
                $media->upload_file($fh, "empty", 0, 0);
            }
        }

        # save the media in an inactive state.  this is necessary to
        # allow element addition - you can't add elements to an
        # unsaved media, strangely.
        $media->deactivate;
        $media->save;

        # Manage the output channels if any are included in the XML file.
        load_ocs($media, $mdata->{output_channels}{output_channel},
                 $melems{$mdata->{element_type}}->[1], 'media', $update)
          if $mdata->{output_channels}{output_channel};

        # sanity checks
        throw_ap(error => __PACKAGE__ . "::create : no output channels defined!")
          unless $media->get_output_channels;
        throw_ap(error => __PACKAGE__ . "::create : no primary output channel defined!")
          unless defined $media->get_primary_oc_id;

        # delete old keywords if updating
        if ($update) {
            my $old;
            my @keywords = ($mdata->{keywords} and $mdata->{keywords}{keyword}) ? @{$mdata->{keywords}{keyword}} : ();
            my $keywords = { map { $_ => 1 } @keywords };
            foreach ($media->get_keywords) {
                push @$old, $_ unless $keywords->{$_->get_id};
            }
            $media->del_keywords(@$old) if $old;
        }

        # add keywords, if we have any
        if ($mdata->{keywords} and $mdata->{keywords}{keyword}) {

            # collect keyword objects
            my @kws;
            foreach (@{$mdata->{keywords}{keyword}}) {
                (my $look = $_) =~ s/([_%\\])/\\$1/g;
                my $kw = Bric::Biz::Keyword->lookup({ name => $look});
                if ($kw) {
                    throw_ap(error => __PACKAGE__ . qq|::create : access denied for keyword "$look"|)
                      unless chk_authz($kw, READ, 1);
                } else {
                    if (chk_authz('Bric::Biz::Keyword', CREATE, 1)) {
                        $kw = Bric::Biz::Keyword->new({ name => $_ })->save;
                        log_event('keyword_new', $kw);
                    }
                    else {
                        throw_ap(error => __PACKAGE__ . '::create : access denied for creating new keywords.');
                    }
                }
                push @kws, $kw;
            }

            # add keywords to the media
            $media->add_keywords(@kws);
        }

        unless ($update && $no_wf_or_desk_param) {
            $media->set_workflow_id($workflow->get_id);
            log_event("media_add_workflow", $media, { Workflow => $workflow->get_name });
            if ($update) {
                my $olddesk = $media->get_current_desk;
                if (defined $olddesk) {
                    $olddesk->transfer({ asset => $media, to => $desk });
                    $olddesk->save;
                } else {
                    $desk->accept({ asset => $media });
                }
            } else {
                $desk->accept({ asset => $media });
            }
            log_event('media_moved', $media, { Desk => $desk->get_name });
        }

        # add element data
        push @relations, deserialize_elements(
            object => $media,
            type   => 'media',
            data   => $mdata->{elements} || {}
        ) unless $aliased;

        # activate if desired
        $media->activate if $mdata->{active};

        # checkin and save
        $media->checkin;
        $media->save;
        log_event('media_checkin', $media, { Version => $media->get_version });
        log_event('media_save', $media);

        # all done, setup the media_id
        push(@media_ids, $media_ids{$id} = $media->get_id);
    }

    $desk->save if defined $desk;

    # if we have any story objects, create them
    my (%story_ids, @story_ids);
    if (my $stories = $data->{story}) {
        @story_ids = Bric::SOAP::Story->load_asset({ data       => $data,
                                                     internal   => 1,
                                                     upload_ids => []    });

        # correlate to relative ids
        for (0 .. $#story_ids) {
            $story_ids{$stories->[$_]{id}} = $story_ids[$_];
        }
    }

    # Resolve related stories and media.
    resolve_relations(\%story_ids, \%media_ids, @relations) if @relations;

    # return a SOAP structure unless this is an internal call
    return @media_ids if $args->{internal};
    return name(ids => [
                        map { name(media_id => $_) } @media_ids,
                        map { name(story_id => $_) } @story_ids,
                       ]);
}


=item $pkg->serialize_asset(writer => $writer, media_id => $media_id, args => $args)

Serializes a single media object into a <media> element using the given
writer and args.

=cut

sub serialize_asset {
    my $pkg      = shift;
    my %options  = @_;
    my $media_id = $options{media_id};
    my $writer   = $options{writer};

    my $media = Bric::Biz::Asset::Business::Media->lookup({id => $media_id});
    throw_ap(error => __PACKAGE__ . "::export : media_id \"$media_id\" not found.")
      unless $media;

    throw_ap(error => __PACKAGE__ . "::export : access denied for media \"$media_id\".")
      unless chk_authz($media, READ, 1);

    # open a media element
    my $alias_id = $media->get_alias_id;
    $writer->startTag("media",
                      id   => $media_id,
                      uuid => $media->get_uuid,
                      ( $alias_id ? (alias_id => $alias_id) :
                        (element_type => $media->get_element_key_name)));

    # Write out the name of the site.
    my $site = Bric::Biz::Site->lookup({ id => $media->get_site_id });
    $writer->dataElement('site' => $site->get_name);

    # write out simple elements in schema order
    foreach my $e (qw(name description uri
                      priority publish_status )) {
        $writer->dataElement($e => $media->_get($e));
    }

    # set active flag
    $writer->dataElement(active => ($media->is_active ? 1 : 0));

    # get source name
    my $src = Bric::Biz::Org::Source->lookup({id => $media->get_source__id });
    throw_ap(error => __PACKAGE__ . "::export : unable to find source")
      unless $src;
    $writer->dataElement(source => $src->get_source_name);

    # get dates and output them in dateTime format
    for my $name qw(cover_date expire_date publish_date first_publish_date) {
        my $date = $media->_get($name);
        next unless $date; # skip missing date
        my $xs_date = db_date_to_xs_date($date);
        throw_ap(error => __PACKAGE__ . "::export : bad date format for $name : $date")
          unless defined $xs_date;
        $writer->dataElement($name, $xs_date);
    }

    # output categories
    $writer->dataElement(category => $media->get_category->ancestry_path);

    # Output output channels.
    $writer->startTag("output_channels");
    my $poc = $media->get_primary_oc;
    $writer->dataElement(output_channel => $poc->get_name, primary => 1);
    my $pocid = $poc->get_id;
    foreach my $oc ($media->get_output_channels) {
        next if $oc->get_id == $pocid;
        $writer->dataElement(output_channel => $oc->get_name);
    }
    $writer->endTag("output_channels");

    # output keywords
    $writer->startTag("keywords");
    foreach my $k ($media->get_keywords) {
        $writer->dataElement(keyword => $k->get_name);
    }
    $writer->endTag("keywords");

    # output contributors
    unless ($alias_id) {
        $writer->startTag("contributors");
        foreach my $c ($media->get_contributors) {
            my $p = $c->get_person;
            $writer->startTag("contributor");
            $writer->dataElement(fname  => $p->get_fname);
            $writer->dataElement(mname  => $p->get_mname);
            $writer->dataElement(lname  => $p->get_lname);
            $writer->dataElement(type   => $c->get_grp->get_name);
            $writer->dataElement(role   => $media->get_contributor_role($c));
            $writer->endTag("contributor");
        }
        $writer->endTag("contributors");

        # output elements, ignore related media
        serialize_elements(writer => $writer,
                           args   => \%options,
                           object => $media);

        # output file if we've got one
        if (my $file_name = $media->get_file_name) {
            $writer->startTag("file");
            $writer->dataElement(name => $file_name);
            $writer->dataElement(size => $media->get_size);
            $writer->dataElement(media_type => $media->get_media_type->get_name);

            # read in file data
            my $fh   = $media->get_file;
            my $data = join('',<$fh>);
            $writer->dataElement(data => MIME::Base64::encode_base64($data,''));
            close $fh;

            $writer->endTag("file");
        }
    }

    # close the media
    $writer->endTag("media");
}


=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>

=cut

1;
