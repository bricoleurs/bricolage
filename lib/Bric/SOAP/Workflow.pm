package Bric::SOAP::Workflow;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Formatting;
use Bric::Biz::OutputChannel;
use Bric::Biz::Workflow qw(STORY_WORKFLOW MEDIA_WORKFLOW TEMPLATE_WORKFLOW);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use Bric::Config        qw(STAGE_ROOT PREVIEW_ROOT PREVIEW_LOCAL ISO_8601_FORMAT);
use Bric::App::Event    qw(log_event);
use Bric::Util::Time    qw(strfdate local_date);
use Bric::Util::MediaType;
use Bric::Dist::Job;
use Bric::Dist::ServerType;
use Bric::Dist::Resource;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::SOAP::Util qw(xs_date_to_db_date);

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

# We'll use this for outputting messages.
my %types = ( story      => 'Story',
              media      => 'Media',
              formatting => 'Template' );

# We'll use this for finding workflows.
my %wf_types = ( story      => STORY_WORKFLOW,
                 media      => MEDIA_WORKFLOW,
                 formatting => TEMPLATE_WORKFLOW );

=head1 NAME

Bric::SOAP::Workflow - SOAP interface to Bricolage workflow.

=head1 VERSION

$Revision: 1.12 $

=cut

our $VERSION = (qw$Revision: 1.12 $ )[-1];

=head1 DATE

$Date: 2003-01-18 01:20:41 $

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage
workflow.  This include facilities for moving objects onto desks,
checkin, checkout, publishing and deploying.

=head1 INTERFACE

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

Set this to true to publish to the preview destination instead of the
publish destination.  This will fail if PREVIEW_LOCAL is On in
bricolage.conf.

=item publish_date

The date and time (in ISO-8601 format) at which to publish the assets.

=back

B<Throws:> NONE.

B<Side Effects:> Stories and media have their publish_status field set to
true.

B<Notes:> The code for this method came mostly from
F<comp/widgets/publish/callback.mc>. It would be nice to collect this code in
a module so it could be kept in one place.

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(story_id media_id publish_ids
                                 publish_related_stories
                                 publish_related_media
                                 publish_date
                                 to_preview);

sub publish {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->publish() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::publish : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    my $pub_date = local_date(xs_date_to_db_date($args->{publish_date}),
                              ISO_8601_FORMAT) || strfdate();

    my $preview = (exists $args->{to_preview} and $args->{to_preview}) ? 1 : 0;
    die __PACKAGE__ . "::publish : cannot publish to_preview with ".
        "PREVIEW_LOCAL set.\n" if $preview and PREVIEW_LOCAL;

    my @ids = _collect_ids("publish_ids",
                           [ 'story_id', 'media_id' ],
                           $env);

    # Instantiate the Burner object.
    my $burner = Bric::Util::Burner->new(
                          { out_dir => $preview ? PREVIEW_ROOT : STAGE_ROOT });

    # iterate through ids publishing shiznats
    my %seen;
    my @published;
    while (my $id = shift @ids) {
        my $obj;
        my $type;
        if ($id->name eq 'story_id') {
            $type = 'story';
            $obj  = Bric::Biz::Asset::Business::Story->lookup(
                                         { id => $id->value });
            die "Unable to find story for story_id \"$id\".\n"
                unless $obj;

        } elsif ($id->name eq 'media_id') {
            $type = 'media';
            $obj  = Bric::Biz::Asset::Business::Media->lookup(
                                         { id => $id->value });
            die "Unable to find media object for media_id \"$id\".\n"
                unless $obj;

        } else {
            die "Unknown element found in publish_ids list.\n";
        }

        # don't need the object anymore
        $id = $id->value;

        # make sure we're not publishing stuff repeatedly
        next if $seen{$type}{$id};
        $seen{$type}{$id} = 1;

        # check check check
        die "Cannot publish checked-out $types{$type}: \"".$id."\".\n"
            if $obj->get_checked_out and not $preview;

        # Check for EDIT permission, or READ if previewing
        die "Access denied.\n" unless chk_authz($obj, EDIT, 1) or
                                      ($preview and chk_authz($obj, READ, 1));

        # schedule related stuff if requested
        if ($args->{publish_related_stories} or
            $args->{publish_related_media}) {
            # loop through related objects, adding to the todo list as
            # appropriate
            my @rel = $obj->get_related_objects;
            foreach my $rel (@rel) {
                if ($args->{publish_related_stories} and
                    ref($rel) =~ /Story$/) {
                    push(@ids, name(story_id => $rel->get_id));
                } elsif ($args->{publish_related_media} and
                         ref($rel) =~ /Media$/) {
                    push(@ids, name(media_id => $rel->get_id));
                }
            }
        }
            my $published = $preview ? $burner->preview($obj, $type, get_user_id)
              : $burner->publish($obj, $type, get_user_id, $args->{publish_date}, 1);
        # record the publish
        push(@published, name("${type}_id", $id)) if $published;
    }

    print STDERR __PACKAGE__ . "->publish() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @published), "\n"
            if DEBUG;

    # name, type and return
    return name(publish_ids => \@published);
}
}

