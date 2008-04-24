<%doc>
###############################################################################

=head1 NAME

=cut

use Bric; our $VERSION = Bric->VERSION;

=head1 SYNOPSIS

Perform text or alpha (match first letter of a field) searching for an input type.

=head1 DESCRIPTION

Returns an array of objects that meet the search criteria.  Text search matches if the pattern is present at the beginning of the field value, ie: john matches johnboy and john and johnson.  Alpha search on 'j' returns every member where the search field value starts with 'j'.  All searches are case-insensitive.

=cut
</%doc>

<%args>
$search
$what
$type
</%args>

<%perl>

my @fields;
my $pkgType;
my @objs;

# $pkgType = getPkgNameFromDictionary($type);
$pkgType = "Bric::Biz::Person";

# get fields to search on from data dictionary
#@fields = getSearchFieldsFromDictionary($type);
@fields = ('fname', 'lname');

my @tmp = $pkgType->list();

foreach my $field (@fields) {
	for (my $i=0; $i < $#tmp; $i++) {

		# this needs to be more sophisticated
		my $meth = "get_$field";

		if ( lc ( $tmp[$i]->$meth() )  =~ /^$what/i  ) {
			push @objs, $tmp[$i];
		}
	}
}

return @objs;

</%perl>
