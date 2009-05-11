package Bric::App::Callback::AssetMeta;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'asset_meta';

use strict;
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:history);
use Bric::Biz::Asset::Template;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;

my %types = (
    template => 'tmpl_prof',
    story    => 'story_prof',
    media    => 'media_prof',
);

my $key = CLASS_KEY . '|note';

sub add_note : Callback {
    my $self = shift;
    my $param = $self->params;

    my $obj = get_state_data($self->class_key, 'obj');
    my $note = $param->{$key};

    unless ($obj->get_checked_out && $obj->get_user__id == get_user_id) {
        # Protect the user from herself.
        $self->raise_forbidden(
            'You cannot add a note to "[_1]" because it is not checked out to you',
            $obj->get_title
        );
        $self->set_redirect(last_page());
        return;
    }

    # Set the note.
    $obj->set_note($note);
    set_state_data($self->class_key, 'obj');

    # Cache the object in the session if it's the current object.
    my $type = $obj->key_name;
    if (my $c_obj = get_state_data($types{$type} => $type)) {
        if ($obj->get_uuid eq $c_obj->get_uuid) {
            # It's the same object. Put it in the cache with the new note.
            set_state_data($types{$type}, $type, $obj);
        } else {
            # It's not the same as the cached object. So just save it.
            $obj->save;
            $self->add_message('Note saved.');
        }
    } else {
        # Just save the asset with the note.
        $obj->save;
        $self->add_message('Note saved.');
    }
    # Use the page history to go back to the page that called us.
    $self->set_redirect(last_page());
}

sub return : Callback {
    shift->set_redirect(last_page());
}


1;
