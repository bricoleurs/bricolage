#!/usr/bin/perl
# Test left nav.

use strict;
use warnings;
use Test::More 'no_plan';

use lib 't/UI';
use TestMech;

my $mech = TestMech->new();

# Navigate to ADMIN->SYSTEM->Preferences in the left nav
$mech->follow_link(tag => 'iframe');
$mech->content_contains('Frameset', 'get left nav iframe content');

$mech->follow_link(url_regex => qr{admin_cb=1});
$mech->content_like(qr{class="open".+admin_cb=0},
                    'open ADMIN menu');

$mech->follow_link(url_regex => qr{adminSystem_cb=1});
$mech->content_like(qr{class="open".+adminSystem_cb=0},
                    'open SYSTEM submenu');

$mech->follow_link(url => '/admin/manager/pref');
$mech->content_contains('Preference Manager', 'follow Preferences link');

# Navigate to MEDIA->Find Media in the left nav
$mech->follow_link(tag => 'iframe');
$mech->content_like(qr{class="open".+adminSystem_cb=0},
                    'get left nav iframe, menus still open');

# (this will get the first workflow that has "media" anywhere in its name;
# to be more general, we could try opening successive workflows until one
# has a link that matches /media)
$mech->follow_link(url_regex => qr{workflow_cb=1}, text_regex => qr{media}i);
$mech->content_like(qr{class="open".+workflow_cb=0},
                    'open Media workflow menu');

my $urlregex = qr{/workflow/manager/media/(\d+)};
$mech->follow_link(url_regex => qr{^$urlregex$});
$mech->content_like(qr{action="$urlregex"},   # <form action="...">
                    'follow Find Media link');
