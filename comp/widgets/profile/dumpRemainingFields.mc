<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.8 $

=cut

our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Date: 2003-09-16 16:52:25 $

=head1 SYNOPSIS

$m->comp("/widgets/profile/dumpRemainingFields.mc", objVals => $objVals,
fieldsUsed => \@fieldsUsed);

=head1 DESCRIPTION

Called by /admin/profile/user/dhandler (or any profile dhandler) to display
fields not explicitly displayed by profile element.

=cut
</%doc>
<%args>

%fieldsUsed => ()
$objref
$useTable => 1
$readOnly => 0
$localize => 1
</%args>
<%perl>

my $methods = $objref->my_meths(1);

foreach my $meth ( @{$methods} ) {
    if ( !$fieldsUsed{$meth->{name}} ) {
	$m->comp("/widgets/profile/displayFormElement.mc",
		 key      => $meth->{name},
		 objref   => $objref,
		 useTable => $useTable,
		 localize => $localize,
		 readOnly => $readOnly
		);
    }
}

</%perl>
