<%once>;
my $type = 'site';
my $disp_name = get_disp_name($type);
</%once>
<%args>
$widget
$param
$field
$obj
$class
</%args>
<%init>
return unless $field eq "$widget|save_cb";
# Grab the site object.
my $site = $obj;

if ($param->{delete}) {
    # Deactivate it.
    $site->deactivate;
    $site->save;
    $c->set_lmu_time;
    $c->set('__SITES__', 0);
    $c->set('__WORKFLOWS__' . $site->get_id, 0);
    log_event("${type}_deact", $site);
    set_redirect('/admin/manager/site');
    add_msg($lang->maketext("$disp_name profile &quot;[_1]&quot; deleted.",
                            $param->{name}));
    return;
}

eval {
    # Set the main attributes.
    $site->set_description($param->{description});
    $site->set_name($param->{name});
    $site->set_domain_name($param->{domain_name});
    $site->save;
    $c->set('__SITES__', 0);
    $c->set('__WORKFLOWS__' . $site->get_id, 0);
    add_msg($lang->maketext("$disp_name profile [_1] saved.", $param->{name}));
    log_event($type . '_save', $site);

    # Take care of group managment.
    if ($param->{add_grp} or $param->{rem_grp}) {

        my @add_grps = map { Bric::Util::Grp->lookup({ id => $_ }) }
          @{mk_aref($param->{add_grp})};
        my @del_grps = map { Bric::Util::Grp->lookup({ id => $_ }) }
          @{mk_aref($param->{rem_grp})};

        # Assemble the new member information.
        foreach my $grp (@add_grps) {
            # Add the user to the group.
            $grp->add_members([{ obj => $site }]);
            $grp->save;
            log_event('grp_save', $grp);
        }

        foreach my $grp (@del_grps) {
            # Deactivate the user's group membership.
            foreach my $mem ($grp->has_member({ obj => $site })) {
                $mem->deactivate;
                $mem->save;
            }
            $grp->save;
            log_event('grp_save', $grp);
        }
    }
    set_redirect('/admin/manager/site');
};

# Return if there are no errors.
my $err = $@ or return;
# Catch Error exctpions and turn them into error messages.
die $err unless isa_bric_exception($err, 'Error');
add_msg($lang->maketext($err->maketext));
return $site;

</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/profile/site.mc - Processes submits from Site Profile

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2003-07-18 23:45:14 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/site.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Site Profile page.

=cut

</%doc>
