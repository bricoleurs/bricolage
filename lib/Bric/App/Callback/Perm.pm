package Bric::App::Callback::Perm;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'perm';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);

my $type = 'perm';
my $disp_name = get_class_info($type)->get_plural_name;
my $class = get_package_name($type);
my $grp_class = get_package_name('grp');
my $not = {
    'usr' => 'obj',
    'obj' => 'usr',
};

my ($do_save);


sub save {
    my $gid = &$do_save;
    set_redirect("/admin/profile/grp/$gid");
}

sub save_and_stay : Callback {
    &$do_save;
}

sub cancel : Callback {
    my $self = shift;
    my $gid = $self->request_args->{'grp_id'};
    set_redirect("/admin/profile/grp/$gid");
}

###

$do_save = sub {
    my $self = shift;
    my $param = $self->request_args;

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
                        # The value is different. Update it.
                        $perm->set_value($perm_val);
                        $perm->save;
                        $chk = 1;
                    }
                } else {
                    # There is no existing permission object. Create one.
                    my $perm = $class->new({ "$not->{$type}_grp" => $gid,
                                             "${type}_grp" => $ugid,
                                             value   => $perm_val
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
    add_msg("$disp_name saved.");

    return $gid;
};


1;
