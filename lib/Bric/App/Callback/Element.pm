package Bric::App::Callback::Element;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'element';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Util qw(:all);
use Bric::Biz::AssetType;

my $type = 'element';
my $class = get_package_name($type);


sub addElement : Callback {
    my $self = shift;
    my $param = $self->request_args;

    # Instantiate the object.
    my $id = $param->{'element_id'};
    my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

    # Check the permissions.
    unless (chk_authz($obj, $id ? EDIT : CREATE, 1)) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg($self->lang->maketext("Changes not saved: permission denied."));
        set_redirect(last_page());
    } else {
        my $value  = $self->value;
        my $elements = (ref $value eq 'ARRAY') ? $value : [ $value ];
        # add element to object using id(s)
        $obj->add_containers($elements);
        $obj->save;
        $param->{obj} = $obj;
    }
}

sub doRedirect : Callback {
    my $self = shift;
    my $param = $self->request_args;

    # Instantiate the object.
    my $id = $param->{'element_id'};
    my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

    # Check the permissions.
    unless (chk_authz($obj, $id ? EDIT : CREATE, 1)) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg($self->lang->maketext("Changes not saved: permission denied."));
        set_redirect(last_page());
    } else {
        set_redirect('/admin/profile/element/' . $param->{element_id});
        $param->{obj} = $obj;
    }
}


1;
