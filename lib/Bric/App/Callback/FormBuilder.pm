package Bric::App::Callback::FormBuilder;

# XXX: $m?

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'formBuilder');
use strict;
use Bric::App::Session qw(:user);
use Bric::App::Util qw(:all);

# XXX: where will this be called from?
sub process_data : Callback {
    my $self = shift;
    my $param = $self->param;

    my ($section, $mode, $key) = $m->comp("/lib/util/parseUri.mc");

    # Get the class name.
    my $class = get_package_name($key);

    # Instantiate the object.
    my $id = $param->{$key . '_id'};
    my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

    # Check the permissions.
    unless (chk_authz($obj, $id ? EDIT : CREATE, 1)
              || ($key eq 'user' && $obj->get_id == get_user_id())) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg($self->lang->maketext("Changes not saved: permission denied."));
        set_redirect(last_page());
        return;
    }
    # Process its data
    $param->{obj} = $m->comp("$key.mc", %ARGS, obj => $obj, class => $class);
}


1;
