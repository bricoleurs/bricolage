package Bric::App::Callback::Publish;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'publish');
use strict;
use Bric::App::Session;

1;
