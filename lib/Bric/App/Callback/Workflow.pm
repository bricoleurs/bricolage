package Bric::App::Callback::Workflow;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'workflow');
use strict;
use Bric::App::Session;

1;
