package Bric::App::Callback::Alert;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'alert');
use strict;
use Bric::App::Session;

1;
