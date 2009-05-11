package Bric::App::Callback::Profile::Grp;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'grp';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:user);
use Bric::App::Util qw(:aref);
use Bric::Config qw(ADMIN_GRP_ID);

my $type = CLASS_KEY;
my $disp_name = 'Group';
my $class = 'Bric::Util::Grp';

my ($reset_cache, $save_sub);


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $grp = $self->obj;

    $param->{'grp_type'} ||= $class;
    my $name = $param->{name};

    # Make the changes and save them.
    $param->{'obj'} = &$save_sub($self, $type, $param, $self->trigger_key,
                                 $grp, $class, $name, '/admin/manager/grp');
}

sub permissions : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $grp = $self->obj;

    $param->{'grp_type'} ||= $class;
    my $name = $param->{name};

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
        if (chk_authz($grp, EDIT, 1)) {
            if ($grp->get_permanent) {
                # Disallow deletion of permanent groups.
                $self->raise_conflict("$disp_name cannot be deleted.");
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
            $self->raise_forbidden(
                'Permission to delete "[_1]" denied.',
                $grp->get_name,
            );
        }
    }
}


###

$reset_cache = sub {
    my ($grp, $class, $self) = @_;
    my $cache = $self->cache;
    if ($class eq 'Bric::Util::Grp::User') {
        # Note that a user group has been updated to force all users logged
        # into the system to reload their user objects from the database.
        $cache->set_lmu_time;
        # Also, clear out the site and workflow caches, since they
        # may have been affected by permission changes. The workflows
        # are cached on a site_id basis, and since site IDs are also
        # always grp IDs, we can just expire the workflow cache for
        # all GRP ids for which each user has membership.
        $cache->set('__SITES__', 0);
        foreach my $u ($grp->get_objects) {
            foreach my $gid ($u->get_grp_ids) {
                $cache->set("__WORKFLOWS__$gid", 0)
                  if $cache->get("__WORKFLOWS__$gid");
            }
        }
    } elsif ($class eq 'Bric::Util::Grp::Workflow') {
        # There may have been permission and member changes. Reset
        # the cache.
        foreach my $wf ($grp->get_objects) {
            $cache->set('__WORKFLOWS__' . $wf->get_site_id, 0);
        }
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
            $self->raise_conflict("$disp_name cannot be deleted.");
        } else {
            # Deactivate it.
            $grp->deactivate;
            $grp->save;
            log_event('grp_deact', $grp);
            # Reset the cache.
            $reset_cache->($grp, $class, $self);
            $self->add_message(qq{$disp_name profile "[_1]" deleted.}, $name);
        }
        # Set redirection back to the manager.
        $self->set_redirect($redir);
        return;
    }

    if ($grp->get_permanent) {
        # Redirect back to the manager.
        $self->set_redirect($redir);
        # Reset the cache.
        $reset_cache->($grp, $class, $self);
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
        if (exists $param->{members} or exists $param->{objects}) {

            # Make sure it isn't an All group.
            if ($param->{grp_id} == $pkg->INSTANCE_GROUP_ID) {
                $self->raise_forbidden(
                    'Permission to manage "[_1]" group membership denied',
                    $grp->get_name,
                );
                return;
            }

            # Make sure they can manage group membership.
            if ($pkg eq 'Bric::Biz::Person::User') {
                unless (user_is_admin || $grp->has_member(get_user_object)) {
                    # No member management only if the current user is a global
                    # admin or a member of the group.
                    $self->raise_forbidden(
                        'Permission to manage "[_1]" group membership denied',
                        $grp->get_name,
                    );
                    return;
                }
            } else {
                unless (chk_authz(0, EDIT, 1, $param->{grp_id})) {
                    # No member management if the current user does not already
                    # have permisssion to edit the members of the group.
                    $self->raise_forbidden(
                        'Permission to manage "[_1]" group membership denied',
                        $grp->get_name,
                    );
                    return;
                }
            }

            # Add any new members.
            if (exists $param->{members}) {
                my $ids = ref $param->{members} ? $param->{members}
                  : [ $param->{members} ];
                # Assemble the new member information.
                my @add = map { { package => $pkg, id => $_ } } @$ids;
                # Add the members.
                $grp->add_members(\@add);
            }

            # Remove any existing members.
            if (exists $param->{objects}) {
                # Deactivate members.
                foreach my $id (ref $param->{objects}
                                ? @{$param->{objects}}
                                : $param->{objects}) {
                    foreach my $mem ($grp->has_member({ package => $pkg,
                                                        id      => $id }) ) {
                        $mem->deactivate;
                        $mem->save;
                    }
                }
            }
        }

        # Save the group
        $grp->save;
        unless ($no_log) {
            log_event('grp_save', $grp);
            $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
        }

        # Redirect back to the manager.
        $self->set_redirect($redir);
        # Reset the cache.
        $reset_cache->($grp, $class, $self);
        return;
    } else {
        # XXX Hack! Make sure that contributor groups are not secret.
        $grp->_set(['secret'] => [0]) if $grp->isa('Bric::Util::Grp::Person');
        # Save the group.
        $grp->save;
        log_event('grp_new', $grp);
        # Return the group.
        return $grp;
    }
};


1;
