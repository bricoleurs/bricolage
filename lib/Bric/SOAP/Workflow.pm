package Bric::SOAP::Workflow;

###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Template;
use Bric::Biz::OutputChannel;
use Bric::Biz::Site;
use Bric::Biz::Workflow qw(:wf_const);
use Bric::App::Cache;
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use Bric::Config        qw(STAGE_ROOT PREVIEW_ROOT PREVIEW_LOCAL ISO_8601_FORMAT);
use Bric::App::Event    qw(log_event);
use Bric::Util::Time    qw(strfdate local_date);
use Bric::Util::MediaType;
use Bric::Util::Fault   qw(throw_ap);
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::Job::Pub;
use Bric::Dist::ServerType;
use Bric::Dist::Resource;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::SOAP::Util qw(xs_date_to_db_date parse_asset_document);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

# We'll use this for outputting messages.
my %types = (
    story      => 'Story',
    media      => 'Media',
    template => 'Template',
);

# We'll use this for finding workflows.
my %wf_types = (
    story      => STORY_WORKFLOW,
    media      => MEDIA_WORKFLOW,
    template   => TEMPLATE_WORKFLOW,
);

=head1 Name

Bric::SOAP::Workflow - SOAP interface to Bricolage workflows.

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

  # set uri for Workflow module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Workflow');

=head1 Description

This module provides a SOAP interface to manipulating Bricolage
workflows.  This include facilities for moving objects onto desks,
checkin, checkout, publishing and deploying.

=head1 Interface

=head2 Public Class Methods

=over 4

=item publish

This method handles the publishing of story and media objects.
Returns "publish_ids", an array of "story_id" and/or "media_id"
integers published.  The method accepts the following parameters:

=over 4

=item story_id

A single story to publish.

=item media_id

A single media object to publish.

=item publish_ids

A list of "story_id" and/or "media_id" elements to be published.

=item publish_related_stories

If this is set to true then related stories will be published too.  In
the web interface this happens if and only if the related stories have
never been published before.  This option is off by default.

=item publish_related_media

If this is set to true then related media will be published too.  In
the web interface this happens if and only if the related media
objects have never been published before.  This option is false by
default.

=item to_preview

Set this to true to publish to all preview destinations instead of the publish
destinations. This will fail if C<PREVIEW_LOCAL> is enabled in
F<bricolage.conf>.

=item publish_date

The date and time (in ISO-8601 format) at which to publish the assets.

=back

Throws:

=over

=item Exception::AP

=back

B<Side Effects:> Stories and media have their publish_status field set to
true.

B<Notes:> The code for this method came mostly from
F<comp/widgets/publish/callback.mc>. It would be nice to collect this code in
a module so it could be kept in one place.

Notes about the notes. It's now F<lib/Bric/App/Callback/Publish.pm>,
This code is out of date since Mark's job-queue patch, as it still
instantiates a $burner to publish immediately, so we need to update it.
It's an opportunity to factor out the code into one place.

=cut

