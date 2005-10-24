<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$LastChangedRevision$

=cut

use Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  $m->comp(
           "/widgets/formBuilder/formBuilder.mc",
           widget                 => $path_to_widget,
           optionalFieldsLocation => $path_to_any_optional_fields,
           numFields              => $num_of_already_existing_field
  );

=head1 DESCRIPTION

Displays a table with radio buttons for each form element type. By default
the text box is selected first.  The possible properties for each form
element type are displayed beneath the radio buttons.  All properties must
be supplied with values by the user before they are allowed to submit the
form.

Pass a value to optional fields location to provide HTML for any additional
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
<%init>;
my ($section, $mode, $type) = parse_uri($r->uri);
my $div          = 'div';
my $name         = "id";
my $closeDiv     = "div";
my $numFieldsTxt = '<input type="hidden" name="fieldNum" value="1">';
my $textareaRows = 5;
my $textareaCols = 20;
$textareaRows    = 5;
$textareaCols    = 25;

# Put together the precision select list with localized options.
my $precision_select = join('', map { sprintf '<option value="%s"%s>%s</option>',
                         $_->[0], ( $_->[0] == MINUTE ? ' selected="selected"' : ''),
                         $lang->maketext($_->[1]) }
                       @{&PRECISIONS} );

# build the numFields select box
my $numFieldsOpts;
if ($numFields != -1) {
        $numFieldsTxt = '<span class=label>'. $lang->maketext('Position') .':</span><br><select name=fb_position size=1>';
        for my $i (1 .. $numFields+1) {
                $numFieldsTxt .= "<option value=$i";
                $numFieldsTxt .= " selected" if ($i == $numFields+1);
                $numFieldsTxt .= "> $i </option>";
                $numFieldsOpts .= qq{<option value="$i"} 
                               . (($i == $numFields+1) ? ' selected="selected"' : '') 
                               . qq{>$i</option>\n};
        }
        $numFieldsTxt .= '</select>';
}
</%init>

% # add hidden fields to receive the values of the fbuilder
<input type="hidden" name="fb_name" value="">
<input type="hidden" name="fb_type" value="">
<input type="hidden" name="fb_disp" value="">
<input type="hidden" name="fb_vals" value="">
<input type="hidden" name="fb_value" value="">
<input type="hidden" name="fb_rows" value="">
<input type="hidden" name="fb_cols" value="">
<input type="hidden" name="fb_size" value="">
<input type="hidden" name="fb_position" value="">
<input type="hidden" name="fb_maxlength" value="">
<input type="hidden" name="fb_req" value="">
<input type="hidden" name="fb_quant" value="">
<input type="hidden" name="fb_allowMultiple" value="">
<input type="hidden" name="fb_precision" value="">
<input type="hidden" name="<% $addCallback %>" value="0">
<input type="hidden" name="<% $saveCallback %>" value="0">
<input type="hidden" name="<% $stayCallback %>" value="0">
<input type="hidden" name="delete" value="0">
% # close the current form context
</form>

<script language="javascript">
var curSub = 'text'
var cancelValidation = false

<%perl>
  if (defined $optionalFieldsLocation) {
      $m->out( 'var optionalFields = "'.$optionalFieldsLocation.'"'."\n");
  } else {
      $m->out( "var optionalFields = ''\n" );
  }
</%perl>

</script>

<& "/widgets/wrappers/sharky/table_top.mc",
   caption => $caption,
   number  => $num,
   height  => 230
&>

<div class="formBuilder clearboth">

<form name="fb_switch">
<ul class="formElement">
<li><input type="radio" name="formElement" id="formElementText" value="text" onclick="showForm('Text')" checked="checked" />
    <label for="formElementText"><% $lang->maketext('Text Box') %></label>
</li>
<li><input type="radio" name="formElement" id="formElementRadio" value="radio" onclick="showForm('Radio')" />
    <label for="formElementRadio"><% $lang->maketext('Radio Buttons')%></label>
</li>
<li><input type="radio" name="formElement" id="formElementCheckbox" value="checkbox" onclick="showForm('Checkbox')" />
    <label for="formElementCheckbox"><% $lang->maketext('Checkbox') %></label>
</li>
<li><input type="radio" name="formElement" id="formElementPulldown" value="pulldown" onclick="showForm('Pulldown')" />
    <label for="formElementPulldown"><% $lang->maketext('Pulldown') %></label>
</li>
<li><input type="radio" name="formElement" id="formElementSelect" value="select" onclick="showForm('Select')" />
    <label for="formElementSelect"><% $lang->maketext('Select') %></label>
