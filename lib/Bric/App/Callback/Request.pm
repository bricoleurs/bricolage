package Bric::App::Callback::Request;

# This class defines request callbacks -- that is, those that execute for
# every request, either before or after the parameter-triggered callbacks
# execute.

use strict;
use base qw(Bric::App::Callback);
use Bric::App::Util qw(:history);
use Bric::Util::ApacheConst qw(HTTP_OK OK);
use HTML::Entities;

use constant CLASS_KEY => 'request';
__PACKAGE__->register_subclass;

sub set_history : PreCallback {
    my $self = shift;
    log_history() unless $self->apache_req->uri =~ /sideNav.mc$/;
}
