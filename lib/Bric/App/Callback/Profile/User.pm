package Bric::App::Callback::Profile::User;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'user';

use strict;
use Bric::App::Callback::Util::Contact qw(update_contacts);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);
use Bric::Biz::Person::User;
use Bric::Config qw(:auth_len LISTEN_PORT);
use Bric::Util::Grp;

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
my $port = LISTEN_PORT == 80 ? '' : ':' . LISTEN_PORT;


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $user = $self->obj;
    my $r = $self->apache_req;

    if ($param->{delete}) {
        # Deactivate it.
        $user->deactivate;
        $user->save;
        # Note that a user has been updated to force all users logged into
        # the system to reload their user objects from the database.
        $self->cache->set_lmu_time;
        log_event('user_deact', $user);
        my $name = "&quot;" . $user->get_name . "&quot;";
        my $msg = "$disp_name profile [_1] deleted.";
        add_msg($self->lang->maketext($msg, $name));
        get_state_name('login') eq 'ssl' ? set_redirect('/admin/manager/user')
          : redirect_onload('http://' . $r->hostname . $port . '/admin/manager/user',
                            $self);
        return;
    }

    # Make sure it's active.
    $user->activate;

    # Roll in the changes.
    my $no_save;
    foreach my $meth ($user->my_meths(1)) {
        next if $meth->{name} eq 'active' || $meth->{name} eq 'login'
          || $meth->{name} eq 'password';
        $meth->{set_meth}->($user, @{$meth->{set_args}}, $param->{$meth->{name}})
          if defined $meth->{set_meth};
    }

    my $login = $param->{login};
    my $cur_login = $user->get_login || '';
    if (!$login) {
        # There is no login!
        add_msg('Login cannot be blank. Please enter a login.');
        $no_save = 1;
    } elsif ($login ne $cur_login) {
        if (length $login < LOGIN_LENGTH ) {
            # The login isn't long enough.
            my $msg = 'Login must be at least [_1] characters.';
            add_msg($self->lang->maketext($msg, LOGIN_LENGTH));
            $no_save = 1;
        }
        if ($login !~ /^[-\.\@\w]+$/) {
            # The login contains invalid characters
            my $msg = 'Login [_1] contains invalid characters.';
            add_msg($self->lang->maketex($msg, "'$login'"));
            $no_save = 1;
        }

        unless ($class->login_avail($login)) {
            # The new login is already used by someone.
            my $msg = 'Login [_1] is already in use. Please try again.';
            add_msg($self->lang->maketext($msg, "&quot;$login&quot;"));
            $no_save = 1;
        }
        # Okay, go ahead and set it, even though the user might have to change it.
        $user->set_login($login);
    }

    # Take care of contact info.
    update_contacts($param, $user);

    # Change the password, if necessary.
    if (!$no_save && (my $pass = $param->{pass_1})) {
        # There is a new password. Let's see if we can do anything with it.
        if ( defined $param->{user_id} && $param->{user_id} != get_user_id() ||
               $user->chk_password($param->{old_pass}) ) {
            # The old password checks out. Check the new passwords.
            if ($pass ne $param->{pass_2}) {
                # The new passwords don't match.
                add_msg('New passwords do not match. Please try again.');
                $no_save = 1;
            }
            if ($pass =~ /^\s+/ || $pass =~ /\s+$/) {
                # Password contains illegal preceding or trailing spaces.
                add_msg('Password contains illegal preceding or trailing spaces.'
                          . ' Please try again.');
                $no_save = 1;
            }
            if (length $pass < PASSWD_LENGTH) {
                # The password isn't long enough.
                my $msg = 'Passwords must be at least [_1] characters!';
                my $arg = "'" . PASSWD_LENGTH . "'";
                add_msg($self->lang->maketext($msg, $arg));
                $no_save = 1;
            }
            # Change the password if we're saving.
            unless ($no_save) {
                $user->set_password($pass);
                log_event('passwd_chg', $user);
            }

        } else {
            # The old password was wrong.
            add_msg('Invalid password. Please try again.');
            $no_save = 1;
        }
    }

    # They weren't trying to change the password, so just save the
    # changes unless there's some other reason not to.
    if ($no_save) {
        $param->{'obj'} = $user;
        return;
    }
    $user->save;
    log_event(defined $param->{user_id} ? 'user_save' : 'user_new', $user);
    my $name = "&quot;" . $user->get_name . "&quot;";
    my $msg = "$disp_name profile [_1] saved.";
    add_msg($self->lang->maketext($msg, $name));

    # Take care of group managment.
    my $id = $param->{user_id} || $user->get_id;
    my $add_ids = mk_aref($param->{add_grp});
    # Assemble the new member information.
    foreach my $grp ( map { Bric::Util::Grp->lookup({ id => $_ }) }
                        @$add_ids ) {
        # Add the user to the group.
        $grp->add_members([{ obj => $user }]);
        $grp->save;
        log_event('grp_save', $grp);
    }
    my $del_ids = mk_aref($param->{rem_grp});
    foreach my $grp ( map { Bric::Util::Grp->lookup({ id => $_ }) }
                        @$del_ids ) {
        # Deactivate the user's group membership.
        foreach my $mem ($grp->has_member({ obj => $user })) {
            $mem->deactivate;
            $mem->save;
        }
        $grp->save;
        log_event('grp_save', $grp);
    }

    # Note that a user has been updated to force all users logged into the system
    # to reload their user objects from the database. Also note that all workflows
    # and sites must be reloaded in the sideNav and header, as permissions may
    # have changed.
    $self->cache->set_lmu_time;
    $self->cache->set('__WORKFLOWS__', 0);
    $self->cache->set('__SITES__', 0);

    # Redirect. Use redirect_onload because the User profile has been using SSL.
    get_state_name('login') eq 'ssl' ? set_redirect('/admin/manager/user')
      : redirect_onload('http://' . $r->hostname . $port . '/admin/manager/user',
                        $self);
}


1;