</li>
<li><input type="radio" name="formElement" id="formElementCodeSelect" value="codeselect" onclick="showForm('CodeSelect')" />
    <label for="formElementCodeSelect"><% $lang->maketext('Code Select') %></label>
</li>
<li><input type="radio" name="formElement" id="formElementTextarea" value="textarea" onclick="showForm('Textarea')" />
    <label for="formElementTextarea"><% $lang->maketext('Text Area') %></label>
</li>
% if (ENABLE_WYSIWYG){
<li><input type="radio" name="formElement" id="formElementWYSIWYG" value="wysiwyg" onclick="showForm('WYSIWYG')" />
    <label for="formElementWYSIWYG"><% $lang->maketext('WYSIWYG') %></label>
</li>
% }
<li><input type="radio" name="formElement" id="formElementDate" value="date" onclick="showForm('Date')" />
    <label for="formElementDate"><% $lang->maketext('Date') %></label>
</li>
</ul>
</form>

<div id="fbDiv">

<form name="fb_form" action="<% $target %>" id="fbFormText" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="text" />

    <dl>
      <dt><label for="fbTextName"><%$lang->maketext('Key Name')%>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbTextName" /></dd>
      
      <dt><label for="fbTextDisp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type="text" name="fb_disp" id="fbTextDisp" /></dd>
      
      <dt><label for="fbTextDef"><% $lang->maketext('Default Value') %>:</label></dt>
      <dd><input type="text" name="fb_value" id="fbTextDef" /></dd>
    </dl>
    
    <dl>
      <dt><label for="fbTextSize"><%$lang->maketext('Size')%>:</label></dt>
      <dd><input type="text" name="fb_size" id="fbTextSize" value="32" size="3" /></dd>
      
      <dt><label for="fbTextMax"><% $lang->maketext('Max size') %>:</label></dt>
      <dd><input type="text" name="fb_maxlength" id="fbTextMax" value="0" size="4" /></dd>
    </dl>

    <dl class="position">
      <dt><label for="fbTextPosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbTextPosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbTextReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbTextReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbTextRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbTextRep" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>

</form>

<form name="fb_form" action="<% $target %>" id="fbFormRadio" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="radio" />
    
    <dl class="meta">
      <dt><label for="fbRadioName"><% $lang->maketext('Key Name') %>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbRadioName" /></dd>
      
      <dt><label for="fbRadioDisp"><% $lang->maketext('Group Label') %>:</label></dt>
      <dd><input type=text name=fb_disp id="fbRadioDisp" /></dd>
      
      <dt><label for="fbRadioDef"><% $lang->maketext('Default Value') %>:</label></dt>
      <dd><input type="text" name="fb_value" id="fbRadioDef" /></dd>
    </dl>
    
    <dl class="opts">
      <dt><label for="fbRadioOpts"><% $lang->maketext('Options, Label') %></label><br />
          (<% $lang->maketext('one per line')%>):</dt>
      <dd><textarea rows="<% $textareaRows %>" cols="<% $textareaCols %>" name="fb_vals" id="fbRadioOpts"></textarea></dd>
    </dl>

    <dl class="position">
      <dt><label for="fbRadioPosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbRadioPosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbRadioReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbRadioReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbRadioRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbRadioRep" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>

</form>

<form name="fb_form" action="<% $target %>" id="fbFormCheckbox" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="checkbox" />
    
    <dl class="meta">
      <dt><label for="fbCheckboxName"><% $lang->maketext('Key Name') %>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbCheckboxName" /></dd>
      
      <dt><label for="fbCheckboxDisp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type=text name=fb_disp id="fbCheckboxDisp" /></dd>
    </dl>
    
    <dl class="position">
      <dt><label for="fbCheckboxPosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbCheckboxPosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbCheckboxReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbCheckboxReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbCheckboxRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbCheckboxRep" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>

</form>

<form name="fb_form" action="<% $target %>" id="fbFormPulldown" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="pulldown" />

    <dl class="meta">
      <dt><label for="fbPulldownName"><% $lang->maketext('Key Name') %>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbPulldownName" /></dd>
      
      <dt><label for="fbPulldownDisp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type=text name=fb_disp id="fbPulldownDisp" /></dd>
      
      <dt><label for="fbPulldownDef"><% $lang->maketext('Default Value') %>:</label></dt>
      <dd><input type="text" name="fb_value" id="fbPulldownDef" /></dd>
    </dl>
    
    <dl class="opts">
      <dt><label for="fbPulldownOpts"><% $lang->maketext('Options, Label') %></label><br />
          (<% $lang->maketext('one per line')%>):</dt>
      <dd><textarea rows="<% $textareaRows %>" cols="<% $textareaCols %>" name="fb_vals" id="fbPulldownOpts"></textarea></dd>
    </dl>
    
    <dl class="position">
      <dt><label for="fbPulldownPosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbPulldownPosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbPulldownReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbPulldownReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbPulldownRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbPulldownRep" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>

