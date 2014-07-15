<%doc>

=head1 NAME

desk - A desk widget for displaying the contents of a desk.

=head1 SYNOPSIS

<& '/widgets/desk/desk.mc' &>

=head1 DESCRIPTION

Display the contents of the named desk.  Allow various actions to be performed
upon each item.

=cut

</%doc>
<%args>
$class   => 'story'
$desk_id => undef
$desk    => undef
$user_id => undef
$work_id => undef
$action  => undef
$wf      => undef
$sort_by => undef
$offset  => 0
$show_all => undef
</%args>
<%once>;
my $widget = 'desk_asset';
my $pkgs = {
    story    => get_package_name('story'),
    media    => get_package_name('media'),
    template => get_package_name('template')
};

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
            # check for sort order
            my $sort_descending = $sort_by =~ s/__desc$//gi;
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
            @$curr_objs = reverse @$curr_objs if $sort_descending;

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
        map  { $_ => $objs->{$_}  ? scalar @{ $objs->{$_} } : 0 }
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
my %desk_sort_for = (
    cover_date   => 'deploy_date',
    element_type => 'output_channel',
);
</%once>
<%init>;
my $pkg   = get_package_name($class);
my $meths = $pkg->my_meths;
my $desk_type = 'workflow';
my $order_key;

if (defined $desk_id) {
    # This is a workflow desk.
    $desk ||= Bric::Biz::Workflow::Parts::Desk->lookup({'id' => $desk_id});
    $order_key = "$class\_order_desk_$desk_id";
}
elsif (defined $user_id) {
    # This is a user workspace
    $desk_type = 'workspace';
    $order_key = "$class\_order_ws_$user_id";
}
# Initialize the ordering.
$sort_by ||= get_state_data($widget, $order_key)
         || get_pref('Default Asset Sort')
         || 'cover_date';

set_state_data($widget, $order_key => $sort_by);

#-- Output each desk item  --#
my $highlight = $sort_by;
if ($highlight) {
    if ($class eq 'template') {
        $sort_by = $desk_sort_for{$sort_by} || $sort_by;
        $highlight = 'name' if $highlight eq 'uri';
    }
} else {
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
if ($class =~ /^(media|template)$/) {
    my $num_stories = defined($d->{story}) ? @{$d->{story}} : 0;
    $obj_offset -= $num_stories if $offset;
}
if ($class eq 'template') {
    my $num_media = defined($d->{media}) ? @{$d->{media}} : 0;
    $obj_offset -= $num_media if $offset;
}

if (defined $objs && @$objs && @$objs > $obj_offset) {
    $m->comp(
        '/widgets/desk/desk_top.html',
        class       => $class,
        others      => $others,
        sort_by_val => $sort_by,
        offset      => $offset,
        show_all    => $show_all,
    );

    my $start = ($limit ? $obj_offset : 0);
    foreach my $obj (@$objs[$start..$#$objs]) {

        my $a_wf = $obj->get_workflow_object;
        if ($desk_type eq 'workflow') {
            # XXX HACK: Stop the 'allowed_desks' error.
            unless ($a_wf) {
                if ($obj->is_active) {
                    # Hrm, we don't have a workflow object. What workflow is
                    # the current desk in?
                    if ($work_id) {
                        $obj->set_workflow_id($work_id);
                        $obj->save;
                        $a_wf = Bric::Biz::Workflow->lookup({ id => $work_id});
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
        }

        $m->comp('desk_item.html',
            widget    => $widget,
            highlight => $highlight,
            obj       => $obj,
            action    => $action,
            desk_type => $desk_type,
            work_id   => $work_id
        );

        $num_displayed++;
        last if $limit && $num_displayed == $limit;
    }

    $r->pnotes('num_displayed', $num_displayed);
    
    $m->comp(
        '/widgets/desk/desk_bottom.html',
        offset      => $offset || 0,
        show_all    => $show_all,
    );

}
</%init>
