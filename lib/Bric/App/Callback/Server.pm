package Bric::App::Callback::Server;

# move to Publish::Server

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'server');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);


my $type = 'server';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
my $dest_class = get_package_name('dest');


sub delete : Callback {
    my $self = shift;

    my $dest = $dest_class->lookup({ id => $self->request_args->{dest_id} });
    chk_authz($dest, EDIT);
    foreach my $id (@{ mk_aref($self->value) }) {
        my $s = $class->lookup({ id => $id }) || next;
        $s->del;
        $s->save;
        log_event('server_del', $s);
    }
}


1;
