<%args>
$nav   => undef
$uri   => undef
$debug => undef
</%args>

<%once>;
my $disp = { map { $_ => get_disp_name($_) }
  qw(story media formatting) };
my $pl_disp = { map { $_ => get_class_info($_)->get_plural_name }
  qw(story media formatting pref user grp output_channel contrib contrib_type
     workflow category element element_type source dest job alert_type) };

my $printLink = sub {
    my ($href, $uri, $caption) = @_;
    my @href = split(/\//, $href);
    my @uri = split(/\//, $uri);
    # Make sure we have something to eq to.
    for (1..5) { $uri[$_] = '' unless defined $uri[$_] }
    my $isLink = 1;
    my $sectionColor = $href[1] eq "admin" ? "orange" : "blue";
    my $out = '';
    my $style = "$sectionColor" . "Link";

    if ($uri[1] eq "admin") {
	$style .= "Bold" if ($uri[1] eq $href[1] && $uri[3] eq $href[3]);
	# disable link in admin/manager when we have a full url match
	$isLink = ($uri[2] eq $href[2]) ? 0:1;
	$isLink = 1 if ($uri[3] eq "element" && defined $uri[4]);
    } else {
	if ($uri[3] eq "desk") {
	    $style .= "Bold" if $uri[1] eq $href[1] && $uri[3] eq $href[3]
	      && $uri[4] eq $href[4] && $uri[5] eq $href[5];
	} elsif ($uri[2] eq "manager" || $uri[2] eq "profile") {
	    $style .= "Bold" if $uri[1] eq $href[1] && $uri[2] eq $href[2]
	      && $uri[3] eq $href[3] && $uri[4] eq $href[4];
	}
    }
    if ($style =~ /Bold/ && !$isLink) {
       $out .= qq {<span class="$style">$caption</span><br />};
    } else {
	$out .= qq {<a href="#" class="$style" onClick="return doLink('$href')">$caption</a><br />};
    }
    return $out;
};
</%once>

<%perl>
# Figure out where we are (assume it's "My Workspace").
my ($section, $mode, $type) = $m->comp("/lib/util/parseUri.mc");
($section, $mode, $type) = qw(workflow profile workspace) unless $section;

my $agent                     = $m->comp("/widgets/util/detectAgent.mc");
my $workflowIndent            = 25;
my $adminIndent               = 25;
my $tabHeight                 = "height=20";
my $numLinks                  = $c->get("__NUM_LINKS__") || 0;
my $workflowGraphic           = ( $section eq 'admin') ? "/media/images/workflow_admin.gif"
                                                       : "/media/images/workflow_workflow.gif";
my $workspaceGraphic          = $type eq "workspace"
  ? "/media/images/my_workspace_on.gif" : "/media/images/my_workspace_off.gif";

my $workflows = $c->get('__WORKFLOWS__');

$uri ||= $r->uri;
$uri = '/workflow/profile/workspace' unless $uri && $uri ne '/';

$nav = get_state_data("nav") if (!$nav);
unless ($workflows) {
    # The cache hasn't been loaded yet. Load it.
    $workflows = [];
    my $tmp = 0;

    foreach my $w (Bric::Biz::Workflow->list) {
	# account for New/Find/Active links and whitespace
	$tmp += 6;
	# account for desks
	my @desks = map { [ $_->get_id, $_->get_name ] } $w->allowed_desks;
	$tmp += scalar(@desks);
	my @gids = $w->get_grp_ids;

	my $wf = { type  => $w->get_type,
		   id    => $w->get_id,
		   name  => $w->get_name,
		   desks => \@desks,
		   gids  => \@gids
		 };
	push @$workflows, $wf;
    }
    # account for open admin links
    $tmp += 16;
    $c->set("__NUM_LINKS__", $tmp) if $numLinks != $tmp;
    $c->set('__WORKFLOWS__', $workflows);
}

</%perl>
% if (!DISABLE_NAV_LAYER && ($agent->{os} ne "SomeNix" || $agent->{browser} eq 'Mozilla')) {
<html>
<meta http-equiv="Expires" content="Mon, 06, Jan 1990 00:00:01 GMT">
<head>
</head>

% if ($agent->{browser} ne "Netscape") {
    <script language="javascript">
    function doNav(callback) {
	document.location.href = callback;
	return false;
    }

    function doLink(link) {
	parent.window.location.href = link;
	return false;
    }
    </script>
    <& "/widgets/wrappers/sharky/css.mc" &>
% }
<body marginwidth=0 marginheight=0 leftmargin=0 topmargin=0 bgcolor="#666633">
% }

<table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=130>
<tr>

  <td><img src="<% $workflowGraphic %>" width=150 height=22></td>
</tr>
<tr>
  <td bgcolor="white"><img src="/media/images/spacer.gif" width=1 height=2></td>
</tr>
</table>

<table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
<tr>
  <td class=sideNavActiveCell><a class=sideNavHeaderBold href="#" onClick="return doLink('/workflow/profile/workspace/')"><img src="<% $workspaceGraphic %>" width=150 height=20 border=0></a></td>
</tr>
<tr>
  <td bgcolor="white"><img src="/media/images/spacer.gif" width=1 height=2></td>
</tr>
</table>

<%perl>


# Begin Workflows -------------------------------------
# iterate thru workflows
foreach my $wf (@$workflows) {
    # Check permissions.
    next unless chk_authz(0, READ, 1, @{ $wf->{gids} });
    my $esc_name = escape_uri($wf->{name});

    $m->out("<table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>\n");

    if ( $nav->{"workflow-". $esc_name} ) { # show open workflow
	$m->out("<tr class=sideNavInactiveCell>\n");
	$m->out(qq{ <td><img src="/media/images/spacer.gif" width=10 height=5></td> } );
	$m->out("<td valign=middle $tabHeight width=15>");
	$m->out(qq {<a href="#" onClick="return doNav('} . $r->uri . qq {?nav|workflow-${esc_name}_cb=0')">});
	$m->out("<img src=\"/media/images/dkgreen_arrow_open.gif\" width=13 height=9 border=0 hspace=0></a></td>\n");
	$m->out("<td valign=middle $tabHeight width=135>");
	$m->out(qq {<a href="#" class=sideNavHeaderBold onClick="return doNav('} . $r->uri . qq {?nav|workflow-${esc_name}_cb=0')">});
	$m->out(uc ( $wf->{name} )  . "</a>");
	$m->out("</td>\n</tr>");

	# actions/desks/publish items for this workflow
	</%perl>
	</table>

% # actions
          <table border=0 cellpadding=0 cellspacing=0 bgcolor="white">
	    <tr>
	      <td colspan=2><img src="/media/images/spacer.gif" width=150 height=10></td>
	    </tr>
	    <tr>
	      <td><img src="/media/images/spacer.gif" width=<% $workflowIndent %> height=1></td>
	      <td>
		<span class=workflowHeader>Actions</span><br />
%               if ($wf->{type} == TEMPLATE_WORKFLOW) {
                   <% &$printLink("/workflow/profile/templates/new/$wf->{id}", $uri, "New $disp->{formatting}") %>
		   <% &$printLink("/workflow/manager/templates/$wf->{id}", $uri, "Find $pl_disp->{formatting}") %>
	           <% &$printLink("/workflow/active/templates/$wf->{id}", $uri, "Active $pl_disp->{formatting}") %>
%               } elsif ($wf->{type} == STORY_WORKFLOW) {
	           <% &$printLink("/workflow/profile/story/new/$wf->{id}", $uri, "New $disp->{story}") %>
		   <% &$printLink("/workflow/manager/story/$wf->{id}/", $uri, "Find $pl_disp->{story}") %>
	           <% &$printLink("/workflow/active/story/$wf->{id}", $uri, "Active $pl_disp->{story}") %>
%               } elsif ($wf->{type} == MEDIA_WORKFLOW) {
                   <% &$printLink("/workflow/profile/media/new/$wf->{id}", $uri, "New $disp->{media}") %>
		   <% &$printLink("/workflow/manager/media/$wf->{id}/", $uri, "Find $pl_disp->{media}") %>
	           <% &$printLink("/workflow/active/media/$wf->{id}", $uri, "Active $pl_disp->{media}") %>
%               }
% # desks
                <img src="/media/images/spacer.gif" width=105 height=1>
		<span class=workflowHeader>Desks</span><br />
		<%perl>
                  foreach my $d (@{$wf->{desks}}) {
		      $m->out( &$printLink("/workflow/profile/desk/$wf->{id}/$d->[0]/", $uri, $d->[1]) );
		  }
		</%perl>
	      </td>
	    </tr>
	    <tr>
	      <td colspan=2><img src="/media/images/spacer.gif" width=150 height=10></td>
	    </tr>
	    </table>
	<%perl>
    } else { # closed state
	$m->out("<table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>\n");
	$m->out("<tr class=sideNavInactiveCell>\n");
	$m->out(qq{ <td><img src="/media/images/spacer.gif" width=10 height=5></td> } );
	$m->out("<td valign=middle $tabHeight width=140>");
	$m->out("<a class=sideNavHeader href=" . $r->uri . "?nav|workflow-${esc_name}_cb=1>");
	$m->out(qq {<a href="#" onClick="return doNav('} . $r->uri . qq {?nav|workflow-${esc_name}_cb=1')">});
	$m->out(qq{<img src="/media/images/mdgreen_arrow_closed.gif" width=8 height=13 border=0 hspace=2></a>\n});
	$m->out(qq {<a href="#" class=sideNavHeader onClick="return doNav('} . $r->uri . qq {?nav|workflow-${esc_name}_cb=1')">});
	$m->out( uc ( $wf->{name} )  . "</a></td>\n</tr>");
	$m->out("</table>\n");

    }
}

</%perl>

% # End Workflows -------------------------------------

% # Begin Admin --------------------------------------

% # First, admin section top graphic
% if ( $nav->{admin} ) {
% # admin always get inactive bg color, but arrow varies

  <table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
      <td bgcolor="white" colspan=2><img src="/media/images/spacer.gif" width=1 height=2></td>
    </tr>
    <tr>
      <td class=sideNavAdminCell <% $tabHeight %> valign="middle" width=24>
	<a href="#" onClick="return doNav('<% $r->uri . "?nav|admin_cb=0" %>')"><img src="/media/images/red_arrow_open.gif" width=16 height=11 border=0 hspace=4></a>
      </td>
      <td class=sideNavAdminCell <% $tabHeight %> valign="middle" width=126>
	<a class=sideNavHeaderBoldWhite href="#" onClick="return doNav('<% $r->uri . "?nav|admin_cb=0" %>')">ADMIN</a>
      </td>
    </tr>

  </table>


% # Begin system submenus


% if ( $nav->{adminSystem} ) { # open system submenu
    <table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
      <td class=sideNavInactiveCell width=9><img src="/media/images/spacer.gif" width=9 height=1></td>
      <td class=sideNavInactiveCell <% $tabHeight %> width=141><a href="#" onClick="return doNav('<% $r->uri . "?nav|adminSystem_cb=0" %>')">
        <img src="/media/images/dkgreen_arrow_open.gif" width=13 height=9 border=0></a>
	<a class=sideNavHeaderBold href="#" onClick="return doNav('<% $r->uri . "?nav|adminSystem_cb=0" %>')">SYSTEM</a>
      </td>
    </tr>

    <tr>
      <td colspan=2>
	<img src="/media/images/spacer.gif" width=150 height=3>
	<table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
	  <tr>
	    <td width=<% $adminIndent %>><img src="/media/images/spacer.gif" width=<% $adminIndent %> height=1></td>
	    <td width=<% 150 - $adminIndent %>>
	      <% &$printLink('/admin/manager/pref', $uri, $pl_disp->{pref}) %>
	      <% &$printLink('/admin/manager/user', $uri, $pl_disp->{user}) %>
	      <% &$printLink('/admin/manager/grp', $uri, $pl_disp->{grp}) %>
	      <% &$printLink('/admin/manager/alert_type', $uri, $pl_disp->{alert_type}) %>
%# Show the change users link if we are an admin.
%             if (user_is_admin()) {
	          <br />
                  <% &$printLink('/admin/control/change_user', $uri, 'User Override') %>
%             }
	    </td>
	  </tr>
        </table>
        <img src="/media/images/spacer.gif" width=150 height=3>
      </td>
    </tr>
    </table>
% } else { # closed system submenu
    <table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
      <td class=sideNavInactiveCell <% $tabHeight %> width=10><img src="/media/images/spacer.gif" width=10 height=1></td>
      <td class=sideNavInactiveCell <% $tabHeight %> width=140><a href="#"  href="#" onClick="return doNav('<% $r->uri . "?nav|adminSystem_cb=1" %>')">
	<img src="/media/images/mdgreen_arrow_closed.gif" width=8 height=13 border=0 hspace=2></a>
	<a class=sideNavHeader href="#" onClick="return doNav('<% $r->uri . "?nav|adminSystem_cb=1" %>')">SYSTEM</a>
      </td>
    </tr>
    </table>
% }

% # End system submenus


% # begin publishing submenus	

% if ( $nav->{adminPublishing} ) { #open publishing submenu
    <table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
      <td class=sideNavInactiveCell <% $tabHeight %> width=9><img src="/media/images/spacer.gif" width=9 height=1></td>
      <td class=sideNavInactiveCell <% $tabHeight %> width=141><a href="#" onClick="return doNav('<% $r->uri . "?nav|adminPublishing_cb=0" %>')">
        <img src="/media/images/dkgreen_arrow_open.gif" width=13 height=9 border=0></a>
	<a class=sideNavHeaderBold href="#"  onClick="return doNav('<% $r->uri . "?nav|adminPublishing_cb=0" %>')">PUBLISHING</a>
      </td>
    </tr>

    <tr>
      <td colspan=2>
	<img src="/media/images/spacer.gif" width=150 height=3>
	<table border=0 cellpadding=0 cellspacing=0 bgcolor="white" width=150>
	  <tr>
	    <td width=<% $adminIndent %>><img src="/media/images/spacer.gif" width=<% $adminIndent %> height=1></td>
	    <td width=<% 150 - $adminIndent %>>
	      <% &$printLink('/admin/manager/output_channel', $uri, $pl_disp->{output_channel}) %>
 	      <% &$printLink('/admin/manager/contrib', $uri, $pl_disp->{contrib}) %>
	      <% &$printLink('/admin/manager/contrib_type', $uri, $pl_disp->{contrib_type}) %>
	      <% &$printLink('/admin/manager/workflow', $uri, $pl_disp->{workflow}) %>
	      <% &$printLink('/admin/manager/category', $uri, $pl_disp->{category}) %>
	      <% &$printLink('/admin/manager/element', $uri, $pl_disp->{element}) %>
	      <% &$printLink('/admin/manager/element_type', $uri, $pl_disp->{element_type}) %>
	      <% &$printLink('/admin/manager/source', $uri, $pl_disp->{source}) %>
	    </td>
	  </tr>
        </table>
	<img src="/media/images/spacer.gif" width=150 height=3>
      </td>
    </tr>
    </table>
% } else { # closed publishing submenu
    <table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
      <td class=sideNavInactiveCell <% $tabHeight %> width=10><img src="/media/images/spacer.gif" width=10 height=2></td>
      <td class=sideNavInactiveCell <% $tabHeight %> width=140><a href="#"  onClick="return doNav('<% $r->uri . "?nav|adminPublishing_cb=1" %>')">
	<img src="/media/images/mdgreen_arrow_closed.gif" width=8 height=13 border=0 hspace=2></a>
	<a class=sideNavHeader href="#" onClick="return doNav('<% $r->uri . "?nav|adminPublishing_cb=1" %>')">PUBLISHING</a>
      </td>
    </tr>
    </table>
% }

% # End publishing submenus


% # Begin distribution submenus

% if ( $nav->{distSystem} ) { # open distribution submenu
    <table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
      <td class=sideNavInactiveCell <% $tabHeight %> width=9><img src="/media/images/spacer.gif" width=9 height=1></td>
      <td class=sideNavInactiveCell <% $tabHeight %> width=141><a href="#" onClick="return doNav('<% $r->uri . "?nav|distSystem_cb=0" %>')">
        <img src="/media/images/dkgreen_arrow_open.gif" width=13 height=9 border=0></a>
	<a class=sideNavHeaderBold href="#" onClick="return doNav('<% $r->uri . "?nav|distSystem_cb=0" %>')">DISTRIBUTION</a>
      </td>
    </tr>

    <tr>
      <td colspan=2>
	<img src="/media/images/spacer.gif" width=150 height=3>
	<table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
	  <tr>
	    <td width=<% $adminIndent %>><img src="/media/images/spacer.gif" width=<% $adminIndent %> height=1></td>
	    <td width=<% 150 - $adminIndent %>>
	      <% &$printLink('/admin/manager/dest', $uri, $pl_disp->{dest}) %>
	      <% &$printLink('/admin/manager/job', $uri, $pl_disp->{job}) %>
	    </td>
	  </tr>
        </table>
        <img src="/media/images/spacer.gif" width=130 height=3>
      </td>
    </tr>
    </table>
% } else { # closed distribution submenu
    <table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
      <td class=sideNavInactiveCell <% $tabHeight %> width=10><img src="/media/images/spacer.gif" width=10 height=1></td>
      <td class=sideNavInactiveCell <% $tabHeight %> width=140><a href="#" onClick="return doNav('<% $r->uri . "?nav|distSystem_cb=1" %>')">
	<img src="/media/images/mdgreen_arrow_closed.gif" width=8 height=13 border=0 hspace=2></a>
	<a class=sideNavHeader href="#" onClick="return doNav('<% $r->uri . "?nav|distSystem_cb=1" %>')">DISTRIBUTION</a>
      </td>
    </tr>
    </table>
% }

% # End distribution submenus


% } else { # closed admin state

  <table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
      <td colspan=2 bgcolor="white"><img src="/media/images/spacer.gif" width=1 height=2></td>
    </tr>
    <tr>
      <td class=sideNavAdminCell <% $tabHeight %> width=18><a href="#" onClick="return doNav('<% $r->uri . "?nav|admin_cb=1" %>')"><img src="/media/images/white_arrow_closed.gif" width=8 height=13 border=0 hspace=5></a></td>
      <td class=sideNavActiveCell <% $tabHeight %> width=132><a class=sideNavHeaderBoldWhite href="#" onClick="return doNav('<% $r->uri . "?nav|admin_cb=1" %>')">ADMIN</a></td>
    </tr>
  </table>
% }

% # Bottom of admin menu white spacer
<table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
<tr>
  <td bgcolor="white"><img src="/media/images/spacer.gif" width=1 height=2></td>
</tr>
</table>

% # End Admin --------------------------------------

% # begin debug widget
% if (Bric::Config::QA_MODE && $debug) {
<table border=0 cellpadding=0 cellspacing=0 bgcolor=white width=150>
    <tr>
        <td align="center" bgcolor=#666633><br /><hr/><& /widgets/qa/qa.mc &><br /></td>
    </tr>
</table>
% }
% # end debug widget

% if (!DISABLE_NAV_LAYER && ($agent->{os} ne "SomeNix" || $agent->{browser} eq 'Mozilla')) {
</body>
</html>
%}


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

$Revision: 1.6.2.4 $

=head1 DATE

$Date: 2002-02-23 01:49:14 $

</%doc>
