<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:21 $

=head1 SYNOPSIS
$m->comp("/widgets/profile/text.mc",
$disp      => ''
$value     => ''
$name     => ''
$length    => ''
$maxlength => ''
$js        => ''
$width     => ''
$indent    => ''
);

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut
</%doc>

<%args>

$disp      => ''
$value     => ''
$name      => ''
$length    => ''
$size      => ''
$maxlength => ''
$js        => ''
$req       => 0
$width     => ''
$indent    => ''
$useTable  => 1
$readOnly  => 0
</%args>

<%perl>

my $vals = {
	    disp      => $disp,
	    value     => $value,
	    props     => { 
			  type      => 'text',
			  length    => $size || $length,
			  maxlength => $maxlength
			 },
            js        => $js,
	    req       => $req,

	   };


$m->comp("/widgets/profile/displayFormElement.mc",
	 key       => $name,
	 vals      => $vals,
	 width     => $width,
	 indent    => $indent,
	 useTable  => $useTable,
	 readOnly  => $readOnly
);

</%perl>
