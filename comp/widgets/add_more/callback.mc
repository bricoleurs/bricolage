<%args>
$widget
$field
$param
</%args>

<%init>;
#return unless $field eq "$widget|add_cb";
my ($w, $type, $cb) = split /\|/, $field;
set_state_data($widget, "add_$type" => 1);
</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/add_more/callback.mc - The Add More Widget callback element.

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2001-11-20 00:04:06 $

=head1 SYNOPSIS

$m->comp('/widgets/add_more/callback.mc');

=head1 DESCRIPTION

This is the callback element for the Add More widget.

</%doc>