</form>

<form name="fb_form" action="<% $target %>" id="fbFormSelect" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="select" />
    
    <dl class="meta">
      <dt><label for="fbSelectName"><% $lang->maketext('Key Name') %>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbSelectName" /></dd>
      
      <dt><label for="fbSelectDisp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type=text name=fb_disp id="fbSelectDisp" /></dd>
      
      <dt><label for="fbSelectDef"><% $lang->maketext('Default Value') %>:</label></dt>
      <dd><input type="text" name="fb_value" id="fbSelectDef" /></dd>
    </dl>
    
    <dl class="opts">
      <dt><label for="fbSelectOpts"><% $lang->maketext('Options, Label') %></label><br />
          (<% $lang->maketext('one per line')%>):</dt>
      <dd><textarea rows="<% $textareaRows %>" cols="<% $textareaCols %>" name="fb_vals" id="fbSelectOpts"></textarea></dd>
    </dl>
    
    <dl class="size">
      <dt><label for="fbSelectSize"><% $lang->maketext('Size') %>:</label></dt>
      <dd><input type="text" name="fb_size" id="fbSelectSize" value="5" size="3" /></dd>
      
      <dt><label for="fbSelectMulti"><% $lang->maketext('Allow multiple') %>?</label></dt>
      <dd><input type="checkbox" name="fb_allowMultiple" id="fbSelectMulti" /></dd>
    </dl>

    <dl class="position">
      <dt><label for="fbSelectPosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbSelectPosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbSelectReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbSelectReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbSelectRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbSelectRep" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>
    
</form>

<form name="fb_form" action="<% $target %>" id="fbFormCodeSelect" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="codeselect" />
    
    <dl class="meta">
      <dt><label for="fbCodeSelectName"><% $lang->maketext('Key Name') %>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbCodeSelectName" /></dd>
      
      <dt><label for="fbCodeSelectDisp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type=text name=fb_disp id="fbCodeSelectDisp" /></dd>
      
      <dt><label for="fbCodeSelectDef"><% $lang->maketext('Default Value') %>:</label></dt>
      <dd><input type="text" name="fb_value" id="fbCodeSelectDef" /></dd>
    </dl>
    
    <dl class="opts"> <!-- class="code" ? -->
      <dt><label for="fbCodeSelectCode"><% $lang->maketext('Code') %>:</label><dt/>
      <dd><textarea rows="<% $textareaRows %>" cols="<% $textareaCols %>" name="fb_vals" id="fbCodeSelectCode"></textarea></dd>
    </dl>
    
    <dl class="size">
      <dt><label for="fbCodeSelectSize"><% $lang->maketext('Size') %>:</label></dt>
      <dd><input type="text" name="fb_size" id="fbCodeSelectSize" value="5" size="3" /></dd>
      
      <dt><label for="fbCodeSelectMulti"><% $lang->maketext('Allow multiple') %>?</label></dt>
      <dd><input type="checkbox" name="fb_allowMultiple" id="fbCodeSelectMulti" /></dd>
    </dl>

    <dl class="position">
      <dt><label for="fbCodeSelectPosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbCodeSelectPosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbCodeSelectReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbCodeSelectReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbCodeSelectRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbCodeSelectRep" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>
    
</form>

<form name="fb_form" action="<% $target %>" id="fbFormTextarea" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="textarea" />
    
    <dl>
      <dt><label for="fbTextareaName"><%$lang->maketext('Key Name')%>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbTextareaName" /></dd>
      
      <dt><label for="fbTextareaDisp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type="text" name="fb_disp" id="fbTextareaDisp" /></dd>
      
      <dt><label for="fbTextareaDef"><% $lang->maketext('Default Value') %>:</label></dt>
      <dd><input type="text" name="fb_value" id="fbTextareaDef" /></dd>
    </dl>
    
    <dl>
      <dt><label for="fbTextareaRows"><%$lang->maketext('Rows')%>:</label></dt>
      <dd><input type="text" name="fb_rows" id="fbTextareaRows" value="4" size="3" /></dd>
      
      <dt><label for="fbTextareaCols"><% $lang->maketext('Columns') %>:</label></dt>
      <dd><input type="text" name="fb_cols" id="fbTextareaCols" value="40" size="3" /></dd>
      
      <dt><label for="fbTextareaMax"><% $lang->maketext('Max size') %>:</label></dt>
      <dd><input type="text" name="fb_maxlength" id="fbTextareaMax" value="0" size="4" /></dd>
    </dl>
    
    <dl class="position">
      <dt><label for="fbTextareaPosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbTextareaPosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbTextareaReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbTextareaReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbTextareaRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbTextareaRep" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>