sub publish {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'publish';

    print STDERR __PACKAGE__ . "->publish() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::publish : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    my $pub_date = exists $args->{publish_date}
      ? local_date(xs_date_to_db_date($args->{publish_date}), ISO_8601_FORMAT)
      : strfdate();

    my $preview = (exists $args->{to_preview} and $args->{to_preview}) ? 1 : 0;
    throw_ap(error => __PACKAGE__ . "::publish : cannot publish to_preview with "
               . "PREVIEW_LOCAL set.")
      if PREVIEW_LOCAL and $preview;

    my $published_only = exists($args->{published_only}) ? $args->{published_only} : 0;

    my @ids = _collect_ids("publish_ids",
                           [ 'story_id', 'media_id' ],
                           $env);

    # Instantiate the Burner object.
    my $burner = Bric::Util::Burner->new({
        $preview
          ? (out_dir => PREVIEW_ROOT, user_id => get_user_id )
          : (out_dir => STAGE_ROOT)
    });

    # iterate through ids publishing shiznats
    my (%seen, @published, %desks);
    while (my $id = shift @ids) {
        my $obj;
        my $type;
        if ($id->name eq 'story_id') {
            $type = 'story';
            $obj  = Bric::Biz::Asset::Business::Story->lookup({
                id => $id->value,
                ( $published_only ? ( published_version => 1) : ())
            });

            throw_ap(error => 'Unable to find story for story_id "'
                              . $id->value . '".')
              unless $obj;

        } elsif ($id->name eq 'media_id') {
            $type = 'media';
            $obj  = Bric::Biz::Asset::Business::Media->lookup({
                id => $id->value,
                ( $published_only ? ( published_version => 1 ) : ())
            });

            throw_ap(error => 'Unable to find media object for media_id "'
                              . $id->value . '".')
              unless $obj;

        } else {
            throw_ap(error => "Unknown element found in publish_ids list.");
        }

        # don't need the object anymore
        $id = $id->value;

        # make sure we're not publishing stuff repeatedly
        next if $seen{$type}{$id};
        $seen{$type}{$id} = 1;

        # check check check
        throw_ap(error => "Cannot publish checked-out $types{$type}: \"".$id."\".")
            if $obj->get_checked_out and not $preview;

        if (! $preview && !$published_only && $obj->get_workflow_id) {
            # It must be on a publish desk.
            my $did = $obj->get_desk_id;
            my $desk = $desks{$did}
              ||= Bric::Biz::Workflow::Parts::Desk->lookup({ id => $did });
            # XXX There should always be a desk when there's a workflow, but
            # sometimes there isn't. Hence the "$desk &&" just lets it publish
            # if that's the case. It will be removed from workflow by the
            # publish.
            throw_ap qq{Cannot publish $types{$type} "$id" because it }
              . "is not on a publish desk"
                unless $desk && $desk->can_publish;
        }

        # Check for PUBLISH permission, or READ if previewing
        throw_ap(error => "Access to publish $types{$type} \"$id\" denied.")
          unless chk_authz($obj, PUBLISH, 1) or ($preview and chk_authz($obj, READ, 1));

        # schedule related stuff if requested
        if ($args->{publish_related_stories} or
            $args->{publish_related_media}) {
            # loop through related objects, adding to the todo list as
            # appropriate
            foreach my $rel ($obj->get_related_objects) {
                # Skip documents whose current version has already been
                # published.
                next unless $rel->needs_publish;
                # Skip deactivated documents.
                next unless $rel->is_active;

                # Add it in.
                if ($args->{publish_related_stories} &&
                    UNIVERSAL::isa($rel, 'Bric::Biz::Asset::Business::Story'))
                {
                    push(@ids, name(story_id => $rel->get_id));
                } elsif ($args->{publish_related_media} &&
                    UNIVERSAL::isa($rel, 'Bric::Biz::Asset::Business::Media'))
                {
                    push(@ids, name(media_id => $rel->get_id));
                } else {
                    # Nothing.
                }
            }
        }

        if ($preview) {
            # Just preview it.
            push @published, name( "$type\_id" => $id ) if grep {
                $burner->preview($obj, $type, get_user_id, $_->get_id)
            } $obj->get_output_channels;
        } else {
            # Schedule the publish.
            my $name = 'Publish "' . $obj->get_name . '"';
            my $job = Bric::Util::Job::Pub->new({
                sched_time  => $args->{publish_date},
                user_id     => get_user_id,
                name        => $name,
                "$type\_id" => $obj->get_id,
                priority    => $obj->get_priority,
            })->save;
            log_event('job_new', $job);
            push @published, name( "$type\_id" => $id );
        }
    }

    # Publish stuff passed to publish_another().
    Bric::Util::Burner->flush_another_queue;

    print STDERR __PACKAGE__ . "->publish() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @published), "\n"
            if DEBUG;

    # name, type and return
    return name(publish_ids => \@published);
}

=item deploy

This method handles deploying templates. The method returns
"deploy_ids", a list of "template_id" integers deployed on success.
The method accepts the following parameters:

=over 4

=item template_id

A single template to publish.

=item deploy_ids

A list of "template_id" elements to be published.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: Templates have their deploy_status set to true.

Notes: Code here comes from comp/widgets/desk/callback.mc.  It might
be cool to move this code into a module so it could be shared.  It's
not nearly as gnarly as the publish() code though.

=cut

