package Bric::App::Callback::Job;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'job');
use strict;
use Bric::App::Session;

1;
