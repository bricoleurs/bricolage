package Bric::App::Callback::Autocomplete;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'autocomplete';

use strict;
use Bric::App::Session qw(:state);

sub save_value : Callback {
    my $self   = shift;
    my $params = $self->params;
    my $obj    = $self->value;

    foreach my $object (ref($obj) ? @$obj : ($obj)) {
        my $sub_widget = $self->class_key . '.' . $object;

        # Handle auto-repopulation of this form.
        my $name = get_state_data($sub_widget, 'form_name');
        set_state_data($sub_widget, 'value', $params->{$name})
            unless ref $params->{$name};
    }
}

1;
