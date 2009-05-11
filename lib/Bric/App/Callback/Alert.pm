package Bric::App::Callback::Alert;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'alert';

use strict;
use Bric::App::Session qw(:user);
use Bric::App::Util qw(:aref :history);
use Bric::Util::Alerted;

my $class = 'Bric::Util::Alerted';
my $disp_name = 'Alert';
my $msg_redirect;

sub ack : Callback {
    my $self = shift;
    my $ids = mk_aref($self->params->{'recip_id'});
    $msg_redirect->($self, $ids);
}

sub ack_all : Callback {
    my $self = shift;
    my $ids = $class->list_ids({ user_id => get_user_id(), ack_time => undef });
    $msg_redirect->($self, $ids);
}

sub return : Callback {
    shift->set_redirect(last_page());
}

$msg_redirect = sub {
    my ($self, $ids) = @_;
    $class->ack_by_id(@$ids);
    my $c = @$ids;
    $self->add_message('[quant,_1,$disp_name] acknowledged.', $c) if $c;
    $self->set_redirect(last_page());
};


1;
