<%args>
$nav   => undef
$uri   => undef
$debug => undef
</%args>
<%once>;
my $disp = { map { $_ => get_disp_name($_) }
  qw(story media formatting) };
my $pl_disp = { map { $_ => get_class_info($_)->get_plural_name }
  qw(story media formatting pref user grp output_channel contrib contrib_type site
     workflow category element element_type media_type source dest job alert_type
     keyword) };

my $printLink = sub {
    my ($href, $uri, $caption, $no_translation) = @_;
    $caption = $no_translation ? $caption : $lang->maketext($caption);
    my @href = split(/\//, $href);
    my @uri = split(/\//, $uri);
    # Make sure we have something to eq to.
    for (1..5) { $uri[$_] = '' unless defined $uri[$_] }
    my $isLink = 1;
    my $sectionColor = $href[1] eq "admin" ? "orange" : "blue";
    my $out = '';
    my $style = "$sectionColor" . "Link";

    if ($uri[1] eq "admin") {
        $style .= " selected" if ($uri[1] eq $href[1] && $uri[3] eq $href[3]);
        # disable link in admin/manager when we have a full url match
        $isLink = ($uri[2] eq $href[2]) ? 0:1;
        $isLink = 1 if ($uri[3] eq "element" && defined $uri[4]);
    } else {
        if ($uri[3] eq "desk") {
            $style .= " selected" if $uri[1] eq $href[1] && $uri[3] eq $href[3]
              && $uri[4] eq $href[4] && $uri[5] eq $href[5];
        } elsif ($uri[2] eq "manager" || $uri[2] eq "profile" || $uri[2] eq "active") {
            $style .= " selected" if $uri[1] eq $href[1] && $uri[2] eq $href[2]
              && $uri[3] eq $href[3] && $uri[4] eq $href[4];
        }
    }
    if ($style =~ "selected" && !$isLink) {
        $out .= qq {<span class="$style">$caption</span>};
    } else {
        $out .= qq {<a href="$href" class="$style" target="_parent">$caption</a>};
    }
    return $out;
};
</%once>
<%perl>;
my $site_id = $c->get_user_cx(get_user_id);
# Make sure we always have a site ID. If the server has just been restarted,
# then sit_context may not have been executed yet. So execute it to get the
# site ID.
$site_id = $m->comp('/widgets/site_context/site_context.mc', display => 0)
  unless defined $site_id;
# Figure out where we are (assume it's "My Workspace").
my ($section, $mode, $type) = split '/', substr($ARGS{uri}, 1);
($section, $mode, $type) = qw(workflow profile workspace) unless $section;

my $workflowGraphic           = $section eq 'admin'
  ? "/media/images/$lang_key/workflow_admin.gif"
  : "/media/images/$lang_key/workflow_workflow.gif";
my $workspaceGraphic          = $type eq "workspace"
  ? "/media/images/$lang_key/my_workspace_on.gif"
  : "/media/images/$lang_key/my_workspace_off.gif";

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
  <script type="text/javascript">
    function resizeframe() {
      var ifrm = parent.document.getElementById("sideNav");
      if (window.opera) {
        ifrm.style.height = document.body.scrollHeight + "px";
      } else {
        ifrm.style.height = document.body.offsetHeight + "px";
      }
    }
  </script>
</head>
<body id="navFrame" onload="resizeframe();">
<div class="btn-workflow"><img src="<% $workflowGraphic %>" alt="Workflow" /></div>
<div class="btn-workspace"><a href="/workflow/profile/workspace/" target="_parent"><img src="<% $workspaceGraphic %>" alt="Workspace"></a></div>

% # Begin Workflows -------------------------------------
<ul class="workflows">
<%perl>;
# iterate thru workflows
foreach my $wf (@$workflows) {
    next if $site_id && $site_id != $wf->{site_id};
    # Check permissions.
    next unless chk_authz(0, READ, 1, @{ $wf->{gids} });

    if ( $nav->{"workflow-$wf->{id}"} ) { # show open workflow
</%perl>
    <li class="open"><a href="<% $r->uri %>?nav|workflow_cb=0&navwfid=<% $wf->{id} %>"><% $wf->{name} %></a>

% # actions/desks/publish items for this workflow
% my $can_create = chk_authz(0, CREATE, 1, @{ $wf->{desks}[0][2] });
% # actions
        <ul class="submenu">
            <li><% $lang->maketext('Actions') %>
                <ul class="items">
%               if ($wf->{type} == TEMPLATE_WORKFLOW) {
%                   if ($can_create) {
                    <li><% &$printLink("/workflow/profile/templates/new/$wf->{id}", $uri, "New $disp->{formatting}") %></li>
%                   }
                    <li><% &$printLink("/workflow/manager/templates/$wf->{id}", $uri, "Find $pl_disp->{formatting}") %></li>
                    <li><% &$printLink("/workflow/active/templates/$wf->{id}", $uri, "Active $pl_disp->{formatting}") %></li>
%               } elsif ($wf->{type} == STORY_WORKFLOW) {
%                   if ($can_create) {
                    <li><% &$printLink("/workflow/profile/story/new/$wf->{id}", $uri, "New $disp->{story}") %></li>
%                   }
                    <li><% &$printLink("/workflow/profile/alias/story/$wf->{id}", $uri, "New Alias") %></li>
                    <li><% &$printLink("/workflow/manager/story/$wf->{id}", $uri, "Find $pl_disp->{story}") %></li>
                    <li><% &$printLink("/workflow/active/story/$wf->{id}", $uri, "Active $pl_disp->{story}") %></li>
%               } elsif ($wf->{type} == MEDIA_WORKFLOW) {
%                   if ($can_create) {
                    <li><% &$printLink("/workflow/profile/media/new/$wf->{id}", $uri, "New $disp->{media}") %></li>
%                   }
                    <li><% &$printLink("/workflow/profile/alias/media/$wf->{id}", $uri, "New Alias") %></li>
                    <li><% &$printLink("/workflow/manager/media/$wf->{id}", $uri, "Find $pl_disp->{media}") %></li>
                    <li><% &$printLink("/workflow/active/media/$wf->{id}", $uri, "Active $pl_disp->{media}") %></li>
%               }
                </ul>
            </li>
% # desks
            <li><% $lang->maketext('Desks') %>
                <ul class="items">
%               foreach my $d (@{$wf->{desks}}) {
%                   next unless chk_authz(0, READ, 1, @{ $d->[2] });
                    <li><% &$printLink("/workflow/profile/desk/$wf->{id}/$d->[0]/", $uri, $d->[1], 1) %></li>
%               }
                </ul>
            </li>
        </ul>
    </li>
%   } else { # closed state
    <li class="closed"><a href="<% $r->uri %>?nav|workflow_cb=1&navwfid=<% $wf->{id} %>"><% $wf->{name} %></a></li>
%   }
% }
</ul>
% # End Workflows -------------------------------------
% # Begin Admin --------------------------------------
<ul class="admin">
% # First, admin section top graphic
% if ( $nav->{admin} ) {
% # admin always get inactive bg color, but arrow varies
    <li class="open"><a href="<% $r->uri . "?nav|admin_cb=0" %>"><% $lang->maketext('Admin') %></a>
        <ul class="submenu">
% # Begin system submenus
% if ( $nav->{adminSystem} ) { # open system submenu
            <li class="open"><a href="<% $r->uri . "?nav|adminSystem_cb=0" %>"><% $lang->maketext('System') %></a>
                <ul class="items">
                    <li><% &$printLink('/admin/manager/pref', $uri, $pl_disp->{pref}) %>
                    <li><% &$printLink('/admin/manager/user', $uri, $pl_disp->{user}) %>
                    <li><% &$printLink('/admin/manager/grp', $uri, $pl_disp->{grp}) %>
                    <li><% &$printLink('/admin/manager/site', $uri, $pl_disp->{site}) %>
                    <li><% &$printLink('/admin/manager/alert_type', $uri, $pl_disp->{alert_type}) %>
%                   # Show the change users link if we are an admin.
                    <li style="padding-top: 1em;"><% &$printLink('/admin/control/change_user', $uri, 'User Override') %>
                </ul>
            </li>
% } else { # closed system submenu
            <li class="closed"><a href="<% $r->uri . "?nav|adminSystem_cb=1" %>"><% $lang->maketext('System') %></a></li>
% }
% # End system submenus
% # begin publishing submenus   
% if ( $nav->{adminPublishing} ) { #open publishing submenu
            <li class="open"><a href="<% $r->uri . "?nav|adminPublishing_cb=0" %>"><% $lang->maketext('Publishing') %></a>
                <ul class="items">
                    <li><% &$printLink('/admin/manager/output_channel', $uri, $pl_disp->{output_channel}) %></li>
                    <li><% &$printLink('/admin/manager/contrib', $uri, $pl_disp->{contrib}) %></li>
                    <li><% &$printLink('/admin/manager/contrib_type', $uri, $pl_disp->{contrib_type}) %></li>
                    <li><% &$printLink('/admin/manager/workflow', $uri, $pl_disp->{workflow}) %></li>
                    <li><% &$printLink('/admin/manager/category', $uri, $pl_disp->{category}) %></li>
                    <li><% &$printLink('/admin/manager/element', $uri, $pl_disp->{element}) %></li>
                    <li><% &$printLink('/admin/manager/element_type', $uri, $pl_disp->{element_type}) %></li>
                    <li><% &$printLink('/admin/manager/media_type', $uri, $pl_disp->{media_type}) %></li>
                    <li><% &$printLink('/admin/manager/source', $uri, $pl_disp->{source}) %></li>
                    <li><% &$printLink('/admin/manager/keyword', $uri, $pl_disp->{keyword}) %></li>
                    <li style="padding-top: 1em;"><% &$printLink('/admin/control/publish', $uri, 'Bulk Publish') %></li>
                </ul>
            </li>
% } else { # closed publishing submenu
            <li class="closed"><a href="<% $r->uri . "?nav|adminPublishing_cb=1" %>"><% $lang->maketext('Publishing') %></a></li>
% }
% # End publishing submenus
% # Begin distribution submenus
% if ( $nav->{distSystem} ) { # open distribution submenu
            <li class="open"><a href="<% $r->uri . "?nav|distSystem_cb=0" %>"><% $lang->maketext('Distribution') %></a>
                <ul class="items">
                    <li><% &$printLink('/admin/manager/dest', $uri, $pl_disp->{dest}) %></li>
                    <li><% &$printLink('/admin/manager/job', $uri, $pl_disp->{job}) %></li>
                </ul>
            </li>
% } else { # closed distribution submenu
            <li class="closed"><a href="<% $r->uri . "?nav|distSystem_cb=1" %>"><% $lang->maketext('Distribution') %></a></li>
% }
% # End distribution submenus
        </ul>
    </li>
% } else { # closed admin state
    <li class="closed"><a href="<% $r->uri . "?nav|admin_cb=1" %>"><% $lang->maketext('Admin') %></a></li>
% }
% # End Admin --------------------------------------
</ul>

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
