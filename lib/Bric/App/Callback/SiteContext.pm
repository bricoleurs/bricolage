package Bric::App::Callback::SiteContext;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'site_context';

use strict;
use Bric::App::Session qw(:user);


sub change_context : Callback {
    $_[0]->cache->set_user_cx(get_user_id(), $_[0]->value);
}

1;
