<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.8 $

=cut

our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Date: 2002-02-12 00:59:17 $

=head1 SYNOPSIS
$m->comp(
    "/widgets/formBuilder/formBuilder.mc",
    widget                 => $path_to_widget,
    optionalFieldsLocation => $path_to_any_optional_fields,
    numFields              => $num_of_already_existing_field (default is 0 - no display of  this feature)
);
=head1 DESCRIPTION

Displays a table with radio buttons for each form element type. By default
the text box is selected first.  The possible properties for each form
element type are displayed beneath the radio buttons.  All properties must
be supplied with values by the user before they are allowed to submit the
form.

Pass a value to optional fields location to provide html for any additional
fields you want to capture with the data.  This can be of any complexity,
but must be formatted in such a way that it can become the value of a 
javascript variable.  See /admin/profile/container/optionalFieldsJavascript.mc
for an example.

The numFields value allows ordering of new meta data.  Pass in the number of 
already existing attributes on the object, and formBuilder will build a 
select box with position numbers.  Default is no numFields select.

The stay argument, when passed a true value, causes a "Save and Stay" button
to be added, with a callback value of "save_n_stay_cb."

=cut
</%doc>
<%args>
$target                 => $r->uri
$optionalFieldsLocation => ''
$numFields              => -1
$formName               => "theForm"
$addCallbackCaption     => "Add to Form"
$addCallback            => "formBuilder|add_cb"
$saveCallback           => "formBuilder|save_cb"
$stayCallback           => "formBuilder|save_n_stay_cb"
$saveCallbackCaption    => "Save"
$num                    => 2
$caption                => "Create new data field"
$useRequired            => 0
$useQuantifier          => 0
$stay                   => undef
</%args>
<%init>

my ($section, $mode, $type) = $m->comp("/lib/util/parseUri.mc");
my $agent        = $m->comp('/widgets/util/detectAgent.mc');
my $div          = 'div';
my $name         = "id";
my $closeDiv     = "div";
my $numFieldsTxt = '<input type="hidden" name="fieldNum" value="1">';
my $position     = 'style="position:relative; width:340; height:230; visibility:visible; z-index:10;"';
my $textStyle    = 'style="width:120px"';
my $textareaRows = 5;
my $textareaCols = 20;

if ($agent->{browser} ne "Netscape") {
    $textareaRows = 5;
    $textareaCols = 25;
}

# hack.  why wouldn't the div tag work in NS for this case? a mystery to solve when
# there is time.
if ($agent->{browser} eq "Netscape") {
	$div = "layer position=\"relative\"";
	$closeDiv = "layer";
	$name = "name";
	$position = "left=350";
}

# build the numFields select box
if ($numFields != -1) {
	$numFieldsTxt = '<span class=label>Position:</span><br><select name=fb_position size=1>';
	for my $i (1 .. $numFields+1) {
		$numFieldsTxt .= "<option value=$i";
		$numFieldsTxt .= " selected" if ($i == $numFields+1);
		$numFieldsTxt .= "> $i </option>";
	}
	$numFieldsTxt .= '</select>';
}
</%init>


% # add hidden fields to recieve the values of the fbuilder
<input type=hidden name=fb_name value=''>
<input type=hidden name=fb_type value=''>
<input type=hidden name=fb_disp value=''>
<input type=hidden name=fb_vals value=''>
<input type=hidden name=fb_value value=''>
<input type=hidden name=fb_rows value=''>
<input type=hidden name=fb_cols value=''>
<input type=hidden name=fb_size value=''>
<input type=hidden name=fb_position value=''>
<input type=hidden name=fb_maxlength value=''>
<input type=hidden name=fb_req value=''>
<input type=hidden name=fb_quant value=''>
<input type=hidden name=fb_allowMultiple value=''>
<input type=hidden name=<% $addCallback %> value=0>
<input type=hidden name=<% $saveCallback %> value=0>
<input type=hidden name=<% $stayCallback %> value=0>
<input type=hidden name=delete value=0>

% # close the current form context
</form>

<script language=javascript>

var curSub = 'text'
var cancelValidation = false

