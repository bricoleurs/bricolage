
<FORM METHOD="post" onSubmit="return confirmDeletions()">
<INPUT type=hidden name=type value=<% $type %>>

<!-- table header display -->
<TABLE BORDER=1>


<!-- iterate rows for objects -->
% for my $i (0 .. @objVals - 1) {
%     if ($i == 0) { # spew the table headers
<TR>
%         foreach my $key (keys %{ $objVals[$i] } )  {
%             if ($key ne "numResults") {
<TH><A HREF="<% $url %>?listManager|sortBy_cb=<% $key %>"><% $objVals[$i]{$key} %></A></TH>
%                       }
%               }

</tr>

%       } else { # end table header
<tr>
        <!-- <td><% $objVals[$i]{id}%></td> -->
%       foreach my $key (keys %{ $objVals[$i] } )  {

%               #if ($key ne "id") {
                <td><% $objVals[$i]{$key} %></td>
%               #}
%       }
        <td><a href="/admin/profile/<% $type %>/?id=<% $objVals[$i]{id} %>">Edit</a></td>
        <td><input type=checkbox name=deleteObj value=<% $type %>_<% $objVals[$i]{id} %>> Delete</td>
</tr>
%       } # end if
% }

# below is code to do pagination.  if you want to page thru your results, this is a good
# place to start.  Requires start/stop values to be passed thru the getList.mc element.
if (0) { # I'm so happy you can't comment with /* */ in perl.  yeah. right.


        # $m->out("start  $start  stop $stop numres $numResults"); # debug code
        # write prev/next links if needed
        
        if ($numResults > Bric::App::Default::get_def('MAX_ROWS')) {
                
                # if we're past the start, do a previous link
                if ($start > 0) {
                        my $newStart = ($start - Bric::App::Default::get_def('MAX_ROWS') <= 0) ? 0 : $start - Bric::App::Default::get_def('MAX_ROWS');
                        my $prev = "<a href=\"/admin/manager/$type/?sortBy=$sortBy&start=$newStart&stop=$start\"><< Previous</a> -- ";
                        $m->out($prev);
                }
        
                # if we're not at the end, do a next link
                if ($stop < $numResults) {
                        my $newStop = ($stop + Bric::App::Default::get_def('MAX_ROWS') < $numResults ) ? $stop + Bric::App::Default::get_def('MAX_ROWS') : $numResults;
                        my $next = "<a href=\"/admin/manager/$type/?sortBy=$sortBy&start=$stop&stop=$newStop\">Next >></a>";
                        $m->out($next);
                }
        }
}

</table>