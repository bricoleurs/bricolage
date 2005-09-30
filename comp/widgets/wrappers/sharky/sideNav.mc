<%args>
$nav   => undef
$uri   => undef
$debug => undef
</%args>
<%once>;
my $disp = { map { $_ => get_disp_name($_) }
  qw(story media formatting) };
my $pl_disp = {
    map { $_ => get_class_info($_)->get_plural_name }
        qw(story media formatting pref user grp output_channel contrib
           contrib_type site workflow category element_type
           media_type source dest job alert_type keyword)
};

my $printLink = sub {
    my ($href, $uri, $caption, $no_translation) = @_;
    $caption = $no_translation ? $caption : $lang->maketext($caption);
    my @href = split(/\//, $href);
    my @uri = split(/\//, $uri);
    # Make sure we have something to eq to.
    for (1..5) { $uri[$_] = '' unless defined $uri[$_] }
    my $isLink = 1;
    my $out = '';
    my $style;

    if ($uri[1] eq "admin") {
        $style = qq{ class="selected"} if ($uri[1] eq $href[1] && $uri[3] eq $href[3]);
        # disable link in admin/manager when we have a full url match
        $isLink = ($uri[2] eq $href[2]) ? 0:1;
        $isLink = 1 if ($uri[3] eq "element_type" && defined $uri[4]);
    } else {
        if ($uri[3] eq "desk") {
            $style = qq{ class="selected"} if $uri[1] eq $href[1] && $uri[3] eq $href[3]
              && $uri[4] eq $href[4] && $uri[5] eq $href[5];
        } elsif ($uri[2] eq "manager" || $uri[2] eq "profile" || $uri[2] eq "active") {
            $style = qq{ class="selected"} if $uri[1] eq $href[1] && $uri[2] eq $href[2]
              && $uri[3] eq $href[3] && $uri[4] eq $href[4];
        }
    }
    if ($style =~ "selected" && !$isLink) {
        $out .= qq {<span$style>$caption</span>};
    } else {
        $out .= qq {<a href="$href" target="_parent"$style>$caption</a>};
    }
    return $out;
};
</%once>
<%perl>;
my $site_id = $c->get_user_cx(get_user_id);
# Make sure we always have a site ID. If the server has just been restarted,
# then site_context may not have been executed yet. So execute it to get the
# site ID.
$site_id = $m->comp('/widgets/site_context/site_context.mc', display => 0)
  unless defined $site_id;

my $workflows = $c->get('__WORKFLOWS__'. $site_id);

$uri ||= $r->uri;
$uri = '/workflow/profile/workspace' unless $uri && $uri ne '/';

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

        my $wf = { type    => $w->get_type,
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
window.onload = function () {
    var workspace = document.getElementById("workspace");
    var workspaceAnchor = workspace.getElementsByTagName("a")[0];
    workspaceAnchor.className = (parent.location.pathname.indexOf("workspace") != -1) ? "open" : "closed";
    resizeframe();
}
</script>
</head>
<body id="navFrame">
<%perl>
# Begin Workflows -------------------------------------
$m->out(qq{<ul id="nav">});
$m->out(qq{<li id="workspace"><a class="closed" href="/workflow/profile/workspace/" target="_parent" title="My Workspace">My Workspace</a></li>});
$m->out(qq{<li id="workflows">});
$m->out(qq{<ul class="submenu">});
# iterate thru workflows
foreach my $wf (@$workflows) {
    next if $site_id && $site_id != $wf->{site_id};
    # Check permissions.
    next unless chk_authz(0, READ, 1, @{ $wf->{gids} });

    if ( $nav->{"workflow-$wf->{id}"} ) { # show open workflow

    $m->out(qq{<li class="open"><a href="} . $r->uri . qq{?nav|workflow_cb=0&navwfid=} . $wf->{id} . qq{">} . $wf->{name} . qq{</a>});
    # actions/desks/publish items for this workflow
    my $can_create = chk_authz(0, CREATE, 1, @{ $wf->{desks}[0][2] });
    
    # actions
    $m->out(qq{<ul class="sections">});
    $m->out(qq{<li>} . $lang->maketext('Actions'));
        $m->out(qq{<ul class="items">});
        if ($wf->{type} == TEMPLATE_WORKFLOW) {
            $m->out(qq{<li>} . &$printLink("/workflow/profile/templates/new/$wf->{id}", $uri, "New $disp->{formatting}") . qq{</li>}) if ($can_create);
            $m->out(qq{<li>} . &$printLink("/workflow/manager/templates/$wf->{id}", $uri, "Find $pl_disp->{formatting}") . qq{</li>});
            $m->out(qq{<li>} . &$printLink("/workflow/active/templates/$wf->{id}", $uri, "Active $pl_disp->{formatting}") . qq{</li>});
        } elsif ($wf->{type} == STORY_WORKFLOW) {
            $m->out(qq{<li>} . &$printLink("/workflow/profile/story/new/$wf->{id}", $uri, "New $disp->{story}") . qq{</li>}) if ($can_create);
            $m->out(qq{<li>} . &$printLink("/workflow/profile/alias/story/$wf->{id}", $uri, "New Alias") . qq{</li>});
            $m->out(qq{<li>} . &$printLink("/workflow/manager/story/$wf->{id}", $uri, "Find $pl_disp->{story}") . qq{</li>});
            $m->out(qq{<li>} . &$printLink("/workflow/active/story/$wf->{id}", $uri, "Active $pl_disp->{story}") . qq{</li>});
        } elsif ($wf->{type} == MEDIA_WORKFLOW) {
            $m->out(qq{<li>} . &$printLink("/workflow/profile/media/new/$wf->{id}", $uri, "New $disp->{media}") . qq{</li>}) if ($can_create);
            $m->out(qq{<li>} . &$printLink("/workflow/profile/alias/media/$wf->{id}", $uri, "New Alias") . qq{</li>});
            $m->out(qq{<li>} . &$printLink("/workflow/manager/media/$wf->{id}", $uri, "Find $pl_disp->{media}") . qq{</li>});
            $m->out(qq{<li>} . &$printLink("/workflow/active/media/$wf->{id}", $uri, "Active $pl_disp->{media}") . qq{</li>});
        }
        $m->out(qq{</ul>});
    $m->out(qq{</li>});
    # desks
    $m->out(qq{<li>} . $lang->maketext('Desks'));
        $m->out(qq{<ul class="items">});
        foreach my $d (@{$wf->{desks}}) {
            next unless chk_authz(0, READ, 1, @{ $d->[2] });
            $m->out(qq{<li>} . &$printLink("/workflow/profile/desk/$wf->{id}/$d->[0]/", $uri, $d->[1], 1) . qq{</li>});
        }
        $m->out(qq{</ul>});
    $m->out(qq{</li>});
    $m->out(qq{</ul>});
    $m->out(qq{</li>});
    } else { # closed state
        $m->out(qq{<li class="closed"><a href="} . $r->uri . qq{?nav|workflow_cb=1&navwfid=} . $wf->{id} . qq{">} . $wf->{name} . qq{</a></li>});
    }
}
$m->out(qq{</ul>});
$m->out(qq{</li>});
# End Workflows -------------------------------------

# Begin Admin --------------------------------------
# First, admin section top graphic
if ( $nav->{admin} ) {
# admin always get inactive bg color, but arrow varies
$m->out(qq{<li id="admin" class="open"><a href="} . $r->uri . qq{?nav|admin_cb=0">} . $lang->maketext('Admin') . qq{</a>});
$m->out(qq{<ul class="submenu">});
# Begin system submenus
if ( $nav->{adminSystem} ) { # open system submenu
    $m->out(qq{<li class="open"><a href="} . $r->uri . qq{?nav|adminSystem_cb=0">} . $lang->maketext('System') . qq{</a>});
        $m->out(qq{<ul class="items">});
        $m->out(qq{<li>} . &$printLink('/admin/manager/pref', $uri, $pl_disp->{pref}). qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/user', $uri, $pl_disp->{user}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/grp', $uri, $pl_disp->{grp}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/site', $uri, $pl_disp->{site}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/alert_type', $uri, $pl_disp->{alert_type}) . qq{</li>});
        $m->out(qq{</ul>});
    $m->out(qq{</li>});
} else { # closed system submenu
    $m->out(qq{<li class="closed"><a href="} . $r->uri . qq{?nav|adminSystem_cb=1">} . $lang->maketext('System') . qq{</a></li>});
}
# End system submenus

# Begin publishing submenus
if ( $nav->{adminPublishing} ) { #open publishing submenu
    $m->out(qq{<li class="open"><a href="} . $r->uri . qq{?nav|adminPublishing_cb=0">} . $lang->maketext('Publishing') . qq{</a>});
        $m->out(qq{<ul class="items">});
        $m->out(qq{<li>} . &$printLink('/admin/manager/output_channel', $uri, $pl_disp->{output_channel}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/contrib', $uri, $pl_disp->{contrib}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/contrib_type', $uri, $pl_disp->{contrib_type}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/workflow', $uri, $pl_disp->{workflow}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/category', $uri, $pl_disp->{category}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/element_type', $uri, $pl_disp->{element_type}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/media_type', $uri, $pl_disp->{media_type}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/source', $uri, $pl_disp->{source}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/keyword', $uri, $pl_disp->{keyword}) . qq{</li>});
        $m->out(qq{<li style="padding-top: 1em;">} . &$printLink('/admin/control/publish', $uri, 'Bulk Publish') . qq{</li>});
        $m->out(qq{</ul>});
    $m->out(qq{</li>});
} else { # closed publishing submenu
    $m->out(qq{<li class="closed"><a href="} . $r->uri . qq{?nav|adminPublishing_cb=1">} . $lang->maketext('Publishing') . qq{</a></li>});
}
# End publishing submenus

# Begin distribution submenus
if ( $nav->{distSystem} ) { # open distribution submenu
    $m->out(qq{<li class="open"><a href="} . $r->uri . qq{?nav|distSystem_cb=0">} . $lang->maketext('Distribution') . qq{</a>});
        $m->out(qq{<ul class="items">});
        $m->out(qq{<li>} . &$printLink('/admin/manager/dest', $uri, $pl_disp->{dest}) . qq{</li>});
        $m->out(qq{<li>} . &$printLink('/admin/manager/job', $uri, $pl_disp->{job}) . qq{</li>});
        $m->out(qq{</ul>});
    $m->out(qq{</li>});
} else { # closed distribution submenu
    $m->out(qq{<li class="closed"><a href="} . $r->uri . qq{?nav|distSystem_cb=1">} . $lang->maketext('Distribution') . qq{</a></li>});
}
# End distribution submenus
    
    $m->out(qq{</ul>});
$m->out(qq{</li>});
} else { # closed admin state
$m->out(qq{<li id="admin" class="closed"><a href="} . $r->uri . qq{?nav|admin_cb=1">} . $lang->maketext('Admin') . qq{</a></li>});
}
# End Admin --------------------------------------
$m->out(qq{</ul>});
</%perl>

% # begin debug widget
% if (Bric::Config::QA_MODE && $debug) {
<br />
<hr/>
<& /widgets/qa/qa.mc &>
<br />
% }
% # end debug widget
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
