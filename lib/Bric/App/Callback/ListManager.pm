package Bric::App::Callback::ListManager;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'listManager';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:aref :pkg);

sub delete : Callback {
    my $self = shift;

    my $ids     = mk_aref($self->value);
    my $obj_key = get_state_name($self->class_key);
    my $pkg     = get_package_name($obj_key);

    foreach my $id (@$ids) {
        my $obj = $pkg->lookup({'id' => $id});
        if (chk_authz($obj, EDIT, 1)) {
            $obj->delete;
            $obj->save;
            log_event($obj_key.'_del', $obj);
        } else {
            my $name = $obj->get_name;
            $name = 'Object' unless defined $name;
            $self->raise_forbidden('Permission to delete "[_1]" denied.', $name);
        }
    }
}

sub deactivate : Callback {
    my $self = shift;

    my $ids     = mk_aref($self->value);
    my $obj_key = get_state_name($self->class_key);
    my $pkg     = get_package_name($obj_key);

    foreach my $id (@$ids) {
        my $obj = $pkg->lookup({'id' => $id});
        if (chk_authz($obj, EDIT, 1)) {
            $obj->deactivate;
            $obj->save;
            log_event($obj_key.'_deact', $obj);
        } else {
            my $name = $obj->get_name;
            $name = 'Object' unless defined $name;
            $self->raise_forbidden('Permission to delete "[_1]" denied.', $name);
        }
    }
}

sub sortBy : Callback {
    my $self    = shift;
    my $value   = $self->value;
    my $widget  = $self->class_key;
    my $obj_key = get_state_name($widget);
    my $state   = get_state_data($widget, $obj_key);

    # Leading '-' means reverse the sort
    $state->{sort_order} = $value =~ s/^-// ? 'descending' : 'ascending';
    $state->{sort_by}    = $value;

    set_state_data($widget, $obj_key, $state);
}

# set offset from beginning record in @sort_objs at which array slice begins
sub set_offset : Callback {
    my $self    = shift;
    my $widget  = $self->class_key;
    my $obj_key = get_state_name($widget);
    my $state   = get_state_data($widget, $obj_key);

    $state->{offset} = $self->value;
    $state->{pagination} = 1;
    set_state_data($widget, $obj_key, $state);
}

# call back to display all results
sub show_all_records : Callback {
    my $self    = shift;
    my $widget  = $self->class_key;
    my $obj_key = get_state_name($widget);
    my $state   = get_state_data($widget, $obj_key);

    $state->{show_all}   = 1;
    $state->{pagination} = 0;
    set_state_data($widget, $obj_key, $state);
}


1;
