<%doc>
###############################################################################

=head1 NAME

getList.mc - generate an array of hashes to be displayed by /widgets/listManager.mc. Requires type, and optionally start /stop range values, sort field search type, and search text.


=head1 VERSION

$Revision: 1.5 $

=cut

our $VERSION = (qw$Revision: 1.5 $ )[-1];

=head1 DATE

$Date: 2001-11-29 00:28:49 $

=head1 SYNOPSIS

=head1 DESCRIPTION

Called by the list manager form.  Each checkbox is named delete_obj, and its value should be in
the form of: type_id.  This function loops thru the ARGS, looking for delete_obj keys, and if it
finds one, it creates an instance of the object and calls its deactivate method.

When complete, this element redirects to the page specified in the mandatory $dest parameter.

=cut
</%doc>

<%args>

$type
$dest

</%args>

<%perl>

use Bric::Biz::Person;

my $pkgType;
my $obj;


# loop thru passed checkbox values, looking for something to kill
foreach my $key (keys %ARGS) {

	# create an $obj with methods to modify $type, which hopefully takes an ID parameter
	
	if ($key eq "deleteObj") {
		# get $type and $id from the hash value
		my ($type,$id) = split /_/, $ARGS{$key};
		
		# $pkgType = getPackageTypeFromDictionary($type);  # the real way to do this
		$pkgType = "Bric::Biz::Person"; # hack to get us started
		
		# retire the object specified by $id
		$obj = $pkgType->lookup( {id => $id} );
		$obj->deactivate;
		$obj->save;
	}
}


# return user to $type manager page
$r->header_out(Location => $dest);
$m->abort(302);

</%perl>



