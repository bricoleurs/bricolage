<%once>;
my $keys = [qw(story media formatting)];
my $pkgs = { map { $_=>  get_package_name($_) } @$keys };
my $dskpkg = 'Bric::Biz::Workflow::Parts::Desk';
</%once>

<%args>
$widget
$param
$field
</%args>
<%init>;
if ($field eq "$widget|checkin_cb") {
    # Checking in assets and moving them to another desk.
    my %desks;
    foreach my $next (@{ mk_aref($param->{"desk|next_desk"})}) {
	next unless $next;
	my ($aid, $from_id, $to_id, $key) = split /-/, $next;
	my $a = $pkgs->{$key}->lookup({ id => $aid, checkout => 1 });
	my $curr = $desks{$from_id} ||= $dskpkg->lookup({ id => $from_id });
	my $next = $desks{$to_id} ||= $dskpkg->lookup({ id => $to_id });
	$curr->checkin($a);
	log_event("${key}_checkin", $a);

        if ($curr->get_id != $next->get_id) {
            $curr->transfer({ to    => $next,
                              asset => $a });
            log_event("${key}_moved", $a, { Desk => $next->get_name });
        }
        $curr->save;
        $next->save;
    }
} elsif ($field eq "$widget|delete_cb") {
    my $burn = Bric::Util::Burner->new;
    # Deleting assets.
    foreach my $key (@$keys) {
        foreach my $aid (@{ mk_aref($param->{"${key}_del_ids"}) }) {
	    my $a = $pkgs->{$key}->lookup({ id => $aid, checkout => 1 });
	    if (chk_authz($a, EDIT, 1)) {
		my $d = $a->get_current_desk;
		$d->checkin($a);
		$d->remove_asset($a);
		$d->save;
		log_event("${key}_rem_workflow", $a);
                $a->set_workflow_id(undef);
		$a->deactivate;
		$a->save;
		$burn->undeploy($a) if $key eq 'formatting';
		log_event("${key}_deact", $a);
	    } else {
		add_msg("Permission to delete &quot;" . $a->get_name
			. "&quot; denied.");
	    }
	}
    }
}
</%init>

<%doc>
###############################################################################

=head1 NAME

/widgets/workspace/callback.mc

=head1 VERSION

$Revision: 1.6.2.3 $

=head1 DATE

$Date: 2002-09-27 19:39:49 $

=head1 SYNOPSIS

=head1 DESCRIPTION

</%doc>
