<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:17 $

=head1 SYNOPSIS
$m->comp("/widgets/profile/checkbox.mc",
         label_after => 0,
         checked     => 0,
         disp        => '',
         value       => '',
         name        => '',
         js          => ''
);

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>
<%args>
$label_after => 0
$disp        => ''
$value       => ''
$name        => ''
$js          => ''
$checked     => 0
$useTable    => 0
$readOnly    => 0
</%args>
<%perl>;
my $vals = { disp  => $disp,
	     value => $value,
	     js    => $js,
	     props => { type => 'checkbox',
			chk  => $checked,
			label_after => $label_after,
		      } };


$m->comp("/widgets/profile/displayFormElement.mc",
	 key  => $name,
	 vals => $vals,
	 readOnly => $readOnly,
	 useTable => $useTable
);
</%perl>