sub deploy {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'deploy';

    print STDERR __PACKAGE__ . "->deploy() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::deploy : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    my @ids = _collect_ids("deploy_ids", [ "template_id" ], $env);

    my $burner = Bric::Util::Burner->new;

    foreach my $id (map { $_->value } @ids) {
        my $fa = Bric::Biz::Asset::Template->lookup({ id => $id });
        throw_ap(error => "Unable to find template for template_id \"$id\".")
            unless $fa;

        # check check check
        throw_ap(error => "Cannot deloy checked-out template : \"$id\".")
            if $fa->get_checked_out;

        # Check for PUBLISH permission
        throw_ap(error => "Access denied.") unless chk_authz($fa, PUBLISH, 1);

        $burner->deploy($fa);
        log_event($fa->get_deploy_status ?
                  'template_redeploy' : 'template_deploy',
                  $fa);
        $fa->set_deploy_date(strfdate());
        $fa->set_deploy_status(1);
        $fa->set_published_version($fa->get_version);

        # Remove it from the current desk.
        if (my $desk = $fa->get_current_desk) {
            $desk->remove_asset($fa);
            $desk->save;
        }

        # Clear the workflow ID.
        if ($fa->get_workflow_id) {
            $fa->set_workflow_id(undef);
            log_event("template_rem_workflow", $fa);
        }

        $fa->save;
    }

    print STDERR __PACKAGE__ . "->deploy() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @ids), "\n"
            if DEBUG;

    return name(deploy_ids => \@ids);
}

=item checkout

This method checks out a story, media and/or template objects.  After
this call the objects are visible on the user's workspace in the web
interface and are not available for other users to edit.

An error will result if you try to checkout an object that is not
checked in.

The method returns a list of ids checked out on success.

The method accepts the following parameters:

=over 4

=item story_id

A single story to checkout.

=item media_id

A single media object to checkout.

=item template_id

A single template object to checkout.

=item checkout_ids

A list of "story_id", "template_id" and/or "media_id" elements to be
checked out.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

sub checkout {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'checkout';

    print STDERR __PACKAGE__ . "->checkout() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::checkout : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    my @ids = _collect_ids("checkout_ids",
                           [ "story_id", "media_id", "template_id" ],
                           $env);

    my %seen;
    foreach my $id (@ids) {
        my $obj;
        my $type;
        if ($id->name eq 'story_id') {
            $type = 'story';
            $obj  = Bric::Biz::Asset::Business::Story->lookup(
                                         { id => $id->value });
            throw_ap(error => "Unable to find story for story_id \"".$id->value."\".")
                unless $obj;

        } elsif ($id->name eq 'media_id') {
            $type = 'media';
            $obj  = Bric::Biz::Asset::Business::Media->lookup(
                                         { id => $id->value });
            throw_ap(error => "Unable to find media object for media_id \"".$id->value."\".")
                unless $obj;
        } elsif ($id->name eq 'template_id') {
            $type = 'template';
            $obj  = Bric::Biz::Asset::Template->lookup(
                                         { id => $id->value });
            throw_ap(error => "Unable to find template object for template_id \"".$id->value."\".")
                unless $obj;
        } else {
            throw_ap(error => "Unknown element found in checkout_ids list.");
        }

        # check check check
        throw_ap(error => "Cannot check-out already checked-out $types{$type}: \"".$id->value."\".")
            if $obj->get_checked_out;

        # make sure we're not trying to checkout stuff repeatedly
        next if $seen{$type}{$id};
        $seen{$type}{$id} = 1;

        # might need to assign a workflow here, if this item was just
        # published, for example.
        if ($obj->get_workflow_id) {
            # Check for EDIT permission
            throw_ap(error => "Access denied.")
              unless chk_authz($obj, EDIT, 1);
        } else {
            # Check for RECALL permission
            throw_ap(error => "Access denied.")
              unless chk_authz($obj, RECALL, 1);
            my $workflow = (Bric::Biz::Workflow->list
                            ({ type => $wf_types{$type} }))[0];

            $obj->set_workflow_id($workflow->get_id);
            log_event("${type}_add_workflow", $obj,
                      { Workflow => $workflow->get_name });

            my $desk = $workflow->get_start_desk;
            $desk->accept({'asset' => $obj});
            $desk->save;
            log_event("${type}_moved", $obj, { Desk => $desk->get_name });
        }

        # check 'em out
        $obj->checkout({user__id => get_user_id});
        $obj->save;

        # log the checkout
        log_event("${type}_checkout", $obj);
    }


    print STDERR __PACKAGE__ . "->checkout() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @ids), "\n"
            if DEBUG;

    return name(checkout_ids => \@ids);
}

