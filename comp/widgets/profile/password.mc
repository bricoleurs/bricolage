<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2001-09-06 21:52:21 $

=head1 SYNOPSIS

$m->comp("/widgets/profile/password.mc",
$disp      => ''
$value     => ''
$name     => ''
$length    => ''
$maxlength => ''
$js        => ''
);


=head1 DESCRIPTION

Easier to use wrapper for displayFormElement.mc
=cut
</%doc>

<%args>

$disp      => ''
$value     => ''
$name     => ''
$length    => ''
$maxlength => ''
$js        => ''
$req       => 0
$useTable  => 1
$readOnly  => 0
</%args>

<%perl>

my $vals = {
	    disp      => $disp,
	    value     => $value,
	    props     => { 
			  type => 'password',
			  length => $length,
			  maxlength => $maxlength
			 },
            js        => $js,
            req       => $req
	   };


$m->comp("/widgets/profile/displayFormElement.mc",
	 key       => $name,
	 vals      => $vals,
	 readOnly  => $readOnly,
         useTable  => $useTable
);

</%perl>
