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

