package Bric::App::Callback::Perm;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'perm';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
use Bric::Util::Priv::Parts::Const qw(:all);

my $type = 'perm';
my $disp_name = 'Permissions';
my $class = 'Bric::Util::Priv';
my $grp_class = 'Bric::Util::Grp';
my $not = {
    'usr' => 'obj',
    'obj' => 'usr',
};

my ($do_save);


sub save : Callback {
    my $self = shift;
    my $gid = $do_save->($self);
    $self->set_redirect("/admin/profile/grp/$gid")
      if defined $gid;
}

sub save_and_stay : Callback {
    &$do_save;
}

sub cancel : Callback {
    my $self = shift;
    my $gid = $self->params->{'grp_id'};
    $self->set_redirect("/admin/profile/grp/$gid");
}

###

$do_save = sub {
    my $self = shift;
    my $param = $self->params;

    # Assemble the relevant IDs.
    my $grp_ids = { usr => mk_aref($param->{usr_grp_id}),
                    obj => mk_aref($param->{obj_grp_id})
                };
    my $perm_ids = { usr => mk_aref($param->{usr_perm_id}),
                     obj => mk_aref($param->{obj_perm_id})
                 };
    # Instantiate the group object and check permissions.
    my $gid = $param->{grp_id};
    my $grp = $grp_class->lookup({ id => $gid });
    chk_authz($grp, EDIT);

    # Get the existing permissions for this group.
    my $perms = {
        (map { $_->get_id => $_ } $class->list({ obj_grp_id => $gid })),
        (map { $_->get_id => $_ } $class->list({ usr_grp_id => $gid })),
    };

    # Loop through each user group ID.
    my $chk;
    foreach my $type (qw(usr obj)) {
        my $i = 0;
        foreach my $ugid (@{$grp_ids->{$type}}) {
            if (my $perm_val = $param->{"$type|$ugid"}) {
                # There's a permssion value.
                if ($perm_ids->{$type}[$i]) {
                    # There's an existing permission object for this value.
                    my $perm = $perms->{$perm_ids->{$type}[$i]};
                    if ($perm->get_value != $perm_val) {
                        # The value is different. Make sure the user has
                        # permssion to change it by having permission to its
                        # objects already.
                        my $tgid = $type eq 'obj' ? $ugid : $gid;
                        unless (chk_authz(0, $perm_val, 1, $tgid)
                                || ($perm_val == DENY && chk_authz(0, READ, 1, $tgid))) {
                            $self->raise_forbidden(
                                'Permission to grant permission "[_1]" to group "[_2]" denied',
                                Bric::Util::Priv->vals_href->{$perm_val},
                                $perm->get_obj_grp->get_name,
                            );
                            return;
                        }

                        # Update it.
                        $perm->set_value($perm_val);
                        $perm->save;
                        $chk = 1;
                    }
                } else {
                    # There is no existing permission object. Make sure the
                    # user has permssion to create a new one by having
                    # permission to its objects already.
                    my $tgid = $type eq 'obj' ? $ugid : $gid;
                    unless (chk_authz(0, $perm_val, 1, $tgid)
                            || ($perm_val == DENY && chk_authz(0, READ, 1, $tgid))) {
                        my $bad_grp = Bric::Util::Grp->lookup({ id => $tgid });
                        $self->raise_forbidden(
                            'Permission to grant permission "[_1]" to group "[_2]" denied',
                            Bric::Util::Priv->vals_href->{$perm_val},
                            $bad_grp->get_name,
                        );
                        return;
                    }

                    my $perm = $class->new({ "$not->{$type}_grp" => $gid,
                                             "${type}_grp"       => $ugid,
                                             value               => $perm_val
                                         });
                    $perm->save;
                    $chk = 1;
                }
            } elsif ($perm_ids->{$type}[$i]) {
                # There's an existing permisison. Delete it.
                my $perm = $perms->{$perm_ids->{$type}[$i]};
                $perm->del;
                $perm->save;
                $chk = 1;
            }
            $i++;
        }
    }

    if ($chk) {
        # Make sure all users update.
        $self->cache->set_lmu_time;
        # Log an event.
        log_event('grp_perm_save', $grp);
    }

    # Set a message and redirect!
    $self->add_message("$disp_name saved.");

    return $gid;
};


1;
