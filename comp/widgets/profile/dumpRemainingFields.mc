<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.2 $

=cut

our $VERSION = substr(q$Revision: 1.2 $, 10, -1);


=head1 DATE

$Date: 2001-10-09 20:54:38 $

=head1 SYNOPSIS

$m->comp("/widgets/profile/dumpRemainingFields.mc", objVals => $objVals,
fieldsUsed => \@fieldsUsed);

=head1 DESCRIPTION

Called by /admin/profile/user/dhandler (or any profile dhandler) to display
fields not explicitly displayed by profile element.

</%doc>
<%args>

%fieldsUsed => ()
$objref
$useTable => 1
$readOnly => 0
</%args>
<%perl>

my $methods = $objref->my_meths(1);

foreach my $meth ( @{$methods} ) {
    if ( !$fieldsUsed{$meth->{name}} ) {
	$m->comp("/widgets/profile/displayFormElement.mc",
		 key      => $meth->{name},
		 objref   => $objref,
		 useTable => $useTable,
		 readOnly => $readOnly
		);
    }
}

</%perl>
