package Bric::App::Callback::AssetMeta;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'asset_meta');
use strict;
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);
use Bric::Biz::Asset::Formatting;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Story;

my %types = (
    'Bric::Biz::Asset::Formatting' => ['tmpl_prof', 'fa'],
    'Bric::Biz::Asset::Business::Story' => ['story_prof', 'story'],
    'Bric::Biz::Asset::Business::Media' => ['media_prof', 'media'],
);

sub add_note : Callback {
    my $self = shift;
    my $param = $self->request_args->{'param'};

    my $obj = get_state_data(CLASS_KEY, 'obj');
    my $key = CLASS_KEY . '|note';
    my $note = $param->{$key};
    $obj->add_note($note);
    add_msg('Note saved.');
    set_state_data(CLASS_KEY, 'obj');

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
    set_redirect(last_page());
}

sub return : Callback {
    set_redirect(last_page());
}


1;
