package Bric::App::Callback::Nav;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'nav');
use strict;
use Bric::App::Session qw(:state);


sub workflow : Callback {
    my $param = $_[0]->request_args;

    # navwfid is set in comp/widgets/wrappers/sharky/sideNav.mc
    set_state_data($_[0]->class_key,
                   $_[0]->cb_key . '-' . $param->{'navwfid'},
                   $_[0]->value);
}

sub admin : Callback {
    &$do_callback;
}

sub adminSystem : Callback {
    &$do_callback;
}

sub adminPublishing : Callback {
    &$do_callback;
}

sub distSystem : Callback {
    &$do_callback;
}


###

my $do_callback = sub {
    set_state_data($_[0]->class_key, $_[0]->cb_key, $_[0]->value);
};


1;