var text_table = '<form name=fb_form target="<% $target %>"><input type=hidden name=fb_type value=text>'
text_table    += "<table width=330 cellpadding=3>"
text_table    += "    <tr>"
text_table    += '    <td valign=top width=170><span class=label>Name:</span><br />'
text_table    += '    <input type=text name=fb_name size=20 <% $textStyle %>></td>'
text_table    += '    <td valign=top width=160><span class=label>Size:</span><br />'
text_table    += '    <input type="text" name="fb_size" value="32" size="3"></td>'
text_table    += "    </tr>"
text_table    += "</table><table width=330 cellpadding=3>"
text_table    += "    <tr><td valign=top width=170>"
text_table    += '    <span class=label>Label:</span><br />'
text_table    += '    <input type=text name=fb_disp size=20 <% $textStyle %>></td>'
text_table    += '    <td valign=top width=160><span class=label>Maximum size:</span><br />'
text_table    += '    <input type="text" name="fb_maxlength" value="32" size="3">'
text_table    += "    </td></tr>"
text_table    += "</table><table width=330 cellpadding=3>"
text_table    += '    <tr><td>'
text_table    += '    <span class=label>Default Value:</span><br />'
text_table    += '    <input type=text name=fb_value size=20 <% $textStyle %>>'
text_table    += "    </td></tr>"
text_table    += "</table><table width=330 cellpadding=3>"
text_table    += '    <tr><td>'
text_table    += '<% $numFieldsTxt %>'
text_table    += '    </td><td>'
% $m->out ( qq {text_table    += '    <span class=label>Required:</span><input type=checkbox name=fb_req>'\n}) if ($useRequired);
text_table    += '    </td><td>'
% $m->out ( qq {text_table    += '    <span class=label>Repeatable:</span><input type=checkbox name=fb_quant>'\n}) if ($useQuantifier);
text_table    += "    </td></tr>"
text_table    += "</table></form>&nbsp;"

var radio_table = "<form name=fb_form target=<% $target %>><input type=hidden name=fb_type value=radio>"
radio_table    += "<table width=340 cellpadding=3>"
radio_table    += "<tr><td valign=top>"
radio_table    += '	<span class=label>Name:</span><br />'
radio_table    += '	<input type=text name=fb_name><br />'
radio_table    += '	<span class=label>Group Label:</span><br />'
radio_table    += '	<input type=text name=fb_disp><br />'
radio_table    += '	<span class=label>Default Value:</span><br />'
radio_table    += '	<input type=text name=fb_value>'
radio_table    += '</td>'
radio_table    += "	<td valign=top>"
radio_table    += '	<span class=label>Options, Label<br>(one per line):</span><br />'
radio_table    += '	<textarea rows=<% $textareaRows %> cols=<% $textareaCols %> name=fb_vals></textarea>'
radio_table    += '</td></tr>'
radio_table    += '</table><table width=340 cellpadding=3>'
radio_table    += "<tr><td valign=top>"
radio_table    += '	<% $numFieldsTxt %>'
radio_table    += '    </td><td>'
% $m->out ( qq {radio_table    += '    <span class=label>Required:</span><input type=checkbox name=fb_req>'\n}) if ($useRequired);
radio_table    += '    </td><td>'
% $m->out ( qq {radio_table    += '    <span class=label>Repeatable:</span><input type=checkbox name=fb_quant>'\n}) if ($useQuantifier);
radio_table    += "    </td></tr>"
radio_table    += '</td></tr></table>'
radio_table    += '</form>&nbsp;'

var checkbox_table = "<form name=fb_form target=<% $target %>><input type=hidden name=fb_type value=checkbox>"
checkbox_table    += "<table width=340 cellpadding=3>"
checkbox_table    += "<tr><td valign=top>"
checkbox_table    += "	<span class=label>Name:</span><br />"
checkbox_table    += '	<input type=text name=fb_name>'
checkbox_table    += '</td></tr>'
checkbox_table    += '</table><table width=340 cellpadding=3>'
checkbox_table    += '<tr><td valign=top>'
checkbox_table    += '	<span class=label>Label:</span><br />'
checkbox_table    += ' 	<input type=text name=fb_disp>'
checkbox_table    += "</td></tr></table>"
checkbox_table    += "<table width=340 cellpadding=3>"
checkbox_table    += "<tr><td valign=top>"
checkbox_table    += '	<% $numFieldsTxt %>'
checkbox_table    += '    </td><td>'
% $m->out ( qq {checkbox_table    += '    <span class=label>Required:</span><input type=checkbox name=fb_req>'\n}) if ($useRequired);
checkbox_table    += '    </td><td>'
% $m->out ( qq {checkbox_table    += '    <span class=label>Repeatable:</span><input type=checkbox name=fb_quant>'\n}) if ($useQuantifier);
checkbox_table    += "    </td></tr>"
checkbox_table    += '</td></tr>'
checkbox_table    += '</table>'
checkbox_table    += '</form>&nbsp;'

