package Bric::App::Callback::Login;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'login';

use strict;
use Bric::App::Auth ();
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:msg del_redirect redirect_onload);

use Bric::Config qw(LISTEN_PORT);

my $port = LISTEN_PORT == 80 ? '' : ':' . LISTEN_PORT;

sub login : Callback {
    my $self = shift;
    my $r = $self->apache_req;
    my $param = $self->params;

    my $un = $param->{$self->class_key . '|username'};
    my $pw = $param->{$self->class_key . '|password'};
    my ($res, $msg) = Bric::App::Auth::login($r, $un, $pw);
    if ($res) {
	if ($param->{$self->class_key . '|ssl'}) {
	    # They want to use SSL. Do a simple redirect.
	    set_state_name($self->class_key, 'ssl');
            $self->redirect(del_redirect() || '');
	} else {
	    # Redirect them back to port 80 if not using SSL.
	    set_state_name($self->class_key, 'nossl');
            # redirect_onload() prevents any other callbacks from executing.
	    redirect_onload('http://' . $r->hostname . $port
                              . (del_redirect() || ''), $self);
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
	$self->set_redirect('/');
    } else {
	add_msg($msg);
	$r->log_reason($msg);
    }
}


1;
