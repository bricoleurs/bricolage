package Bric::App::Callback::SiteContext;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'site_context');
use strict;
use Bric::App::Session;

1;
