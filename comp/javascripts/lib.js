<%perl>
# create a browser detect variable
my $agent = $m->comp('/widgets/util/detectAgent.mc');
</%perl>

// set up global to track names of double list managers
var doubleLists = new Array();
var formObj = '';

function validateStory(obj) {

    if (hasSpecialCharacters(obj["slug"].value)) {
	alert("The slug can only contain alphanumeric characters (A-Z, 0-9, - or _)!");
	obj["slug"].focus();
	return false;
    }
    return true;
}

/*
returns number of words in form field, based on number of spaces found
*/
function wordCount(obj, targetName, wordResultName, charResultName) {

    var target = obj[targetName];
    var word   = obj[wordResultName];
    var chars  = obj[charResultName];
    var tmp    = new Array();
    var words  = new Array();

    tmp = target.value.split(" ");
    for (i=0; i<tmp.length; i++) {
	if ( tmp[i].length && tmp[i] != "\r" ) {
	    words[words.length] = tmp[i];
	}
    }
    
    word.value  = words.length;
    chars.value = target.value.length
    return false;
}

/*
if an array named roles is defined, look for the form field value in it,
and do an alert and return false if found.
*/
function uniqueRole(obj) {

    if (typeof roles != "undefined") {
	if (inArray(obj.value, roles)) {
	    alert("You must supply a unique name for this role!");
	    obj.focus();
	    return false;
	}
    }
    return true
}

/*
Input: an object ref to username field
Output: true if username meets the defined rules, false otherwise
*/
function checkLogin(obj) {
	var what = obj.value

	// login must be 6 characters minimum
	if (what.length < 6) {
		alert("Usernames must be at least 6 characters!");
		obj.focus();
		return false;
	}

	// Only allow these characters: A-Za-z0-9_-.@
	var regExp = new RegExp("[^a-zA-Z0-9_-.@]");
	return regExp.test(what);
	
}

/*
sets a callback to be handled, as if it were an image submit button.  optFunctions is an array of
javascript statements that can be evaluated before the form is submitted.
Input: name of the form to be submitted, an array of callbacks to be sent, an array of optional statements
Output: returns false to cancel the link action.
*/
function customSubmit(formName, cbNames, cbValues, optFunctions) {

    var frm = document.forms[formName];

    if(typeof cbNames == "string") {
	frm.elements[cbNames].value = cbValues;
    } else {
	for (var i in cbNames) {
	    frm.elements[cbNames[i]].value = cbValues[i];
	    alert(frm.elements[cbNames[i]].name);
	}
    }
    if (typeof optFunctions == "string") {
	eval(optFunctions);
    } else {
	for (var i in optFunctions) {
	    eval(optFunctions[i]);
	}
    }

    frm.submit();
    return false;
}

/*
Input: object refs to password fields
Output: true if username meets the defined rules, false otherwise
*/
function checkPasswords(obj1, obj2) {

    var pass1 = obj1.value;
    var pass2 = obj2.value;

    if (!newUser && pass1.length == 0) return true;
    
    // No fewer than 6 characters.
    if (pass1.length < <% PASSWD_LENGTH %>) {
	alert("Passwords must be at least <% PASSWD_LENGTH %> characters!");
	obj1.focus();
	return false;
    }

    // must match
    if (pass1 != pass2) {
	alert("Passwords must match!");
	obj1.value = "";
	obj2.value = "";
	obj1.focus();
	return false;
    }
    
    // No preceding or trailing spaces.
    if (pass1.substring(0,1) == " ") {
	alert("Passwords cannot have spaces at the beginning!");
	obj1.value = "";
	obj2.value = "";
	obj1.focus();
	return false;		
    }
    if (pass1.substring(pass1.length-1, pass1.length) == " ") {
	alert("Passwords cannot have spaces at the end!");
	obj1.value = "";
	obj2.value = "";
	obj1.focus();
	return false;
    }
	
    return true;
	
}

/*
returns true if characters that would be illegal for a url are found, false otherwise.
*/
function hasSpecialCharacters(what) {

    var regExp = new RegExp("[^a-zA-Z0-9/_-]");
    return regExp.test(what);

}

/*
general textarea cleanup function
*/
function textUnWrap (text) {
    var text2 = text.replace( /\r\n/g, "\n");    //Change Windows newlines to Unix newlines.
    text      = text2.replace( /\n{3,}/, "\n\n"); //Allow only two newlines between paragraphs on Unix & Win.
    text2     = text.replace( /\r{3,}/, "\r\r"); //Allow only two returns between paragraphs on Macs.
    //Return with newlines or returns only between paragraphs - not within paragraphs.
    return text2.replace( /([^\n])\x20*\n\x20*([^\n])|([^\r])\r([^\r])/g, "$1 $2");
}

