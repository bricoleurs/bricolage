package Bric::App::Callback::Alert;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'alert');
use strict;
use Bric::App::Session;
use Bric::App::Util;
use Bric::Util::Alerted;

my $class = get_package_name('recip');
my $disp_name = get_disp_name(CLASS_KEY);
my $pl_name = get_class_info(CLASS_KEY)->get_plural_name();
my %num = (
    1 => 'One',
    2 => 'Two',
    3 => 'Three',
    4 => 'Four',
    5 => 'Five',
    6 => 'Six',
    7 => 'Seven',
    8 => 'Eight',
    9 => 'Nine',
    10 => 'Ten',
);

sub ack : Callback {
    my $self = shift;
    my $param = $self->request_args->{'param'};
    my $ids = mk_aref($param->{'recip_id'});
    $msg_redirect->($ids);
}

sub ack_all : Callback {
    my $self = shift;
    my $ids = $class->list_ids({ user_id => get_user_id(), ack_time => undef });
    $msg_redirect->($ids);
}


my $msg_redirect = sub msg_redirect {
    my $ids = shift;
    $class->ack_by_id(@$ids);
    my $c = @$ids;
    my $disp = $c == 1 ? $disp_name : $pl_name;
    $c = $num{$c} || $c;
    add_msg("$c $disp acknowledged.") if $c;
    set_redirect(last_page());
}


1;
