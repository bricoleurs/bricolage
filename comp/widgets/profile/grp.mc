<%doc>
###############################################################################

=head1 NAME

/widgets/profile/grp.mc - Processes submits from Group Profile

=head1 VERSION

$Revision: 1.8.2.1 $

=head1 DATE

$Date: 2003-03-05 22:10:54 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/grp.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the User Profile page.

=cut

</%doc>

<%once>;
my $type = 'grp';
my $disp_name = get_disp_name($type);

my $reset_cache = sub {
    my $class = shift;
    if ($class eq 'Bric::Util::Grp::User') {
        # Note that a user has been updated to force all users logged
        # into the system to reload their user objects from the
        # database.
        $c->set_lmu_time;
        # Also, clear out the site and workflow caches, since they
        # may have been affected by permission changes.
        $c->set('__WORKFLOWS__', 0);
        $c->set('__SITES__', 0);
    } elsif ($class eq 'Bric::Util::Grp::Workflow') {
        # There may have been permission and member changes. Reset
        # the cache.
        $c->set('__WORKFLOWS__', 0);
    } elsif ($class eq 'Bric::Util::Grp::Site') {
        # There may have been permission and member changes. Reset
        # the cache.
        $c->set('__SITES__', 0);
    } else {
        # Do nothing!
    }
};

my $save_sub = sub {
    my ($widget, $param, $field, $grp, $class, $name, $redir, $no_log) = @_;
    if ($param->{delete} && !$no_log) {
        if ($grp->get_permanent) {
            # Dissallow deletion of permanent groups.
            add_msg("$disp_name cannot be deleted");
        } else {
            # Deactivate it.
            $grp->deactivate;
            $grp->save;
	    log_event('grp_deact', $grp);
            # Reset the cache.
            $reset_cache->($class);
            add_msg($lang->maketext("$disp_name profile [_1] deleted.", $name));
        }
        # Set redirection back to the manager.
        set_redirect($redir);
	return;
    }
    # Roll in the changes.
    $grp->activate;
    $grp->set_name($param->{name}) unless defined $param->{grp_id}
      && $param->{grp_id} == ADMIN_GRP_ID;
    $grp->set_description($param->{description});
    if (defined $param->{grp_id}) {
	# Get the name of the member package.
	my $pkg = $grp->member_class->get_pkg_name;
        if (exists $param->{members}) {
	    my $ids = ref $param->{members} ? $param->{members}
	      : [ $param->{members} ];
	    # Assemble the new member information.
	    my @add = map { { package => $pkg, id => $_ } } @$ids;
	    # Add the members.
	    $grp->add_members(\@add);
	} if (exists $param->{objects}) {
            # Deactivate members.
            foreach my $id (ref $param->{objects} ? @{$param->{objects}}
                            : $param->{objects}) {
                foreach my $mem ($grp->has_member({ package => $pkg,
                                                    id => $id }) ) {
		    $mem->deactivate;
                    $mem->save;
                }
            }
	}
	# Save the group
	$grp->save;
        unless ($no_log) {
	    log_event('grp_save', $grp);
            add_msg($lang->maketext("$disp_name profile [_1] saved.",$name));
        }
	# Redirect back to the manager.
	set_redirect($redir);
        # Reset the cache.
        $reset_cache->($class);
	return;
    } else {
	# Save the group.
	$grp->save;
	log_event('grp_new', $grp);
	# Return the group.
	return $grp;
    }
};

</%once>
<%args>
$widget
$param
$field
$obj
$class
</%args>
<%init>;
# Instantiate the grp object and get its name.
$param->{grp_type} ||= $class;
my $grp = $obj;
my $name = "&quot;$param->{name}&quot;";

if ($field eq "$widget|save_cb") {
    # Make the changes and save them.
    return &$save_sub($widget, $param, $field, $grp, $class, $name,
                      '/admin/manager/grp');
} elsif ($field eq "$widget|permissions_cb") {
    # Make the changes and save them.
    return &$save_sub($widget, $param, $field, $grp, $class, $name,
                      "/admin/profile/grp/perm/$param->{grp_id}", 1);
} else {
    # Nothing.
}
</%init>
