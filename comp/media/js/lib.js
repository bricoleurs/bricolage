// set up global to track names of double list managers
 var doubleLists = new Array();
var formObj = '';

function validateStory(obj) {

    if (hasSpecialCharacters(obj["slug"].value)) {
        alert(slug_chars_msg);
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
            alert(role_msg);
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
function checkLogin(obj, length, pass1, pass2, passwd_length) {
    var what = obj.value

    // login must be length characters minimum
    if (what.length < length) {
        alert(login_msg1 + length + login_msg2);
        obj.focus();
        return false;
    }
    return checkPasswords(pass1, pass2, passwd_length);
}

/*
Input: object refs to password fields
Output: true if username meets the defined rules, false otherwise
*/
function checkPasswords(obj1, obj2, passwd_length) {

    var pass1 = obj1.value;
    var pass2 = obj2.value;

    if (!newUser && pass1.length == 0) return true;
    
    // No fewer than 6 characters.
    if (pass1.length < passwd_length) {
        alert(passwd_msg1 + passwd_length + passwd_msg2);
        obj1.focus();
        return false;
    }

    // must match
    if (pass1 != pass2) {
        alert(passwd_match_msg);
        obj1.value = "";
        obj2.value = "";
        obj1.focus();
        return false;
    }

    // No preceding or trailing spaces.
    if (pass1.substring(0,1) == " ") {
        alert(passwd_start_msg);
        obj1.value = "";
        obj2.value = "";
        obj1.focus();
        return false;      
    }
    if (pass1.substring(pass1.length-1, pass1.length) == " ") {
        alert(passwd_end_msg);
        obj1.value = "";
        obj2.value = "";
        obj1.focus();
        return false;
    }
    return true;
}

/*
Sets a callback to be handled, as if it were an image submit
button. optFunctions is an array of javascript statements that can be
evaluated before the form is submitted. Input: name of the form to be
submitted, an array of callbacks to be sent, an array of optional statements
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
    if (optFunctions != null) {
        if (typeof optFunctions == "string") {
            eval(optFunctions);
        } else {
            for (var i in optFunctions) {
                eval(optFunctions[i]);
            }
        }
    }

    if (frm.onsubmit) {
       if (frm.onsubmit()) {
           frm.submit();
       }
    } else {
        frm.submit();
    }
    return false;
}


/*
returns true if characters that would be illegal for a url are found, false otherwise.
*/
function hasSpecialCharacters(what) {
    var regExp = new RegExp("[^-a-zA-Z0-9_.]");
    return regExp.test(what);

}

/*
returns true if characters that would be illegal for a URL prefix or suffix, false otherwise.
*/
function hasSpecialCharactersOC(what) {
    var regExp = new RegExp("[^-a-zA-Z0-9_./]");
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
        // the subsequent elements toward it.
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
        alert(day_msg + numDays);
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

    var html = '';
    var name, caption, vals, length, maxlength;

    // get handle to fb form object
    var fb_obj = (document.layers) 
        ? document.layers["fbDiv"].document.fb_form 
        : document.all ? document.all.fbDiv.all.fb_form 
        : document.getElementById('fbDiv').getElementsByTagName('form')[0];

    // gather the current values the user may have entered in the form
    if (fb_obj) { // prevent an error if first time (nothing could have been inputted yet)
        name    = (fb_obj.fb_name) ? (fb_obj.fb_name.value) : '';
        caption = (fb_obj.fb_disp) ? (fb_obj.fb_disp.value) : '';
        vals    = (fb_obj.fb_vals) ? (fb_obj.fb_vals.value) : '';
        length  = (fb_obj.fb_length) ? (fb_obj.fb_length.value) : '';
        maxlength   = (fb_obj.fb_length) ? (fb_obj.fb_maxlength.value) : '';
    }

    // put the html together and write it to the div
    // create spacer html for netscape
    html    += eval(which + "_table");
    html    += optionalFields;
    writeDiv("fbDiv", html);

    // repopulate the new form with any values that may have been present in the old form, where applicable.
    if (fb_obj) { // prevent an error if first time (nothing could have been inputted yet)

        fb_obj = (document.layers) 
            ? document.layers["fbDiv"].document.fb_form 
            : document.all ? document.all.fbDiv.all.fb_form 
            : document.getElementById('fbDiv').getElementsByTagName('form')[0];

        fb_obj.fb_name.value = name;
        fb_obj.fb_disp.value = caption;
        if (fb_obj.fb_vals) fb_obj.fb_vals.value = vals;
        if (fb_obj.fb_length) fb_obj.fb_length.value = length;
        if (fb_obj.fb_maxlength) fb_obj.fb_maxlength.value = maxlength;
    }

    // get handle to new form
    fb_obj = (document.layers) 
        ? document.layers["fbDiv"].document.fb_form 
        : document.all ? document.all.fbDiv.all.fb_form 
        : document.getElementById('fbDiv').getElementsByTagName('form')[0];
            
    // move the focus to the name field
    if (fb_obj) fb_obj.fb_name.focus();
}

/*
Generic function to write html to div or layer on a page.
*/
function writeDiv(which, html) {

    if (document.layers) {
        document.layers[which].document.open();
        document.layers[which].document.write(html);
        document.layers[which].document.close();
    } else if (document.all) {
        var tmp = eval("document.all." + which);
        tmp.innerHTML = html;
    } else {
        var tmp = document.getElementById(which);
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
    return confirm(warn_delete_msg);
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
    var obj    = document[formName];
    var fb_obj = (document.layers) ? document.layers["fbDiv"].document.fb_form : document.all ? document.all.fbDiv.all.fb_form : document.getElementById('fbDiv').getElementsByTagName('form')[0];

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
                alert(data_msg);
                fb_obj.elements[i].focus();
                confirming = false // check this
                    return false;                       
            }
        } else {
            obj[curName].value = textUnWrap( fb_obj.elements[i].options[fb_obj.elements[i].selectedIndex].value );
        }
    }

    // get the delete button value into the main form: 
    if (fb_obj && document.fb_magic_buttons.elements["delete"] &&
        document.fb_magic_buttons.elements["delete"].checked) {
            obj.elements["delete"].value = 1;
    }

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
var requiredFields         = new Object();
var specialCharacterFields = new Object();
var specialOCFields = new Object();
function confirmChanges(obj) {
    if (confirming || submitting) return false;
    confirming = true
    var ret = true;
    var tmp;
    var confirmed = false;

    // Sometimes just an ID can be passed in.
    if (typeof obj != "object")
        obj = document.getElementById(obj);

    // Check for slug.
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

    // make sure all required fields are filled out.
    if (typeof requiredFields != "undefined") {         
        for (field in requiredFields) {
            tmp = obj[field];
            if (typeof tmp != "undefined") {
                if ( tmp.value == '') {
                    alert(empty_field_msg + requiredFields[field]);
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
                    alert( specialCharacterFields[field] + illegal_chars_msg );
                    tmp.focus();
                    confirming = false
                    return false;
                }
            }
        }
    }  


    // examine registered special output channel fields(with slash allowed).
    if (typeof specialOCFields != "undefined") {         
        for (field in specialOCFields) {
            tmp = eval("obj." + field);
            if (typeof tmp != "undefined") {
                if ( hasSpecialCharactersOC(tmp.value) ) {
                    alert( specialOCFields[field] + illegal_chars_msg );
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

// begin double list manager functions

/*
Input: handle to form button, names of left and right list objects.
Output: Adds any selected values from the list on the left to the list on the right.  The selected values are then removed from
the list on the left.
*/
function addToList(formName,  leftName, rightName) {
    
    formObj           = document.forms[formName]; // sets this globally for use by verify
    var rightOpt      = formObj[rightName];
    var leftOpt       = formObj[leftName];
    var newLeftOpt    = new Array('');
    newLeftOpt.length = 0;
    var leftReadOnly  = eval(leftName + "_readOnly");
    cleanLeftOpt(leftOpt);

    // loop thru all left options
    for (var i=0; i<leftOpt.length; i++) {

        // if we find a selected option, 
        if (leftOpt[i].selected) {
            // that's not already on the right, and  isn't in the readOnly array for this list
            if ( !isInList(leftOpt[i].value, rightOpt) && !inArray(leftOpt[i].value, leftReadOnly) ) {
                // create new option object for the right side list, give it the value and text
                var opt = new Option(leftOpt[i].text, leftOpt[i].value);
                rightOpt[rightOpt.length] = opt;
            } else {
                // put it in the new list for the left side
                newLeftOpt[newLeftOpt.length] = new Option(leftOpt[i].text, leftOpt[i].value);
            }
        } else {
            // put it in the newLeftOpt list, cuz it's staying on the left
            newLeftOpt[newLeftOpt.length] = new Option(leftOpt[i].text, leftOpt[i].value);
            
        }
    }
    
    // zero out the left side options
    for (var i=0; i < leftOpt.length; i++) {
        leftOpt[i] = null;
    }
   
    // adjust size of left side option array, taking wacky browser behavior into account
    if (newLeftOpt.length == 0) {
        leftOpt.length = 1
        leftOpt[0] = new Option ('','_RESERVED_FOR_ZATHRAS_'); // hack. NS/Unix acts strangely when the number of elements is set to 0
    } else {
        leftOpt.length = newLeftOpt.length;
    }

    // populate the left option list
    for (var i=0; i < newLeftOpt.length; i++) {
        leftOpt[i] = newLeftOpt[i];
    }

    cleanLeftOpt(leftOpt);
    return false;
}

/*
Input: handle to form button, names of left and right list objects.
Output: Removes any selected values from the list on the right and adds them to the list on the left.  
*/
function removeFromList(formName, leftName, rightName) {
    
    formObj           = document.forms[formName];
    var rightOpt      = formObj[rightName];
    var leftOpt       = formObj[leftName];
    var newRightOpt   = new Array();
    var newLeftOpt    = new Array();
    var curOpt        = 0;
    var rightReadOnly = eval(rightName + "_readOnly");

    cleanLeftOpt(leftOpt);

    for (var i=0; i<rightOpt.length; i++) {
        // if option is selected, and not in the right side readOnly list
        if (rightOpt[i].selected && !inArray(rightOpt[i].value, rightReadOnly)) {
            // add it to the options on the left
            
            newLeftOpt[newLeftOpt.length] = new Option(rightOpt[i].text, rightOpt[i].value);
        } else {
            // keep it on the right
            newRightOpt[curOpt++] = new Option(rightOpt[i].text, rightOpt[i].value);
        }
    }
        
    rightOpt.length = newRightOpt.length;
    // reset right list with options that were not selected
    for (var i=0; i < curOpt; i++) {
        rightOpt[i] =  newRightOpt[i];
    }
    
    for (var i=0; i < newLeftOpt.length; i++) {
        leftOpt[leftOpt.length] = newLeftOpt[i];
    }

    return false;
        
}

function cleanLeftOpt(opt) {
    for (var i=0; i < opt.length; i++) {
        if (opt[i].value == "_RESERVED_FOR_ZATHRAS_") {
            opt[i] = null
        }
    }
}

/*
Check all the checkboxes whose name matches "str"
*/
var all_checked = false;
function checkAll(str) {
    for (var i=0; i < document.forms.length; i++) {
        var tmp = document.forms[i];
        for (var j=0; j < tmp.elements.length; j++) {
            if (tmp.elements[j].type == "checkbox" && tmp.elements[j].name.indexOf(str) != -1) {
                tmp.elements[j].checked = all_checked ? false : true
            }
        }
    }
    all_checked = all_checked ? false : true;
}


/*
Real time character counter for text areas
*/
function textCount(which, maxLength) {
    var myObj= document.getElementById(which);
    if (myObj.value.length>maxLength) myObj.value=myObj.value.substring(0,maxLength); 
    writeDiv("textCountUp" + which,myObj.value.length);
    writeDiv("textCountDown" + which,maxLength-myObj.value.length);
}



/*
Resize navigation iframe
*/
function resizeframe() {
    var ifrm = parent.document.getElementById("sideNav");
    var agt = navigator.userAgent.toLowerCase();
    var is_major = parseInt(navigator.appVersion);
    var is_ie    = ((agt.indexOf("msie") != -1) && (agt.indexOf("opera") == -1));
    var is_ie5   = (is_ie && (is_major == 4) && (agt.indexOf("msie 5.0") !=-1));
    var is_ie5_5 = (is_ie && (is_major == 4) && (agt.indexOf("msie 5.5") !=-1));
    var is_mac = (agt.indexOf("mac")!=-1);
    if (window.opera || ((is_ie5 || is_ie5_5) && !is_mac)) {
      // Opera and IE5/Win only
      ifrm.style.height = document.body.scrollHeight + "px";
    } else {
      // Everyone else
      ifrm.style.height = document.body.offsetHeight + "px";
    }
}
