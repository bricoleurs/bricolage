%#-- Once Section --#
<%once>;
my (%users, $fmt);
my $cfg = { alert => { obj  => 'event',
		       pkg  => get_package_name('event'),
		       fields => [qw(timestamp subject message)],
		       pl_name => get_class_info('alert')->get_plural_name
                     },
            recip => { obj  => 'alert',
		       pkg  => get_package_name('alert'),
		       fields => [qw(user_id sent timestamp ack_time)],
		       pl_name => get_class_info('recip')->get_plural_name,
		       alter => { user_id => sub {
		                          my $u = $users{$_[0]} ||= $_[1]->get_user;
				          $u->format_name($fmt);
                                      },
				  sent => sub {
				          join(', ', map { $_->get_type } @{$_[0]} );
                                      }
                                },
                     }
          };
</%once>

%#-- Args Section --#
<%args>
$mode => 'alert'
$recip_url => undef
</%args>

%#-- Init Section --#
<%init>;
my $d = $cfg->{$mode};
my $key = "$d->{obj}_id";
my $obj = $ARGS{$d->{obj}} || $d->{pkg}->lookup({ id => $ARGS{$key} });
my $title = '&quot;' . $obj->get_name . "&quot; $d->{pl_name}";
$fmt = get_pref('List Name Format');

my $prof_sub = sub {
    return unless $recip_url;
    return ['Recipients', "$recip_url/" . $_[0]->get_id, ''];
};

$m->comp('/widgets/wrappers/table_top.mc', caption => $title );
$m->comp('/widgets/listManager/listManager.mc',
	 object => $mode,
	 fields => $d->{fields},
         alter  => $d->{alter},
	 profile => $prof_sub,
	 addition => undef,
	 constrain => { $key => $ARGS{$key} },
	 select => undef);
$m->comp('/widgets/wrappers/table_bottom.mc');
     
(%users, $fmt) = ();
</%init>

%#-- Documentation --#
<%doc>
###############################################################################

=head1 NAME

/widgets/alert/alertList.mc - The Alert List Widget.

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  $m->comp('/widgets/alertList/alertList.mc', mode => 'alert',
           event_id => $id);

=head1 DESCRIPTION

This widget uses listManager to display a list of alerts for an event. Here are
its supported arguments:

=over 4

=item *

mode - Indicates whether to display the alerts for a given event ('alert'), or
the recipients for a given alert ('recip'). Defaults to 'alert'.

=item *

event_id - Required if the mode is 'alert'. This is the ID of the event for
which to display alerts.

=item *

alert_id - Required if the mode is 'recip'. This is the ID of the alert for
which to display the recipients.

=item *

recip_url - The base URL for the display of recipients. This will be used to
create a link from alerts to their recipients when the mode is 'alert'. No link
will be if this argument is not passed.

=item *

event - The event corresponding to the ID passed via event_id. This argument is
optional, and is provided in case you've already instantiated the event object,
so that alertList won't instantiate it again.

alert - The alert corresponding to the ID passed via alert_id. This argument is
optional, and is provided in case you've already instantiated the alert object,
so that alertList won't instantiate it again.

=back

</%doc>
