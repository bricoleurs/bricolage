%#--- Documentation ---#

<%doc>

=head1 NAME

desk - A desk widget for displaying the contents of a desk.

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2001-11-20 00:04:06 $

=head1 SYNOPSIS

<& '/widgets/desk/desk.mc' &>

=head1 DESCRIPTION

Display the contents of the named desk.  Allow various actions to be performed
upon each item.

=cut

</%doc>

%#--- Arguments ---#

<%args>
$class   => 'story'
$desk_id => undef
$desk    => undef
$user_id => undef
$work_id => undef
$style   => 'standard'
$action  => undef
$wf      => undef
$sort_by => undef
</%args>

%#--- Initialization ---#

<%once>;
my $widget = 'desk';
my $pkgs = { story      => get_package_name('story'),
	     media      => get_package_name('media'),
	     formatting => get_package_name('formatting')
           };
my $others;
my $cached_assets = sub {
    my ($ckey, $desk, $user_id, $class, $meths, $sort_by) = @_;
    my $objs = $rc->get("$widget.objs");
    unless ($objs) {
	# We have no objects. So get 'em!
	if ($desk) {
	    # Get them from the desk object.
	    $objs = $desk->get_assets_href;
	} else {
	    # Get them from each asset package.
	    while (my ($key, $pkg) = each %$pkgs) {
		$objs->{$key} = $pkg->list({user__id => $user_id,
	                                    active   => 1});
	    }
	}
    }

    if (my $curr_objs = $objs->{$ckey}) {
	if ($sort_by) {
	    # Check for READ permission and sort them.
	    my ($sort_get, $sort_arg) = @{$meths->{$sort_by}}{'get_meth', 'get_args'};
	    @$curr_objs = sort { $sort_get->($a, @$sort_arg) cmp $sort_get->($b, @$sort_arg) }
	      map { chk_authz($_, READ, 1) ? $_ : () } @$curr_objs;
	} else {
	    # Just check for READ permission.
	    @$curr_objs = map { chk_authz($_, READ, 1) ? $_ : () } @$curr_objs;
	}
	# Set the hash key to undef if there aren't any assets left.
	$objs->{$ckey} = undef unless @$curr_objs;
    }

    # Cache them for this request.
    $rc->set("$widget.objs", $objs);

    # Figure out what all we've got. We'll use this for displaying
    # relative links.
    foreach (keys %$pkgs) { $others->{$_} = 1 if defined $objs->{$_} }

    # Return them.
    return $objs->{$ckey};
};
</%once>

<%init>;
my $pkg   = get_package_name($class);
my $meths = $pkg->my_meths;
my $desk_type = 'workflow';
my $mlabel = 'Move to';

if (defined $desk_id) {
    # This is a workflow desk.
    $desk ||= Bric::Biz::Workflow::Parts::Desk->lookup({'id' => $desk_id});
}
elsif (defined $user_id) {
    # This is a user workspace
    $desk_type = 'workspace';
    $mlabel = 'Check In to';
}
#-- Output each desk item  --#
my $highlight = $sort_by;
unless ($highlight) {
    foreach my $f (keys %$meths) {
	# Break out of the loop if we find the searchable field.
	$highlight = $f and last if $meths->{$f}->{search};
    }
}

