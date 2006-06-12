package Bric::App::Callback::Publish;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'publish';

use strict;
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:aref :msg :history :browser redirect_onload);
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::OutputChannel;
use Bric::Dist::ServerType;
use Bric::Config qw(:prev :time);
use Bric::Util::Burner;
use Bric::Util::Job::Pub;
use Bric::Util::Trans::FS;
use Bric::App::Event qw(log_event);
use Bric::Util::Fault qw(throw_error);

sub preview : Callback {
    my $self = shift;
    my $param = $self->params;
    my $story_id = $param->{'story_id'};
    my $media_id = $param->{'media_id'};
    my $oc_id    = $param->{'oc_id'};

    # Note that we're previewing so that the error page will work correctly.
    if (my $ar = $self->apache_req) {
        $ar->notes("burner.preview" => 1);
    }

    # Grab the story and media IDs from the session.
    my ($story_pub_ids, $media_pub_ids);
    if (my $d = get_state_data($self->class_key)) {
        ($story_pub_ids, $media_pub_ids) = @{$d}{qw(story media)};
        clear_state($self->class_key);
    } elsif (! defined $story_id && ! defined $media_id ) {
        return;
    }

    # Instantiate the Burner object.
    my $b = Bric::Util::Burner->new({ out_dir => PREVIEW_ROOT,
                                      user_id => get_user_id });
    if (defined $media_id) {
        my $media = get_state_data('media_prof', 'media');
        unless ($media && (defined $media_id) && ($media->get_id == $media_id)) {
            $media = Bric::Biz::Asset::Business::Media->lookup({
                id => $media_id,
                $param->{checkout} ? () : (checked_in => 1),
            });
        }

        # Move out the media document and then redirect to preview.
        if (my $url = $b->preview($media, 'media', get_user_id(), $oc_id)) {
            status_msg("Redirecting to preview.");
            # redirect_onload() prevents any other callbacks from executing.
            redirect_onload($url, $self);
        }
    } else {
        my $s = get_state_data('story_prof', 'story');
        unless ($s && defined $story_id && $s->get_id == $story_id) {
            $s = Bric::Biz::Asset::Business::Story->lookup({
                id => $story_id,
                $param->{checkout} ? () : (checked_in => 1),
             });
        }

        # Get all the related media to be previewed as well
        foreach my $ra ($s->get_related_objects) {
            next if ref $ra eq 'Bric::Biz::Asset::Business::Story';
            next unless $ra->is_active;

            unless ($ra->get_path) {
                status_msg('No file associated with media "[_1]". Skipping.',
                           $ra->get_title);
                next;
            }

            $b->preview($ra, 'media', get_user_id(), $oc_id);
        }
        # Move out the story and then redirect to preview.
        if (my $url = $b->preview($s, 'story', get_user_id(), $oc_id)) {
            status_msg("Redirecting to preview.");
            # redirect_onload() prevents any other callbacks from executing.
            redirect_onload($url, $self);
        }
    }
}

# this is used by Desk.pm to let the user deselect related assets
# published from the publish desk
sub select_publish : Callback(priority => 1) {  # run this before 'publish'
    my $self = shift;
    # (this was set in comp/widgets/publish/publish.mc)
    my $values = mk_aref($self->value);

    my (@story, @media);
    foreach my $val (@$values) {
        # Push on the related assets that were checked
        if ($val =~ s/^story=(\d+)$//) {
            push @story, $1;
        } elsif ($val =~ s/^media=(\d+)$//) {
            push @media, $1;
        }
    }

    set_state_data($self->class_key, story => \@story);
    set_state_data($self->class_key, media => \@media);
}

