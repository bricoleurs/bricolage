%#--- Documentation ---#

<%doc>

=head1 NAME

desk - A desk widget for displaying the contents of a desk.

=head1 VERSION

$Revision: 1.22 $

=head1 DATE

$Date: 2003-09-29 18:41:47 $

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
$sort_by => 'cover_date'
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
    my ($ckey, $desk, $user_id, $class, $meths, $sort_by) = @_;
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
                } map { chk_authz($_, READ, 1) ? $_ : () } @$curr_objs;
            } elsif ($type eq 'date') {
              @$curr_objs = sort {
                  # Date sort. Use ISO format to ensure proper ordering.
                  $sort_get->($a, ISO_8601_FORMAT) cmp
                    $sort_get->($b, ISO_8601_FORMAT)
                }map { chk_authz($_, READ, 1) ? $_ : () } @$curr_objs;
            } else {
                # Do a case-insensitive sort.
              @$curr_objs = sort {
                  lc $sort_get->($a, @$sort_arg) cmp
                  lc $sort_get->($b, @$sort_arg)
              } map { chk_authz($_, READ, 1) ? $_ : () } @$curr_objs;
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

if (my $objs = &$cached_assets($class, $desk, $user_id, $class, $meths,
                               $sort_by)) {

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
        my $type = defined $atid ? $types{$atid} ||=
          $obj->get_element_name : '';

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
                $pub = $m->scomp('/widgets/profile/checkbox.mc',
                            name  => "$widget|${class}_pub_ids",
                            id    => "$widget\_$aid",
                            value => $aid)
                  . qq{<label for="$widget\_$aid">}
                  . ($class eq 'formatting' ? 'Deploy' : 'Publish')
                  . '</label>'
                  unless $obj->get_checked_out;
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
                    $user = $users{$uid} ||= Bric::Biz::Person::User->lookup
                      ({ id => $uid })->format_name;
                }
            }
        } else {
            # It's 'My Workspace'.
            $desk = $obj->get_current_desk;

            # HACK: sometimes objects don't have a current desk.  I don't
            # know why, but it happens and then a fatal error occurs
            # when $desk->get_id is called on an undef desk.  Instead,
            # find the default desk for this object and put it there
            # with a warning for the user.
            if (not defined $desk) {
                my $wf = $obj->get_workflow_object;

                # no workflow either!  Find one appropriate for the
                # object.
                if (not defined $wf) {
                    if (ref($obj) =~ /Story$/) {
                        ($wf) = Bric::Biz::Workflow->list({'type' => 2});
                    } elsif (ref($obj) =~ /Media/) {
                        ($wf) = Bric::Biz::Workflow->list({'type' => 3});
                    } elsif (ref($obj) =~ /Formatting$/) {
                        ($wf) = Bric::Biz::Workflow->list({'type' => 1});
                    }
                    # assign to workflow
                    $obj->set_workflow_id($wf->get_id());
                }

                # assign to start desk of workflow
                $desk = $wf->get_start_desk;
                $desk->accept({'asset' => $obj});
                $desk->save();

                # tell the user this object was baked
                add_msg('Warning: object "[_1]" had no associated desk.  It has been assigned to the "[_2]" desk.',
                        $obj->get_name, $desk->get_name);
            }



            $desk_id = $desk->get_id;
            $label = $lang->maketext('Check In to [_1]',$desk->get_name);
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
        my $a_wf = $wfs{$obj->get_workflow_id} ||= $obj->get_workflow_object;

        my $value = '';
        if ($desk_opts) {

            # HACK:  Stop the 'allowed_desks' error.
            unless ($a_wf) {
                if ($obj->is_active) {
                    # Find a workflow to put it on.
                    if (ref($obj) =~ /Story$/) {
                        ($a_wf) = Bric::Biz::Workflow->list({'type' => 2});
                    } elsif (ref($obj) =~ /Media/) {
                        ($a_wf) = Bric::Biz::Workflow->list({'type' => 3});
                    } elsif (ref($obj) =~ /Formatting$/) {
                        ($a_wf) = Bric::Biz::Workflow->list({'type' => 1});
                    }

                    $obj->set_workflow_id($a_wf->get_id);
                    $obj->save;

                    my @msg_args = ('Warning: object "[_1]" had no associated workflow.  It has been assigned to the "[_2]" workflow.',
                                 $obj->get_name, $a_wf->get_name);

                    if ($desk) {
                        my @ad = $a_wf->allowed_desks;
                        unless (grep($desk->get_id == $_->get_id, @ad)) {
                            my $st = $a_wf->get_start_desk;
                            $desk->transfer({'to'    => $st,
                                             'asset' => $obj});
                            $desk->save;
                            $msg_args[0] .= ' This change also required that this object be moved to the "[_3]" desk.';
                            push(@msg_args, $st->get_name);
                        }
                    }
                    add_msg(@msg_args);
                } else {
                    # Remove it from the desk!
                    $desk->remove_asset($obj) if $desk;
                    next;
                }
            }

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
    }
    $m->out("<br />\n");
}
</%init>

%#--- Log History ---#