</form>

% if (ENABLE_WYSIWYG) {
<form name="fb_form" action="<% $target %>" id="fbFormWYSIWYG" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="wysiwyg" />
    <input type="hidden" name="fb_allowMultiple" value="1" />
    
    <dl>
      <dt><label for="fbWYSIWYGName"><%$lang->maketext('Key Name')%>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbWYSIWYGName" /></dd>
      
      <dt><label for="fbWYSIWYGDisp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type="text" name="fb_disp" id="fbWYSIWYGDisp" /></dd>
      
      <dt><label for="fbWYSIWYGDef"><% $lang->maketext('Default Value') %>:</label></dt>
      <dd><input type="text" name="fb_value" id="fbWYSIWYGDef" /></dd>
    </dl>
    
    <dl>
      <dt><label for="fbWYSIWYGRows"><%$lang->maketext('Rows')%>:</label></dt>
      <dd><input type="text" name="fb_rows" value="8" size="3" onchange="if (this.value < 8) {this.value=8;}" /></dd>
      
      <dt><label for="fbWYSIWYGCols"><% $lang->maketext('Columns') %>:</label></dt>
      <dd><input type="text" name="fb_cols" value="67" size="3" onchange="if (this.value < 67) {this.value=67;}" /></dd>
    </dl>
    
    <dl class="position">
      <dt><label for="fbWYSIWYGPosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbWYSIWYGPosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbWYSIWYGReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbWYSIWYGReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbWYSIWYGRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbWYSIWYGRep" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>

</form>
% }

<form name="fb_form" action="<% $target %>" id="fbFormDate" class="fbForm" onsubmit="return formBuilder.submit(this, '<% $formName %>', 'add');">
    <input type="hidden" name="fb_type" value="date" />

    <dl>
      <dt><label for="fbDateName"><% $lang->maketext('Key Name') %>:</label></dt>
      <dd><input type="text" name="fb_name" id="fbDateName" /></dd>

      <dt><label for="fbDateDisp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type="text" name="fb_disp" id="fbDateDisp" /></dd>
    </dl>
    
    <dl>
      <dt><label for="fbDatePrecision"><% $lang->maketext('Precision') %>:</label></dt>
      <dd><select name="fb_precision" for="fbDatePrecision">
          <% $precision_select %>
          </select>
      </dd>
    </dl>
    
    <dl class="position">
      <dt><label for="fbDatePosition"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fbDatePosition">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fbDateReq"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fbDateReq" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fbDateRep"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fbDateRep" /></dd>
%}
    </dl>

    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" />
    </div>

</form>

</div>

</div>

<& "/widgets/wrappers/sharky/table_bottom.mc" &>

<form method="post" action="#" name="fb_magic_buttons" id="fbMagicButtons">
<div class="delete">
<& '/widgets/profile/displayFormElement.mc',
         key => 'delete',
         vals => { disp => '<span class="burgandyLabel">'.$lang->maketext('Delete this Profile').'</span>',
                   props => { type => 'checkbox',
                              label_after => 1 },
#                  value => '0',
                   id => 'deleteProfile'
                 },
         useTable => 0
&>
</div>

<div class="buttons">
    <input type="image" src="/media/images/<% $lang_key %>/save_red.gif" onclick="formBuilder.submit(null, '<% $formName %>', 'save'); return false;" alt="Save" />
%    $m->out(qq{<input type="image" src="/media/images/$lang_key/save_and_stay_lgreen.gif" onclick="formBuilder.submit(null, '$formName', 'save_n_stay'); return false;" alt="Save and Stay" />\n}) if $stay;
    <a href="#" onclick="window.location.href='<% "/$section/manager/$type/" %>'; return false;"><img src="/media/images/<% $lang_key %>/return_dgreen.gif" alt="Return" /></a>
</div>
</form>
