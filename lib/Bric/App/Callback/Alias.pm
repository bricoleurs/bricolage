package Bric::App::Callback::Alias;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'alias');
use strict;
use Bric::App::Session;

1;
