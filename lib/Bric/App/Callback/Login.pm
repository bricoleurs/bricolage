package Bric::App::Callback::Login;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'login');
use strict;
use Bric::App::Auth qw(login);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);

use Bric::Config qw(LISTEN_PORT);

my $port = LISTEN_PORT == 80 ? '' : ':' . LISTEN_PORT;

sub login : Callback {
    my $self = shift;
    my $r = $self->apache_req;
    my $param = $self->param;

    my $un = $param->{CLASS_KEY . '|username'};
    my $pw = $param->{CLASS_KEY . '|password'};
    my ($res, $msg) = login($r, $un, $pw);
    if ($res) {
	if ($param->{CLASS_KEY . '|ssl'}) {
	    # They want to use SSL. Do a simple redirect.
	    set_state_name(CLASS_KEY, 'ssl');
	    do_queued_redirect() || redirect('/');
	} else {
	    # Redirect them back to port 80 if not using SSL.
	    set_state_name(CLASS_KEY, 'nossl');
	    redirect_onload('http://' . $r->hostname . $port
                              . (del_redirect() || ''));
	}
    } else {
	add_msg($msg);
	$r->log_reason($msg);
    }
}

sub masquerade : Callback {
    my $self = shift;
    my $r = $self->apache_req;

    my $un = $self->value;
    my ($res, $msg) = Bric::App::Auth::masquerade($r, $un);

    if ($res) {
	set_redirect('/');
    } else {
	add_msg($msg);
	$r->log_reason($msg);
    }
}


1;
