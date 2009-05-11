package Bric::App::Callback::Profile::UserPref;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'user_pref';

use strict;
use Bric::App::Authz qw(chk_authz EDIT);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref :history);
use Bric::App::Session qw(:user);

my $disp_name = 'User Preference';


sub save : Callback {
    my $self = shift;

    my $param = $self->params;

    my $user = Bric::Biz::Person::User->lookup({ id => $param->{user_id} });
    unless (chk_authz($user, EDIT, 1) || $param->{user_id} == get_user_id) {
        $self->raise_forbidden('Changes not saved: permission denied.');
        return;
    }

    my $user_pref = Bric::Util::UserPref->lookup({ pref_id => $param->{pref_id},
                                                   user_id => $param->{user_id} });

    $user_pref ||= Bric::Util::UserPref->new({ pref_id => $param->{pref_id},
                                               user_id => $param->{user_id} });

    $user_pref->set_value($param->{value});
    $user_pref->save;

    my $name = $user_pref->get_name;

    log_event('user_pref_save', $user_pref);
    $self->add_message(qq{$disp_name "[_1]" updated.}, $name);

    $self->cache->set_lmu_time;

    pop_page();
    $self->set_redirect("/admin/profile/user/$param->{user_id}");
}

sub delete : Callback {
    my $self = shift;

    my $param = $self->params;

    my $user = Bric::Biz::Person::User->lookup({ id => $param->{user_id} });
    unless (chk_authz($user, EDIT, 1) || $param->{user_id} == get_user_id) {
        $self->raise_forbidden('Changes not saved: permission denied.');
        return;
    }

    foreach my $id (@{ mk_aref($param->{'user_pref|delete_cb'}) }) {
        my $user_pref = Bric::Util::UserPref->lookup({ id => $id });

        next unless $user_pref;

        log_event('user_pref_reset', $user_pref);

        my $name = $user_pref->get_name;

        $user_pref->delete;

        $self->add_message(qq{$disp_name "[_1]" reset.}, $name);
    }

    $self->cache->set_lmu_time;

    pop_page();
    $self->set_redirect("/admin/profile/user/$param->{user_id}");
}


sub return : Callback {
    # Go back in time.
    pop_page, pop_page;
}

1;
