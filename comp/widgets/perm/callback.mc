<%once>;
my $type = 'perm';
my $disp_name = get_class_info($type)->get_plural_name;
my $class = get_package_name($type);
my $grp_type = 'grp';
my $grp_class = get_package_name($grp_type);
my $not = { qw(usr obj obj usr)};
</%once>

<%args>
$widget
$field
$param
</%args>

<%init>;
return unless $field eq "$widget|save_cb";

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
my $perms = { (map { $_->get_id => $_ } $class->list({ obj_grp_id => $gid })),
	      (map { $_->get_id => $_ } $class->list({ usr_grp_id => $gid }))
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
    $c->set_lmu_time;
    # Log an event.
    log_event('grp_perm_save', $grp);
}

# Set a message and redirect!
add_msg("$disp_name saved.");
set_redirect("/admin/profile/grp/$gid");
</%init>

<%doc>
###############################################################################

=head1 NAME

/widgets/perm/callback.mc - Permissions Callback.

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2001-10-09 20:54:38 $

=head1 SYNOPSIS

  $m->comp('/widgets/perm/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the Permissions screen of the Group
Manager.

</%doc>
