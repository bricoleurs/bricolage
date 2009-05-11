package Bric::App::Callback::Profile::ElementType;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'element_type';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:history);
use Bric::Biz::ElementType;
use Bric::Util::DBI qw(:junction);

my $type  = 'element_type';
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
        $self->raise_forbidden('Changes not saved: permission denied.');
        $self->set_redirect(last_page());
    } else {
        $param->{obj} = $obj;
        my $value     = $self->value or return;
        my %existing  = map { $_->get_id => undef } $obj->get_containers;
        my $ids       = [
            grep { !exists $existing{$_} } ref $value ? @$value : $value
        ];
        return unless @$ids;

        # Get a list of subelement types to add, excluding existing ones.
        my $element_types = Bric::Biz::ElementType->list({ id => ANY(@$ids) });

        # Add 'em all and log 'em.
        $obj->add_containers($element_types);
        $obj->save;
        log_event('element_type_add', $obj, { Name => $_->get_name })
            for @$element_types;
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
        $self->raise_forbidden('Changes not saved: permission denied.');
        $self->set_redirect(last_page());
    } else {
        $self->set_redirect('/admin/profile/element_type/' . $param->{element_type_id});
        $param->{obj} = $obj;
    }
}


1;
