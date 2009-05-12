package Bric::SOAP::Story;

###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::ElementType;
use Bric::Biz::Category;
use Bric::Biz::Site;
use Bric::Biz::OutputChannel;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::Fault   qw(throw_ap);
use Bric::Biz::Workflow qw(STORY_WORKFLOW);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ CREATE);
use Bric::App::Event    qw(log_event);
use XML::Writer;
use IO::Scalar;
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Config qw(:l10n);

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
use Bric::SOAP::Media;

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 Name

Bric::SOAP::Story - SOAP interface to Bricolage stories.

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

  # set uri for Story module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Story');

  # get a list of story_ids for published stories w/ "foo" in their title
  my $story_ids = $soap->list_ids(name(title          => '%foo%'),
                                  name(publish_status => 1)     )->result;

  # export a story
  my $xml = $soap->export(name(story_id => $story_id)->result;

  # create a new story from an xml document
  my $story_ids = $soap->create(name(document => $xml_document)
                                ->type('base64'))->result;

  # update an existing story from an xml document
  my $story_ids = $soap->update(name(document => $xml_document)->type('base64'),
                                name(update_ids =>
                                     [ name(story_id => 1024) ]))->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage stories.

=head1 Interface

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the story database for matching stories and
returns a list of ids.  If no stories are found an empty list will be
returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item title (M)

The story's title.

=item description (M)

The story's description.

=item slug (M)

The story's slug.

=item category

A category containing the story, given as the complete category path
from the root.  Example: "/news/linux".

=item keyword (M)

A keyword associated with the story.

=item simple (M)

a single OR search that hits title, description, primary_uri
and keywords.

=item workflow

The name of the workflow containing the story.  (ex. Story)

=item no_workflow

Set to 1 to return only stories that are out of workflow.  This is
true after stories are published and until they are recalled into
workflow for editing.

=item primary_uri (M)

The primary uri of the story.

=item priority

The priority of the story.

=item publish_status

Stories that have been published have a publish_status of "1",
otherwise "0".  This value never changes after being turned on.  For a
more accurate read on a story's current status see no_workflow above.

=item element

The name of the top-level element for the story.  Also known as the
"Story Type".  This value corresponds to the element attribute on the
story element in the asset schema.

=item site

The name of the site which the story is in.

=item publish_date_start

Lower bound on publishing date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item publish_date_end

Upper bound on publishing date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item first_publish_date_start

Lower bound on the first date a story was published. Given in XML Schema
dateTime format (CCYY-MM-DDThh:mm:ssTZ).

=item first_publish_date_end

Upper bound on the first date a story was published. Given in XML Schema
dateTime format (CCYY-MM-DDThh:mm:ssTZ).

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

The key name of the top-level element for the story. This is more accurate
than the C<element> parameter, since there can be multiple elements with the
same name.

=item unexpired

Set to a true value to get a list of only unexpired stories.

=item subelement_key_name (M)

The key name for a container element that's a subelement of a story.

=item data_text (M)

Text stored in the fields of the story element or any of its subelements. Only
fields that use the "short" storage type will be searched.

=item output_channel

The name of an ouput channel that stories must be associated with.

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
Bric::Biz::Asset::Business::Story.

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

    # no_workflow means workflow__id => 0
    if ($args->{no_workflow}) {
        $args->{workflow__id} = 0;
        delete $args->{no_workflow};
    }

    # handle element => element_id conversion
    $args->{element_type} = $args->{element} if exists $args->{element};
    if (exists $args->{element_type}) {
        my ($element_id) = Bric::Biz::ElementType->list_ids({
            key_name => $args->{element_type},
            media => 0
        });
        throw_ap(error => __PACKAGE__ . "::list_ids : no story element type found matching "
                   . "(element => \"$args->{element_type}\")")
          unless defined $element_id;
        $args->{element_type_id} = $element_id;
        delete $args->{element_type};
    }

    # translate dates into proper format
    for my $name (grep { /_date_/ } keys %$args) {
        my $date = xs_date_to_db_date($args->{$name});
        throw_ap(error => __PACKAGE__ . "::list_ids : bad date format for $name parameter "
                   . "\"$args->{$name}\" : must be proper XML Schema dateTime format.")
          unless defined $date;
        $args->{$name} = $date;
    }

    # perform list using existing Bricolage list_ids functionality
    my @list = Bric::Biz::Asset::Business::Story->list_ids($args);

    print STDERR "Bric::Biz::Asset::Business::Story->list_ids() called : ",
        "returned : ", Data::Dumper->Dump([\@list],['list'])
            if DEBUG;

    # name the results
    my @result = map { name(story_id => $_) } @list;

    # name the array and return
    return name(story_ids => \@result);
}