/*
input: a form object, and the name of the form it contains
output: none.
This function is called when a position drop down is changed in a story profile.
It looks for form elements named in the selectOrderNames array, and tries to find
a new home for the now displaced value.
*/
function reorder(obj) {

    var newVal  = obj.selectedIndex;
    var tmp;
    var form  = obj.form;

    // Bail if there are no names.
    if (typeof selectOrderNames == "undefined") return false;

    var curObjName;
    var curObjVal;
    var curObj = new Object();
    var orderObjs = new Array(); 

    // First order the elements by their index.
    for (var i = 0; i < selectOrderNames.length; i++) {
        curObjName = selectOrderNames[i];
        curObj     = form[curObjName];
	if (curObj.type == null) {
	    // It's an array. Process all if its elements.
            for (var i = 0; i < curObj.length; i++) {
	        curObjVal = curObj[i].selectedIndex;
   	        if (curObj[i] != obj) {
		    orderObjs[curObjVal] = curObj[i];
                }
            }
        } else {
	    // It's a normal input object.
    	    curObjVal  = curObj.selectedIndex;
	    if (curObj != obj) {
		orderObjs[curObjVal] = curObj;
	    }
        }
    }

    var offset = 0;

    // Now go through and shift the elements forward or backward as required.
    for (var i=0; i<orderObjs.length; i++) {
	curObj     = orderObjs[i];

        // If we hit an empty array slot, its where the moving element is; suck
        // the subsequent elements towards it.
        if (typeof curObj == "undefined") {
            // This is the empty space left by the moving element; backshuffle
            offset = offset - 1;


        // Otherwise get the object and see if we need to update our offset
        } else {

            // No shifting has been done if offset is 0 
	    if ((i == newVal) && (offset == 0)) {
                offset = offset + 1;
            }
            // Special adjustment to make sure all necessary elems are shifted
            if ((i == (newVal+1)) && (offset == -1)) {
                offset = 0;
            }

            // Update the index.
            curObj.selectedIndex = curObj.selectedIndex + offset;
        }
    }
}


/*
input: a value, and a hash
output: returns true if the value of 'what' is found in the values of the hash, otherwise returns false
*/
function inHash(what, hash) {

    for (field in hash) {
	if (hash[field] == what) return true;
    }
    return false;
}

/*
Input: name of the year, month and days form fields, plus a handle to the currently modified form object.
Output: adjusts the number of days in the days dropdown to be valid for the currently selected month, year, etc.
*/
function setDays (year, month, days, obj) {

    var form = obj.form

    var yearObj  = form[year];
    var monthObj = form[month];
    var daysObj  = form[days];

    var month  = monthObj.options[monthObj.selectedIndex].value;
    var year   = yearObj.options[yearObj.selectedIndex].value;
    var curDay = daysObj.options[daysObj.selectedIndex].value;
    var numDays = 30;
    var opt;
	
    if (month == "01" || month == "03" || month == "05" || month == "07" || month == "08" || month == "10" || month == "12") {	
	numDays = 31;
    } else if (month == "02") {
	if ( ! (year % 4) ) {
	    numDays = 29;
	} else {
	    numDays = 28;
	}
    }

    // If the list is longer than num days, just truncate it.
    if (daysObj.options.length > numDays) {
	daysObj.options.length = numDays + 1;
    } 
    // If its shorter than num days, add to it.
    else {
	for (var i=daysObj.options.length; i <= numDays; i++) {
            opt = new Option(i,i);
	    daysObj.options[i] = opt;
        }
    }

    if (numDays < curDay) {
	alert("This day does not exist! Your day is changed to the " + numDays + "th");
	curDay = numDays;
    }

    daysObj.selectedIndex = (curDay == -1) ? 0 : curDay;
}

