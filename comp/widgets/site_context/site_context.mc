<%once>;
my $widget = 'site_context';
my $usites_key = 'sites';
my $cachekey = '__SITES__';
</%once>
<%args>
$display => 1
</%args>
<%init>;
my $uid = get_user_id;
 # This code can execute before the redirect to login screen!
return unless defined $uid;
my $sites = $c->get($cachekey);
my $user_sites = get_state_data($widget, $usites_key);
my $cx = $c->get_user_cx($uid);
$cx = -1 unless defined $cx;

unless ($sites) {
    # The list of sites has been reset. Grab them all again.
    $sites = Bric::Biz::Site->list({ active => 1 });
    $c->set($cachekey, $sites);
    # Reset the list of user sites.
    $user_sites = undef;
}

unless ($user_sites) {
    # The list of user sites has been reset. Figure them out again.
    $user_sites = [];
    if ($sites) {
        # We have some sites to choose from, so set 'em up.
        # It's okay if all sites is the context.
        my $cx_ok = $cx == 0;
        foreach my $s (@$sites) {
            next unless chk_authz($s, READ, 1);
            # Keep the site if the user has permission.
            my $id = $s->get_id;
            push @$user_sites, [$id, $s->get_name];
            # Check if they can use the same old context.
            $cx_ok ||= $id == $cx;
        }

        # Do we need to give them a new context?
        unless ($cx_ok) {
            $cx = $user_sites->[0] ? $user_sites->[0][0] : undef;
            $c->set_user_cx($uid, $cx);
        }

        # Create an option for all available sites.
        push @$user_sites, [0, $lang->maketext('All Sites') ]
          if ALLOW_ALL_SITES_CX;

        # Save their list of site and their context.
        set_state_data($widget, $usites_key => $user_sites);
    } else {
        # There are no sites! Not bloody likely.
        $user_sites = [];
        set_state_data($widget, $usites_key => $user_sites);
        $c->set_user_cx($uid, undef);
    }
} else {
    # Make sure we have a context.
    if ($cx == -1) {
        $cx = $user_sites->[0] ? $user_sites->[0][0] : undef;
        $c->set_user_cx($uid, $cx);
    }
}

# Just return the context if we don't want to display the context.
return $cx unless $display;

# Do nothing if there are fewer than two sites for this user.
return unless @$user_sites > (ALLOW_ALL_SITES_CX ? 2 : 1);

# Give 'em a select list.
#$m->print($lang->maketext("Site Context"), ': ');
$m->comp('/widgets/profile/select.mc',
         options  => $user_sites,
         name     => 'site_context|change_context_cb',
         js       => qq{onChange="location.href='} . $r->uri .
                     qq{?' + this.name + '=' +} .
                     qq{this.options[this.selectedIndex].value"},
         useTable => 0,
         localize => 0,
         value    => $cx
        );
</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/site_context/site_context.mc - Display and set Site Context

=head1 SYNOPSIS

  $m->comp('/widgets/site_context/site_context.mc);

=head1 DESCRIPTION

This element is called by /widgets/wrappers/header.mc to display a
select list of sites on every page. Its callback handles a change of site
context.

=cut

</%doc>
