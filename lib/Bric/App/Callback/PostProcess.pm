package Bric::App::Callback::PostProcess;

# Handles processing necessary after callbacks have completed execution,
# but before Mason does its thing. Mainly handling redirects and logging
# the URI history.

use strict;
use base qw(Bric::App::Callback);
use Bric::App::Util qw(:history del_redirect);
use constant CLASS_KEY => 'post_process';
__PACKAGE__->register_subclass;

sub do_redirect : PostCallback {
    my $self = shift;
    if ($self->apache_req->uri !~ /sideNav.mc$/) {
        # Do a redirect if there is one.
        if (my $url = del_redirect()) {
            $self->redirect($url);
        }
        # Otherwise, log the history.
        log_history();
    }
}
