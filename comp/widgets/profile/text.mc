<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2004/04/30 00:14:01 $

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
$localize  => 1
$readOnly  => 0
</%args>
<%perl>;
my $vals = { disp      => $disp,
             value     => $value,
             props     => { type      => 'text',
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
	 localize  => $localize,
	 readOnly  => $readOnly
);
</%perl>
