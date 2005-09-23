package Bric::App::Callback::Element;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'element_type';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Util qw(:msg :history);
use Bric::Biz::ElementType;

my $type = 'element_type';
my $class = 'Bric::Biz::ElementType';


sub addElementType : Callback {
    my $self = shift;
    my $param = $self->params;

    # Instantiate the object.
    my $id = $param->{element_type_id};
    my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

    # Check the permissions.
    unless (chk_authz($obj, $id ? EDIT : CREATE, 1)) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg("Changes not saved: permission denied.");
        $self->set_redirect(last_page());
    } else {
        my $value  = $self->value;
        my $element_types = (ref $value eq 'ARRAY') ? $value : [ $value ];
        # add element to object using id(s)
        $obj->add_containers($element_types);
        $obj->save;
        $param->{obj} = $obj;
    }
}

sub doRedirect : Callback {
    my $self = shift;
    my $param = $self->params;

    # Instantiate the object.
    my $id = $param->{element_type_id};
    my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

    # Check the permissions.
    unless (chk_authz($obj, $id ? EDIT : CREATE, 1)) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg("Changes not saved: permission denied.");
        $self->set_redirect(last_page());
    } else {
        $self->set_redirect('/admin/profile/element_type/' . $param->{element_type_id});
        $param->{obj} = $obj;
    }
}


1;
