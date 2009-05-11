package Bric::App::Callback::Publish;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'publish';

use strict;
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:aref :history :browser redirect_onload);
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::OutputChannel;
use Bric::Dist::ServerType;
use Bric::Config qw(:prev :time);
use Bric::Util::Burner;
use Bric::Util::DBI qw(:junction);
use Bric::Util::Job::Pub;
use Bric::Util::Trans::FS;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:pkg);
use Bric::Util::Fault qw(throw_error);

sub preview : Callback {
    my $self = shift;
    my $param = $self->params;
    my $story_id = $param->{'story_id'};
    my $media_id = $param->{'media_id'};
    my $oc_id    = $param->{'oc_id'};

    # Note that we're previewing so that the error page will work correctly.
    if (my $ar = $self->apache_req) {
        $ar->pnotes('burner.preview' => 1);
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
        my $url = do {
            if (AUTO_PREVIEW_MEDIA && !$media->get_needs_preview) {
                my $oc = $oc_id
                  ? Bric::Biz::OutputChannel->lookup({ id => $oc_id })
                  : $media->get_primary_oc;
                if (PREVIEW_LOCAL) {
                    Bric::Util::Trans::FS->cat_uri(
                        '/', PREVIEW_LOCAL, $media->get_uri($oc)
                    );
                } else {
                    my ($dest) = Bric::Dist::ServerType->list({
                        can_preview       => 1,
                        active            => 1,
                        output_channel_id => $oc->get_id,
                    });
                    throw_error
                        error => 'Cannot preview asset "' . $media->get_name
                          . '" because there are no Preview Destinations '
                          . 'associated with its output channels.',
                        maketext => ['Cannot preview asset "[_1]" because there '
                                     . 'are no Preview Destinations associated with '
                                     . 'its output channels.', $media->get_name]
                      unless $dest;
                    ($oc->get_protocol || 'http://')
                      . ($dest->get_servers)[0]->get_host_name
                      . $media->get_uri($oc);
                }
            } else {
                $b->preview($media, 'media', get_user_id(), $oc_id);
            }
        };
        if ($url) {
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

            $b->preview($ra, 'media', get_user_id(), $oc_id)
                unless AUTO_PREVIEW_MEDIA && !$ra->get_needs_preview;
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
    my $story_id = $param->{story_id};
    my $media_id = $param->{media_id};

    # Grab the story and media IDs from the session.
    my ($story_pub_ids, $media_pub_ids);
    if (my $d = get_state_data($self->class_key)) {
        ($story_pub_ids, $media_pub_ids) = @{$d}{qw(story media)};
        clear_state($self->class_key);
    } elsif (! defined $story_id && ! defined $media_id ) {
        return;
    }

    my $stories = mk_aref($story_pub_ids);
    my $media   = mk_aref($media_pub_ids);

    # Iterate through each story and media object to be published.
    for my $spec (
        [ 'story', 'stories', $stories ],
        [ 'media', 'media',   $media   ],
    ) {
        my ($key, $plural, $doc_ids) = @$spec;
        my $count = @$doc_ids or next;
        my $exp_count = 0;
        my $pkg = get_package_name($key);
        my $disp = get_disp_name($key);
        for my $doc ($pkg->list({ version_id => ANY(@$doc_ids) })) {
            # Schedule
            my $name = 'Publish "' . $doc->get_name . '"';
            my $job = Bric::Util::Job::Pub->new({
                sched_time             => $param->{pub_date},
                user_id                => get_user_id,
                name                   => $name,
                "$key\_instance_id"    => $doc->get_version_id,
                priority               => $doc->get_priority,
            });
            $job->save;
            log_event('job_new', $job);

            my $exp_date = $doc->get_expire_date(ISO_8601_FORMAT);
            my $expired  = $exp_date
                && $exp_date lt $job->get_sched_time(ISO_8601_FORMAT);
            if ($count <= 3) {
                my $saved = $expired
                    ? $job->get_comp_time ? 'expired from '   : 'scheduled for expiration from'
                    : $job->get_comp_time ? 'published to' : 'scheduled for publication to';
                $self->add_message(
                    qq{"[_1]" ${saved} [_2].},
                    $doc->get_title,
                    $doc->get_site->get_name,
                );
            } else {
                $exp_count++ if $expired;
            }

            # Remove it from the desk it's on.
            if (my $d = $doc->get_current_desk) {
                $d->remove_asset($doc);
                $d->save;
            }

            # Remove it from the workflow by setting its workflow ID to undef
            # Yes, we have to use user__id instead of checked_out because
            # non-current versions of documents always have checked_out set to
            # 0, even when the current version is checked out.
            if ($doc->get_workflow_id
                    && !defined $doc->get_user__id # Not checked out.
                        && $doc->get_version == $doc->get_current_version
             ) {
                $doc->set_workflow_id(undef);
                log_event("$key\_rem_workflow", $doc);
            }
            $doc->save;
        }
        $self->add_message(
            "[quant,_1,$key,$plural] published.",
            $count - $exp_count,
        ) if $count > 3;
        $self->add_message(
            "[quant,_1,$key,$plural] expired.",
            $exp_count,
        ) if $exp_count;

        # Publish stuff passed to publish_another().
        Bric::Util::Burner->flush_another_queue if $key eq 'story';
    }

    unless (exists($param->{instant}) && $param->{instant}) {
        # redirect_onload() prevents any other callbacks from executing.
        redirect_onload(last_page(), $self);
    }
}

1;