=item export

The export method retrieves a set of stories from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item story_id

Specifies a single story_id to be retrieved.

=item story_ids

Specifies a list of story_ids.  The value for this option should be an
array of interger "story_id" elements.

=item export_related_media

If set to 1 any related media attached to the story will be included
in the exported document.  The story will refer to these included
media objects using the relative form of related-media linking.  (see
the XML Schema document in L<Bric::SOAP|Bric::SOAP> for
details)

=item export_related_stories

If set to 1 then the export will work recursively across related
stories.  If export_media is also set then media attached to related
stories will also be returned.  The story element will refer to the
included story objects using relative references (see the XML Schema
document in L<Bric::SOAP|Bric::SOAP> for details).

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
    my $method = 'export';

    print STDERR __PACKAGE__ . "->export() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::export : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # story_id is sugar for a one-element story_ids arg
    $args->{story_ids} = [ $args->{story_id} ] if exists $args->{story_id};

    # make sure story_ids is an array
    throw_ap(error => __PACKAGE__ . "::export : missing required story_id(s) setting.")
      unless defined $args->{story_ids};
    throw_ap(error => __PACKAGE__ . "::export : malformed story_id(s) setting.")
      unless ref $args->{story_ids} and ref $args->{story_ids} eq 'ARRAY';

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

    # iterate through story_ids, serializing stories as we go, storing
    # media ids to serialize for later.
    my @story_ids = @{$args->{story_ids}};
    my @media_ids;
    my %done;
    while(my $story_id = shift @story_ids) {
      next if exists $done{$story_id}; # been here before?
      my @related = $pkg->serialize_asset(writer   => $writer,
                                          story_id => $story_id,
                                          args     => $args);
      $done{$story_id} = 1;

      # queue up the related stories, story the media for later
      foreach my $obj (@related) {
          push(@story_ids, $obj->[1]) if $obj->[0] eq 'story';
          push(@media_ids, $obj->[1]) if $obj->[0] eq 'media';
      }
    }

    # serialize related media if we have any
    %done = ();
    foreach my $media_id (@media_ids) {
      next if $done{$media_id};
      Bric::SOAP::Media->serialize_asset(media_id => $media_id,
                                         writer   => $writer,
                                         args     => {});
      $done{$media_id} = 1;
    }

    # end the assets element and end the document
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

The create will fail if your story element contains non-relative
related_story_ids or related_media_ids that do not refer to existing stories
or media in the system. Related stores and media can be identified by either
an ID (set the "relative" attribute to 1 if it refers to an ID elsewhere in
the same XML file) or by URI (primary URI for stories) and site ID. If
C<related_story_uri> or C<related_media_uri> is specified without an
accompanying C<related_site_id> the related document's site is assumed to be
the same as the current story or media document.

Returns a list of new story_ids and media_ids created in the order of
the assets in the document.

Available options:

=over 4

=item document (required)

The XML document containing objects to be created.  The document must
contain at least one story and may contain any number of related media
objects.

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

Notes: The setting for publish_status in the incoming story is ignored
and always 0 for new stories.

New stories are put in the first "story workflow" unless you pass in
the --workflow option. The start desk of the workflow is used unless
you pass the --desk option.

=cut

=item update

The update method updates stories using the data in an XML document
of the format created by export().  A common use of update() is to
export() a selected story, make changes to one or more fields and
then submit the changes with update().

Returns a list of new story_ids and media_ids updated or created in
the order of the assets in the document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one story and may contain any number of
related media objects.

=item update_ids (required)

A list of "story_id" integers for the assets to be updated.  These
must match id attributes on story elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=item workflow

Specifies the workflow to move the story to

=item desk

