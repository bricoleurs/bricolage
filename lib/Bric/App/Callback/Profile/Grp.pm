package Bric::App::Callback::Profile::Grp;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'grp';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Config qw(ADMIN_GRP_ID);

my $type = CLASS_KEY;
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);

my ($reset_cache, $save_sub);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $grp = $self->obj;

    $param->{'grp_type'} ||= $class;
    my $name = "&quot;$param->{name}&quot;";

    # Make the changes and save them.
    $param->{'obj'} = &$save_sub($self, $type, $param, $self->trigger_key,
                                 $grp, $class, $name, '/admin/manager/grp');
}

sub permissions : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $grp = $self->obj;

    $param->{'grp_type'} ||= $class;
    my $name = "&quot;$param->{name}&quot;";

    # Make the changes and save them.
    $param->{'obj'} = &$save_sub($self, $type, $param, $self->trigger_key,
                                 $grp, $class, $name,
                                 "/admin/profile/grp/perm/$param->{grp_id}", 1);
}


# strictly speaking, this is a Manager (not a Profile) callback

sub deactivate : Callback {
    my $self = shift;

    foreach my $id (@{ mk_aref($self->value) }) {
        my $grp = $class->lookup({ id => $id }) || next;
        if (chk_authz($grp, EDIT)) {
            if ($grp->get_permanent) {
                # Disallow deletion of permanent groups.
                my $msg = '[_1] cannot be deleted';
                add_msg($self->lang->maketext($msg, $disp_name));
            } else {
                # Deactivate it.
                $grp->deactivate;
                $grp->save;
                log_event('grp_deact', $grp);
                # Note that a user has been updated to force all
                # users logged into the system to reload their
                # user objects from the database.
                $self->cache->set_lmu_time if $grp->isa('Bric::Util::Grp::User');
            }
            $grp->save;
            log_event('grp_deact', $grp);
        } else {
            my $msg = 'Permission to delete [_1] denied.';
            my $arg = '&quot;' . $grp->get_name . '&quot;';
            add_msg($self->lang->maketext($msg, $arg));
        }
    }
}


###

$reset_cache = sub {
    my ($class, $self) = @_;
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

$save_sub = sub {
    my ($self, $widget, $param, $field, $grp, $class, $name, $redir, $no_log) = @_;
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
            $reset_cache->($class, $self);
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
        $reset_cache->($class, $self);
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
