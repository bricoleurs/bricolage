package Bric::App::Callback::ListManager;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'listManager';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);


# XXX: as far as I can tell, this is never used anywhere  ???

# Try to match a custom select action.
# sub select-(.+) : Callback {          # XXX: callback subversion
#     my $method = $1;                  # XXX

#     my $self = shift;
#     my $value = $self->value;
#     my $ids = ref $value ? $value : [$value];
#     my $pkg = get_state_data($self->class_key, 'pkg_name');

#     foreach my $id (@$ids) {
#         my $obj = $pkg->lookup({'id' => $id});
#         if (chk_authz($obj, EDIT, 1)) {
#             $obj->$method;
#             $obj->save;
#         } else {
#             my $msg = "Permission to delete [_1] denied.";
#             my $name = defined($obj->get_name) ?
#               '&quot;' . $obj->get_name . '&quot' : 'Object';
#             add_msg($self->lang->maketext($msg, "$method $name"));
#         }
#     }
# }

sub delete : Callback {
    my $self = shift;

    my $ids = mk_aref($self->value);
    my $pkg = get_state_data($self->class_key, 'pkg_name');
    my $obj_key = get_state_data($self->class_key, 'object');

    foreach my $id (@$ids) {
        my $obj = $pkg->lookup({'id' => $id});
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

    my $ids = mk_aref($self->value);
    my $pkg = get_state_data($self->class_key, 'pkg_name');
    my $obj_key = get_state_data($self->class_key, 'object');

    foreach my $id (@$ids) {
        my $obj = $pkg->lookup({'id' => $id});
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
    my $value = $self->value;

    # Leading '-' means reverse the sort
    if ($value =~ s/^-//) {
        set_state_data('listManager', 'sortOrder', 'reverse');
    } else {
        set_state_data('listManager', 'sortOrder', '');
    }
    set_state_data('listManager', 'sortBy', $value);
}

# set offset from beginning record in @sort_objs at which array slice begins
sub set_offset : Callback {
    set_state_data($self->class_key, 'pagination', 1);
    set_state_data($self->class_key, 'offset', $_[0]->value);
}

# call back to display all results
sub show_all_records : Callback {
    set_state_data($self->class_key, 'pagination', 0);
}


1;
