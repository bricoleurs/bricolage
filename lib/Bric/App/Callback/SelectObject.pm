package Bric::App::Callback::SelectObject;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'select_object');
use strict;
use Bric::App::Session qw(:state);
use HTML::Mason::Commands;


# XXX: look at it later...
my ($object) = $field =~ /\|([^-]+)-/;
my $sub_widget = "$widget.$object";

if ($field eq "$widget|$object-selected_id_cb") {
    # Handle auto-repopulation of this form.
    my $name = get_state_data($sub_widget, 'form_name');

    set_state_data($sub_widget, 'selected_id', $param->{$name})
      unless ref $param->{$name};
}


sub clear : Callback {
    my $self = shift;
    my $trigger = $self->value;

    # If the trigger field was submitted with a true value, clear state!
    if ($self->request_args->{$trigger}) {
        my $s = \%HTML::Mason::Commands::session;
        
        # Find all the select_object widget information
        my @sel = grep(substr($_,0,13) eq 'select_object', keys %$s);
        
        # Clear out all the state data.
        foreach my $sub_widget (@sel) {
            set_state_data($sub_widget, {});   # XXX: $sub_widget
        }
    }
}


1;
