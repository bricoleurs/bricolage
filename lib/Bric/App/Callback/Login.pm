package Bric::App::Callback::Login;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'login';

use strict;
use Bric::App::Auth ();
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(del_redirect redirect_onload);
use Bric::Util::Priv::Parts::Const qw(:all);

use Bric::Config qw(LISTEN_PORT);

my $port = LISTEN_PORT == 80 ? '' : ':' . LISTEN_PORT;

sub login : Callback {
    my $self = shift;
    my $r = $self->apache_req;
    my $param = $self->params;

    my $un = $param->{$self->class_key . '|username'};
    my $pw = $param->{$self->class_key . '|password'};
    my ($res, $msg) = Bric::App::Auth::login($r, $un, $pw);
    my $redir = del_redirect() || '';
    $redir = '/' if $redir =~ m|^/login|;
    if ($res) {
        if ($param->{$self->class_key . '|ssl'}) {
            # They want to use SSL. Do a simple redirect.
            set_state_name($self->class_key, 'ssl');
            $self->redirect($redir);
        } else {
            # Redirect them back to port 80 if not using SSL.
            set_state_name($self->class_key, 'nossl');
            # redirect_onload() prevents any other callbacks from executing.
            redirect_onload('http://' . $r->hostname . $port . $redir, $self);
        }
    } else {
        $self->raise_forbidden($msg);
        $r->log_reason($msg);
    }
}

sub masquerade : Callback {
    my $self = shift;
    my $r = $self->apache_req;

    my $u = Bric::Biz::Person::User->lookup({ login => $self->value });

    if (get_user_object->can_do($u, EDIT)) {
        log_event('user_overridden', $u);
        my ($res, $msg) = Bric::App::Auth::masquerade($r, $u);
        $self->set_redirect('/');
    } else {
        $self->raise_forbidden(
            'You do not have permission to override user "[_1]"',
            $u->get_name,
        );
    }
}


1;
