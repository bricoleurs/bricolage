package Bric::App::Callback::AddMore;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'add_more';

use strict;
use Bric::App::Session qw(:state);


sub add : Callback {
    my $self = shift;
    my $type = $self->request_args->{'addmore_type'};
    set_state_data($self->class_key, "add_$type" => 1);
}


1;
