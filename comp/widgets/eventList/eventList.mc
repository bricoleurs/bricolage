%#-- Perl Section --#
<%perl>;
$m->comp('/widgets/listManager/listManager.mc',
	 object => 'event',
	 constrain => $constrain,
	 fields => [qw(name user_id timestamp attr)],
         alter => { attr => $attr_alter, user_id => $trig_alter },
	 profile => $prof_sub,
	 addition => undef,
	 title => $title,
	 select => undef);
(%users, $fmt) = ();
</%perl>


%#-- Once Section --#
<%once>;
my (%users, $fmt);
my $attr_alter = sub {
    return unless $_[0];
    my $ret = '';
    while (my ($k, $v) = each %{$_[0]}) {
        $ret .= $ret ? "<br />$k: $v" : "$k: $v";
    }
    return $ret;
};

my $trig_alter = sub {
    my $u = $users{$_[0]} ||= $_[1]->get_user;
    $u->format_name($fmt);
};

my $pl_adisp = get_class_info('alert')->get_plural_name;
</%once>

%#-- Args Section --#
<%args>
$object
$obj_id
$constrain => undef
$title => undef
$alert_uri => undef
</%args>

%#-- Init Section --#
<%init>;
my $class = get_class_info($object);
#chk_authz($class->get_pkg_name->lookup({ id => $obj_id }), READ);
@{$constrain}{qw(obj_id class_id)} = ($obj_id, $class->get_id);
$title ||= '';

my $prof_sub = sub {
    return unless $alert_uri && $_[0]->has_alerts;
    return [$pl_adisp, "$alert_uri/" . $_[0]->get_id, ''];
};
$fmt = get_pref('List Name Format');
</%init>

%#-- Documentation --#
<%doc>
###############################################################################

=head1 NAME

/widgets/event/eventList.mc - The Event List Widget.

=head1 VERSION

$Revision: 1.4 $

=head1 DATE

$Date: 2001-11-29 00:28:51 $

=head1 SYNOPSIS

  $m->comp('/widgets/eventList/eventList.mc', object => 'user',
           obj_id => $id);

=head1 DESCRIPTION

This widget uses listManager to display a list of events for an object. Here are
its supported arguments:

=over 4

=item *

object - Required. A short name for the type of object for which to look up
events, e.g. 'person' translates to the package name 'Bric::Biz::Person'. This
mapping is maintained in the 'class' table, where the short name is the
'disp_name' column and the package name is in the 'pkg_name' column.

=item *

obj_id - Reuired. The ID of the object of the type represented by the "object"
argument for which to look up events.

=item *

constrain - Optional. An anonymous hash of constraining arguments to be passed
to Bric::Util::Event->list().

=item *

alert_uri - URI of a page that uses the alertList widget to display alerts for a
given event. The link to Alerts will only be present for those events that have
alerts associated with them.

=back

</%doc>
