package Bric::App::Callback::Profile::User;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'user';

use strict;
use Bric::App::Callback::Util::Contact qw(update_contacts);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state :user);
use Bric::App::Util qw(:aref :history redirect_onload);
use Bric::Biz::Person::User;
use Bric::Config qw(:auth_len LISTEN_PORT);
use Bric::Util::Grp;

my $type = CLASS_KEY;
my $disp_name = 'User';
my $class = 'Bric::Biz::Person::User';


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
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
        $self->add_message(qq{$disp_name profile "[_1]" deleted.}, $user->get_name);
        # redirect_onload() prevents any other callbacks from executing.
        get_state_name('login') eq 'ssl' ? $self->set_redirect(last_page)
          : redirect_onload(last_page,
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
        $self->raise_conflict('Login cannot be blank. Please enter a login.');
        $no_save = 1;
    } elsif ($login ne $cur_login) {
        if (length $login < LOGIN_LENGTH ) {
            # The login isn't long enough.
            $self->raise_conflict(
                'Login must be at least [_1] characters.',
                LOGIN_LENGTH,
            );
            $no_save = 1;
        }
        if ($login !~ /^[-\.\@\w]+$/) {
            # The login contains invalid characters
            $self->raise_conflict(
                'Login "[_1]" contains invalid characters.',
                $login,
            );
            $no_save = 1;
        }

        unless ($class->login_avail($login)) {
            # The new login is already used by someone.
            $self->raise_conflict(
                'Login "[_1]" is already in use. Please try again.',
                $login,
            );
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
        my $uid = $user->get_id;
        if (!defined $uid || $uid != get_user_id()
            || $user->chk_password($param->{old_pass})
        ) {
            # The old password checks out. Check the new passwords.
            if ($pass ne $param->{pass_2}) {
                # The new passwords don't match.
                $self->raise_conflict(
                    'New passwords do not match. Please try again.'
                );
                $no_save = 1;
            }
            if ($pass =~ /^\s+/ || $pass =~ /\s+$/) {
                # Password contains illegal preceding or trailing spaces.
                $self->raise_conflict(
                    'Password contains illegal preceding or trailing spaces. Please try again.'
                );
                $no_save = 1;
            }
            if (length $pass < PASSWD_LENGTH) {
                # The password isn't long enough.
                $self->raise_conflict(
                    'Passwords must be at least [_1] characters!',
                    PASSWD_LENGTH,
                );
                $no_save = 1;
            }
            # Change the password if we're saving.
            unless ($no_save) {
                $user->set_password($pass);
                log_event('passwd_chg', $user);
            }

        } else {
            # The old password was wrong.
            $self->raise_conflict('Invalid password. Please try again.');
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
    $self->add_message(qq{$disp_name profile "[_1]" saved.}, $user->get_name);

    # Take care of group management, since the use of the redirect_onload()
    # function below will prevent it from executing as a callback.
    $self->manage_grps;

    # Note that a user has been updated to force all users logged into the system
    # to reload their user objects from the database. Also note that all workflows
    # and sites must be reloaded in the sideNav and header, as permissions may
    # have changed.
    my $c = $self->cache;
    $c->set_lmu_time;
    $c->set('__SITES__', 0);
    foreach my $gid ($user->get_grp_ids) {
        $c->set("__WORKFLOWS__$gid", 0) if $c->get("__WORKFLOWS__$gid");
    }

    # Redirect. Use redirect_onload because the User profile has been using SSL.
    # But note that because it executes right away, no more callbacks will execute!
    get_state_name('login') eq 'ssl' ? $self->set_redirect(last_page)
      : redirect_onload(last_page,
                        $self);
}


1;
