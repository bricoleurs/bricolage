package Bric::App::Callback::Site;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'site');
use strict;
use Bric::App::Session;

1;