=item deploy

This method handles deploying templates. The method returns
"deploy_ids", a lits of "template_id" integers deployed on success.
The method accepts the following parameters:

=over 4

=item template_id

A single template to publish.

=item deploy_ids

A list of "template_id" elements to be published.

=back

Throws: NONE

Side Effects: Templates have their deploy_status set to true.

Notes: Code here comes from comp/widgets/desk/callback.mc.  It might
be cool to move this code into a module so it could be shared.  It's
not nearly as gnarly as the publish() code though.

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(template_id deploy_ids);

sub deploy {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->deploy() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::deploy : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    my @ids = _collect_ids("deploy_ids", [ "template_id" ], $env);

    my $burner = Bric::Util::Burner->new;

    foreach my $id (map { $_->value } @ids) {
        my $fa = Bric::Biz::Asset::Formatting->lookup({ id => $id });
        die "Unable to find template for template_id \"$id\".\n"
            unless $fa;

        # check check check
        die "Cannot deloy checked-out template : \"$id\".\n"
            if $fa->get_checked_out;

        # Check for EDIT permission
        die "Access denied.\n" unless chk_authz($fa, EDIT, 1);

        $burner->deploy($fa);
        log_event($fa->get_deploy_status ?
                  'formatting_redeploy' : 'formatting_deploy',
                  $fa);
        $fa->set_deploy_date(strfdate());
        $fa->set_deploy_status(1);

        # Remove it from the current desk.
        if (my $desk = $fa->get_current_desk) {
            $desk->remove_asset($fa);
            $desk->save;
        }

        # Clear the workflow ID.
        if ($fa->get_workflow_id) {
            $fa->set_workflow_id(undef);
            log_event("formatting_rem_workflow", $fa);
        }

        $fa->save;
    }

    print STDERR __PACKAGE__ . "->deploy() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @ids), "\n"
            if DEBUG;

    return name(deploy_ids => \@ids);
}
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

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(story_id media_id template_id checkout_ids);

sub checkout {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->checkout() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::checkout : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
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
            die "Unable to find story for story_id \"".$id->value."\".\n"
                unless $obj;

        } elsif ($id->name eq 'media_id') {
            $type = 'media';
            $obj  = Bric::Biz::Asset::Business::Media->lookup(
                                         { id => $id->value });
            die "Unable to find media object for media_id \"".$id->value."\".\n"
                unless $obj;
        } elsif ($id->name eq 'template_id') {
            $type = 'formatting';
            $obj  = Bric::Biz::Asset::Formatting->lookup(
                                         { id => $id->value });
            die "Unable to find template object for template_id \"".$id->value."\".\n"
                unless $obj;
        } else {
            die "Unknown element found in checkout_ids list.\n";
        }

        # check check check
        die "Cannot check-out already checked-out $types{$type}: \"".$id->value."\".\n"
            if $obj->get_checked_out;

        # Check for EDIT permission
        die "Access denied.\n" unless chk_authz($obj, EDIT, 1);

        # make sure we're not trying to checkout stuff repeatedly
        next if $seen{$type}{$id};
        $seen{$type}{$id} = 1;

        # might need to assign a workflow here, if this item was just
        # published, for example.
        unless ($obj->get_workflow_id) {
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

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(story_id media_id template_id checkin_ids);

sub checkin {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->checkin() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::checkin : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    my @ids = _collect_ids("checkin_ids",
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
            die "Unable to find story for story_id \"".$id->value."\".\n"
                unless $obj;

        } elsif ($id->name eq 'media_id') {
            $type = 'media';
            $obj  = Bric::Biz::Asset::Business::Media->lookup(
                                         { id => $id->value });
            die "Unable to find media object for media_id \"".$id->value."\".\n"
                unless $obj;
        } elsif ($id->name eq 'template_id') {
            $type = 'formatting';
            $obj  = Bric::Biz::Asset::Formatting->lookup(
                                         { id => $id->value });
            die "Unable to find template object for template_id \"".$id->value."\".\n"
                unless $obj;
        } else {
            die "Unknown element found in checkin_ids list.\n";
        }

        # check check check
        die "Cannot check-in non checked-out $types{$type}: \"".$id->value."\".\n"
            unless $obj->get_checked_out;

        # Check for EDIT permission
        die "Access denied.\n" unless chk_authz($obj, EDIT, 1);

        # make sure we're not trying to checkin stuff repeatedly
        next if $seen{$type}{$id};
        $seen{$type}{$id} = 1;

        # check that we have a desk
        my $curr_desk = $obj->get_current_desk;
        die "Cannot check-in $types{$type} without a current desk: \"".$id->value."\".\n"
            unless $curr_desk;

        # check 'em in
        $obj->checkin;
        $obj->save;

        # log the checkin
        log_event("${type}_checkin", $obj);
    }


    print STDERR __PACKAGE__ . "->checkin() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @ids), "\n"
            if DEBUG;

    return name(checkin_ids => \@ids);
}
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

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(story_id media_id template_id move_ids
                                 desk workflow);

