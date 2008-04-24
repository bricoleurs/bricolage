%#--- Documentation ---#

<%doc>

=head1 NAME

login - A login widget

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$Id$

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


