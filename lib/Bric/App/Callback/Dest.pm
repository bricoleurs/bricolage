package Bric::App::Callback::Dest;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'dest');
use strict;
use Bric::App::Session;

1;
