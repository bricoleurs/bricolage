<%args>
$fixed
$pref
$vals
</%args>

<%init>
my @tokens;

  if( $fixed ) {
    @tokens = qw( categories day month year );
  } else {
    @tokens = qw( categories day month slug year );
  }
</%init>

<table border="0" width="578">
<tr>
  <td colspan="2"><p>Please supply a string delimited by '/'s, consisting of the
  following tokens (each of which must also be separated by '/'s): <% join( ", ", @tokens ) %>.</p>
  <p>Assuming the current date is <i>03/07/2002</i> and a story in the
  category <i>/subjects/articles/</i> with the slug <i>stuff</i>, the format string
  <i>'/categories/year/month/day/slug/'</i> would yield the URI:
  <b>/subject/articles/2002/03/07/stuff/</b></p>
%  if( $fixed ) {
  <p><i>N.B.</i> the token, slug, is unavailable for Fixed URI Format</p>
%  }
  </td>
</tr>
<tr>
<td colspan="2"> </td>
</tr>
</table>

<%perl>
$m->comp("/widgets/profile/displayFormElement.mc", key => 'value',
         vals => { props => { type => 'text',
                              size => 128,
                              vals => $vals },
                   disp  => 'Format String',
                   value => $pref->get_value },
         js   => 'onChange="checkURI( \'pref_profile\', \'value\' );
                            validateURI( \'pref_profile\', \'value\', ' . $fixed  . ' );"' );
</%perl>
