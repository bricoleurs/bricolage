package Bric::App::Callback::SiteContext;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'site_context');
use strict;
use Bric::App::Session qw(:user);


sub change_context : Callback {
    $_[0]->cache->set_user_cx(get_user_id(), $_[0]->value);
}

1;
