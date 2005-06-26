#!/usr/bin/perl
# Test My Workspace

use strict;
use warnings;
use Carp 'croak';
use Test::More 'no_plan';

use lib 't/UI';
use TestMech qw(%STORY %MEDIA %TEMPLATE);

my $mech = TestMech->new();

$mech->title_like(qr/^Workspace for /, 'login, see My Workspace');

# Story
SKIP: {
    my $story_link = $mech->find_link(text => $STORY{title});
    skip "Test story doesn't exist" unless $story_link;

    is($story_link->text, $STORY{title}, 'found test story');

    my $id = get_story_id($story_link);
    skip 'Story ID not found in story link' unless $id;


    ### Notes ##########
    my $notes_link = $mech->follow_link(text => 'Notes',
                                        url_regex => qr{story/edit_notes.+id=$id$});
    $mech->title_is('Edit Notes', 'followed Notes link');

    # XXX: add tests for Edit Notes

    $mech->click('asset_meta|return_cb');
    $mech->title_like(qr/^Workspace for /, 'cancelled Edit Notes');


    ### Edit ###########
    my $edit_link = $mech->follow_link(text => 'Edit',
                                       url_regex => qr{^/workflow/profile/story/$id});
    $mech->title_is('Story Profile', 'followed Edit link');
    $mech->click('story_prof|return_cb');
    $mech->title_like(qr/^Workspace for /, 'clicked Cancel button');


    ### Log ############
    my $log_link = $mech->follow_link(text => 'Log',
                                      url_regex => qr{^/workflow/events/story/$id$});
    $mech->title_is('Story Events', 'followed Log link');
    $mech->content_contains('Story Changes Saved', "'Story Changes Saved' event present");

    # XXX: add test reversing Timestamp column sort

    # text = [IMG] is because it uses HTML::TokeParser and does
    # $parser->get_text on the <img> element.
    $mech->follow_link(url => '/', text => '[IMG]');
    $mech->title_like(qr/^Workspace for /, 'clicked Return button');


    ### Clone ##########


#print $mech->content;
}

# Media
SKIP: {
    ;
}

# Template
SKIP: {
    ;
}


sub get_story_id {
    my $link = shift;
    my $attr = $link->attrs;
    my $onclick = $attr->{onclick};
    if ($onclick =~ m{/workflow/profile/preview/story/(\d+)}) {
        return $1;
    } else {
        return 0;
    }
}
