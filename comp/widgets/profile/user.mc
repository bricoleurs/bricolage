<%doc>
###############################################################################

=head1 NAME

/widgets/profile/user.mc - Processes submits from User Profile

=head1 VERSION

$Revision: 1.12.2.1 $

=head1 DATE

$Date: 2003-03-05 22:10:54 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/user.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the User Profile page.

=cut

</%doc>
<%once>;
my $type = 'user';
my $disp_name = get_disp_name($type);
my $port = LISTEN_PORT == 80 ? '' : ':' . LISTEN_PORT;
</%once>
<%args>
$widget
$param
$field
$obj
$class
</%args>
<%init>;
return unless $field eq "$widget|save_cb";
# Grab the user object.
my $user = $obj;
if ($param->{delete}) {
    # Deactivate it.
    $user->deactivate;
    $user->save;
    # Note that a user has been updated to force all users logged into the system
    # to reload their user objects from the database.
    $c->set_lmu_time;
    log_event('user_deact', $user);
    my $name = "&quot;" . $user->get_name . "&quot;";
    add_msg($lang->maketext("$disp_name profile [_1] deleted.",$name));
    get_state_name('login') eq 'ssl' ? set_redirect('/admin/manager/user')
      : redirect_onload('http://' . $r->hostname . $port . '/admin/manager/user');
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
        add_msg($lang->maketext('Login must be at least [_1] characters.',LOGIN_LENGTH));
	$no_save = 1;
    }
    if ($login !~ /^[-\.\@\w]+$/) {
	# The login contains invalid characters
        add_msg($lang->maketex("Login [_1] contains invalid characters.","'$login'"));
	$no_save = 1;
    }
    unless ($class->login_avail($login)) {
	# The new login is already used by someone.
        add_msg($lang->maketext("Login [_1] is already in use. Please try again.","&quot;$login&quot;"));
	$no_save = 1;
    }
    # Okay, go ahead and set it, even though the user might have to change it.
    $user->set_login($login);

}

# Take care of contact info.
$m->comp('/widgets/profile/updateContacts.mc',param => $param, obj => $user);

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
            add_msg($lang->maketext('Passwords must be at least [_1] characters!',"'".PASSWD_LENGTH."'"));
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
return $user if $no_save;
$user->save;
log_event(defined $param->{user_id} ? 'user_save' : 'user_new', $user);
my $name = "&quot;" . $user->get_name . "&quot;";
add_msg($lang->maketext("$disp_name profile [_1] saved.",$name));

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
$c->set_lmu_time;
$c->set('__WORKFLOWS__', 0);
$c->set('__SITES__', 0);

# Redirect. Use redirect_onload because the User profile has been using SSL.
get_state_name('login') eq 'ssl' ? set_redirect('/admin/manager/user')
  : redirect_onload('http://' . $r->hostname . $port . '/admin/manager/user');
return;
</%init>
