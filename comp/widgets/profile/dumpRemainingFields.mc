<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = substr(q$Revision: 1.1 $, 10, -1);


=head1 DATE

$Date: 2001-09-06 21:52:19 $

=head1 SYNOPSIS

$m->comp("/widgets/profile/dumpRemainingFields.mc", objVals => $objVals,
fieldsUsed => \@fieldsUsed);

=head1 DESCRIPTION

Called by /admin/profile/user/dhandler (or any profile dhandler) to display
fields not explicitly displayed by profile element.

=head1 REVISION HISTORY
$Log: dumpRemainingFields.mc,v $
Revision 1.1  2001-09-06 21:52:19  wheeler
Initial revision

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