Specifies the desk to move the story to

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: The setting for publish_status in a newly created story is
ignored and always 0 for new stories.  Updated stories do get
publish_status set from the document setting.

=cut

##############################################################################

=item delete

The delete() method deletes stories.  It takes the following options:

=over 4

=item story_id

Specifies a single story_id to be deleted.

=item story_ids

Specifies a list of story_ids to delete.

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
    my $method = 'delete';

    print STDERR __PACKAGE__ . "->delete() called : args : ",
      Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::delete : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # story_id is sugar for a one-element story_ids arg
    $args->{story_ids} = [ $args->{story_id} ] if exists $args->{story_id};

    # make sure story_ids is an array
    throw_ap(error => __PACKAGE__ . "::delete : missing required story_id(s) setting.")
      unless defined $args->{story_ids};
    throw_ap(error => __PACKAGE__ . "::delete : malformed story_id(s) setting.")
      unless ref $args->{story_ids} and ref $args->{story_ids} eq 'ARRAY';

    # delete the stories
    foreach my $story_id (@{$args->{story_ids}}) {
        print STDERR __PACKAGE__ . "->delete() : deleting story_id $story_id\n"
          if DEBUG;

        # first look for a checked out version
        my $story = Bric::Biz::Asset::Business::Story->lookup({ id => $story_id,
                                                                checkout => 1 });
        unless ($story) {
            # settle for a non-checked-out version and check it out
            $story = Bric::Biz::Asset::Business::Story->lookup({ id => $story_id });
            throw_ap(error => __PACKAGE__ . "::delete : no story found for id \"$story_id\"")
              unless $story;
            throw_ap(error => __PACKAGE__ . "::delete : access denied for story \"$story_id\".")
              unless chk_authz($story, EDIT, 1);
            $story->checkout({ user__id => get_user_id });
            log_event("story_checkout", $story);
        }

        # Remove the story from any desk it's on.
        if (my $desk = $story->get_current_desk) {
            $desk->checkin($story);
            $desk->remove_asset($story);
            $desk->save;
        }

        # Remove the story from workflow.
        if ($story->get_workflow_id) {
            $story->set_workflow_id(undef);
            log_event("story_rem_workflow", $story);
        }

        # Deactivate the story and save it.
        $story->deactivate;
        $story->save;
        log_event("story_deact", $story);
    }

    return name(result => 1);
}


=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'story' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