=item checkin

This method checks in a story, media and/or template objects.  After
this call the objects are no longer visible on the user's workspace in
the web interface and are available for other users to edit.

An error will result if you try to checkin an object that is not
checked out.

The method returns a list of ids checked in.

The method accepts the following parameters:

=over 4

=item story_id

A single story to checkin.

=item media_id

A single media object to checkin.

=item template_id

A single template object to checkin.

=item checkin_ids

A list of "story_id", "template_id" and/or "media_id" elements to be
checked in.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

sub checkin {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'checkin';

    print STDERR __PACKAGE__ . "->checkin() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::checkin : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    my @ids = _collect_ids("checkin_ids",
                           [ "story_id", "media_id", "template_id" ],
                           $env);

    my %seen;
    foreach my $id (@ids) {
        # What do we have here?
        (my $type = $id->name) =~ s/_id$//;
        my $class = $type eq 'template'
            ? 'Bric::Biz::Asset::Template'
            : 'Bric::Biz::Asset::Business::' . ucfirst $type;

        # Look up the asset.
        my $obj = $class->lookup({ id => $id->value, checkout => 1 }) or throw_ap(
            error => qq{Unable to find checked-oiut $type for id "}
                   . $id->value . '".'
        );

        # Check for EDIT permission.
        throw_ap( error => 'Access denied.' ) unless chk_authz($obj, EDIT, 1);

        # Make sure we're not trying to checkin stuff repeatedly
        next if $seen{$type}{$id}++;

        # Make sure that we have a desk.
        throw_ap(
            error => qq{Cannot check-in $types{$type} without a current desk: "}
                  . $id->value . '".'
        ) unless $obj->get_current_desk;

        # Check it in.
        $obj->checkin;
        $obj->save;

        # Log the checkin.
        log_event("${type}_checkin", $obj, { Version => $obj->get_version });
    }


    print STDERR __PACKAGE__ . "->checkin() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @ids), "\n"
            if DEBUG;

    return name(checkin_ids => \@ids);
}

=item move

This method moves objects between workflows and desks.  The method
returns a list of ids moved.  The method accepts the following
parameters:

=over 4

=item desk (required)

The name of the desk to move to.

=item workflow

The name of the workflow to move to.  If this is unspecified then desk
must refer to a desk in the current workflow for the object.  If
specified then only one type of object can be successfully moved since
workflows are type-specific, I think.

=item story_id

A single story to move.

=item media_id

A single media object to move.

=item template_id

A single template object to move.

=item move_ids

A list of "story_id", "template_id" and/or "media_id" elements to be
checked in.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

sub move {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'move';

    print STDERR __PACKAGE__ . "->move() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::move : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # make sure we have a desk
    throw_ap(error => __PACKAGE__ . "::move : missing required parameter \"desk\".")
        unless $args->{desk};

    # find destination workflow if defined
    my $to_workflow;
    if (exists $args->{workflow}) {
        ($to_workflow) = Bric::Biz::Workflow->list({
            name => $args->{workflow},
        });
        throw_ap(error => __PACKAGE__ . "::move : no workflow found matching " .
                          "(workflow => \"$args->{workflow}\")")
            unless defined $to_workflow;
    }

    # find destination desk
    my ($to_desk) = Bric::Biz::Workflow::Parts::Desk->list({
        name => $args->{desk},
    });
    throw_ap(error => __PACKAGE__ . "::move : no desk found matching " .
                      "(desk => \"$args->{desk}\")")
      unless $to_desk;

    my @ids = _collect_ids(
        "move_ids",
        [ "story_id", "media_id", "template_id" ],
        $env
    );

    foreach my $id (@ids) {
        my $obj;
        my $type;
        if ($id->name eq 'story_id') {
            $type = 'story';
            $obj  = Bric::Biz::Asset::Business::Story->lookup({
                id => $id->value,
            });
            throw_ap(error => "Unable to find story for story_id \"".$id->value."\".")
                unless $obj;

        } elsif ($id->name eq 'media_id') {
            $type = 'media';
            $obj  = Bric::Biz::Asset::Business::Media->lookup({
                id => $id->value,
            });
            throw_ap(error => "Unable to find media object for media_id \"".$id->value."\".")
                unless $obj;
        } elsif ($id->name eq 'template_id') {
            $type = 'template';
            $obj  = Bric::Biz::Asset::Template->lookup({ id => $id->value });
            throw_ap 'Unable to find template object for template_id "'
                . $id->value .'".'
                unless $obj;
        } else {
            throw_ap(error => "Unknown element found in move_ids list.");
        }

        # check check check
        throw_ap(error => "Cannot move checked-out $types{$type}: \""
                       . $id->value."\".")
            if $obj->get_checked_out;

        # Check for EDIT permission
        throw_ap(error => "Access denied.") unless chk_authz($obj, EDIT, 1);

        # are we moving to a new workflow?
        if ($to_workflow) {
            # check the type
            my $ok = 0;
            if ($type eq 'story') {
                $ok = 1 if $to_workflow->get_type == STORY_WORKFLOW;
            } elsif ($type eq 'media') {
                $ok = 1 if $to_workflow->get_type == MEDIA_WORKFLOW;
            } else {
                $ok = 1 if $to_workflow->get_type == TEMPLATE_WORKFLOW;
            }
            throw_ap(error => __PACKAGE__ . "::move : cannot move $types{$type} \""
                            . $id->value . "\" to "
                            . "workflow \"$args->{workflow}\" : type mismatch.")
              unless $ok;

            # move to new workflow
            $obj->set_workflow_id($to_workflow->get_id);
            log_event("${type}_add_workflow", $obj, {
                Workflow => $to_workflow->get_name
            });
        } else {
            # might need to assign a workflow here, if this item was just
            # published, for example.
            unless ($obj->get_workflow_id) {
                my $workflow = (Bric::Biz::Workflow->list({
                    type => $wf_types{$type},
                }))[0];

                $obj->set_workflow_id($workflow->get_id);
                log_event("${type}_add_workflow", $obj, {
                    Workflow => $workflow->get_name,
                });

                my $desk = $workflow->get_start_desk;
                $desk->accept({asset => $obj});
                $desk->save;
                log_event("$type\_moved", $obj, { Desk => $desk->get_name });
            }
        }

        # get origin desk
        my $from_desk = $obj->get_current_desk;
        throw_ap(error => "Cannot move $types{$type} without a current desk: \""
                        . $id->value . "\".)")
            unless $from_desk;

        # don't move if we're already here
        unless ($from_desk->get_id == $to_desk->get_id) {
            $from_desk->transfer({
                asset => $obj,
                to    => $to_desk,
            });
            $from_desk->save;
            $to_desk->save;
        }
        $obj->save;

        # log the move
        log_event("$type\_moved", $obj, {  Desk => $to_desk->get_name });
    }


    print STDERR __PACKAGE__ . "->move() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @ids), "\n"
            if DEBUG;

    return name(move_ids => \@ids);
}

=item list_ids

This method queries the database for matching workflows and returns a
list of ids.  If no workflows are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The workflow's name.

=item description

The workflow's description.

=item site

The workflow's site name.

=item type

Return workflows of type 'Story', 'Media', or 'Template'.
By default all workflow types are returned.

=item desk

Given a desk name, return workflows that contain this desk.

=item active

Set false to return deleted workflows. Returns only active
workflows by default.

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

    # convert site name to site_id
    if (exists $args->{site}) {
        my $site = delete $args->{site};
        my $site_id = Bric::Biz::Site->list_ids({ name => $site });
        if (defined $site_id) {
            $args->{site_id} = $site_id->[0];
        } else {
            throw_ap error => __PACKAGE__ . "::$method: unknown site \""
              . $args->{site} . "\".";
        }
    }

    # convert type to integer
    if (exists $args->{type}) {
        if (exists $wf_types{$args->{type}}) {
            my $type = $wf_types{lc($args->{type})};
            $args->{type} = $type;
        } else {
            throw_ap error => __PACKAGE__ . "::$method: invalid type \""
              . $args->{type} . "\".";
        }
    }

    # convert desk name to desk_id
    if (exists $args->{desk}) {
        my $desk = delete $args->{desk};
        my $desk_id = Bric::Biz::Workflow::Parts::Desk->list_ids({ name => $desk });
        if (defined $desk_id) {
            $args->{desk_id} = $desk_id->[0];
        } else {
            throw_ap error => __PACKAGE__ . "::$method: unknown desk \""
              . $args->{desk} . "\".";
        }
    }

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

=item workflow_id

Specifies a single workflow_id to be retrieved.

=item workflow_ids

Specifies a list of workflow_ids.  The value for this option should be an
array of integer "workflow_id" assets.

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

A list of "workflow_id" integers for the assets to be updated.  These
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

=item workflow_id

Specifies a single asset ID to be deleted.

=item workflow_ids

Specifies a list of asset IDs to delete.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: The ONLY reason this method needs overridden is
because of the __WORKFLOWS__ cache.

=cut

sub delete {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $module = $pkg->module;
    my $method = 'delete';

    my $cache = Bric::App::Cache->new;

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
        $cache->set('__WORKFLOWS__' . $asset->get_site_id, 0);
    }

    return name(result => 1);
}


