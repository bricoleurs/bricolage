package Bric::App::Callback::PostProcess;

# Handles processing necessary after callbacks have completed execution,
# but before Mason does its thing. Mainly handling redirects and logging
# the URI history.

use strict;
use base qw(Bric::App::Callback);
use Bric::App::Util qw(:history);
use constant CLASS_KEY => 'post_process';
__PACKAGE__->register_subclass;

sub do_redirect : PostCallback {
    my $self = shift;
    log_history() unless $self->apache_req->uri =~ /sideNav.mc$/;
}
