package Bric::App::Callback::Publish;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'publish';

use strict;
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:all);
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;
use Bric::Config qw(:prev);
use Bric::Util::Burner;


sub preview : Callback {
    my $self = shift;
    my $param = $self->request_args;
    my $story_id = $param->{'story_id'};
    my $media_id = $param->{'media_id'};
    my $oc_id    = $param->{'oc_id'};

    # Grab the story and media IDs from the session.
    my ($story_pub_ids, $media_pub_ids, $story_pub, $media_pub);
    if (my $d = get_state_data($self->class_key)) {
        ($story_pub_ids, $media_pub_ids, $story_pub, $media_pub) =
          @{$d}{qw(story media story_pub media_pub)};
        clear_state($self->class_key);
    } elsif (! defined $story_id && ! defined $media_id ) {
        return;
    }

    # Instantiate the Burner object.
    my $b = Bric::Util::Burner->new({ out_dir => PREVIEW_ROOT });
    if (defined $media_id) {
        my $media = get_state_data('media_prof', 'media');
        unless ($media && (defined $media_id) && ($media->get_id == $media_id)) {
            $media = Bric::Biz::Asset::Business::Media->lookup
              ({ id => $media_id,
                 checkout => $param->{checkout} });
        }

        # Move out the story and then redirect to preview.
        my $url = $b->preview($media, 'media', get_user_id(), $oc_id);
        status_msg("Redirecting to preview.");
        redirect_onload($url, $self);
    } else {
        my $s = get_state_data('story_prof', 'story');
        unless ($s && defined $story_id && $s->get_id == $story_id) {
            $s = Bric::Biz::Asset::Business::Story->lookup
              ({ id => $story_id,
                 checkout => $param->{checkout} });
        }

        # Get all the related media to be previewed as well
        foreach my $ra ($s->get_related_objects) {
            next if (ref $ra eq 'Bric::Biz::Asset::Business::Story');

            # Make sure this media object isn't checked out.
            if ($ra->get_checked_out) {
                my $msg = 'Cannot auto-publish related media [_1] '
                  . 'because it is checked out';
                my $arg = '&quot;' . $ra->get_title . '&quot';
                add_msg($self->lang->maketext($msg, $arg));
                next;
            }
            $b->preview($ra, 'media', get_user_id(), $oc_id);
        }
        # Move out the story and then redirect to preview.
        my $url = $b->preview($s, 'story', get_user_id(), $oc_id);
        status_msg("Redirecting to preview.");
        redirect_onload($url, $self);
    }
}

sub publish : Callback {
    my $self = shift;
    my $param = $self->request_args;
    my $story_id = $param->{'story_id'};
    my $media_id = $param->{'media_id'};

    # Grab the story and media IDs from the session.
    my ($story_pub_ids, $media_pub_ids, $story_pub, $media_pub);
    if (my $d = get_state_data($self->class_key)) {
        ($story_pub_ids, $media_pub_ids, $story_pub, $media_pub) =
          @{$d}{qw(story media story_pub media_pub)};
        clear_state($self->class_key);
    } elsif (! defined $story_id && ! defined $media_id ) {
        return;
    }

    # Instantiate the Burner object.
    my $b = Bric::Util::Burner->new({ out_dir => STAGE_ROOT });
    my $stories = mk_aref($story_pub_ids);
    my $media = mk_aref($media_pub_ids);

    # Iterate through each story and media object to be published.
    my $count = @$stories;
    foreach my $sid (@$stories) {
        # Instantiate the story.
        my $s = $story_pub->{$sid} ||
          Bric::Biz::Asset::Business::Story->lookup({ id => $sid });
        $b->publish($s, 'story', get_user_id(), $param->{pub_date});
        my $arg = '&quot;' . $s->get_title . '&quot;';
        add_msg($self->lang->maketext("Story [_1] published.", $arg))
          if $count <= 3;
    }
    add_msg($self->lang->maketext("[_1] stories published.", $count))
      if $count > 3;

    $count = @$media;
    foreach my $mid (@$media) {
        # Instantiate the media.
        my $ma = $media_pub->{$mid} ||
          Bric::Biz::Asset::Business::Media->lookup({ id => $mid });
        $b->publish($ma, 'media', get_user_id(), $param->{pub_date});
        my $arg = '&quot;' . $ma->get_title . '&quot;';
        add_msg($self->lang->maketext("Media [_1] published.", $arg))
          if $count <= 3;
    }
    add_msg($self->lang->maketext("[_1] media published.", $count))
      if $count > 3;

    unless (exists($param->{'instant'}) && $param->{'instant'}) {
        redirect_onload(last_page(), $self);
    }
}


1;
