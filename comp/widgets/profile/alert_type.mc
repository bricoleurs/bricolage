<%once>;
my $type = 'alert_type';
my $disp_name = get_disp_name($type);
my $class = get_package_name($type);
my $save = sub {
    my ($param, $at, $name) = @_;
    # Roll in the changes.
    $at->set_name($param->{name});
    $at->set_owner_id($param->{owner_id});
    if (defined $param->{alert_type_id}) {

	# Set the subject and the message.
        $at->set_subject($param->{subject});
	$at->set_message($param->{message});

	# Set the active flag.
	my $act = $at->is_active;
	if (exists $param->{active} && !$act) {
	    # They want to activate it. Do so.
	    $at->activate;
	    log_event("${type}_act", $at);
	} elsif ($act && !exists $param->{active}) {
	    # Deactivate it.
	    $at->deactivate;
	    log_event("${type}_deact", $at);
	}

	# Update the rules.
	my $rids = mk_aref($param->{alert_type_rule_id});
	for (my $i = 0; $i < @{$param->{attr}}; $i++) {
	    if (my $id = $rids->[$i]) {
		my ($r) = $at->get_rules($id);
		$r->set_attr($param->{attr}[$i]);
		$r->set_operator($param->{operator}[$i]);
		$r->set_value($param->{value}[$i]);
	    } else {
		next unless $param->{attr}[$i];
		my $r = $at->new_rule($param->{attr}[$i], $param->{operator}[$i],
				      $param->{value}[$i]);
	    }
	}
	$at->del_rules(@{ mk_aref($param->{del_alert_type_rule})} )
	  if $param->{del_alert_type_rule};
    } else {
	if (defined $param->{event_type_id}) {
	    $at->set_event_type_id($param->{event_type_id});
	    if ($at->name_used) {
		add_msg("The name $name is already used by another $disp_name.");
	    } else {
		$at->save;
		log_event($type . '_new', $at);
	    }
	}
	return $at;
    }

    # Make sure the name isn't already in use.
    if ($at->name_used) {
	add_msg("The name $name is already used by another $disp_name.");
	return $at;
    }

    $at->save;
    log_event($type . (defined $param->{alert_type_id} ? '_save' : '_new'),
	      $at);
    return;
};
</%once>
<%args>
$widget
$param
$field
$obj
</%args>
<%init>;
# Grab the element type object and its name.
my $at = $obj;
if ($field eq "$widget|save_cb") {
    my $name = $param->{name} ? "&quot;$param->{name}&quot;" : '';
    if ($param->{delete}) {
	# Remove it.
	$at->remove;
	$at->save;
	log_event("${type}_del", $at);
	add_msg("$disp_name profile $name deleted.");
	set_redirect('/admin/manager/alert_type');
    } else {
	# Just save it.
	my $ret = &$save($param, $at, $name);
	return $ret if $ret;
	add_msg("$disp_name profile $name saved.");
	set_redirect('/admin/manager/alert_type');
    }
} elsif ($field eq "$widget|recip_cb") {
    # Save it and let them edit recipients.
    my $name = $param->{name} ? "&quot;$param->{name}&quot;" : '';
    my $ret = &$save($param, $at, $name);
    return $ret if $ret;
    set_state_name('alert_type', $param->{$widget."|recip_cb"});
    set_redirect("/admin/profile/$type/recip/$param->{alert_type_id}");
} elsif ($field eq "$widget|edit_recip_cb") {
    $at->add_users( $param->{ctype}, @{ mk_aref($param->{add_users}) } );
    $at->del_users( $param->{ctype}, @{ mk_aref($param->{del_users}) } );
    $at->add_groups( $param->{ctype}, @{ mk_aref($param->{add_groups}) } );
    $at->del_groups( $param->{ctype}, @{ mk_aref($param->{del_groups}) } );
    $at->save;
    add_msg("$param->{ctype} recipients changed.");
    set_redirect("/admin/profile/alert_type/$param->{alert_type_id}");
}

</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/profile/alert_type.mc - Processes submits from Alert Type Profile

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2001-12-04 18:17:41 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/alert_type.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Alert Type Profile page.

</%doc>