sub publish : Callback {
    my $self = shift;
    my $param = $self->params;
    my $story_id = $param->{'story_id'};
    my $media_id = $param->{'media_id'};

    # Grab the story and media IDs from the session.
    my ($story_pub_ids, $media_pub_ids);
    if (my $d = get_state_data($self->class_key)) {
        ($story_pub_ids, $media_pub_ids) = @{$d}{qw(story media)};
        clear_state($self->class_key);
    } elsif (! defined $story_id && ! defined $media_id ) {
        return;
    }

    my $stories = mk_aref($story_pub_ids);
    my $media = mk_aref($media_pub_ids);

    # Iterate through each story and media object to be published.
    my $count = @$stories;
    my $exp_count = 0;
    foreach my $sid (@$stories) {
        # Schedule
        my $s = Bric::Biz::Asset::Business::Story->lookup({id => $sid});
        my $name = 'Publish "' . $s->get_name . '"';
        my $job = Bric::Util::Job::Pub->new({
            sched_time    => $param->{pub_date},
            user_id       => get_user_id(),
            name          => $name,
            story_id      => $sid,
            priority      => $s->get_priority(),
        });
        $job->save();
        log_event('job_new', $job);
        $self->record_action($s, $job, \$count, \$exp_count);

        # Remove it from the desk it's on.
        if (my $d = $s->get_current_desk) {
            $d->remove_asset($s);
            $d->save;
        }

        # Remove it from the workflow by setting its workflow ID to undef
        # Yes, we have to use user__id instead of checked_out because non-current
        # versions of documents always have checked_out set to 0, even when the
        # current version is checked out.
        if ($s->get_workflow_id
            && !defined $s->get_user__id # Not checked out.
            && $s->get_version == $s->get_current_version # Is the current version.
        ) {
            $s->set_workflow_id(undef);
            log_event("story_rem_workflow", $s);
        }
        $s->save();
    }
    add_msg('[quant,_1,story,stories] published.', $count - $exp_count)
        if $count > 3;
    add_msg('[quant,_1,story,stories] expired.',   $exp_count) if $exp_count;

    $count = @$media;
    $exp_count = 0;
    foreach my $mid (@$media) {
        # Schedule
        my $m = Bric::Biz::Asset::Business::Media->lookup({id => $mid});
        my $name = 'Publish "' . $m->get_name . '"';
        my $job = Bric::Util::Job::Pub->new({
            sched_time    => $param->{pub_date},
            user_id       => get_user_id(),
            name          => $name,
            media_id      => $mid,
            priority      => $m->get_priority,
        });
        $job->save();
        log_event('job_new', $job);
        $self->record_action($m, $job, \$count, \$exp_count);

        # Remove it from the desk it's on.
        if (my $d = $m->get_current_desk) {
            $d->remove_asset($m);
            $d->save;
        }
        # Remove it from the workflow by setting its workflow ID to undef
        if ($m->get_workflow_id) {
            $m->set_workflow_id(undef);
            log_event("media_rem_workflow", $m);
        }
        $m->save();
    }
    add_msg('[quant,_1,media,media] published.', $count - $exp_count)
        if $count > 3;
    add_msg('[quant,_1,media,media] expired.',   $exp_count) if $exp_count;

    unless (exists($param->{'instant'}) && $param->{'instant'}) {
        # redirect_onload() prevents any other callbacks from executing.
        redirect_onload(last_page(), $self);
    }
}

sub record_action {
    my ($self, $doc, $job, $count_ref, $exp_count_ref) = @_;
    my $exp_date = $doc->get_expire_date(ISO_8601_FORMAT);
    my $expired  = $exp_date && $exp_date lt $job->get_sched_time(ISO_8601_FORMAT);
    if ($$count_ref <= 3) {
        my $saved = $expired
            ? $job->get_comp_time ? 'expired from '   : 'scheduled for expiration from'
            : $job->get_comp_time ? 'published to' : 'scheduled for publication to';
        add_msg(
            ucfirst($doc->key_name) . qq{ "[_1]" ${saved} [_2].},
            $doc->get_title,
            Bric::Biz::Site->lookup({ id => $doc->get_site_id })->get_name
        );
    } else {
        if ($expired) {
            $$exp_count_ref++;
        }
    }
}

1;
