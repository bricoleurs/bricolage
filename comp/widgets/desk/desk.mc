%#--- Documentation ---#

<%doc>

=head1 NAME

desk - A desk widget for displaying the contents of a desk.

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

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
$sort_by => get_pref('Default Asset Sort') || 'cover_date'
$offset  => 0
$show_all => undef
</%args>

%#--- Initialization ---#

<%once>;
my $widget = 'desk_asset';
my $pkgs = { story      => get_package_name('story'),
             media      => get_package_name('media'),
             formatting => get_package_name('formatting')
           };
my $item_comp = USE_XHTML ? 'desk_item.html' : 'desk_item_old.html';

my $others;
my $cached_assets = sub {
    my ($ckey, $desk, $user_id, $meths, $sort_by) = @_;

    my $objs = $r->pnotes("$widget.objs");
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
            my ($sort_get, $sort_arg) =
              @{$meths->{$sort_by}}{'get_meth', 'get_args'};
            my $type = $meths->{$sort_by}{props}{type};
            if ($sort_by eq 'id') {
                # Do a numerical sort.
                @$curr_objs = sort {
                    $sort_get->($a, @$sort_arg) <=> $sort_get->($b, @$sort_arg)
                } grep { chk_authz($_, READ, 1) } @$curr_objs;
            } elsif ($type eq 'date') {
                @$curr_objs = sort {
                    # Date sort. Use ISO format to ensure proper ordering.
                    $sort_get->($a, ISO_8601_FORMAT) cmp
                    $sort_get->($b, ISO_8601_FORMAT)
                } grep { chk_authz($_, READ, 1) } @$curr_objs;
            } else {
                # Do a case-insensitive sort.
                @$curr_objs = sort {
                    lc $sort_get->($a, @$sort_arg) cmp
                    lc $sort_get->($b, @$sort_arg)
                } grep { chk_authz($_, READ, 1) } @$curr_objs;
            }

        } else {
            # Just check for READ permission.
            @$curr_objs = map { chk_authz($_, READ, 1) ? $_ : () } @$curr_objs;
        }
        # Set the hash key to undef if there aren't any assets left.
        $objs->{$ckey} = undef unless @$curr_objs;
    }

    # Cache them for this request.
    $r->pnotes("$widget.objs", $objs);

    # Figure out what all we've got. We'll use this for displaying
    # relative links.
    $others = {
        map  { $_ => 1 }
        grep { $objs->{$_} && @{ $objs->{$_} } }
        keys %$pkgs
    };

    # Return them.
    return $objs->{$ckey};
};

# XXX This is used by the desk and workflow placement hacks.
my $dump_events = sub {
    my $obj = shift;
    return if $r->pnotes("$obj");
    $r->pnotes("$obj" => 1);
    my $cid = get_class_info(ref $obj)->get_id;
    print STDERR "Recent events for ", $obj->key_name, ' "',
      $obj->get_name, "\":$/";
    my $i = 0;
    my %users;
    for my $e (reverse Bric::Util::Event->list({
        obj_id   => $obj->get_id,
        class_id => $cid}))
    {
        my $u = $users{$e->get_user_id} ||= $e->get_user->get_login;
        print STDERR "   ", $e->get_timestamp, ": ", $e->get_name,
          " by $u$/";
        last if ++$i >= 20;
    }
    print STDERR $/;
};

# XXX This is a hack. We still have no idea when or why a document forgets
# its workflow or desk.
my $put_into_wf = sub {
    my ($obj, $cancel) = @_;
    $r->log->error(uc($obj->key_name) . ' "' . $obj->get_name
                   . '" forgot what workflow it was in.');
    $dump_events->($obj);
    # No workflow, either. Find one.
    my $wf = find_workflow($obj->get_site_id, $obj->workflow_type, READ);
    unless ($wf) {
        # Oh, hell. They don't have access to the appropriate
        # workflow. Just cancel the checkout.
        $obj->cancel_checkout;
        $obj->save;
        add_msg('Warning: object "[_1]" had no associated workflow, and '
                . 'you do not have the appropriate permissions to assign '
                . 'it to one. Checkout cancelled.', $obj->get_name);
        return;
    }

    # Assign to workflow
    $obj->set_workflow_id($wf->get_id);
    add_msg('Warning: object "[_1]" had no associated workflow. It has been '
            . 'assigned to the "[_2]" workflow',
            $obj->get_name, $wf->get_name);
    return $wf;
};

