package Bric::App::Callback::ListManager;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'listManager');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);


# Try to match a custom select action.
sub select-(.+) : Callback {          # XXX: callback subversion
    my $method = $1;                  # XXX

    my $self = shift;
    my $value = $self->param_field;
    my $id      = ref $value ? $value : [$value];
    my $pkg = get_state_data(CLASS_KEY, 'pkg_name');

    foreach (@$id) {
        my $obj = $pkg->lookup({'id' => $_});
        if (chk_authz($obj, EDIT, 1)) {
            $obj->$method;
            $obj->save;
        } else {
            my $msg = "Permission to delete [_1] denied.";
            my $name = defined($obj->get_name) ?
              '&quot;' . $obj->get_name . '&quot' : 'Object';
            add_msg($self->lang->maketext($msg, "$method $name"));
        }
    }
}

sub delete : Callback {
    my $self = shift;

    my $id  = mk_aref($param->{$field});
    my $pkg = get_state_data(CLASS_KEY, 'pkg_name');
    my $obj_key = get_state_data(CLASS_KEY, 'object');

    foreach (@$id) {
        my $obj = $pkg->lookup({'id' => $_});
        if (chk_authz($obj, EDIT, 1)) {
            $obj->delete;
            $obj->save;
            log_event($obj_key.'_del', $obj);
        } else {
            my $msg = "Permission to delete [_1] denied.";
            my $name = defined($obj->get_name) ?
              '&quot;' . $obj->get_name . '&quot' : 'Object';
            add_msg($self->lang->maketext($msg, $name));
        }
    }
}

sub deactivate : Callback {
    my $self = shift;

    my $id  = mk_aref($param->{$field});
    my $pkg     = get_state_data(CLASS_KEY, 'pkg_name');
    my $obj_key = get_state_data(CLASS_KEY, 'object');

    foreach (@$id) {
        my $obj = $pkg->lookup({'id' => $_});
        if (chk_authz($obj, EDIT, 1)) {
            $obj->deactivate;
            $obj->save;
            log_event($obj_key.'_deact', $obj);
        } else {
            my $msg = "Permission to delete [_1] denied.";
            my $name = defined($obj->get_name) ?
              '&quot;' . $obj->get_name . '&quot' : 'Object';
            add_msg($self->lang->maketext($msg, $name));
        }
    }
}

sub sortBy : Callback {
    my $self = shift;

    # Leading '-' means reverse the sort
    if ($param->{$field} =~ s/^-//) {
        set_state_data('listManager', 'sortOrder', 'reverse');
    } else {
        set_state_data('listManager', 'sortOrder', '');
    }
    set_state_data('listManager', 'sortBy', $param->{$field});
}

# set offset from beginning record in @sort_objs at which array slice begins
sub set_offset : Callback {
    my $self = shift;

    set_state_data(CLASS_KEY, 'pagination', 1);
    set_state_data(CLASS_KEY, 'offset', $self->param_field);
}

# call back to display all results
sub show_all_records : Callback {
    set_state_data(CLASS_KEY, 'pagination', 0);
}


1;
