#!/usr/bin/perl
# Initializes a new Bricolage installation.
# See the accompanying README for vital information.

use warnings;
use strict;

use Bric::App::Event qw(log_event);
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::ElementType;
use Bric::Biz::Category;
use Bric::Biz::OutputChannel;
use Bric::Biz::Person::User;
use Bric::Biz::Workflow;
use Bric::Dist::ServerType;
use Bric::Util::Pref;

my %conf = (
    # uncomment this if you want to change password
#    password => 'change me?',    # <-- security risk
    prefs => {
        # add other prefs here from 'ADMIN -> SYSTEM -> Preferences'
        'Time Zone' => 'America/New_York',
        'Bricolage Instance Name' => 'Hell',
    },
    destination => {
        name => 'Web Destination',
        description => 'Auto-initialized web destination',
        move_method => 'File System',   # FTP, SFTP
        action => {
            type => 'Move',
        },
        server => {
            host_name => 'localhost',
            os => 'Unix',
            doc_root => '/usr/local/apache/htdocs/mason',
            # uncomment these if you change move_method above
#            login => 'nobody',
#            password => '',      # <-- security risk
        },
    },
    story => {
        title => 'Fascinating Story',
        slug => 'fascinating',
        type => 'Column',
        priority => 'Normal',
    },
);

main();


sub main {
    if (exists $conf{'password'}) {
        print "Changing password.\n";
        change_password();
    }
    print "Editing preferences.\n";
    edit_preferences();
    print "Adding destination.\n";
    add_destination();
    print "Adding story.\n";
    add_story();
}

sub change_password {
    my $user = Bric::Biz::Person::User->lookup({ login => 'admin' });
    $user->set_password($conf{'password'});
    $user->save();
}

sub edit_preferences {
    foreach my $name (keys %{$conf{'prefs'}}) {
        my $pref = Bric::Util::Pref->lookup({name => $name});
        my $value = $conf{'prefs'}{$name};
        eval { $pref->set_value($value) };
        if ($@) {
            die "Couldn't set preference '$name' to '$value'\nDetails:\n$@\n";
        } else {
            # XXX: this requires using the cache, which requires
            # write permission to /tmp/bricolage/cache...
            $pref->save();
        }
    }
}

# see comp/widgets/profile/dest.mc, server.mc, action.mc
sub add_destination {
    my ($destconf, @oc, $st);

    $destconf = $conf{'destination'};
    @oc = Bric::Biz::OutputChannel->list({name => 'Web'});

    $st = Bric::Dist::ServerType->new();
    # Properties
    $st->set_name($destconf->{'name'});
    $st->set_description($destconf->{'description'});
    $st->set_move_method($destconf->{'move_method'});
    $st->copy();
    $st->on_publish();
    $st->on_preview();
    $st->activate();
    # Output Channels
    $st->add_output_channels(@oc);
    $st->save();        # otherwise new_action/new_server fail
    log_event('dest_new', $st);

    # Actions
    $st->new_action($destconf->{'action'});
    # Servers
    $st->new_server($destconf->{'server'});
    $st->save();
    # need to log 'action_new' and 'server_new' events?
}

# see comp/widgets/story_prof/callback.mc, $handle_create sub
sub add_story {
    my ($storyconf, $story, $wf, $wid, $eid, $sid, $cat, $cid, $uid,
        $start_desk, $priority_labels);

    # Create a story object
    $storyconf = $conf{'story'};
    $priority_labels = Bric::Biz::Asset->list_priorities();
    $storyconf->{'priority'} = $priority_labels->{$storyconf->{'priority'}};
    ($wf) = Bric::Biz::Workflow->list({name => 'Story'});
    $wid = $wf->get_id();
    $storyconf->{'workflow_id'} = $wid;
    ($eid) = Bric::Biz::ElementType->list_ids({name => $storyconf->{'type'}});
    $storyconf->{'element_type_id'} = $eid;
    ($sid) = Bric::Biz::Org::Source->list_ids({name => 'Internal'});
    $storyconf->{'source__id'} = $sid;
    ($storyconf->{'user__id'}) = Bric::Biz::Person::User->list_ids({ login => 'admin' });

    $story = Bric::Biz::Asset::Business::Story->new($storyconf);

    # Configure story object
    ($cid) = Bric::Biz::Category->list_ids({uri => '/'});
    $story->add_categories([$cid]);
    $story->set_primary_category($cid);

    $story->set_workflow_id($wid);

    # Save story object
    $story->save();

    # Send story to desk
    $start_desk = $wf->get_start_desk();
    $start_desk->accept({ asset => $story });
    $start_desk->save();

    # Log that a new story has been created and generally handled
    $cat = Bric::Biz::Category->lookup({id => $cid});

    log_event('story_new', $story);
    log_event('story_add_category', $story, { Category => $cat->get_name() });
    log_event('story_add_workflow', $story, { Workflow => $wf->get_name() });
    log_event('story_moved', $story, { Desk => $start_desk->get_name() });
    log_event('story_save', $story);
}
