package Bric::App::Callback::Perm;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'perm');
use strict;
use Bric::App::Session;

1;