/*
Input: name of a form property table
Ouput: displays new table on the page in the form builder area.  Along the way, it caches any values that could be 
consistent from form to form, and repopulates the new form with the cached values.  Finally, the cursor focus is moved
to the name field of the new form.
*/
function showForm(which) {

% if ($agent->{browser} eq "Netscape") { # create spacer html for netscape
    var html = '<table><tr><td><img src="/media/images/spacer.gif" width=300 height=25></td></tr></table>';
% } else {
    var html = '';
% }
    var name, caption, vals, length, maxlength;

    // get handle to fb form object
    var fb_obj = (document.layers) ? document.layers["fbDiv"].document.fb_form : document.all.fbDiv.all.fb_form;

    // gather the current values the user may have entered in the form
    if (typeof fb_obj != "undefined" ) { // prevent error if first time
	name      = fb_obj.fb_name.value;
	caption   = fb_obj.fb_disp.value;
	vals      = (typeof (fb_obj.fb_vals)      != "undefined" && fb_obj.fb_vals.value)      ? fb_obj.fb_vals.value   : '';
	length    = (typeof (fb_obj.fb_length)    != "undefined" && fb_obj.fb_length.value)    ? fb_obj.fb_length.value : '';
	maxlength = (typeof (fb_obj.fb_maxlength) != "undefined" && which != 'textarea' && fb_obj.fb_maxlength.value) ? fb_obj.fb_maxlength.value : '';
    }

    // put the html together and write it to the div
    // create spacer html for netscape
    html    += eval(which + "_table");
    html    += optionalFields;
    writeDiv("fbDiv", html);

    // repopulate the new form with any values that may have been present in the old form, where applicable.
    if (typeof fb_obj != "undefined" ) { // prevent error if first time
	fb_obj = (document.layers) ? document.layers["fbDiv"].document.fb_form : document.all.fbDiv.all.fb_form;
	fb_obj.fb_name.value = name;
	fb_obj.fb_disp.value = caption;
	if (typeof fb_obj.fb_vals      != "undefined") fb_obj.fb_vals.value = vals;
	if (typeof fb_obj.fb_length    != "undefined") fb_obj.fb_length.value = length;
	if (typeof fb_obj.fb_maxlength != "undefined") fb_obj.fb_maxlength.value = maxlength;
    }

% if ($agent->{browser} ne "Netscape" && $agent->{os} ne "Windows" ) { # the focus method causes the window to jump on NS/PC 
    // get handle to new form
    fb_obj = (document.layers) ? document.layers["fbDiv"].document.fb_form : document.all.fbDiv.all.fb_form;
 
    // move the focus to the name field
    if (typeof fb_obj != "undefined" ) fb_obj.fb_name.focus();

% }

}

/*
Generic function to write html to div or layer on a page.
*/
function writeDiv(which, html) {

    if (document.layers) {
	document.layers[which].document.open();
	document.layers[which].document.write(html);
	document.layers[which].document.close();
    } else {
	var tmp = eval("document.all." + which);
	tmp.innerHTML = html;
    }
}

/*
Input: a string.
Output: Returns false if there is non whitespace text in the string, true if it is blank.
*/
function isEmpty(what) {
    for (var i=0; i < what.length; i++) {
	var c = what.charAt(i);
	if ((c != ' ') && (c != '\n') && (c != '\t')) return false;
    }
    return true
}


function confirmDeletions() {
    return confirm("You are about to permanently delete items! Do you wish to continue?");
}

/*
Submits the main form when a user hits the 'add to form' button in the form builder.  Calls confirmChanges() along the way.
*/
function formBuilderMagicSubmit(formName, action) {

    if (action == "add") {
	if (confirmFormBuilder(formName)) { // verify data
	    document[formName].elements["formBuilder|add_cb"].value = 1;
	    document[formName].submit();
	}
    } else {
        // get the delete button value into the main form: 
        if (document.fb_magic_buttons.elements["delete"].checked) {
	    document[formName].elements["delete"].value = 1;
            // Always just save when we're deleting.
            document[formName].elements["formBuilder|save_cb"].value = 1;
        } else {
            // It'll either save or save and stay.
            document[formName].elements["formBuilder|" + action + "_cb"].value = 1;
        }
        if ( confirmChanges(document[formName]) ) document[formName].submit();	
    }

}

function confirmFormBuilder(formName) {
    var fb_obj;
    var obj    = document[formName];

    // get object reference
% if ($agent->{browser} eq "Netscape") {  
    if (document.layers["fbDiv"]) {
	fb_obj = document.layers["fbDiv"].document.fb_form;
    }
% } else {
    if (document.all.fbDiv) fb_obj = document.all.fbDiv.all.fb_form;
% }

    // look for formbuilder objects, and get their values
    // assign these values to the hidden fields in the main form

    for (var i=0; i < fb_obj.elements.length; i++) {
	var curName = fb_obj.elements[i].name;
	if (curName != "fb_position") {
	    if (fb_obj.elements[i].type == 'checkbox') {
		if (fb_obj.elements[i].checked == true) {
		    obj[curName].value = 1;
		}
	    } else if (!isEmpty(fb_obj.elements[i].value) ) {
		obj[curName].value = fb_obj.elements[i].value;
	    } else if (curName != "fb_value") {
		alert("You must provide a value for all data field elements!");
		fb_obj.elements[i].focus();
		confirming = false // check this
		    return false;			
	    }
	} else {
	    obj[curName].value = textUnWrap( fb_obj.elements[i].options[fb_obj.elements[i].selectedIndex].value );
	}
    }

    // get the delete button value into the main form: 
    if (fb_obj && document.fb_magic_buttons.elements["delete"].checked) obj.elements["delete"].value = 1;

    // all good
    return true;
}

