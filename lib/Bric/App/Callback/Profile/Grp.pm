package Bric::App::Callback::Profile::Grp;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass('class_key' => 'grp');
use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $grp = $self->obj;

    # XXX: $class was from %args
    $param->{grp_type} ||= $class;
    my $name = "&quot;$param->{name}&quot;";

    # Make the changes and save them.
    return &$save_sub($type, $param, $self->trigger_key, $grp, $class, $name,
                      '/admin/manager/grp');
}

sub permissions : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $grp = $self->obj;

    # XXX: $class was from %args
    $param->{grp_type} ||= $class;
    my $name = "&quot;$param->{name}&quot;";

    # Make the changes and save them.
    return &$save_sub($type, $param, $self->trigger_key, $grp, $class, $name,
                      "/admin/profile/grp/perm/$param->{grp_id}", 1);
}

# XXX: there's also an empty else clause in grp.mc
# so there might be other grp callbacks to handle


###

my $reset_cache = sub {
    my $class = shift;
    if ($class eq 'Bric::Util::Grp::User') {
        # Note that a user has been updated to force all users logged
        # into the system to reload their user objects from the
        # database.
        $self->cache->set_lmu_time;
        # Also, clear out the site and workflow caches, since they
        # may have been affected by permission changes.
        $self->cache->set('__WORKFLOWS__', 0);
        $self->cache->set('__SITES__', 0);
    } elsif ($class eq 'Bric::Util::Grp::Workflow') {
        # There may have been permission and member changes. Reset
        # the cache.
        $self->cache->set('__WORKFLOWS__', 0);
    } elsif ($class eq 'Bric::Util::Grp::Site') {
        # There may have been permission and member changes. Reset
        # the cache.
        $self->cache->set('__SITES__', 0);
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
            add_msg($self->lang->maketext("$disp_name profile [_1] deleted.", $name));
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
            add_msg($self->lang->maketext("$disp_name profile [_1] saved.",$name));
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


1;
