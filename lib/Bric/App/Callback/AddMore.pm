package Bric::App::Callback::AddMore;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'add_more');
use strict;
use Bric::App::Session qw(:state);

sub add : Callback {
    my $self = shift;

    # XXX: note that add_more expects things like 'add_more|contact|add_cb'
    # XXX: change it so it doesn't do that
    my $field = $self->trigger_key;
    my (undef, $type) = split /\|/, $field;

    set_state_data(CLASS_KEY, "add_$type" => 1);
}

1;
