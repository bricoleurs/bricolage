<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:21 $

=head1 SYNOPSIS
$m->comp("/widgets/profile/select.mc",
$disp      => ''
$value     => ''
$name      => ''
$options   => {}
$js        => ''
);
=head1 DESCRIPTION
Pretty little wrapper for displayFormElement.mc.
=cut
</%doc>

<%args>

$disp      => ''
$value     => ''
$name      => ''
$options   => {}
$js        => ''
$req       => 0
$useTable  => 1
$width     => ''
$indent    => ''
$multiple  => 0
$size      => 1
$readOnly  => 0
</%args>

<%perl>

my $vals = {
	    disp      => $disp,
	    value     => $value,
	    props     => { 
                         size     => $size,
                         multiple =>  $multiple,
			 type     => 'select',
			 vals     => $options
			 },
            js        => $js,
            req       => $req,

	   };

$m->comp("/widgets/profile/displayFormElement.mc",
	 key      => $name,
	 vals     => $vals,
         useTable => $useTable,
	 readOnly  => $readOnly,
	 width     => $width,
	 indent    => $indent,
);

</%perl>
