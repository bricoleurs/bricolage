#!/usr/bin/perl
# Test creating new stories

use strict;
use warnings;
use Carp 'croak';
use Test::More 'no_plan';

use lib 't/UI';
use TestMech '%STORY';

my $mech = TestMech->new();

# Go into left nav
$mech->follow_link(tag => 'iframe');
$mech->content_contains('Frameset', 'get left nav iframe content');

# Keep opening workflows until one is a story workflow
my $newstory_regex = qr{/workflow/profile/story/new/(\d+)$};
my $link = '';
while (! ($link = $mech->find_link(url_regex => $newstory_regex))) {
    last unless $mech->follow_link(url_regex => qr{workflow_cb=1});
}

# Save workflow ID
my $wfid = 0;
if (ref($link) && $link->url =~ $newstory_regex) {
    $wfid = $1;
} else {
    croak "Story workflow not found\n";
}

$mech->get($link);
$mech->title_is('New Story', 'follow New Story link');

# XXX: To guarantee it's a Story element type, we'll need
# to go to ADMIN->PUBLISHING->Element Types, find an
# element type of 'Story', then go to ADMIN->PUBLISHING->Elements
# and find the first element of that element type. Here I just
# assume there's a 'Story' element.

# XXX: need to delete the story if it already exists. Maybe should
# test Find Stories first

$mech->submit_form(
    form_name => 'theForm',
    fields => \%STORY,
    button => 'story_prof|create_cb',
);

$mech->title_is('Story Profile', 'click Create button, goes to Story Profile');
$mech->content_like(qr{Story Type Element:.*\</td>\n.+Story\</td>},
                    'story element type is "Story"');



#print $mech->content;
