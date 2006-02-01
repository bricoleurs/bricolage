<%args>
$nav   => undef
$uri   => undef
$debug => undef
</%args>
<%once>;
my $disp = { map { $_ => get_disp_name($_) } qw(story media template) };
my $pl_disp = {
    map { $_ => get_class_info($_)->get_plural_name }
        qw(story media template pref user grp output_channel contrib
           contrib_type site workflow category element_type
           media_type source dest job alert_type keyword)
};

my $printLink = sub {
    my ($href, $uri, $caption, $no_translation) = @_;
    $caption = $lang->maketext($caption) unless $no_translation;
    my @href = split(/\//, $href);
    my @uri  = split(/\//, $uri);

    # Make sure we have something to eq to.
    for (1..5) { $uri[$_] = '' unless defined $uri[$_] }

    my $isLink = 1;
    my $out    = '';
    my $style;

    if ($uri[1] eq 'admin') {
        $style = ' class="selected"' if $uri[1] eq $href[1] && $uri[3] eq $href[3];
        # disable link in admin/manager when we have a full url match
        $isLink = $uri[2] eq $href[2] ? 0 : 1;
        $isLink = 1 if $uri[3] eq 'element_type' && defined $uri[4];
    } else {
        if ($uri[3] eq 'desk') {
            $style = ' class="selected"'
                if $uri[1] eq $href[1]
                && $uri[3] eq $href[3]
                && $uri[4] eq $href[4]
                && $uri[5] eq $href[5];
        } elsif ($uri[2] eq 'manager' || $uri[2] eq 'profile' || $uri[2] eq 'active') {
            $style = ' class="selected"'
                if $uri[1] eq $href[1]
                && $uri[2] eq $href[2]
                && $uri[3] eq $href[3]
                && $uri[4] eq $href[4];
        }
    }
    if ($style =~ /selected/ && !$isLink) {
        $out .= "<span$style>$caption</span>";
    } else {
        $out .= qq{<a href="$href" target="_parent"$style>$caption</a>};
    }
    return $out;
};

my $admin_links = sub {
    my $uri = shift;
    $m->print(
        '<li>', $printLink->("/admin/manager/$_->[0]", $uri, $_->[2], 1),
        "</li>\n"
    ) for
        sort { $a->[1] cmp $b->[1] }
        map  {
            my $trans = $lang->maketext($pl_disp->{$_});
            [ $_ => lc $trans, $trans]
        } @_;
};
</%once>\
<%perl>;
my $site_id = $c->get_user_cx(get_user_id);
# Make sure we always have a site ID. If the server has just been restarted,
# then site_context may not have been executed yet. So execute it to get the
# site ID.
$site_id = $m->comp('/widgets/site_context/site_context.mc', display => 0)
  unless defined $site_id;

my $workflows = $c->get('__WORKFLOWS__'. $site_id);

my $nav_uri = $r->uri;
$uri      ||= $nav_uri;
$uri        = '/workflow/profile/workspace' unless $uri && $uri ne '/';

$nav ||= get_state_data("nav");
unless ($workflows) {
    # The cache hasn't been loaded yet. Load it.
    $workflows = [];
    foreach my $w (Bric::Biz::Workflow->list({site_id => $site_id})) {
        # account for desks
        my @desks = map { [ $_->get_id, $_->get_name,
                            [$_->get_asset_grp, $_->get_grp_ids] ]
                        } $w->allowed_desks;
        my @gids = ($w->get_asset_grp_id, $w->get_grp_ids);

        my $type = $w->get_type;
        my $wf = {
            type    => $type,
            key     => lc Bric::Biz::Workflow::WORKFLOW_TYPE_MAP->{$type},
            id      => $w->get_id,
            name    => $w->get_name,
            site_id => $w->get_site_id,
            desks   => \@desks,
            gids    => \@gids
        };
        push @$workflows, $wf;
    }
    # account for open admin links
    $c->set('__WORKFLOWS__'. $site_id, $workflows);
}

</%perl>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">
<html>
<head>
<link rel="stylesheet" type="text/css" href="/media/css/style.css" />
<link rel="stylesheet" type="text/css" href="/media/css/style-nav.css" />
<script type="text/javascript" src="/media/js/lib.js"></script>
  
<script type="text/javascript">
var navLoader = function () {
    var workspace = document.getElementById('workspace');
    var workspaceAnchor = workspace.getElementsByTagName('a')[0];
    workspaceAnchor.className = (parent.location.pathname.indexOf('workspace') != -1) ? 'open' : 'closed';
    resizeframe();
}
multiOnload.onload(navLoader);
</script>
</head>
<body id="navFrame">
<%perl>
# Begin Workflows -------------------------------------
$m->print(
    '<ul id="nav">',
    '<li id="workspace"><a class="closed" href="/workflow/profile/workspace/"',
    'target="_parent" title="My Workspace">My Workspace</a></li>',
    '<li id="workflows"><ul class="submenu">'
);

# iterate thru workflows
foreach my $wf (@$workflows) {
    next if $site_id && $site_id != $wf->{site_id};
    # Check permissions.
    next unless chk_authz(0, READ, 1, @{ $wf->{gids} });

    if ( $nav->{"workflow-$wf->{id}"} ) { # show open workflow

        $m->print(
            qq{<li class="open"><a href="$nav_uri?nav|workflow_cb=0&navwfid=},
            qq{$wf->{id}">$wf->{name}</a>},
            '<ul class="sections"><li>',
            $lang->maketext('Actions')
        );

        # actions/desks/publish items for this workflow
        my $can_create = chk_authz(0, CREATE, 1, @{ $wf->{desks}[0][2] });

    # actions
        $m->out(qq{<ul class="items">});
        my $key = $wf->{key};
        $m->print(
            '<li>',
            $printLink->(
                "/workflow/profile/$key/new/$wf->{id}",
                $uri,
                "New $disp->{$key}"
            ),
            '</li>',
        ) if $can_create;

        $m->print(
            '<li>',
            $printLink->(
                "/workflow/manager/$key/$wf->{id}",
                $uri,
                "Find $pl_disp->{$key}"
            ),
            '</li><li>',

            $printLink->(
                "/workflow/active/$key/$wf->{id}",
                $uri,
                "Active $pl_disp->{$key}"
            ),
            '</li>'
        );

        $m->print(
            '<li>',
            $printLink->(
                "/workflow/profile/alias/$key/$wf->{id}",
                $uri,
                'New Alias'
            ),
            '</li>',
        ) unless $key eq 'template';

        $m->print('</ul></li>');

        # desks
        $m->print('<li>', $lang->maketext('Desks'), '<ul class="items">');
        for my $d (@{$wf->{desks}}) {
            next unless chk_authz(0, READ, 1, @{ $d->[2] });
            $m->print(
                '<li>',
                $printLink->(
                    "/workflow/profile/desk/$wf->{id}/$d->[0]/",
                    $uri,
                    $d->[1],
                    1
                ),
                '</li>'
            );
        }
        $m->print('</ul></li></ul></li>');
    } else {
        # closed state
        $m->print(
            qq{<li class="closed"><a href="$nav_uri?nav|workflow_cb=1&navwfid=},
            qq{$wf->{id}">$wf->{name}</a></li>}
        );
    }
}
$m->print(qq{</ul></li>});
# End Workflows -------------------------------------

# Begin Admin --------------------------------------
if ( $nav->{admin} ) {
    # Start the open admin menu.
    $m->print(
        qq{<li id="admin" class="open"><a href="}, $nav_uri,
        qq{?nav|admin_cb=0">}, $lang->maketext('Admin'), qq{</a>},
        qq{<ul class="submenu">},
    );

    # Begin system submenus
    if ( $nav->{adminSystem} ) {
        # open system submenu
        $m->print(
            qq{<li class="open"><a href="}, $nav_uri,
            qq{?nav|adminSystem_cb=0">}, $lang->maketext('System'),
            qq{</a>}, qq{<ul class="items">},
        );
        $admin_links->($uri, qw(alert_type grp pref site user));
        $m->print(qq{</ul></li>});
    }

    else {
        # closed system submenu
        $m->print(
            qq{<li class="closed"><a href="}, $nav_uri,
            qq{?nav|adminSystem_cb=1">}, $lang->maketext('System'), qq{</a></li>}
        );
    }
    # End system submenus

    # Begin publishing submenus
    if ( $nav->{adminPublishing} ) {
        # Start the open publishing menu.
        $m->print(
            qq{<li class="open"><a href="}, $nav_uri,
            qq{?nav|adminPublishing_cb=0">}, $lang->maketext('Publishing'),
            qq{</a>}, qq{<ul class="items">},
        );

        $admin_links->($uri, qw(category contrib_type contrib element_type keyword
                                media_type output_channel source workflow));

        $m->print(
            qq{<li style="padding-top: 1em;">},
            $printLink->('/admin/control/publish', $uri, 'Bulk Publish'),
            qq{</li></ul></li>}
        );

    } else {
        # closed publishing submenu
        $m->print(
            qq{<li class="closed"><a href="}, $nav_uri,
        qq{?nav|adminPublishing_cb=1">}, $lang->maketext('Publishing'),
            qq{</a></li>}
        );
    }
    # End publishing submenus

    # Begin distribution submenus
    if ( $nav->{distSystem} ) {
        # Start the open distribution menu.
        $m->print(
            qq{<li class="open"><a href="}, $nav_uri,
            qq{?nav|distSystem_cb=0">}, $lang->maketext('Distribution'),
            qq{</a>}, qq{<ul class="items">},
        );

        $admin_links->($uri, qw(dest job));

        $m->print(qq{</ul></li>});
    } else {
        $m->print(
            qq{<li class="closed"><a href="}, $nav_uri,
        qq{?nav|distSystem_cb=1">}, $lang->maketext('Distribution'),
            qq{</a></li>}
        );
    }
    # End distribution submenus

    $m->print(qq{</ul></li>});
} else {
# closed admin state
    $m->print(
        qq{<li id="admin" class="closed"><a href="}, $nav_uri,
        qq{?nav|admin_cb=1">}, $lang->maketext('Admin'), qq{</a></li>}
    );
}
# End Admin --------------------------------------
$m->print(qq{</ul>});
</%perl>
</body>
</html>
<%doc>

###############################################################################

=head1 NAME

sideNav.mc

=head1 SYNOPSIS

<& "/widgets/wrappers/sharky/sideNav.mc" &>

=head1 DESCRIPTION

Based on information in the 'nav' state, display a contextually 
appropriate side navigation bar.

=cut

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

</%doc>
