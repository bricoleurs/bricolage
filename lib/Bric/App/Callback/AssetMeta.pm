package Bric::App::Callback::AssetMeta;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'asset_meta';

use strict;
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:msg :history);
use Bric::Biz::Asset::Formatting;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;

my %types = (
    'Bric::Biz::Asset::Formatting' => ['tmpl_prof', 'fa'],
    'Bric::Biz::Asset::Business::Story' => ['story_prof', 'story'],
    'Bric::Biz::Asset::Business::Media' => ['media_prof', 'media'],
);

for my $sub (qw(Image Audio Video)) {
    $types{"Bric::Biz::Asset::Business::Media::$sub"} =
      $types{'Bric::Biz::Asset::Business::Media'};
}

my $key = CLASS_KEY . '|note';

sub add_note : Callback {
    my $self = shift;
    my $param = $self->params;

    my $obj = get_state_data($self->class_key, 'obj');
    my $note = $param->{$key};
    $obj->add_note($note);
    add_msg('Note saved.');
    set_state_data($self->class_key, 'obj');

    # Cache the object in the session if it's the current object.
    my @state_vals = @{ $types{ ref $obj } };
    if (my $c_obj = get_state_data(@state_vals)) {
        my $cid = $c_obj->get_id();
        my $id = $obj->get_id();
        set_state_data(@state_vals, $obj)
          if (!defined $cid && !defined $id) ||
          (defined $cid && defined $id && $id == $cid);
    }
    # Use the page history to go back to the page that called us.
    $self->set_redirect(last_page());
}

sub return : Callback {
    shift->set_redirect(last_page());
}


1;
