%#--- Documentation ---#

<%doc>

=head1 NAME

login - A login widget

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:12 $

=head1 SYNOPSIS

<& '/widgets/login/login.mc' &>

=head1 DESCRIPTION



=cut

</%doc>

%#--- Arguments ---#

<%args>
</%args>

%#--- Initialization ---#

<%once>
my $widget = 'login';
</%once>

<%init>
$m->comp("loggedout.html", widget => $widget);
</%init>

%#--- Log History ---#

<%doc>
$Log: login.mc,v $
Revision 1.1  2001-09-06 21:52:12  wheeler
Initial revision

</%doc>
