# Test left nav methods.
# Before `make install` is performed this script should be runnable with
# `make test`. After `make install` it should work as `perl 20-leftnav.t`.

use strict;
require 5.006001;
use warnings;

use Test::More tests => 17;    # must match `skip' below
use Bric::Mech;

SKIP: {
    my $msg = "Bricolage env vars not set.\n"
      . "See 'README' for installation instructions.";
    skip($msg, 17) unless exists $ENV{BRICOLAGE_SERVER}
      && exists $ENV{BRICOLAGE_USERNAME} && exists $ENV{BRICOLAGE_PASSWORD};

    my $mech = Bric::Mech->new();
    $mech->login();

    # my_workspace
    $mech->my_workspace();
    like($mech->content, qr{action="/workflow/profile/workspace/"},
         'clicking My Workspace');
    ok(!$mech->in_leftnav, 'not in left nav');

    # enter_leftnav
    $mech->enter_leftnav();
    ok($mech->in_leftnav, 'enter_leftnav');

    # open_workflow_menu
    # id arg
    my $link = $mech->find_link(url_regex => qr/workflow_cb/);
    isa_ok($link, 'WWW::Mechanize::Link');
    $link->url =~ /navwfid=(\d+)\b/;
    my $id = $1;
    $mech->open_workflow_menu(id => $id);
    ok($mech->in_leftnav, 'open_workflow_menu goes in left nav');
    is($mech->get_workflow_menu, $id, 'get_workflow_menu returns correct ID');
    # XXX: this test doesn't work in 1.8
    $link = $mech->find_link(url_regex => qr/workflow_cb=0/);
    isa_ok($link, 'WWW::Mechanize::Link');
    $link->url =~ /navwfid=(\d+)\b/;
    is($1, $id, 'workflow menu expanded');
    # XXX: add tests for 'name' and 'expand_only' args

    # expand_workflow_menus
    $mech->expand_workflow_menus();
    ok($mech->in_leftnav, 'expand_workflow_menus in left nav');
    # XXX: 

    # follow_action_link
    $mech->follow_action_link(action => 'find');
    ok(!$mech->in_leftnav, 'follow_action_link');
    # XXX: 

    # follow_desk_link
    # XXX: 

    # follow_admin_link
    $mech->follow_admin_link(manager => 'user');
    ok(! $mech->in_leftnav, 'follow_admin_link');
    # XXX: 

    # close_workflow_menu
    $mech->close_workflow_menu();
    ok($mech->in_leftnav, 'close_workflow_menu goes in left nav');
    is($mech->get_workflow_menu, 0, 'get_workflow_menu returns 0');
    $link = $mech->find_link(url_regex => qr/workflow_cb=1/);
    isa_ok($link, 'WWW::Mechanize::Link');
    $link->url =~ /navwfid=(\d+)\b/;
    is($1, $id, 'workflow menu collapsed');
    # XXX: add test for 'id' arg

    # collapse_workflow_menus
    $mech->collapse_workflow_menus();
    ok($mech->in_leftnav, 'collapse_workflow_menus in left nav');
    # XXX: 

    # expand_admin_menus
    $mech->expand_admin_menus();
    ok($mech->in_leftnav, 'expand_admin_menus in left nav');
    # XXX: 
}
