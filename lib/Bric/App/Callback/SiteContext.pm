package Bric::App::Callback::SiteContext;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'site_context');
use strict;
use Bric::App::Cache;
use Bric::App::Session qw(:user);


my $c = Bric::App::Cache->new();   # singleton


sub change_context : Callback {
    my $self = shift;
    $c->set_user_cx(get_user_id(), $self->param_field);
}

1;