=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'workflow' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        publish  => { map { $_ => 1 } qw(story_id media_id publish_ids
                                         publish_related_stories
                                         publish_related_media
                                         publish_date published_only
                                         to_preview) },
        deploy   => { map { $_ => 1 } qw(template_id deploy_ids) },
        checkout => { map { $_ => 1 } qw(story_id media_id template_id checkout_ids) },
        checkin  => { map { $_ => 1 } qw(story_id media_id template_id checkin_ids) },
        move     => { map { $_ => 1 } qw(story_id media_id template_id move_ids
                                         desk workflow) },
        list_ids => { map { $_ => 1 } qw(name description site type desk active) },
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
        eval { $data = parse_asset_document($document, $module, 'desk') };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no $module found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{$module};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # loop over workflows, filling @ids
    my (@ids, %paths);

    foreach my $adata (@{ $data->{$module} }) {
        my $id = $adata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # get object
        my $asset;
        unless ($update) {
            # create empty workflow
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

        $adata->{site} = 'Default Site' unless exists $adata->{site};
        (my $look = $adata->{site}) =~ s/([_%\\])/\\$1/g;
        my $site = Bric::Biz::Site->lookup({ name => $look });
        unless (defined $site) {
            throw_ap error => __PACKAGE__ . ": site \"" . $adata->{site}
              . "\" not found.";
        }

        # don't create a workflow that's already taken
        my @wfs = ($pkg->class->list_ids({ name => $adata->{name},
                                           site_id => $site->get_id }),
                   $pkg->class->list_ids({ name => $adata->{name},
                                           site_id => $site->get_id,
                                           active => 0 }) );
        if (@wfs > 1) {
            throw_ap error => __PACKAGE__
              . ": can't create/update existing inactive workflow "
              . '"' . $adata->{name} . '" in site "' . $adata->{site} . '".';
        } elsif (@wfs == 1 && !$update) {
            throw_ap error => __PACKAGE__
              . "::create: existing active workflow "
              . '"' . $adata->{name} . '" in site "' . $adata->{site} . '".';
        } elsif (@wfs == 1 && $update && $wfs[0] != $id) {
            throw_ap error => __PACKAGE__
              . "::update: existing active workflow "
              . '"' . $adata->{name} . '" in site "' . $adata->{site} . '".';
        }

        my $type = lc $adata->{type};
        if (exists $wf_types{$type}) {
            $type = $wf_types{$type};
        } else {
            throw_ap error => __PACKAGE__ . ": invalid type \"$type\".";
        }

        # set simple fields
        $asset->set_name($adata->{name});
        $asset->set_description($adata->{description});
        $asset->set_site_id($site->get_id);
        $asset->set_type($type);

        # desks
        if ($update) {
            # update desks
            my %old_desks = map { $_->get_name => $_ } $asset->allowed_desks;
            my %new_desks = map { (ref($_) ? $_->{content} : $_) => $_  }
              @{ $adata->{desks}{desk} };

            # delete any desks not in the XML
            foreach my $old_name (keys %old_desks) {
                unless (exists $new_desks{$old_name}) {
                    # check if the desk has assets
                    my $old_desk = $old_desks{$old_name};
                    if ($old_desk->assets) {
                        throw_ap error => __PACKAGE__ . '::update: desk '
                          . "\"$old_name\" can't be deleted - it has assets."
                    } else {
                        $asset->del_desk([$old_desk]);
                        log_event('workflow_del_desk', $asset, { Desk => $old_name });
                    }
                }
            }

            # add any new desks
            foreach my $new_name (keys %new_desks) {
                unless (exists $old_desks{$new_name}) {
                    my $new_ddata = $new_desks{$new_name};
                    _add_desk($asset, $new_ddata, $new_name);
                }
            }
        } else {
            # create - add desks
            foreach my $ddata (@{ $adata->{desks}{desk} }) {
                my $name = ref($ddata) ? $ddata->{content} : $ddata;
                _add_desk($asset, $ddata, $name);
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
                             workflow_id  => $id,
                             args     => $args)

Serializes a single workflow object into a <workflow> workflow using
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

    # open workflow element
    $writer->startTag($module, id => $id);

    my $site = Bric::Biz::Site->lookup({ id => $asset->get_site_id });

    # write out simple attributes in schema order
    $writer->dataElement(name        => $asset->get_name);
    $writer->dataElement(description => $asset->get_description);
    $writer->dataElement(site        => $site->get_name);
    $writer->dataElement(type        => WORKFLOW_TYPE_MAP->{$asset->get_type});
    $writer->dataElement(active      => ($asset->is_active ? 1 : 0));

    # write out desks
    my @desks = grep { chk_authz($_, READ, 1) } $asset->allowed_desks;
    $writer->startTag('desks');
    foreach my $desk (@desks) {
        my $is_start = $asset->is_start_desk($desk);
        my $is_pub   = $desk->can_publish;
        $writer->dataElement(desk => $desk->get_name,
                             ($is_start ? (start => 1) : ()),
                             ($is_pub ? (publish => 1) : ()) );
    }
    $writer->endTag('desks');

    # close workflow element
    $writer->endTag($module);
}


=item @ids = _collect_ids("publish_ids", [ "story_id", "media_id" ], $env);

This method takes care of extracting a collating the id parameters
accepted by the above methods.  The result is an array of SOAP::Data
objects with name() and value() set accordingly.

Throws: NONE

Side Effects: NONE

Notes: I bet this method is inefficient.  Using XPath syntax just
I<feels> slow...

=cut

sub _collect_ids {
  my ($list, $single, $env) = @_;
  my @ids;

  # operate on the method
  my $meth = $env->match('/Envelope/Body/[1]');

  # find single params and collect their SOAP::Data representations
  foreach (@$single) {
    my $data = $meth->dataof($_);
    push(@ids, $data) if $data;
  }

  # switch to list arg, if available
  my $list_meth = $env->match('/Envelope/Body/[1]/' . $list);
  if ($list_meth) {
    # iterate through subelements collecting SOAP::Data objects
    my ($data, $count);
    for ($count = 1; $data = $list_meth->dataof("[${count}]"); $count++) {
      # should I check that $data->name() is within @$single here?
      push(@ids, $data);
    }
  }

  return @ids;
}

=begin comment

Private function to add a desk to a workflow during create/update

=end comment

=cut

sub _add_desk {
    my ($asset, $ddata, $name) = @_;
    (my $look = $name) =~ s/([_%\\])/\\$1/g;

    my $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ name => $look });
    unless (defined $desk) {
        # desk doesn't exist, so create it
        my $is_publish = (ref($$ddata) && exists($ddata->{publish})
                            && $ddata->{publish}) ? 1 : 0;
        $desk = Bric::Biz::Workflow::Parts::Desk->new({
            name => $name,
            publish => $is_publish,
        });
        $desk->save;
        log_event('desk_new', $desk);

        # note: if the desk already exists, I don't think we should
        # change its publishability here based on the publish attribute
        # because the desk might be on other workflows
    }

    # add the desk to the workflow
    $asset->add_desk({ allowed => [$desk] });
    log_event('workflow_add_desk', $asset, { Desk => $name });

    # set start desk if there's a start attribute;
    # I guess if they put multiple start desks,
    # we'll just go with the last one
    if (ref($ddata) && exists($ddata->{start})) {
        $asset->set_start_desk($desk);
    }
}

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

Scott Lanning <lannings@who.int>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>, L<Bric::Biz::Workflow|Bric::Biz::Workflow>

=cut

1;
