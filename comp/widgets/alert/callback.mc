<%doc>
###############################################################################

=head1 NAME

/widgets/alert/callback.mc - My Alerts Callback.

=head1 VERSION

$Revision: 1.6 $

=head1 DATE

$Date: 2002-05-20 03:21:58 $

=head1 SYNOPSIS

  $m->comp('/widgets/alert/callback.mc', %ARGS);

=head1 DESCRIPTION

This element is called by submits from the My Alerts Profile, where one or
more alerts have been marked for acknowledgment.

</%doc>

<%once>;
my $type = 'recip';
my $class = get_package_name($type);
my $atype = 'alert';
my $disp_name = get_disp_name($atype);
my $pl_name = get_class_info($atype)->get_plural_name;
my %num = ( 1 => 'One',
	    2 => 'Two',
	    3 => 'Three',
	    4 => 'Four',
            5 => 'Five',
	    6 => 'Six',
	    7 => 'Seven',
	    8 => 'Eight',
	    9 => 'Nine',
	    10 => 'Ten'
	  );
</%once>

<%args>
$widget
$field
$param
</%args>

<%init>;
my $ids;
if ($field eq "$widget|ack_cb") {
    $ids = mk_aref($param->{recip_id});
} elsif ($field eq "$widget|ack_all_cb") {
    $ids = $class->list_ids({ user_id => get_user_id(), ack_time => undef });
} else {
    return;
}
$class->ack_by_id(@$ids);
my $c = @$ids;
my $disp = $c == 1 ? $disp_name : $pl_name;
$c = $num{$c} || $c;
add_msg("$c $disp acknowledged.") if $c;
set_redirect(last_page());
</%init>
