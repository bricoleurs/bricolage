<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2003/09/29 18:41:48 $

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
$localize  => 1
$id        => undef
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
	 localize  => $localize,
         id        => $id,
);

</%perl>
