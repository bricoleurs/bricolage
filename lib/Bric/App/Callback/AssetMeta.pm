package Bric::App::Callback::AssetMeta;

# $Id $

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'asset_meta';

use strict;
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:msg :history);
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
    $obj->add_note($note);
    set_state_data($self->class_key, 'obj');

    # Cache the object in the session if it's the current object.
    my $type = $obj->key_name;
    if (my $c_obj = get_state_data($types{$type} => $type)) {
        my $cid = $c_obj->get_id;
        my $id = $obj->get_id;
        if ((!defined $cid && !defined $id) ||
            (defined $cid && defined $id && $id == $cid)) {
            # It's the same object. Put it in the cache with the new note.
            set_state_data($types{$type}, $type, $obj);
        } else {
            # It's not the same as the cached object. So just save it.
            $obj->save;
            add_msg('Note saved.');
        }
    } else {
        # Just save the asset with the note.
        $obj->save;
        add_msg('Note saved.');
    }
    # Use the page history to go back to the page that called us.
    $self->set_redirect(last_page());
}

sub return : Callback {
    shift->set_redirect(last_page());
}


1;
