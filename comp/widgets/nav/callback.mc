<%doc>
###############################################################################

=head1 NAME

sideNav.mc

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001/09/06 21:52:15 $

=head1 SYNOPSIS

<& "/widgets/profile/nav.mc" &>

=head1 DESCRIPTION

Callback hander for navigation.

=cut
</%doc>

<%args>
$widget
$field
$param
</%args>

<%init>

my ($fullSection, $state ) = split /_/, $field;
my ($nav,$section) = split /\|/, $fullSection;
set_state_data('nav', $section, $param->{$field});

</%init>
