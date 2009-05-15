package Bric::SOAP::Workflow::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::SOAP::Workflow');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w

=head1 Name

Workflow.pl - a test script for Bric::SOAP::Story

=head1 Synopsis

  $ ./Workflow.pl
  ok 1 ...

=head1 Description

This is a Test::More test script for the Bric::SOAP::Workflow module.

B<WARNING:> This script will publish stories and media and deploy
templates.  Do not run this script on a production system!

Bricolage requirements are:

=over 4

=item *

Some stories, media and templates.

=item *

Nothing checked out.

=item *

Two template desks named "Development" and "Deploy".

=back

=head1 Constants

=over 4

=item DEBUG

Set this to 1 to see debugging text including the full XML for every
SOAP method call and response.  Highly educational.

=item USER

Set this to a working login.

=item PASSWORD

Set this to the password for the USER account.

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=cut

use strict;
use constant DEBUG => $ENV{DEBUG} || 0;

use constant USER     => 'admin';
use constant PASSWORD => 'change me now!';

use Test::More qw(no_plan);
use SOAP::Lite (DEBUG ? (trace => [qw(debug)]) : ());
import SOAP::Data 'name';
use Data::Dumper;
use HTTP::Cookies;

# setup soap object
my $soap = new SOAP::Lite
    uri => 'http://bricolage.sourceforge.net/Bric/SOAP/Auth',
    readable => DEBUG;
$soap->proxy('http://localhost/soap',
         cookie_jar => HTTP::Cookies->new(ignore_discard => 1));

# login
my $response = $soap->login(name(username => USER), 
             name(password => PASSWORD));
ok(!$response->fault, 'fault check');

# gets ids for testing
$soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Story');
$response = $soap->list_ids();
ok(!$response->fault, 'fault check');
my $story_ids = $response->result;
ok(@$story_ids, 'retrieved story ids from list_id');

$soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Media');
$response = $soap->list_ids();
ok(!$response->fault, 'fault check');
my $media_ids = $response->result;
ok(@$media_ids, 'retrieved media ids from list_id');

$soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Template');
$response = $soap->list_ids();
ok(!$response->fault, 'fault check');
my $template_ids = $response->result;
ok(@$media_ids, 'retrieved template ids from list_id');

# switch to workflow
$soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Workflow');

# try publishing every story individually
foreach my $story_id (@$story_ids) {
    $response = $soap->publish(name(story_id => $story_id));
    ok(!$response->fault,  'fault check');
    exit 1 if $response->fault;
    ok($response->result, "published story ($story_id)");
}

# try publishing every story individually, with related media
foreach my $story_id (@$story_ids) {
    $response = $soap->publish(name(story_id => $story_id),
                   name(publish_related_media => 1));
    ok(!$response->fault,  'fault check');
    exit 1 if $response->fault;
    my $publish_ids = $response->result;
    ok(@$publish_ids, "published story ($story_id) with related media");
}


# try publishing every story individually, with related stories
foreach my $story_id (@$story_ids) {
    $response = $soap->publish(name(story_id => $story_id),
                   name(publish_related_stories => 1));
    ok(!$response->fault,  'fault check');
    exit 1 if $response->fault;
    my $publish_ids = $response->result;
    ok(@$publish_ids, "published story ($story_id) with related stories");
}

# try publishing every media object individually
foreach my $media_id (@$media_ids) {
    $response = $soap->publish(name(media_id => $media_id));
    ok(!$response->fault,  'fault check');
    exit 1 if $response->fault;
    ok($response->result, "published media ($media_id)");
}

# try publishing them all in a single call
$response = $soap->publish(name(publish_ids => 
                [
                 ( map { name(story_id => $_) } @$story_ids ),
                 ( map { name(media_id => $_) } @$media_ids ),
                ]));
ok(!$response->fault,  'fault check');
exit 1 if $response->fault;
ok($response->result, "published stories (" . join(', ', @$story_ids) . ") and media (" . join(', ', @$media_ids) . ")");

# try deploying all templates
foreach my $template_id (@$template_ids) {
    $response = $soap->deploy(name(template_id => $template_id));
    ok(!$response->fault,  'fault check');
    exit 1 if $response->fault;
    ok($response->result, "deployed template ($template_id)");
}

# try deploying them all in a single call
$response = $soap->deploy(name(deploy_ids => 
              [ map { name(template_id => $_) } @$template_ids ]));
ok(!$response->fault,  'fault check');
exit 1 if $response->fault;
ok($response->result, "deployed templates (" . join(', ', @$template_ids));

# check everything out
$response = $soap->checkout(name(checkout_ids => 
                [
                 ( map { name(story_id => $_) } @$story_ids ),
                 ( map { name(media_id => $_) } @$media_ids ),
                 ( map { name(template_id => $_) } @$template_ids ),
                ]));
ok(!$response->fault,  'fault check');
exit 1 if $response->fault;
ok($response->result, "checked out every object.");

# check everything in
$response = $soap->checkin(name(checkin_ids => 
                [
                 ( map { name(story_id => $_) } @$story_ids ),
                 ( map { name(media_id => $_) } @$media_ids ),
                 ( map { name(template_id => $_) } @$template_ids ),
                ]));
ok(!$response->fault,  'fault check');
exit 1 if $response->fault;
ok($response->result, "checked in every object.");

# move all templates to the development desk
$response = $soap->move(name(move_ids => 
                 [
                  ( map { name(template_id => $_) } @$template_ids ),
                 ]),
            name(desk => "Development"));
ok(!$response->fault,  'fault check');
exit 1 if $response->fault;
ok($response->result, "moved all templates to development");

# move all templates to the deploy desk
$response = $soap->move(name(move_ids => 
                 [
                  ( map { name(template_id => $_) } @$template_ids ),
                 ]),
            name(desk => "Deploy"));
ok(!$response->fault,  'fault check');
exit 1 if $response->fault;
ok($response->result, "moved all templates to deploy");
