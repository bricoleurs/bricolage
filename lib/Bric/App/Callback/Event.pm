package Bric::App::Callback::Event;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'event';

use strict;
use Bric::App::Session qw(:user);
use Bric::App::Util qw(:aref :msg :history);

sub return : Callback {
    shift->set_redirect(last_page());
}

1;