sub move {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->move() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::move : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    # make sure we have a desk
    die __PACKAGE__ . "::move : missing required parameter \"desk\".\n"
        unless $args->{desk};

    # find destination workflow if defined
    my $to_workflow;
    if (exists $args->{workflow}) {
        ($to_workflow) = Bric::Biz::Workflow->list(
                   { name => $args->{workflow} });
      die __PACKAGE__ . "::move : no workflow found matching " .
          "(workflow => \"$args->{workflow}\")\n"
              unless defined $to_workflow;
    }

    # find destination desk
    my ($to_desk) = Bric::Biz::Workflow::Parts::Desk->list(
                                 { name => $args->{desk} });
    die __PACKAGE__ . "::move : no desk found matching " .
        "(desk => \"$args->{desk}\")\n"
            unless $to_desk;

    my @ids = _collect_ids("move_ids",
                           [ "story_id", "media_id", "template_id" ],
                           $env);

    foreach my $id (@ids) {
        my $obj;
        my $type;
        if ($id->name eq 'story_id') {
            $type = 'story';
            $obj  = Bric::Biz::Asset::Business::Story->lookup(
                                         { id => $id->value });
            die "Unable to find story for story_id \"".$id->value."\".\n"
                unless $obj;

        } elsif ($id->name eq 'media_id') {
            $type = 'media';
            $obj  = Bric::Biz::Asset::Business::Media->lookup(
                                         { id => $id->value });
            die "Unable to find media object for media_id \"".$id->value."\".\n"
                unless $obj;
        } elsif ($id->name eq 'template_id') {
            $type = 'formatting';
            $obj  = Bric::Biz::Asset::Formatting->lookup(
                                         { id => $id->value });
            die "Unable to find template object for template_id \"".$id->value."\".\n"
                unless $obj;
        } else {
            die "Unknown element found in move_ids list.\n";
        }

        # check check check
        die "Cannot move checked-out $types{$type}: \"".$id->value."\".\n"
            if $obj->get_checked_out;

        # Check for EDIT permission
        die "Access denied.\n" unless chk_authz($obj, EDIT, 1);

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
            die __PACKAGE__ . "::move : cannot move $types{$type} \"".$id->value."\" to " .
                "workflow \"$args->{workflow}\" : type mismatch.\n"
                    unless $ok;

            # move to new workflow
            $obj->set_workflow_id($to_workflow->get_id);
            log_event("${type}_add_workflow", $obj,
                      { Workflow => $to_workflow->get_name });
        } else {
            # might need to assign a workflow here, if this item was just
            # published, for example.
            unless ($obj->get_workflow_id) {
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
        }

        # get origin desk
        my $from_desk = $obj->get_current_desk;
        die "Cannot move $types{$type} without a current desk: \"".$id->value."\".\n"
            unless $from_desk;

        # don't move if we're already here
        unless ($from_desk->get_id == $to_desk->get_id) {
            $from_desk->transfer({asset => $obj,
                                  to    => $to_desk});
            $from_desk->save;
            $to_desk->save;
        }
        $obj->save;

        # log the move
        log_event("${type}_moved", $obj, {Desk => $to_desk->get_name});
    }


    print STDERR __PACKAGE__ . "->move() finished : ",
        join(', ', map { $_->name . " => " . $_->value } @ids), "\n"
            if DEBUG;

    return name(move_ids => \@ids);
}
}

=back

=head2 Private Class Methods

=over 4

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

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