if (my $objs = &$cached_assets($class, $desk, $user_id, $class, $meths, $sort_by)) {

    $m->comp("/widgets/desk/desk_top.html",
	     class => $class,
	     others => $others,
	     sort_by_val => $sort_by);

    my $disp = get_disp_name($class);
    my (%types, %users, %wfs);
    my $profile_page = '/workflow/profile/' .
      ($class eq 'formatting' ? 'templates' : $class);

    foreach my $obj ( @$objs ) {
        my $can_edit = chk_authz($obj, EDIT, 1);
	my $aid = $obj->get_id;
	# Grab the type name.
	my $atid = $obj->get_element__id;
	my $type = defined $atid ? $types{$atid} ||= $obj->get_element_name : '';

	# Grab the User ID.
	my $user_id = $obj->get_user__id;
	# Figure out the Checkout status.
	my $label = $can_edit ? 'Check Out' : '';
	my $vlabel = 'View';
	my $action = 'checkout_cb';
	my $desk_opts = [['', '']];
	my ($user);
	my $pub = '';
	if ($desk_type eq 'workflow') {
	    # Figure out publishing stuff, if necessary.
	    if ($can_edit && $desk->can_publish) {
		$pub = ($class eq 'formatting' ? 'Deploy' : 'Publish') .
                  $m->scomp('/widgets/profile/checkbox.mc',
			    name  => "$widget|${class}_pub_ids",
			    value => $aid) unless $obj->get_checked_out;
	    }
	    # Now figure out the checkout/edit link.
	    if (defined $user_id) {
		if (get_user_id() == $user_id) {
		    $label = 'Check In';
		    $action = 'checkin_cb';
		    $vlabel = 'Edit' if $can_edit;
		} else {
		    $desk_opts = undef;
		    my $uid = $obj->get_user__id;
		    $user = $users{$uid} ||=
		      Bric::Biz::Person::User->lookup({ id => $uid })->format_name;
		}
	    }
	} else {
	    # It's 'My Workspace'.
	    $desk = $obj->get_current_desk;
	    $desk_id = $desk->get_id;
	    $label = 'Check In to ' . $desk->get_name;
	    $action = 'checkin_cb';
	    if ($can_edit) {
	        $vlabel = 'Edit';
	        $pub = $m->scomp('/widgets/profile/checkbox.mc',
		          name  => "${class}_del_ids",
		          value => $aid) . 'Delete';
	    }
        }
	my $elink = $user ? $user : $label ? qq{<a href="} . $r->uri . "?" .
      join('&', ("$widget|$action=$aid", "$widget|asset_class=$class"))
      . qq{" class=blackUnderlinedLink>$label</a>} : '';

	# Assemble the list of desks we can move this to.
	my $a_wf = $wfs{$obj->get_workflow_id} ||= $obj->get_workflow_object;

	my $value = '';
	if ($desk_opts) {

	    # HACK:  Stop the 'allowed_desks' error.
	    unless ($a_wf) {
		my ($msg, $name);
		if (ref($obj) =~ /Story$/) {
		    ($a_wf) = Bric::Biz::Workflow->list({'type' => 2});
		    $name = 'Story';
		} elsif (ref($obj) =~ /Media/) {
		    ($a_wf) = Bric::Biz::Workflow->list({'type' => 3});
		    $name = 'Media';
		} elsif (ref($obj) =~ /Formatting$/) {
		    ($a_wf) = Bric::Biz::Workflow->list({'type' => 1});
		    $name = 'Template';
		}

		$obj->set_workflow_id($a_wf->get_id);
		$obj->save;

		$msg = "Warning: $name object '".$obj->get_name.
                       "' had no associated workflow.  It has been ".
		       "assigned to the '".$a_wf->get_name."' workflow.";
	

		if ($desk) {
		    my @ad = $a_wf->allowed_desks;
		    unless (grep($desk->get_id == $_->get_id, @ad)) {
			my $st = $a_wf->get_start_desk;
			$desk->transfer({'to'    => $st,
					 'asset' => $obj});
			$desk->save;

			$msg .= "  This change also required that this ".
			        lc($name)." be moved to the '".$st->get_name.
				"' desk";
		    }
		}
		
		add_msg($msg);
	    }
	    
	    foreach ($a_wf->allowed_desks) {
		# Do not include the current desk in the list.
		next if $_->get_id eq $desk_id;
		push @$desk_opts, [join('-',$aid,$desk_id,$_->get_id,$class), $_->get_name];
	    }
	}

	# Now display it!
	$m->comp('desk_item.html',
		 widget    => $widget,
		 highlight => $highlight,
		 obj       => $obj,
		 can_edit  => $can_edit,
		 vlabel    => $vlabel,
		 mlabel    => $mlabel,
		 desk_val  => $value,
		 desk_opts => $desk_opts,
		 ppage     => $profile_page,
		 aid       => $aid,
		 pub       => $pub,
		 disp      => $disp,
		 type      => $type,
		 elink     => $elink,
		 class     => $class,
		 desk      => $desk,
		 did       => $desk_id,
		 desk_type => $desk_type);
    }
    $m->out("<br />\n");
}
</%init>

%#--- Log History ---#