my $allowed = {
    list_ids => { map { $_ => 1 } qw(title description slug category keyword
                                     simple primary_uri priority workflow
                                     no_workflow publish_status element
                                     publish_date_start publish_date_end
                                     cover_date_start first_publish_date_start
                                     first_publish_date_end cover_date_end
                                     expire_date_start expire_date_end site
                                     alias_id element_key_name unexpired
                                     data_text output_channel contrib_id
                                     subelement_key_name Order OrderDirection
                                     Limit Offset),
                  grep { /^[^_]/}
                    keys %{ Bric::Biz::Asset::Business::Story->PARAM_WHERE_MAP }
                },
    export   => { map { $_ => 1 } qw(story_id story_ids
                                     use_related_uri
                                     export_related_media
                                     export_related_stories) },
    create   => { map { $_ => 1 } qw(document workflow desk) },
    update   => { map { $_ => 1 } qw(document update_ids workflow desk) },
    delete   => { map { $_ => 1 } qw(story_id story_ids) },
};

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
    my $data = $args->{data};
    my %to_update = map { $_ => 1 } @{$args->{update_ids}};

    unless ($data) {
        # parse and catch errors
        eval { $data = parse_asset_document($args->{document}) };
        throw_ap(error => __PACKAGE__ . ": problem parsing asset document: $@")
          if $@;
        throw_ap(error => __PACKAGE__ . ": problem parsing asset document: "
                          . "no stories found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{story};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # Determine workflow and desk for stories if not default
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

    # loop over stories, filling in %story_ids and @relations
    my (%story_ids, @story_ids, @relations, %selems);
    foreach my $sdata (@{delete $data->{story}}) {
        my $id = $sdata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # are we aliasing?
        my $aliased = exists($sdata->{alias_id}) && $sdata->{alias_id} && ! $update
          ? Bric::Biz::Asset::Business::Story->lookup({
              id => $story_ids{$sdata->{alias_id}} || $sdata->{alias_id}
            })
          : undef;

        # setup init data for create
        my %init;

        # get user__id from Bric::App::Session
        $init{user__id} = get_user_id;

        # Get the site ID.
        $sdata->{site} = 'Default Site' unless exists $sdata->{site};
        $init{site_id} = site_to_id(__PACKAGE__, $sdata->{site});

        $sdata->{element_type} = delete $sdata->{element}
            if exists $sdata->{element};
        if (exists $sdata->{element_type} and not $aliased) {
            # It's a normal story.
            unless ($selems{$sdata->{element_type}}) {
                my $e = (Bric::Biz::ElementType->list({
                    key_name => $sdata->{element_type},
                    media => 0 }))[0]
                  or throw_ap(error => __PACKAGE__ . "::create : no story"
                                     . " element type found matching (element => "
                                     . "\"$sdata->{element_type}\")");
                $selems{$sdata->{element_type}} =[
                    $e->get_id,
                    { map { $_->get_name => $_ } $e->get_output_channels }
                ];
            }

            # get element_type_id from story element
            $init{element_type_id} = $selems{$sdata->{element_type}}->[0];

        } elsif ($aliased) {
            # It's an alias.
            $init{alias_id} = $sdata->{alias_id};
        } else {
            # It's bogus.
            throw_ap(error => __PACKAGE__ . "::create: No story element type or alias ID found");
        }

        # get source__id from source
        ($init{source__id}) = Bric::Biz::Org::Source->list_ids({
            source_name => $sdata->{source}
        });
        throw_ap(error => __PACKAGE__ . "::create : no source found matching "
                   . "(source => \"$sdata->{source}\")")
          unless defined $init{source__id};

        # Get category and desk.
        unless ($update && $no_wf_or_desk_param) {
            unless (exists $args->{workflow}) {  # already done above
                $workflow = (Bric::Biz::Workflow->list({
                    type => STORY_WORKFLOW,
                    site_id => $init{site_id}
                }))[0];
            }

            unless (exists $args->{desk}) {  # already done above
                $desk = $workflow->get_start_desk;
            }
        }

        # get base story object
        my $story;
        unless ($update) {
            # create empty story
            # XXX Put in supplied UUID?
            $story = Bric::Biz::Asset::Business::Story->new(\%init);
            throw_ap(error => __PACKAGE__ . "::create : failed to create empty story object.")
              unless $story;
            print STDERR __PACKAGE__ . "::create : created empty story object\n"
                if DEBUG;

            # is this is right way to check create access for stories?
            throw_ap(error => __PACKAGE__ . " : access denied.")
              unless chk_authz($story, CREATE, 1, $desk->get_asset_grp);
            if ($aliased) {
                # Log that we've created an alias.
                my $origin_site = Bric::Biz::Site->lookup
                  ({ id => $aliased->get_site_id });
                log_event("story_alias_new", $story,
                          { 'From Site' => $origin_site->get_name });
                my $site = Bric::Biz::Site->lookup({ id => $init{site_id} });
                log_event("story_aliased", $aliased,
                          { 'To Site' => $site->get_name });
            } else {
                # Log that we've created a new story asset.
                log_event('story_new', $story);
            }

        } else {
            # updating - first look for a checked out version
            $story = Bric::Biz::Asset::Business::Story->lookup({ id => $id,
                                                                 checkout => 1
                                                               });
            if ($story) {
                # make sure it's ours
                throw_ap(error => __PACKAGE__ .
                           "::update : story \"$id\" is checked out to another user.")
                  unless $story->get_user__id == get_user_id;
                throw_ap(error => __PACKAGE__ . " : access denied.")
                  unless chk_authz($story, EDIT, 1);
            } else {
                # try a non-checked out version
                $story = Bric::Biz::Asset::Business::Story->lookup({ id => $id });
                throw_ap(error => __PACKAGE__ . "::update : no story found for \"$id\"")
                  unless $story;
                throw_ap(error => __PACKAGE__ . " : access denied.")
                  unless chk_authz($story, RECALL, 1);

                # FIX: race condition here - between lookup and checkout
                #      someone else could checkout...

                # check it out
                $story->checkout( { user__id => get_user_id });
                $story->save;
                log_event('story_checkout', $story);
            }

            # Make sure that the UUID hasn't changed.
            if (exists $sdata->{uuid}) {
                throw_ap __PACKAGE__ . "::update: story \"$id\" has a different UUID"
                  if $story->get_uuid ne $sdata->{uuid};
            }

            # update %init fields
#            $story->set_element_type_id($init{element_type_id});
#            $story->set_alias_id($init{alias_id});
            $story->set_source__id($init{source__id});
        }

        # set simple fields
        my @simple_fields = qw(name description slug primary_uri priority);
        $story->_set(\@simple_fields, [ @{$sdata}{@simple_fields} ]);

        # assign dates
        $sdata->{publish_date} ||= $sdata->{first_publish_date}
            if $sdata->{first_publish_date};
        for my $name qw(cover_date expire_date publish_date first_publish_date) {
            my $date = $sdata->{$name};
            if ($date) {
                throw_ap error => __PACKAGE__ . "::create : $name must be undefined if publish_status is false"
                    if not $sdata->{publish_status} and $name =~ /publish/;

                my $db_date = xs_date_to_db_date($date);
                throw_ap(error => __PACKAGE__ . "::create : bad date format for $name : $date")
                    unless defined $db_date;
                $story->_set([$name],[$db_date]);
            } else {
                throw_ap error => __PACKAGE__ . "::create : $name must be defined if publish_status is true"
                    if $sdata->{publish_status} and $name =~ /publish/;
            }
        }

        # almost totally ignoring whatever publish_status is set to
        if ($update) {
            if ($story->get_publish_date or $story->get_first_publish_date) {
                # some publish date is set, so it must've been published
                $story->set_publish_status(1);
            } else {
                $story->set_publish_status($sdata->{publish_status});
            }
        } else {
            # creating, so can't have published it yet
            $story->set_publish_status(0);
        }

        # remove all categories if updating
        if ($update) {
            if (my $cats = $story->get_categories) {
                # Delete 'em and log it.
                $story->delete_categories($cats);
                foreach my $cat (@$cats) {
                    log_event('story_del_category', $story,
                              { Category => $cat->get_name });
                }
            }
        }

        # assign categories
        my @cids;
        my $primary_cid;
        foreach my $cdata (@{$sdata->{categories}{category}}) {
            # get cat id
            my $path = ref $cdata ? $cdata->{content} : $cdata;
            (my $look = $path) =~ s/([_%\\])/\\$1/g;
            my $cat = Bric::Biz::Category->lookup({
                uri => $look,
                site_id => $init{site_id}
            });
            throw_ap(error => __PACKAGE__ . "::create : no category found matching "
                       . "(category => \"$path\")")
              unless defined $cat;

            my $category_id = $cat->get_id;
            push(@cids, $category_id);
            $primary_cid = $category_id
              if ref $cdata and $cdata->{primary};

            # Log it!
            log_event('story_add_category', $story,
                      { Category => $cat->get_name });
        }

        # sanity checks
        throw_ap(error => __PACKAGE__ . "::create : no categories defined!")
          unless @cids;
        throw_ap(error => __PACKAGE__ . "::create : no primary category defined!")
          unless defined $primary_cid;

        # add categories to story
        $story->add_categories(\@cids);
        $story->set_primary_category($primary_cid);

        unless ($aliased) {
            if ($update) {
                if (my $contribs = $story->get_contributors) {
                    foreach my $contrib (@$contribs) {
                        log_event('story_del_contrib', $story,
                                  { Name => $contrib->get_name });
                    }
                    $story->delete_contributors($contribs);
                }
            }

            # add contributors, if any
            if ($sdata->{contributors} and $sdata->{contributors}{contributor}) {
                my %grps;
                foreach my $c (@{$sdata->{contributors}{contributor}}) {
                    (my $look = $c->{type}) =~ s/([_%\\])/\\$1/g;
                    my $grp = $grps{$c->{type}} ||=
                      Bric::Util::Grp::Person->lookup({ name => $look })
                      or throw_ap __PACKAGE__ . "::create: No contributor type found "
                      . "matching (type => $c->{type})";
                    my %init = (grp   => $grp,
                                fname => defined $c->{fname} ? $c->{fname} : "",
                                mname => defined $c->{mname} ? $c->{mname} : "",
                                lname => defined $c->{lname} ? $c->{lname} : "");
                    my ($contrib) =
                      Bric::Util::Grp::Parts::Member::Contrib->list(\%init);
                    throw_ap(error => __PACKAGE__ . "::create : no contributor found matching "
                               . "(contributor => "
                               . join(', ', map { "$_ => $c->{$_}" } keys %$c))
                      unless defined $contrib;
                    $story->add_contributor($contrib, $c->{role});
                    log_event('story_add_contrib', $story,
                              { Name => $contrib->get_name });
                }
            }
        }

        # save the story in an inactive state.  this is necessary to
        # allow element addition - you can't add elements to an
        # unsaved story, strangely.
        $story->deactivate;
        $story->save;

        # Manage the output channels if any are included in the XML file.
        load_ocs($story, $sdata->{output_channels}{output_channel},
                 $selems{$sdata->{element_type}}->[1], 'story', $update)
          if $sdata->{output_channels}{output_channel};

        # sanity checks
        throw_ap(error => __PACKAGE__ . "::create : no output channels defined!")
          unless $story->get_output_channels;
        throw_ap(error => __PACKAGE__ . "::create : no primary output channel defined!")
          unless defined $story->get_primary_oc_id;

        # delete old keywords if updating
        if ($update) {
            my $old;
            my @keywords = ($sdata->{keywords} and $sdata->{keywords}{keyword}) ? @{$sdata->{keywords}{keyword}} : ();
            my $keywords = { map { $_ => 1 } @keywords };
            foreach ($story->get_keywords) {
                push @$old, $_ unless $keywords->{$_->get_id};
            }
            $story->del_keywords(@$old) if $old;
        }

        # add keywords, if we have any
        if ($sdata->{keywords} and $sdata->{keywords}{keyword}) {

            # collect keyword objects
            my @kws;
            foreach (@{$sdata->{keywords}{keyword}}) {
                (my $look = $_) =~ s/([_%\\])/\\$1/g;
                my $kw = Bric::Biz::Keyword->lookup({ name => $look });
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

            # add keywords to the story
            $story->add_keywords(@kws);
        }

        unless ($update && $no_wf_or_desk_param) {
            $story->set_workflow_id($workflow->get_id);
            log_event("story_add_workflow", $story, { Workflow => $workflow->get_name });
            if ($update) {
                my $olddesk = $story->get_current_desk;
                if (defined $olddesk) {
                    $olddesk->transfer({ asset => $story, to => $desk });
                    $olddesk->save;
                } else {
                    $desk->accept({ asset => $story });
                }
            } else {
                $desk->accept({ asset => $story });
            }
            log_event('story_moved', $story, { Desk => $desk->get_name });
        }

        # add element data
        push @relations,
            deserialize_elements(object => $story,
                                 type   => 'story',
                                 data   => $sdata->{elements} || {})
              unless $aliased;

        # activate if desired
        $story->activate if $sdata->{active};

        # checkin and save
        $story->checkin;
        $story->save;
        log_event('story_checkin', $story, { Version => $story->get_version });
        log_event('story_save', $story);

        # all done, setup the story_id
        push(@story_ids, $story_ids{$id} = $story->get_id);
    }

    $desk->save if defined $desk;

    # if we have any media objects, create them
    # Keep a handlde on them because Media.pm will delete them from $data.
    my (%media_ids, @media_ids);
    if (my $media = $data->{media}) {
        @media_ids = Bric::SOAP::Media->load_asset({ data       => $data,
                                                     internal   => 1,
                                                     upload_ids => []    });

        # correlate to relative ids
        for (0 .. $#media_ids) {
            $media_ids{$data->{media}[$_]{id}} = $media_ids[$_];
            $media_ids{$media->[$_]{id}} = $media_ids[$_];
        }
    }

    # Resolve related stories and media.
    resolve_relations(\%story_ids, \%media_ids, @relations) if @relations;

    # return a SOAP structure unless this is an internal call
    return @story_ids if $args->{internal};
    return name(ids => [
                        map { name(story_id => $_) } @story_ids,
                        map { name(media_id => $_) } @media_ids
                       ]);
}

=item @related = $pkg->serialize_asset(writer => $writer, story_id => $story_id, args => $args)

Serializes a single story into a <story> element using the given
writer and args.  Returns a list of two-element arrays - [ "media",
$id ] or [ "story", $id ].  These are the related media objects
serialized.

=cut

sub serialize_asset {
    my $pkg      = shift;
    my %options  = @_;
    my $story_id = $options{story_id};
    my $writer   = $options{writer};
    my @related;

    my $story = Bric::Biz::Asset::Business::Story->lookup({id => $story_id});
    throw_ap(error => __PACKAGE__ . "::export : story_id \"$story_id\" not found.")
      unless $story;

    throw_ap(error => __PACKAGE__ . "::export : access denied for story \"$story_id\".")
      unless chk_authz($story, READ, 1);

    # open a story element
    my $alias_id = $story->get_alias_id;
    $writer->startTag("story",
                      id   => $story_id,
                      uuid => $story->get_uuid,
                      ( $alias_id ? (alias_id => $alias_id) :
                        (element_type => $story->get_element_key_name)));

    # Write out the name of the site.
    my $site = Bric::Biz::Site->lookup({ id => $story->get_site_id });
    $writer->dataElement('site' => $site->get_name);

    # write out simple elements in schema order
    foreach my $e (qw(name description slug primary_uri
                      priority publish_status )) {
        $writer->dataElement($e => $story->_get($e));
    }

    # set active flag
    $writer->dataElement(active => ($story->is_active ? 1 : 0));

    # get source name
    my $src = Bric::Biz::Org::Source->lookup({id => $story->get_source__id });
    throw_ap(error => __PACKAGE__ . "::export : unable to find source")
      unless $src;
    $writer->dataElement(source => $src->get_source_name);

    # get dates and output them in dateTime format
    for my $name qw(cover_date expire_date publish_date first_publish_date) {
        my $date = $story->_get($name);
        next unless $date; # skip missing date
        my $xs_date = db_date_to_xs_date($date);
        throw_ap(error => __PACKAGE__ . "::export : bad date format for $name : $date")
          unless defined $xs_date;
        $writer->dataElement($name, $xs_date);
    }

    # output categories
    $writer->startTag("categories");
    my $cat = $story->get_primary_category();
    $writer->dataElement(category => $cat->ancestry_path, primary => 1);
    foreach $cat ($story->get_secondary_categories) {
        $writer->dataElement(category => $cat->ancestry_path);
    }
    $writer->endTag("categories");

    # Output output channels.
    $writer->startTag("output_channels");
    my $poc = $story->get_primary_oc;
    $writer->dataElement(output_channel => $poc->get_name, primary => 1);
    my $pocid = $poc->get_id;
    foreach my $oc ($story->get_output_channels) {
        next if $oc->get_id == $pocid;
        $writer->dataElement(output_channel => $oc->get_name);
    }
    $writer->endTag("output_channels");

    # output keywords
    $writer->startTag("keywords");
    foreach my $k ($story->get_keywords) {
        $writer->dataElement(keyword => $k->get_name);
    }
    $writer->endTag("keywords");

    # output contributors
    unless ($alias_id) {
        $writer->startTag("contributors");
        foreach my $c ($story->get_contributors) {
            my $p = $c->get_person;
            $writer->startTag("contributor");
            $writer->dataElement(fname  =>
                                 defined $p->get_fname ? $p->get_fname : "");
            $writer->dataElement(mname  =>
                                 defined $p->get_mname ? $p->get_mname : "");
            $writer->dataElement(lname  =>
                                 defined $p->get_lname ? $p->get_lname : "");
            $writer->dataElement(type   => $c->get_grp->get_name);
            $writer->dataElement(role   => $story->get_contributor_role($c));
            $writer->endTag("contributor");
        }
        $writer->endTag("contributors");

    # output elements
    @related = serialize_elements(writer => $writer,
                                  args   => $options{args},
                                  object => $story);
    }

    # close the story
    $writer->endTag("story");
    return @related;
}

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>

=cut

1;
