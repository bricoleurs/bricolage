package Bric::SOAP::Story;
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
use Carp qw(croak);

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Workflow - SOAP interface to Bricolage workflow.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-02-14 21:33:39 $

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

This method handles the publishing of story and media objects.  If a
story has related stories and media then these will also be published.
The behavior mirrors that of the publish system in the web interface.

The method returns 1 on success.

The method accepts the following parameters:

=over 4

=item story_id

A single story to publish.

=item media_id

A single media object to publish.

=item publish_ids

A list of "story_id" and/or "media_id" elements to be published.

=item publish_date

If set, this must be a date in the future at which the specified
stories will be published.  The date must be in XML Schema dataTime
format.  If publish_date is not specified then publishing occurs
immediately.

=back

Throws: NONE

Side Effects: Stories and media have their publish_status field set to
true.

Notes: NONE

=cut

sub publish {}

=item deploy

This method handles deploying templates. The method returns 1 on
success.  The method accepts the following parameters:

=over 4

=item template_id

A single template to publish.

=item template_ids

A list of "template_id" elements to be published.

=back

Throws: NONE

Side Effects: Templates have their deploy_status set to true.

Notes: NONE

=cut

sub deploy {}

=item checkout

This method checks out a story, media and/or template objects.  After
this call the objects are visible on the user's workspace in the web
interface and are not available for other users to edit.

An error will result if you try to checkout an object that is not
checked in.

The method returns 1 on success.

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

sub checkout {}

=item checkin

This method checks in a story, media and/or template objects.  After
this call the objects are no longer visible on the user's workspace in
the web interface and are available for other users to edit.

An error will result if you try to checkin an object that is not
checked out.

The method returns 1 on success.

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

sub checkin {}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
