package Bric::App::Callback::SelectObject;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'select_object';

use strict;
use Bric::App::Session qw(:state);


sub save_selected_id : Callback {
    my $self = shift;
    my $param = $self->params;

    my $obj = $self->value;
    my @objs = ref($obj) ? @$obj : ($obj);

    foreach my $object (@objs) {
        my $sub_widget = $self->class_key . '.' . $object;

        # Handle auto-repopulation of this form.
        my $name = get_state_data($sub_widget, 'form_name');
        set_state_data($sub_widget, 'selected_id', $param->{$name})
          unless ref $param->{$name};
    }
}

sub clear : Callback {
    my $self = shift;
    my $trigger = $self->value;

    # If the trigger field was submitted with a true value, clear state!
    if ($self->params->{$trigger}) {
        my $s = Bric::App::Session->instance;

        # Find all the select_object widget information
        my @sel = grep(substr($_,0,13) eq 'select_object', keys %$s);

        # Clear out all the state data.
        foreach my $sub_widget (@sel) {
            set_state_data($sub_widget, {});
        }
    }
}


1;
