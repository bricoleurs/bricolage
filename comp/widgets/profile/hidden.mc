<%doc>
###############################################################################

=head1 NAME

/widgets/profile/hidden.mc - Simple interface for creating hidden fields.

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2003/09/19 13:35:35 $

=head1 SYNOPSIS

$m->comp("/widgets/profile/hidden.mc",
         name      => 'my_hidden_field'
         value     => 'foo'
         js        => 'onClick="alert('Drop dead!)');

=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc

=cut

</%doc>

<%args>
$value => ''
$name  => ''
$length => undef
$maxlength => undef
$js    => undef
</%args>

<%perl>;
$m->comp("/widgets/profile/displayFormElement.mc",
	 key  => $name,
	 vals => { value => $value,
	           js    => $js,
	 	   props => { type => 'hidden',
                              length => $length,
                              maxlength => $maxlength
                             }
		 },
         useTable => 0
);
</%perl>
