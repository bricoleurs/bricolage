<%doc>
###############################################################################

=head1 NAME

getList.mc - generate an array of hashes to be displayed by /widgets/listManager.mc. Requires type, and optionally start /stop range values, sort field search type, and search text.


=cut

use Bric; our $VERSION = Bric->VERSION;

=head1 SYNOPSIS

=head1 DESCRIPTION

Returns an array of hashes, sorted by specified field (or id by default).  Gets all instances of type and introspects them to produce hashes with field name => value pairs.  Sorts the results, digs out the slice specified by the start and stop values, (or the first 20 by default).  Default behavior is to filter inactive items.  Call this element with a true value for $useInactive to override.  Default behavior is to return all fields.  Call this element with desired fields in an array @fields to limit it to specific fields.

=cut
</%doc>

<%args>

$type
$sortBy => "id"
$search => 0
$what => ''
@fields => ('all')
$useInactive => 0

</%args>

<%perl>

use Bric::Biz::Person;

my $methods;
my @objs;
my @objVals;
my @sorted_array;
my $numResults;
my @tmp;
my $pkgType;

# $pkgType = getPkgNameFromDictionary($type);
$pkgType = "Bric::Biz::Person";


# procure an array of objects of the requested type.
# if a search is called for, do it here, otherwise
# return all available objects.
if (!$search) {
	@objs= $pkgType->list();
} else {
	@objs = $m->comp("/lib/util/search.mc", type => $type, search => $search, what => $what);
}

# filter out inactive objects (default behavior, can be overridden by setting useInactive to true)
unless ($useInactive) {
	
	foreach my $o (@objs) {
		if ($o->is_active) {
			$tmp[@tmp] = $o;
		}
	}
	
	# refresh @objs with only the active items.
	@objs = ();
	push @objs, @tmp;
	@tmp = ();
}

# how many are left?
$numResults = $#objs;


# using the introspection methods, build an array of hashes where each row is a hash of all 
# an objects name/value pairs
foreach my $obj (@objs) {

	my %tmpHash;
	
	# $methods becomes a reference to meths hash for one property:
	$methods = $obj->my_meths;

	# big todo here:  handle situations where the anonymous accessor method requires argument(s)

	foreach my $key (keys %$methods) { # keys to $method are: meth, args, length etc.
		
		#if ( $m->comp("/lib/util/in_array", ar => @fields, what => $key) || $fields[0] eq "all" ) {
			
			# set tmpHash key (prop) = value (method ref)
			$tmpHash{$key} = $methods->{$key}->{meth}->($obj); 
			#$m->out("key = $key , value = " . $methods->{$key}->{meth}->($obj) ."<br>" ); # debug code
		#}
	}
	#$m->out("done:<p>");
	
	# can we assume a get_id method for all objects (or all displayable objects)?
	$tmpHash{id} = $obj->get_id;
	$objVals[@objVals] = \%tmpHash;
	
}



# sort the hash
if ($sortBy eq "id") {
	@sorted_array = sort ( { $a->{$sortBy}  <=>  $b->{$sortBy} }  @objVals );
} else {
	@sorted_array = sort ( { lc ( $a->{$sortBy})  cmp  lc ( $b->{$sortBy} ) }  @objVals );
}

# zero out Obj vals for reuse
@objVals = ();


# use the code below to return a slice if you're interested in pagination.

#$m->out($start);
#$m->out($stop);
# now that we've got a million objects, dump the slice provided by start/stop parameters back into objVals
#if ($#sorted_array > ($stop - $start) ) {
	
	#for (my $i = $start; $i < $stop; $i++) {
	#	$tmp[@tmp] = $sorted_array[$i];
	#}
	#@sorted_array = ();
	#push @sorted_array, @tmp;
	
#}

# end pagination code block

# create a header for table display.
# using the introspection methods, build a hash with 
# key=field name, value=human readable column header
my $meths = $pkgType->my_meths;
my %headers;
foreach my $ref (keys %$meths) {
	my %sub;
	my $key;
	%sub = %$meths->{$ref};
	foreach my $key (keys %{ $$meths{$ref} } ) {
		if ($key eq "disp") {
			$headers{$ref} = $$meths{$ref}{$key};
		}
	}
}
$headers{id} = "ID";
#$headers{numResults} = $numResults; #overload this row for use with drawing prev/next links

#stuff column headers into first row of array
$objVals[0] = \%headers;

push @objVals, @sorted_array;

# return sliced hash
return @objVals;

</%perl>


