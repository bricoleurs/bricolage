package Bric::App::Callback::Desk;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'desk');
use strict;
use Bric::App::Session qw(:state :user);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::App::Callback::Publish;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Formatting;
use Bric::Biz::Workflow;
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Config qw(ALLOW_WORKFLOW_TRANSFER);
use Bric::Util::Burner;
use Bric::Util::Time;

my %num = (
    1 => 'One',
    2 => 'Two',
    3 => 'Three',
    4 => 'Four',
    5 => 'Five',
    6 => 'Six',
    7 => 'Seven',
    8 => 'Eight',
    9 => 'Nine',
    10 => 'Ten',
);
my $type = 'formatting';
my $disp_name = get_disp_name($type);
my $pl_name = get_class_info($type)->get_plural_name;


sub checkin : Callback {
    my $self = shift;

    my $a_id    = $self->value;
    my $a_class = $self->request_args->{CLASS_KEY.'|asset_class'};
    my $pkg     = get_package_name($a_class);
    my $a_obj   = $pkg->lookup({'id' => $a_id, checkout => 1});
    my $d       = $a_obj->get_current_desk;

    $d->checkin($a_obj);
    $d->save;
    log_event("${a_class}_checkin", $a_obj);
}

sub checkout : Callback {
    my $self = shift;

    my $a_id    = $self->value;
    my $a_class = $self->request_args->{CLASS_KEY.'|asset_class'};
    my $pkg     = get_package_name($a_class);
    my $a_obj   = $pkg->lookup({'id' => $a_id});
    my $d       = $a_obj->get_current_desk;

    $d->checkout($a_obj, get_user_id());
    $d->save;
    $a_obj->save;
    log_event("${a_class}_checkout", $a_obj);

    $a_id = $a_obj->get_id;

    my $profile;
    if ($a_class eq 'formatting') {
        $profile = '/workflow/profile/templates';
    } elsif ($a_class eq 'media') {
        $profile = '/workflow/profile/media';
    } else {
        $profile = '/workflow/profile/story';
    }

    set_redirect("$profile/$a_id/?checkout=1");
}

sub move : Callback {
    my $self = shift;

    # Accept one or more assets to be moved to another desk.
    my $next_desk = $self->request_args->{CLASS_KEY.'|next_desk'};
    my $assets    = ref $next_desk ? $next_desk : [$next_desk];

    my ($a_id, $a_class, $d_id, $pkg, %wfs);
    foreach my $a (@$assets) {
        my ($a_id, $from_id, $to_id, $a_class, $wfid) = split('-', $a);

        # Do not move assets where the user has not chosen a next desk.
        # And where the desk ID is the same.
        next unless $to_id and $to_id != $from_id;

        my $pkg   = get_package_name($a_class);
        my $a_obj = $pkg->lookup({'id' => $a_id});

        unless ($a_obj->is_current) {
            my $msg = "Cannot move [_1] asset '[_2]' while it is checked out";
            add_msg($self->lang->maketext($msg, $a_class, $a_obj->get_name));
            next;
        }

        my $dpkg = 'Bric::Biz::Workflow::Parts::Desk';

        # Get the current desk and the next desk.
        my $d    = $dpkg->lookup({'id' => $from_id});
        my $next = $dpkg->lookup({'id' => $to_id});

        # Transfer from the current to the next.
        $d->transfer({'to'    => $next,
                      'asset' => $a_obj});

        # Save both desks.
        $d->save;
        $next->save;

        if (ALLOW_WORKFLOW_TRANSFER) {
            if ($wfid != $a_obj->get_workflow_id) {
                # Transfer workflows.
                $a_obj->set_workflow_id($wfid);
                $a_obj->save;
                my $wf = $wfs{$wfid} ||=
                  Bric::Biz::Workflow->lookup({ id => $wfid });
                log_event("${a_class}_add_workflow", $a_obj,
                          { Workflow => $wf->get_name });
            }
        }

        # Log an event
        log_event("${a_class}_moved", $a_obj, { Desk => $next->get_name });
    }
}