/*
Prompts the user if any changes have been made to form fields.  Checks for double list
managers on the page.  If any are found, all left values are deselected, and any
new values on the right are marked selected.
*/
var confirming = false
var submitting = false
function confirmChanges(obj) {
    
    if (confirming || submitting) return false;
    confirming = true
    var ret = true;
    var tmp;
    var confirmed = false;

    // Check f r slug.
    if (typeof obj["slug"] != "undefined") {
    if (!validateStory(obj)) {
	    // The slug isn't valid! Return false.
            confirming = false;
            return false;
        }
    }

    // look for a delete checkbox and do an alert if it is checked...
    for (var i=0; i < document.forms.length; i++) {
	var tmp = document.forms[i];	
	for (var j=0; j < tmp.elements.length; j++) {	
	    if (tmp.elements[j].type == "checkbox" && tmp.elements[j].name.indexOf("delete") != -1) {    		
		if (tmp.elements[j].checked && !confirmed) {
		    ret = confirmDeletions();
		    confirmed = true;
		}
	    }
	}
    }

    // check for password fields.  Make sure they match.
    if (typeof obj.pass_1 != "undefined" && typeof obj.pass_2 != "undefined") {
	if (obj.pass_1.value != obj.pass_2.value) {
	    alert("Passwords do not match!  Please re-enter.");
	    obj.pass_1.value = '';
	    obj.pass_2.value = '';
	    obj.pass_1.focus();
	    confirming = false
	    return false;
	}
    }
    
    // make sure all required fields are filled out.
    if (typeof requiredFields != "undefined") {       	
	for (field in requiredFields) {
	    tmp = obj[field];
	    if (typeof tmp != "undefined") {
		if ( tmp.value == '') {
		    alert("You must supply a value for " + requiredFields[field]);
		    tmp.focus();
		    confirming = false
		    return false;
		}
	    }
	}
    }
   
    // examine registered special character fields
    if (typeof specialCharacterFields != "undefined") {       	
	for (field in specialCharacterFields) {
	    tmp = eval("obj." + field);
	    if (typeof tmp != "undefined") {
		if ( hasSpecialCharacters(tmp.value) ) {
		    alert( specialCharacterFields[field] + " contains illegal characters!" );
		    tmp.focus();
		    confirming = false
		    return false;
		}
	    }
	}
    }  


    // if we get this far, we've got a live submission.
    // if there is a 2xLM,
    // find the items that are new on the right, mark them 
    // selected, and send it on.
    if (formObj) {       
	// loop thru the array of 2xLM names
	for (var i=0; i < doubleLists.length; i++) {
	    var tmp = doubleLists[i].split(":");
	    var leftObj  = formObj.elements[tmp[0]]; // get handle to lVals
	    var rightObj = formObj.elements[tmp[1]]; // get handle to rVals on form
	    var lVals = eval(tmp[0] + "_values");     // get handle to original lVals array
	    var rVals = eval(tmp[1] + "_values");     // get handle to original rVals array

	    // loop thru the right vals in the list...
	    for (var j=0; j < rightObj.length; j++) {
		if (!inArray(rightObj[j].value, rVals)) { // if value not in original rvals list, mark it selected
		    rightObj[j].selected = true;
		} else {  // else mark it not selected (to keep it from accidentally being submitted)
		    rightObj[j].selected = false;
		}
	    }

	    // loop thru the left vals in the list...
	    for (var j=0; j < leftObj.length; j++) {
		if (!inArray(leftObj[j].value, lVals)) { // if value not in original rvals list, mark it selected
		    leftObj[j].selected = true;
		} else {  // else mark it not selected (to keep it from accidentally being submitted)
		    leftObj[j].selected = false;
		}
	    }
	}
    }
    confirming = false
    submitting = ret
    return ret
}

function inArray(what, arr) {

    for (var i=0; i < arr.length; i++) {
	if (arr[i].toString() == what.toString()) return true
    }
    return false
}

function isInList(what, list) {

	for (var i=0; i < list.length; i++) {
		if (list.options[i].value == what) return true
	}
	return false;
}
// end double list manager functions


