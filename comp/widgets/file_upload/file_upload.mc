%#--- Documentation ---*

<%doc>

=head1 NAME

file_upload - Handles the uploading of files to the system

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:08 $

=head1 SYNOPSIS

<& '/widgets/file_upload/file_upload.mc' &>

=head1 DESCRIPTION

=cut

</%doc>

<%once>
my $widget = 'file_upload';
</%once>

%#--- Arguments ---#

<%args>

</%args>

%#--- Initialization ---#

<%init>
# check if we have a file yet
my $file = get_state_data($widget, 'file');

if ($file) {
	# do file things
} else {
	$m->comp('no_file.html', widget => $widget);
}

</%init>

%#--- Log History ---#

<%doc>

$Log: file_upload.mc,v $
Revision 1.1  2001-09-06 21:52:08  wheeler
Initial revision

</%doc>
