<%args>
$widget
$field
$param
</%args>

<%init>

#if ($field eq "$widget|file_cb") {

#	# they are trying to upload a file
#
#	my $upload = $r->upload;
#	my $fh = $upload->fh();
#print STDERR "FH is a " . ref $fh . "\n";
#	while (<$fh>) {
#		print STDERR $_;
#	}
#}

</%init>