var password_table  = "<form name=fb_form target=<% $target %>><input type=hidden name=fb_type value=password>"
password_table     += '<table width=340 cellpadding=3>'
password_table     += '<tr><td valign=top width=170>'
password_table     += '		<span class=label>Name:</span><br />'
password_table     += '		<input type=text name=fb_name>'
password_table     += '</td><td valign=top width=170>'
password_table     += '		<span class=label>Size of box:</span><br />'
password_table     += '		<input type=text name=fb_size value=32 size=3>'
password_table     += '</td></tr>'
password_table     += '</table><table width=340 cellpadding=3>'
password_table     += '<tr><td valign=top width=170>'
password_table     += '		<span class=label>Label:</span><br />'
password_table     += '		<input type=text name=fb_disp>'
password_table     += '</td><td valign=top width=170>'
password_table     += '		<span class=label>Maximum size of input:</span><br />'
password_table     += '		<input type=text name=fb_maxlength value=32 size=3>'
password_table     += "</td></tr>"
password_table     += '</table><table width=340 cellpadding=3>'
password_table     += '<tr><td>'
password_table     += '		<% $numFieldsTxt %>'
password_table     += '    </td><td>'
% $m->out ( qq {password_table     += '    <span class=label>Required:</span><input type=checkbox name=fb_req>'\n}) if ($useRequired);
password_table     += '    </td><td>'
% $m->out ( qq {password_table     += '    <span class=label>Repeatable:</span><input type=checkbox name=fb_quant>'\n}) if ($useQuantifier);
password_table     += "    </td></tr>"
password_table     += '</table>'
password_table     += '</form>&nbsp;'


var pulldown_table  = "<form name=fb_form target=<% $target %>><input type=hidden name=fb_type value=select>"
pulldown_table     += '<table width=340 cellpadding=3>'
pulldown_table     += '<tr><td valign=top width=170>'
pulldown_table     += '		<span class=label>Name:</span><br />'
pulldown_table     += '		<input type=text name=fb_name><br />'
pulldown_table     += '		<span class=label>Label:</span><br />'
pulldown_table     += '  	<input type=text name=fb_disp><br />'
pulldown_table     += '		<span class=label>Default Value:</span><br />'
pulldown_table     += ' 	<input type=text name=fb_value>'
pulldown_table 	   += '</td><td valign=top width=170>'
pulldown_table     += '		<span class=label>Option, Label<br />(one per line):</span><br />'
pulldown_table 	   += "  	<textarea rows=<% $textareaRows %> cols=<% $textareaCols %> name=fb_vals></textarea>"
pulldown_table     += "</td></tr>"
pulldown_table     += '</table><table width=340 cellpadding=3>'
pulldown_table     += '<tr><td>'
pulldown_table     += '		<% $numFieldsTxt %>'
pulldown_table     += '    </td><td>'
% $m->out ( qq {pulldown_table     += '    <span class=label>Required:</span><input type=checkbox name=fb_req>'\n}) if ($useRequired);
pulldown_table     += '    </td><td>'
% $m->out ( qq {pulldown_table     += '    <span class=label>Repeatable:</span><input type=checkbox name=fb_quant>'\n}) if ($useQuantifier);
pulldown_table     += "</td></tr></table>"
pulldown_table     += '</form>&nbsp;'