# XXX This is a hack. We still have no idea when or why a document forgets
# its workflow or desk.
my $put_onto_desk = sub {
    my ($obj, $wf, $perm) = @_;
    $r->log->error(uc($obj->key_name) . ' "' . $obj->get_name
                   . '" forgot what desk it was on.');
    $dump_events->($obj);
    # Put it on a desk in the workflow.
    my $desk = find_desk($wf, $perm);
    unless ($desk) {
        # Oh, hell. They don't have permission to a desk. Cancel the checkout.
        $obj->cancel_checkout;
        $obj->save;
        add_msg('Warning: object "[_1]" had no associated desk, and you '
                . 'do not have the appropriate permissions to assign it '
                . 'to one. Checkout cancelled.', $obj->get_name);
        return;
    }
    $desk->accept({'asset' => $obj});
    $desk->save;

    # Tell the user this object was baked
    add_msg('Warning: object "[_1]" had no associated desk. It has been '
            . 'assigned to the "[_2]" desk.',
            $obj->get_name, $desk->get_name);
    return $desk;
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

# Paging limit
my $num_displayed = $r->pnotes('num_displayed') || 0;
my $limit = $show_all ? 0 : get_pref('Search Results / Page');
my $objs = [];
if (!$limit || ($limit && $num_displayed < $limit)) {
    $objs = &$cached_assets($class, $desk, $user_id, $meths, $sort_by)
}

# Paging offset
my $obj_offset = $offset;
my $d = $r->pnotes('desk_asset.objs');
if ($class =~ /^(media|formatting)$/) {
    my $num_stories = defined($d->{story}) ? @{$d->{story}} : 0;
    $obj_offset -= $num_stories if $offset;
}
if ($class eq 'formatting') {
    my $num_media = defined($d->{media}) ? @{$d->{media}} : 0;
    $obj_offset -= $num_media if $offset;
}

if (defined $objs && @$objs > $obj_offset) {
    $m->comp("/widgets/desk/desk_top.html",
             class => $class,
             others => $others,
             sort_by_val => $sort_by);

    my $disp = get_disp_name($class);
    my (%types, %users, %wfs);
    my $profile_page = '/workflow/profile/' .
      ($class eq 'formatting' ? 'templates' : $class);

    for (my $i = 0; $i < @$objs; $i++) {
        if ($limit) {
            next unless $i >= $obj_offset;
        }
        my $obj = $objs->[$i];

        my $can_edit = chk_authz($obj, EDIT, 1);
        my $aid = $obj->get_id;
        # Grab the type name.
        my $atid = $obj->get_element__id;
        my $type = $class eq 'formatting'
          ? $obj->get_output_channel_name
          : defined $atid
          ? $types{$atid} ||= $obj->get_element_name
          : '';

        # Grab the User ID.
        my $user_id = $obj->get_user__id;
        # Figure out the Checkout status.
        my $label = $can_edit ? 'Check Out' : '';
        my $vlabel = 'View';
        my $action = 'checkout_cb';
        my $desk_opts = [['', '']];
        my ($user);
        my $pub = '';
        my $a_wf = $wfs{$obj->get_workflow_id} ||= $obj->get_workflow_object;
        if ($desk_type eq 'workflow') {
            # Figure out the checkout/edit link.
            if (defined $user_id) {
                if (get_user_id() == $user_id) {
                    $label = 'Check In';
                    $action = 'checkin_cb';
                    $vlabel = 'Edit' if $can_edit;
                } else {
                    $desk_opts = undef;
                    my $uid = $obj->get_user__id;
                    $user = $users{$uid} ||= Bric::Biz::Person::User->lookup
                      ({ id => $uid })->format_name;
                }
            }
            # Make a checkbox for Publish/Deploy if publishing is authorized
            # and the asset isn't checked out; otherwise, a Delete checkbox
            my $checkname = "${class}_delete_ids";
            my $checklabel = $lang->maketext('Delete');
            # Only show Delete checkbox if user can edit the story
            # (Publish checkbox when PUBLISH permission, but PUBLISH > EDIT anyway)
            if ($can_edit) {
                my $can_pub = $desk->can_publish && chk_authz($obj, PUBLISH, 1);
                if ($can_pub and ! $obj->get_checked_out) {
                    $checkname = "$widget|${class}_pub_ids";
                    $checklabel = $lang->maketext($class eq 'formatting'
                                                  ? 'Deploy' : 'Publish');
                }

                # We don't want both Delete and Publish on the same page
                unless ($desk->can_publish && $checkname =~ /_delete_ids$/) {
                    $pub = $m->scomp('/widgets/profile/checkbox.mc',
                                     name  => $checkname,
                                     id    => "$widget\_$aid",
                                     value => $aid)
                      . qq{<label for="$widget\_$aid">$checklabel</label>};
                }
            }

            # XXX HACK: Stop the 'allowed_desks' error.
            unless ($a_wf) {
                if ($obj->is_active) {
                    # Hrm, we don't have a workflow object. What workflow is
                    # the current desk in?
                    if ($work_id) {
                        $obj->set_workflow_id($work_id);
                        $obj->save;
                        $a_wf = $wfs{$work_id}
                          ||= Bric::Biz::Workflow->lookup({ id => $work_id});
                        add_msg('Warning: object "[_1]" had no associated '
                                . 'workflow.  It has been assigned to the '
                                . '"[_2]" workflow.',
                                $obj->get_name, $a_wf->get_name);
                    } else {
                        # This shouldn't happen, since $work_id is always
                        # passed as a paramter.
                        $a_wf = $put_into_wf->($obj) or next;
                    }
                    # We know we have a desk because we're currently *on*
                    # a desk!
                } else {
                    # Remove it from the desk.
                    $desk->remove_asset($obj) if $desk;
                    next;
                }
            }
        } else {
            # It's 'My Workspace'.
            $desk = $obj->get_current_desk;
            # XXX We should never lose track of the workflow! This is a hack.
            $a_wf ||= $obj->get_workflow_object || $put_into_wf->($obj)
              || next;

            unless ($desk) {
                # XXX I really want to make this go away!
                # HACK: sometimes objects don't have a current
                # desk. I don't know why, but it happens and then
                # a fatal error occurs. So find a desk for it.
                $desk = $put_onto_desk->($obj, $a_wf, EDIT) or next;
            }

            $desk_id = $desk->get_id;
            $label = $lang->maketext('Check In to [_1]', $desk->get_name);
            $action = 'checkin_cb';
            if ($can_edit) {
                $vlabel = 'Edit';
                $pub = $m->scomp('/widgets/profile/checkbox.mc',
                                 name  => "${class}_delete_ids",
                                 id    => "$widget\_$aid",
                                 value => $aid)
                  . qq{<label for="$widget\_$aid">}
                  . $lang->maketext('Delete') . '</label>';
            }
        }

        # Assemble the list of desks we can move this to.
        my $value = '';
        if ($desk_opts) {
            my %seen;
            my $a_wfid = $a_wf->get_id;
            foreach my $d ($a_wf->allowed_desks) {
                next unless chk_authz(undef, READ, 1, $d->get_asset_grp);
                my $did = $d->get_id;
                next if $did == $desk_id and $desk_type eq 'workflow';
                push @$desk_opts, [join('-', $aid, $desk_id, $did, $class,
                                        $a_wfid),
                                   $d->get_name];
                $seen{$did} = 1;
            }

            if (ALLOW_WORKFLOW_TRANSFER) {
                # Find all the other workflows this desk is in.
                foreach my $wf (Bric::Biz::Workflow->list({ desk_id => $desk_id })) {
                    my $wid = $wf->get_id;
                    next if $wid == $a_wfid;
                    # Add all of their desks to the list.
                    foreach ($wf->allowed_desks) {
                        my $did = $_->get_id;
                        next if $seen{$did};
                        next if $did == $desk_id and $desk_type eq 'workflow';
                        push @$desk_opts, [join('-', $aid, $desk_id, $did,
                                                $class, $wid),
                                           $_->get_name];
                        $seen{$did} = 1;
                    }
                }
            }
        }

        # Now display it!
        $m->comp($item_comp,
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
                 class     => $class,
                 desk      => $desk,
                 did       => $desk_id,
                 user      => $user,
                 label     => $label,
                 action    => $action,
                 desk_type => $desk_type);

        $num_displayed++;
        last if $limit && $num_displayed == $limit;
    }
    $r->pnotes('num_displayed', $num_displayed);

    $m->out("<br />\n");
}
</%init>

%#--- Log History ---#


