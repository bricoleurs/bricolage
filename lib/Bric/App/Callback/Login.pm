package Bric::App::Callback::Login;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'login');
use strict;
use Bric::App::Session;

1;
