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

    // Get a handle on things.
    var word   = obj[wordResultName]
    var chars  = obj[charResultName];

    // Remove POD tags and newlines.
    var text = obj[targetName].value.replace(/=.*|\n+/g, ' ');

    // Get an array of words.
    var words      = text.split(/\s+/);
    var wordcount  = 0;

    // Only count words that have, er, words.
    for (var i = 0; i < words.length; i++) {
        if (words[i].length > 0) wordcount++;
    }

    // Display the results.
    word.value  = wordcount;
    chars.value = text.length;
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
    } else if (/^\s+/.test(what) || /\s+$/.test(what)) {
        alert(login_space);
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
    
    // No fewer than passwd_length characters.
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

    // XXX: These could be combined if we can get translators to update the
    //      messages into "Passwords cannot have spaces at the beginning or
    //      end!"
    if (/^\s+/.test(pass1)) {
        alert(passwd_start_msg);
        obj1.value = "";
        obj2.value = "";
        obj1.focus();
        return false;
    }
    if (/\s+$/.test(pass1)) {
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

XXX: Can this be done using only the text variable?
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

function showForm(which, noScroll) {

    var frm = document.getElementById('fbForm' + which);
    var siblings = frm.parentNode.getElementsByTagName('form');
    for(var i = 0; i < siblings.length; i++) {
        if(siblings[i].id != 'fbForm' + which) {
            siblings[i].style.display = "none";
        }
    }
    frm.style.display = "block";

/*
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
    if (!noScroll && fb_obj) fb_obj.fb_name.focus();
    
*/    
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
var formBuilder = {};
formBuilder.submit = function(frm, mainform, action) {
    var main = document.getElementById(mainform);
    if (action == "add") {
        if (formBuilder.confirm(frm, main)) { // verify data
            main.elements["formBuilder|add_cb"].value = 1;
            main.submit();
        }
    } else {
        // get the delete button value into the main form: 
        if(document.getElementById('fbMagicButtons').elements['delete'].checked) {
            main.elements["delete"].value = 1;
            // Always just save when we're deleting.
            main.elements["formBuilder|save_cb"].value = 1;
        } else {
            // It'll either save or save and stay.
            main.elements["formBuilder|" + action + "_cb"].value = 1;
        }
        if ( confirmChanges(main) ) main.submit();  
    }
    
    return false;
};

formBuilder.confirm = function (frm, main) {

    // look for formbuilder mainects, and get their values
    // assign these values to the hidden fields in the main form

    for (var i=0; i < frm.elements.length; i++) {
        var obj = frm.elements[i];
        if (obj.name != "fb_position") {
            if (obj.type == 'checkbox') {
                if (obj.checked == true) {
                    main[obj.name].value = 1;
                }
            } else if (!isEmpty(obj.value) ) {
                main[obj.name].value = obj.value;
            } else if (obj.name != "fb_value") {
                alert(data_msg);
                obj.focus();
                confirming = false // check this
                    return false;                       
            }
        } else {
            main[obj.name].value = textUnWrap( obj.options[obj.selectedIndex].value );
        }
    }

    // all good
    return true;
};


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
            var Objs = new Array(
                formObj.elements[doubleLists[i][0]], // get handle to lVals
                formObj.elements[doubleLists[i][1]] // get handle to rVals on form
            );

            for (var k in [0, 1]) {
                var obj = Objs[k];
                if (movedItems[obj.id]) {
                    // mark all moved items as selected and all others unselected.
                    for (var j=0; j < obj.length; j++) {
                        if (movedItems[obj.id][obj[j].value]) {
                            obj[j].selected = true;
                        } else {
                            obj[j].selected = false;
                        }
                    }
                }
            }
        }
    }
    confirming = false;
    submitting = ret;
    return ret;
}

// Used to confirm that output channel formats are legit.
function confirmURIFormats(obj) {
    var formats = [
        obj['uri_format'],
        obj['fixed_uri_format']
    ];
        
    for (var i in formats) {
        var format = formats[i].value;
        if (!format.match(/%\{categories\}/)) {
            alert(uri_format_msg);
            format.focus;
            return false;
        }
    }
    return true;
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

var movedItems = new Array;

// Originally by Saqib Khan - http://js-x.com/ 
// Modified (quite heavily) by Marshall Roch, 2005-03-14
function move_item(formName, fromObj, toObj) {
    var found;

    formObj = document.forms[formName]; // sets this globally for use by verify

    var from = document.getElementById(fromObj);
    var to = document.getElementById(toObj);

    if (!movedItems[from.id]) movedItems[from.id] = new Array();
    if (!movedItems[to.id])   movedItems[to.id]   = new Array();

    if (from.options.length >0) {
        for (i=0; i<from.length; i++) {

            found = false;

            if (from.options[i].selected && !from.options[i].disabled) {

                to.options[to.length] = new Option(
                    from.options[i].text,
                    from.options[i].value
                );

                if (movedItems[from.id][from.options[i].value]) {
                    movedItems[from.id].splice(from.options[i].value, 1);
                    found = true;
                }

                if (movedItems[to.id][from.options[i].value]) {
                    movedItems[to.id].splice(from.options[i].value, 1);
                }

                if (!found) {
                    // Might we have a use for the index (length-1) someday?
                    // Not using the actual index because 0 is false.
                    movedItems[to.id][from.options[i].value] = to.length;
                }

                from.options[i]=null;
                i--; /* make the loop go through them all */
            }
        }
    }
}

/*
Check all the checkboxes whose name matches "str"
*/
var all_checked = false;
function checkAll(str) {
    var checkboxes = document.getElementsByTagName("input");
    for (var i=0; i < checkboxes.length; i++) {
        if (checkboxes[i].name.indexOf(str) != -1) {
            checkboxes[i].checked = all_checked ? false : true
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

/*
Open popup window
*/
function installHelpButtons() {    
    document.getElementById("btnAbout").onclick = openAbout;
    document.getElementById("btnHelp").onclick = openHelp;
}

function openWindow(page) {
    window.open('/help/' + lang_key + '/' + page + '.html', 
                                'Help_<% SERVER_WINDOW_NAME %>', 
                                'menubar=0,location=0,toolbar=0,personalbar=0,status=0,scrollbars=1,height=600,width=505'
                                );
    return false;
}
function openAbout() { return openWindow("about"); }
function openHelp()  { 
    var uri = window.location.pathname.replace(/\/?\d*\/?$/g, "");
    if (uri.length == 0) { uri = "/workflow/profile/workspace"; }
    return openWindow(uri);
}

/*
 * Handle multiple onload events
 * By Marshall Roch, 2005-03-25
 *
 * To use, instead of writing "window.onload = someFunction" or 
 * "<body onload='someFunction'>", use "multiOnload.onload('someFunction')".
 */
var multiOnload = new Object();
multiOnload.onload = multiOnload_addOnload;
window.onload = multiOnload_onload;

function multiOnload_onload() {
    if (multiOnload.events) {
        for (var i=0; i < multiOnload.events.length; i++) {
            eval(multiOnload.events[i] + "()");
        }
    }
}
function multiOnload_addOnload(eventFn) {
    if(!this.events) { this.events = new Array(); }
    this.events[this.events.length] = eventFn;
}