var select_table  = "<form name=fb_form target=<% $target %>><input type=hidden name=fb_type value=select>"
select_table 	 += '<table width=340 cellpadding=3>'
select_table     += '<tr><td valign=top>'
select_table     += '	<span class=label>Name:</span><br />'
select_table     += '	<input type=text name=fb_name size=20> <br />'
select_table 	 += '	<span class=label>Label:</span><br />'
select_table     += '	<input type=text name=fb_disp size=20><br />'
select_table  	 += '	<span class=label>Default Value:</span><br />'
select_table     += '	<input type=text name=fb_value size=20>'
select_table  	 += '</td><td valign=top>'
select_table 	 += '	<span class=label>Option, Label<br>(one per line):</span><br>'
select_table     += '	<textarea rows=<% $textareaRows %> cols=<% $textareaCols %> name=fb_vals></textarea>'
select_table     += "</td></tr>"
select_table 	 += '</table><table width=300 border=0 cellpadding=3>'
select_table     += "<tr><td valign=top"
select_table 	 += '	<span class=label>Size:</span><br />'
select_table     += '	<input type=text name=fb_size value=5 size=3>'
select_table 	 += '</td><td valign=top>'
select_table     += '	<span class=label>Allow multiple?</span><br />'
select_table     += '	<input type=checkbox name=fb_allowMultiple>'
select_table     += "</td><td>"
select_table     += '<% $numFieldsTxt %>'
select_table     += "</td></tr>"
select_table 	 += '</table><table width=300 border=0 cellpadding=3>'
select_table     += '    <tr><td>'
select_table     += '    </td><td>'
% $m->out ( qq {select_table     += '    <span class=label>Required:</span><input type=checkbox name=fb_req>'\n}) if ($useRequired);
select_table     += '    </td><td>'
% $m->out ( qq {select_table     += '    <span class=label>Repeatable:</span><input type=checkbox name=fb_quant>'\n}) if ($useQuantifier);
select_table     += '</td></tr></table></form>&nbsp;'

var textarea_table  = "<form name=fb_form target=<% $target %>><input type=hidden name=fb_type value=textarea>"
textarea_table 	   += '<table width=340 cellpadding=3><tr><td valign=top><span class=label>Name:</span><br>'
textarea_table     += '<input type=text name=fb_name></td>'
textarea_table 	   += '<td valign=top><span class=label>Rows:</span><br>'
textarea_table     += '<input type=text name=fb_rows value=4 size=3></td>'
textarea_table 	   += '<td valign=top><span class=label>Max size:</span><br>'
textarea_table     += '<input type=text name=fb_maxlength value="0" size=4 /></td></tr>'
textarea_table 	   += '<tr><td valign=top><span class=label>Label:</span><br>'
textarea_table     += '<input type=text name=fb_disp></td>'
textarea_table 	   += '<td valign=top><span class=label>Columns:</span><br>'
textarea_table     += '<input type=text name=fb_cols value=40 size=3></td></tr>'
textarea_table     += '<tr><td colspan=3><span class=label>Default Value:</span><br>'
textarea_table     += '<input type=text name=fb_value></td>'
textarea_table     += "</tr>"
textarea_table     += '</table><table width=340 cellpadding=3>'
textarea_table     += "    <tr><td>"
textarea_table     += '<% $numFieldsTxt %>'
textarea_table     += '    </td><td>'
% $m->out ( qq {textarea_table     += '    <span class=label>Required:</span><input type=checkbox name=fb_req>'\n}) if ($useRequired);
textarea_table     += '    </td><td>'
% $m->out ( qq {textarea_table     += '    <span class=label>Repeatable:</span><input type=checkbox name=fb_quant>'\n}) if ($useQuantifier);
textarea_table     += '</td></tr></table></form>&nbsp;'


var date_table 	= "<form name=fb_form target=<% $target %>><input type=hidden name=fb_type value=date>"
date_table     += "<table width=340 cellpadding=3><tr>"
date_table     += '<td valign=top><span class=label>Name:</span><br>'
date_table     += '<input type=text name=fb_name></td></tr>'
date_table     += '<tr><td valign=top><span class=label>Caption:</span><br>'
date_table     += '<input type=text name=fb_disp></td>'
date_table     += "</tr>"
date_table     += '</table><table width=300 border=0 cellpadding=3>'
date_table     += "<tr><td>"
date_table     += '<% $numFieldsTxt %>'
date_table     += '    </td><td>'
% $m->out ( qq {date_table     += '    <span class=label>Required:</span><input type=checkbox name=fb_req>'\n}) if ($useRequired);
date_table     += '    </td><td>'
% $m->out ( qq {date_table     += '    <span class=label>Repeatable:</span><input type=checkbox name=fb_quant>'\n}) if ($useRequired);
date_table     += '</td></tr></table></form>&nbsp;'