sub publish : Callback {
    my $self = shift;
    my $param = $self->request_args;
    my $story_pub = $param->{'story_pub'};
    my $media_pub = $param->{'media_pub'};

    my $mpkg = 'Bric::Biz::Asset::Business::Media';
    my $spkg = 'Bric::Biz::Asset::Business::Story';
    my $story = mk_aref($param->{CLASS_KEY.'|story_pub_ids'});
    my $media = mk_aref($param->{CLASS_KEY.'|media_pub_ids'});
    my (@rel_story, @rel_media);

    # start with the objects checked for publish
    my @objs = ((map { $mpkg->lookup({id => $_}) } @$media),
		(map { $spkg->lookup({id => $_}) } @$story),
                (values %$story_pub),
                (values %$media_pub)
               );

    # Make sure we have the IDs for any assets passed in explicitly.
    push @$story, keys %$story_pub;
    push @$media, keys %$media_pub;

    # make sure we don't get into circular loops
    my %seen;

    # iterate through objects looking for related media
    while(@objs) {
        my $a = shift @objs;
        next unless $a;

        # haven't I seen you someplace before?
        my $key = ref($a) . '.' . $a->get_id;
        next if exists $seen{$key};
        $seen{$key} = 1;

        if ($a->get_checked_out) {
            my $msg = "Cannot publish [_1]  because it is checked out";
            my $arg = lc(get_disp_name($a->key_name))
              . " '" . $a->get_name . "'";
            add_msg($self->lang->maketext($msg, $arg));
            next;
        }

        # Examine all the related objects.
        foreach my $r ($a->get_related_objects) {
            # Skip assets whose current version has already been published.
            next if not $r->needs_publish();

            if ($r->get_checked_out) {
                my $msg = "Cannot auto-publish related [_1] because "
                  . "it is checked out";
                my $arg = lc(get_disp_name($r->key_name))
                  . " '" . $r->get_name."'";
                add_msg($self->lang->maketext($msg, $arg));
                next;
            }

	    # push onto the appropriate list
	    if (ref $r eq $spkg) {
		push @rel_story, $r->get_id;
		push(@objs, $r); # recurse through related stories
	    } else {
		push @rel_media, $r->get_id;
	    }
	}
    }

    # Add these unpublished related assets to be published as well.
    push @$story, @rel_story;
    push @$media, @rel_media;

    set_state_data('publish', { story => $story,
                                media => $media,
                                story_pub => $story_pub,
                                media_pub => $media_pub
                              });

    if (%$story_pub or %$media_pub) {
        # Instant publish!
        my $pub = Bric::App::Callback::Publish->new(
            'ah' => $self->ah,
            'apache_req' => $self->apache_req,
            'request_args' => {
                'instant' => 1,
                'pub_date' => Bric::Util::Time::strfdate,
            },
        );
        $pub->publish();
    } else {
        set_redirect('/workflow/profile/publish');
    }
}

sub deploy : Callback {
    my $self = shift;

    my $a_ids = $self->request_args->{CLASS_KEY.'|formatting_pub_ids'};
    my $b = Bric::Util::Burner->new;

    $a_ids = ref $a_ids ? $a_ids : [$a_ids];

    my $name;
    my $c = @$a_ids;
    foreach (@$a_ids) {
        my $fa = Bric::Biz::Asset::Formatting->lookup({ id => $_ });
        my $action = $fa->get_deploy_status ? 'formatting_redeploy'
          : 'formatting_deploy';
        $b->deploy($fa);
        $fa->set_deploy_date(strfdate());
        $fa->set_deploy_status(1);
        $fa->set_published_version($fa->get_current_version);
        $fa->save;
        log_event($action, $fa);

        # Get the current desk and remove the asset from it.
        my $d = $fa->get_current_desk;
        $d->remove_asset($fa);
        $d->save;

        # Clear the workflow ID.
        $fa->set_workflow_id(undef);
        $fa->save;
        log_event("formatting_rem_workflow", $fa);

        # Get the template's name, if it's just one template we're deploying.
        $name = '&quot;' . $fa->get_name . '&quot;' if $c == 1;
    }
    # Let 'em know we've done it!
    my $msg = '[_1] deployed.';
    my $arg = $name ? $disp_name : ($num{$c} || $c) . " $pl_name";
    add_msg($self->lang->maketext($msg, $arg));
}

sub clone : Callback {
    my $self = shift;

    my $aid = $self->value;
    # Lookup the story and log that it has been cloned.
    my $story = Bric::Biz::Asset::Business::Story->lookup({ id => $aid });
    log_event('story_clone', $story);
    # Look it up again to avoid the event above being logged on the clone
    # instead of the original story.
    $story = Bric::Biz::Asset::Business::Story->lookup({ id => $aid });
    # Get the current desk.
    my $desk = $story->get_current_desk;
    # Clone and save the story.
    $story->clone;
    $story->set_title('Clone of ' . $story->get_title);
    $story->save;
    # Put the cloned story on the desk.
    $desk->accept({ asset => $story });
    $desk->save;
    # Log events.
    my $wf = $story->get_workflow_object;
    log_event('story_clone_create', $story);
    log_event('story_add_workflow', $story, { Workflow => $wf->get_name });
    log_event('story_moved', $story, { Desk => $desk->get_name });
    log_event('story_checkout', $story);
}



1;
