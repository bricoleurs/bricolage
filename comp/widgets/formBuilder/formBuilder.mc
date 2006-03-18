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
my $numFieldsTxt = '<input type="hidden" name="fieldNum" value="1" />';

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

<script type="text/javascript">
// Label overrides
formBuilder.labels = new Array();
formBuilder.labels['radio'] = new Array();
formBuilder.labels['radio']['fb_disp']  = '<% $lang->maketext('Group Label') %>';
formBuilder.labels['codeselect'] = new Array();
formBuilder.labels['codeselect']['fb_vals']  = '<% $lang->maketext('Code') %>';

// Value overrides
formBuilder.values = new Array();
formBuilder.values['select'] = new Array();
formBuilder.values['select']['fb_size'] = 5;
formBuilder.values['codeselect'] = new Array();
formBuilder.values['codeselect']['fb_size'] = 5;
formBuilder.values['wysiwyg'] = new Array();
formBuilder.values['wysiwyg']['fb_rows'] = 8;
formBuilder.values['wysiwyg']['fb_cols'] = 67;
</script>

% # add hidden fields to receive the values of the fbuilder
<input type="hidden" name="<% $addCallback %>" value="0" />
<input type="hidden" name="<% $saveCallback %>" value="0" />
<input type="hidden" name="<% $stayCallback %>" value="0" />
<input type="hidden" name="delete" value="0">
% # close the current form context

<script language="javascript">
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
   number  => $num
&>

<div id="formBuilder" class="clearboth">

<ul class="types">
<li><input type="radio" name="fbSwitcher" id="formElementText" value="text" onclick="formBuilder.switchType('text')" checked="checked" />
    <label for="formElementText"><% $lang->maketext('Text Box') %></label>
</li>
<li><input type="radio" name="fbSwitcher" id="formElementRadio" value="radio" onclick="formBuilder.switchType('radio')" />
    <label for="formElementRadio"><% $lang->maketext('Radio Buttons')%></label>
</li>
<li><input type="radio" name="fbSwitcher" id="formElementCheckbox" value="checkbox" onclick="formBuilder.switchType('checkbox')" />
    <label for="formElementCheckbox"><% $lang->maketext('Checkbox') %></label>
</li>
<li><input type="radio" name="fbSwitcher" id="formElementPulldown" value="pulldown" onclick="formBuilder.switchType('pulldown')" />
    <label for="formElementPulldown"><% $lang->maketext('Pulldown') %></label>
</li>
<li><input type="radio" name="fbSwitcher" id="formElementSelect" value="select" onclick="formBuilder.switchType('select')" />
    <label for="formElementSelect"><% $lang->maketext('Select') %></label>
</li>
<li><input type="radio" name="fbSwitcher" id="formElementCodeSelect" value="codeselect" onclick="formBuilder.switchType('codeselect')" />
    <label for="formElementCodeSelect"><% $lang->maketext('Code Select') %></label>
</li>
<li><input type="radio" name="fbSwitcher" id="formElementTextarea" value="textarea" onclick="formBuilder.switchType('textarea')" />
    <label for="formElementTextarea"><% $lang->maketext('Text Area') %></label>
</li>
% if (ENABLE_WYSIWYG){
<li><input type="radio" name="fbSwitcher" id="formElementWYSIWYG" value="wysiwyg" onclick="formBuilder.switchType('wysiwyg')" />
    <label for="formElementWYSIWYG"><% $lang->maketext('WYSIWYG') %></label>
</li>
% }
<li><input type="radio" name="fbSwitcher" id="formElementDate" value="date" onclick="formBuilder.switchType('date')" />
    <label for="formElementDate"><% $lang->maketext('Date') %></label>
</li>
</ul>


<div id="fbDiv" class="fbDiv">

    <input type="hidden" name="fb_type" id="fb_type" value="text" />

    <dl class="meta">
      <dt><label for="fb_name"><% $lang->maketext('Key Name') %>:</label></dt>
      <dd><input type="text" name="fb_name" id="fb_name" /></dd>
      
      <dt><label for="fb_disp"><% $lang->maketext('Label') %>:</label></dt>
      <dd><input type="text" name="fb_disp" id="fb_disp" /></dd>
      
      <dt class="fb_value"><label for="fb_value"><% $lang->maketext('Default Value') %>:</label></dt>
      <dd class="fb_value"><input type="text" name="fb_value" id="fb_value"/></dd>
    </dl>

    <dl class="opts">
      <dt><label for="fb_vals"><% $lang->maketext('Options, Label') %><br /><span class="small">(<% $lang->maketext('one per line')%>):</span></label></dt>
      <dd><textarea rows="5" cols="25" name="fb_vals" id="fb_vals"></textarea></dd>
    </dl>    

    <dl class="size">
      <dt class="fb_precision"><label for="fb_precision"><% $lang->maketext('Precision') %>:</label></dt>
      <dd class="fb_precision"><select name="fb_precision" id="fb_precision">
          <% $precision_select %>
          </select>
      </dd>
    
      <dt class="fb_rows"><label for="fb_rows"><%$lang->maketext('Rows')%>:</label></dt>
      <dd class="fb_rows"><input type="text" name="fb_rows" id="fb_rows" value="4" size="3" /></dd>
      
      <dt class="fb_cols"><label for="fb_cols"><% $lang->maketext('Columns') %>:</label></dt>
      <dd class="fb_cols"><input type="text" name="fb_cols" id="fb_cols" value="40" size="3" /></dd>
      
      <dt class="fb_size"><label for="fb_size"><%$lang->maketext('Size')%>:</label></dt>
      <dd class="fb_size"><input type="text" name="fb_size" id="fb_size" size="3" value="32" /></dd>
      
      <dt class="fb_maxlength"><label for="fb_maxlength"><% $lang->maketext('Max size') %>:</label></dt>
      <dd class="fb_maxlength"><input type="text" name="fb_maxlength" id="fb_maxlength" value="0" size="4" /></dd>
      
      <dt class="fb_allowMultiple"><label for="fb_allowMultiple"><% $lang->maketext('Allow multiple') %>?</label></dt>
      <dd class="fb_allowMultiple"><input type="checkbox" name="fb_allowMultiple" id="fb_allowMultiple" /></dd>
    </dl>

    <dl class="position">
      <dt><label for="fb_position"><% $lang->maketext('Position') %>:</label></dt>
      <dd><select name="fb_position" id="fb_position">
          <% $numFieldsOpts %>
          </select>
      </dd>
%if ($useRequired){
      <dt><label for="fb_req"><% $lang->maketext('Required') %>:</label></dt>
      <dd><input type="checkbox" name="fb_req" id="fb_req" /></dd>
%}
%if ($useQuantifier){
      <dt><label for="fb_quant"><% $lang->maketext('Repeatable') %>:</label></dt>
      <dd><input type="checkbox" name="fb_quant" id="fb_quant" /></dd>
%}
    </dl>
    
    <div class="submit">
        <input type="image" src="/media/images/<% $lang_key %>/add_to_form_lgreen.gif" title="Add to Form" onclick="formBuilder.submit('', '<% $formName %>', 'add')" />
    </div>

</div>

</div>

<& "/widgets/wrappers/sharky/table_bottom.mc" &>

<div id="fbMagicButtons">
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
</div>