<%perl>
  if (defined $optionalFieldsLocation) {
      $m->out( 'var optionalFields = "'.$optionalFieldsLocation.'"'."\n");
  } else {
      $m->out( "var optionalFields = ''\n" );
  }
</%perl>

</script>

% if ($agent->{browser} eq "Netscape") {

<<% $div %> <% $position %> <% $name %>="fbDiv" visibility=show width=300 height=400 z-index=5 style="font-family:sans-serif; font-weight:bold; font-size:10pt; width:380; height:400">


</<% $closeDiv %>>

% }

% $m->comp("/widgets/wrappers/sharky/table_top.mc",
%  	 caption => $caption,
%	 number  => $num,
%        height  => 230);

<form name='fb_switch'>
<table border=0 cellpadding=0 cellspacing=0 width=570 height=230>
<tr>
  <td width=20><img src="/media/images/spacer.gif" width=20 height=1 /></td>
  <td width=150 valign=top>

<table border=0>
  <tr>
    <td width=140><img src="/media/images/spacer.gif" width=140 height=5 /></td>
  </tr>
</table>
<table border=1 width=140>

  <tr>
    <td width=140>
    <input type=radio name=formElement value=text onClick="showForm('text')" checked>
    <b>Text box</b>
    </td>
  </tr>
  <tr>
    <td width=140>
    <input type=radio name=formElement value=radio onClick="showForm('radio')">
    <b>Radio Buttons</b>
    </td>
  </tr>
  <tr>
	<td>
	<input type=radio name=formElement value=checkbox onClick="showForm('checkbox')">
	<b>Checkbox</b>
	</td>
</tr>
<tr>
	<td>
	<input type=radio name=formElement value=password onClick="showForm('password')">
	<b>Password</b>
	</td>
</tr>
<tr>
	<td>
	<input type=radio name=formElement value=pulldown onClick="showForm('pulldown')">
	<b>Pulldown</b>
	</td>
</tr>
<tr>
	<td>
	<input type=radio name=formElement value=select onClick="showForm('select')">
	<b>Select</b>
	</td>
</tr>
<tr>
	<td>
	<input type=radio name=formElement value=textarea onClick="showForm('textarea')">
	<b>Text Area</b>
	</td>
</tr>
<tr>
	<td>
	<input type=radio name=formElement value=date onClick="showForm('date')">
	<b>Date</b>
	</td>
</tr>
</table>
</form>

  </td>
  <td width=400 height=230 valign=top rowspan=2>
% if ($agent->{browser} ne "Netscape") {

<<% $div %> <% $position %> id="fbDiv">

&nbsp;
</<% $closeDiv %>>

% }
&nbsp;</td>

<tr>
  <td width=20><img src="/media/images/spacer.gif" width=20 height=1 /></td>
  <td valign=top>
  <form name=fb_magic_buttons>
  <a href="#" onClick="formBuilderMagicSubmit('<% $formName %>', 'add'); return false"><img src="/media/images/add_to_form_lgreen.gif" border=0 vspace=5 /></a>
  </td>
</tr>
</table>
<%perl>

$m->comp("/widgets/wrappers/sharky/table_bottom.mc");

$m->comp('/widgets/profile/displayFormElement.mc',
	 key => 'delete',
	 vals => { disp => '<span class="burgandyLabel">Delete this Profile</span>',
		   props => { type => 'checkbox',
			      label_after => 1 },
#		   value => '0'
		 },
	 useTable => 0
	);
$m->out("<br />\n");

</%perl>
<a href="#" onClick="formBuilderMagicSubmit('<% $formName %>', 'save');return false"><img src="/media/images/save_red.gif" border="0" /></a>
% $m->out(qq{<a href="#" onClick="formBuilderMagicSubmit('$formName', 'save_n_stay');return false"><img src="/media/images/save_and_stay_lgreen.gif" border="0" /></a>\n}) if $stay;
<a href="#" onClick="window.location.href='<% "/$section/manager/$type/" %>'; return false;"><img src="/media/images/return_dgreen.gif" border="0" /></a>
</form>
