<%perl>

# for my $key (@keys) {
   @array = sort {$$a{lname} cmp $$b{lname}} @array;
# }
 return @array;
</%perl>

<%args>
@array # the first to the array that needs sorting..
@keys  # the second to an array of keys to sort by
</%args>

<%doc>
$Log: sortArrayOfHashes.mc,v $
Revision 1.1  2001-09-06 21:51:57  wheeler
Initial revision

</%doc>