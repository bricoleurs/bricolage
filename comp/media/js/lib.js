// Extend Prototype's Form.Element
Object.extend(Form.Element, {
    label: function(element) {
        element = $(element);
        if (element.id) {
            return $A(document.getElementsByTagName("label")).collect(function(label) {
                if (label.htmlFor == element.id) {
                    return Element.collectTextNodes(label);
                }
            }).join('');
        }
        return false;
    },

    radioValue: function(form, name) {
        var val = $A(Form.getInputs(form, "radio", name)).find(function(radio) {
            return radio.checked;
        });
        return val.value;
    }
});

// Override Prototype's Form.EventObserver constructor to force it to work when
// $(element) is not a form tag.
Form.EventObserver.prototype._initialize = Form.EventObserver.prototype.initialize;
Object.extend(Form.EventObserver.prototype, {
    initialize: function(element, callback) {
      this._initialize(element, callback);
      this.registerFormCallbacks();
    }
});

Ajax.Autocompleter.prototype._onComplete =
  Ajax.Autocompleter.prototype.onComplete;
Ajax.Autocompleter.prototype._onKeyPress =
  Ajax.Autocompleter.prototype.onKeyPress;
Object.extend(Ajax.Autocompleter.prototype, {
  initialize: function(element, update, url, options) {
    this.baseInitialize(element, update, options);
    this.options.asynchronous = true;
    this.options.onComplete = this.onComplete.bind(this);
    this.options.defaultParams = this.options.parameters || null;
    this.url = url;
    this.cache = {};
  },

  getUpdatedChoices: function() {
    this.startIndicator();

    var t = this.getToken();
    if (this.cache[t]) {
      this.updateChoices(this.cache[t]);
    } else {
      entry = encodeURIComponent(this.options.paramName) + '=' + encodeURIComponent(t);

      this.options.parameters = this.options.callback ?
        this.options.callback(this.element, entry) : entry;

      if(this.options.defaultParams)
        this.options.parameters += '&' + this.options.defaultParams;

      new Ajax.Request(this.url, this.options);
    }
  },

  onKeyPress: function(event) {
      var originallyActive = this.active;
      this._onKeyPress(event);

      // Catch <enter> keypresses
      if (event.keyCode == 13) {

          // Workaround for a bug in for Safari 2.0.3.  Already fixed in WebKit as of 2006-06-29.
          // This makes the selection go to the end.
          if(navigator.appVersion.indexOf('AppleWebKit/4') > -1) {
              var element = Event.element(event);
              element.setSelectionRange(element.value.length, element.value.length);
              return false;
          }

          // Don't submit the form when you click enter!
          Event.stop(event);

          if (!originallyActive && this.options.onEnter) {
              this.options.onEnter(this.element);
          }

          return false;
      }

      return true;
  },

  // Extend Ajax.Autocompleter to add a callback when the returned list is empty
  // See http://dev.rubyonrails.org/ticket/5120
  onComplete: function(request) {
    this._onComplete(request);
    if (this.entryCount == 0 && this.options.onEmpty) {
      this.options.onEmpty(this.element);
    } else if (this.options.onNotEmpty) {
      this.options.onNotEmpty(this.element);
    }

    // for caching
    this.updateChoices(this.cache[this.getToken()] = request.responseText);
  },

    // Page jump fix
    markPrevious: function() {
      if (this.index > 0) {
        this.index--;
      } else {
        this.index = this.entryCount-1;
        this.update.scrollTop = this.update.scrollHeight;
      }

      selection = this.getEntry(this.index);
      selection_top = selection.offsetTop;

      if (selection_top < this.update.scrollTop) {
        this.update.scrollTop = this.update.scrollTop - selection.offsetHeight;
      }
    },

    markNext: function() {
      if (this.index < this.entryCount-1) {
        this.index++;
      } else {
        this.index = 0;
        this.update.scrollTop = 0;
      }
      selection = this.getEntry(this.index);
      selection_bottom = selection.offsetTop+selection.offsetHeight;
      if (selection_bottom > this.update.scrollTop + this.update.offsetHeight) {
        this.update.scrollTop = this.update.scrollTop+selection.offsetHeight;
      }
    },

    updateChoices: function(choices) {
      if (!this.changed && this.hasFocus) {
        this.update.innerHTML = choices;
        Element.cleanWhitespace(this.update);
        Element.cleanWhitespace(this.update.down());

        if (this.update.firstChild && this.update.down().childNodes) {
          this.entryCount = this.update.down().childNodes.length;
          for (var i = 0; i < this.entryCount; i++) {
            var entry = this.getEntry(i);
            entry.autocompleteIndex = i;
            this.addObservers(entry);
          }
        } else {
          this.entryCount = 0;
        }

        this.stopIndicator();
        this.update.scrollTop = 0;
        this.index = 0;

        if (this.entryCount==1 && this.options.autoSelect) {
          this.selectEntry();
          this.hide();
        } else {
          this.render();
        }
      }
    }
});

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
function wordCount(textbox, words, chars) {

    // Get a handle on things.
    textbox = $(textbox);
    words   = $(words);
    chars   = $(chars);

    // Remove POD tags and newlines.
    var text = textbox.value.replace(/=.*|\n+/g, ' ');
    var charCount = text.length;
    var wordCount = 0;
    text = text.split(/\s+/);
    for(var i = 0; i < text.length; i++) {
        if (text[i].length > 0) wordCount++;
    }

    // Display the results.
    words.innerHTML = wordCount;
    chars.innerHTML = charCount;
    return false;
}

/*
if an array named roles is defined, look for the form field value in it,
and do an alert and return false if found.
*/
function uniqueRole(obj) {

    if (typeof roles != "undefined") {
        if ($A(roles).include(obj.value)) {
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
input: a form object (e.g. input, select, textarea), and the container that groups
       all of the reorder selects together
output: none.
This function is called when a position drop down is changed in a story profile.
*/
function reorder(obj, container) {

    var container = $(container);
    var selects = $A(document.getElementsByClassName("reorder", container));
    var newIndex = obj.selectedIndex;

    var order = $A();
    selects.each(function(select) {
        if (select != obj) order[select.selectedIndex] = select;
    });

    var offset = 0;
    for (var i = 0; i < order.length; i++) {
        var curObj = order[i];

        if (!(i in order)) {
            // This is the empty space left by the moving element; backshuffle
            offset--;
        } else {
            // Otherwise get the object and see if we need to update our offset

            // No shifting has been done if offset is 0
            if (i == newIndex && offset == 0) offset++;

            // Special adjustment to make sure all necessary elems are shifted
            if (i == newIndex + 1 && offset == -1) offset = 0;

            // Update the index.
            curObj.selectedIndex = curObj.selectedIndex + offset;
        }
    }
}

/*
input: An element ID.
output: none.
This function looks up a checkbox element by its ID, and if it exists, it
unchecks it. If it does not exist, it does nothing.
 */
function uncheck (id) {
    var checkbox = document.getElementById(id);
    if (checkbox) checkbox.checked = false;
}

/*
input: An element ID.
output: none.
This function looks up a checkbox element by its ID, and if it exists, it
unchecks it. If it does not exist, it does nothing.
 */
function uncheck (id) {
    var checkbox = document.getElementById(id);
    if (checkbox) checkbox.checked = false;
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

function confirmDeletions() {
    return confirm(warn_delete_msg);
}

/*
Submits the main form when a user hits the 'add to form' button in the form builder.  Calls confirmChanges() along the way.
*/
var formBuilder = {};
formBuilder.submit = function(frm, mainform, action) {
    var main = $(mainform);
    if (action == "add") {
        if (formBuilder.confirm(main)) { // verify data
            main.elements["formBuilder|add_cb"].value = 1;
            main.submit();
        }
    } else {
        // get the delete button value into the main form
        if(main.elements['delete'].checked) {
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

formBuilder.confirm = function (frm) {

    // look for formbuilder objects, and get their values
    // assign these values to the hidden fields in the main form

    for (var i = 0; i < frm.elements.length; i++) {
        var obj = frm.elements[i];
        if (obj.name.substring(0,1) == "fb") {
            if (obj.name != "fb_position") {
                if (obj.type == 'checkbox') {
                    if (obj.checked == true) {
                        obj.value = 1;
                    }
                } else if (obj.style.display == "none") {
                    obj.value = '';
                } else if (obj.name != "fb_value" && obj.style.display != "none") {
                    alert(data_msg);
                    obj.focus();
                    confirming = false // check this
                        return false;
                }
            }
        }
    }

    // all good
    return true;
};

formBuilder.switchType = function(type) {
    var fb = $("fbDiv");
    fb.className = type;
    $("fb_type").value = type;
    var labels = fb.getElementsByTagName("label");
    for (var i = 0; i < labels.length; i++) {
        var target = $(labels[i].htmlFor);
        if (typeof this.labels[type] != "undefined"
            && typeof this.labels[type][target.name] != "undefined") {

            // Save the default label before changing it
            if (typeof this.defaultLabels[target.name] == "undefined")
                this.defaultLabels[target.name] = labels[i].innerHTML;

            labels[i].innerHTML = this.labels[type][target.name] + ":";

        // Use the default if it exists and a new value doesn't
        } else if (typeof this.defaultLabels[target.name] != "undefined") {
            labels[i].innerHTML = this.defaultLabels[target.name];
        }

        if (typeof this.values[type] != "undefined"
            && typeof this.values[type][target.name] != "undefined") {

            // Save the default value before changing it
            if (typeof this.defaultValues[target.name] == "undefined")
                this.defaultValues[target.name] = target.value;

            target.value = this.values[type][target.name];
        } else if (typeof this.defaultValues[target.name] != "undefined") {
            target.value = this.defaultValues[target.name];
        }
    }
};

formBuilder.defaultLabels = new Array();
formBuilder.defaultValues = new Array();


/*
Prompts the user if any changes have been made to form fields.  Checks for double list
managers on the page.  If any are found, all left values are deselected, and any
new values on the right are marked selected.
*/
var confirming = false
var submitting = false

function checkRequiredFields(form) {
    ret = true;
    Form.getElements(form).each(function(element) {
        if (Element.hasClassName(element, "required")
                && Element.visible(element) && $F(element) == '') {
            alert(empty_field_msg + Form.Element.label(element));
            element.focus();
            ret = false;
        }
    });
    return ret;
}

function confirmChanges(obj) {
    if (confirming || submitting) return false;
    confirming = true
    var ret = true;
    var tmp;
    var confirmed = false;

    // Sometimes just an ID can be passed in.
    obj = $(obj);

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
            var field = tmp.elements[j];

            // Check for validating class names.
            // Note: This is a good way to simply add new validations. Just
            // add create the proper class name to the field and set its title
            // attribute. Then implement the handling of the validating class
            // here.
            if ( Element.hasClassName(field, 'validate-digits') ) {
                if ( field.value.match( /\S/ ) && !field.value.match( /^\d+$/ ) ) {
                    field.value = '';
                    field.focus();
                    field.style.background = '#f99';
                    field.style.border     = '1px solid red';
                    alert((field.title || field.name) + digits_only_msg);
                    return confirming = false;
                }
            }

            // Throw an alert for delete checkbox.
            if (field.type == "checkbox" && field.name.indexOf("delete") != -1) {
                if (field.checked && !confirmed) {
                    ret = confirmDeletions();
                    confirmed = true;
                }
            }
        }
    }

    if (!checkRequiredFields(obj)) { confirming = false; return false; }

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

// begin double list manager functions

var movedItems = new Array;

// Originally by Saqib Khan - http://js-x.com/
// Modified (quite heavily) by Marshall Roch, 2005-03-14
function move_item(formName, from, to) {
    var found;

    formObj = document.forms[formName]; // sets this globally for use by verify

    from = $(from);
    to = $(to);

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
    var myObj= $(which);
    if (myObj.value.length > maxLength) myObj.value=myObj.value.substring(0,maxLength);
    $("textCountUp" + which).innerHTML = myObj.value.length;
    $("textCountDown" + which).innerHTML = maxLength-myObj.value.length;
}

/* Simple browser detection */
function Browser () {
    this.is_major = parseInt(navigator.appVersion);
    if (window.opera) {
        this.is_opera = true;
    } else {
        var agt = navigator.userAgent.toLowerCase();
        if (agt.indexOf('msie') != -1) {
            this.is_ie = true;
            if (this.is_major == 4) {
                if      (agt.indexOf('msie 5.0') !=-1) this.is_ie5 = true;
                else if (agt.indexOf('msie 5.5') !=-1) this.is_ie5_5 = true;
            }
        }
    }
    this.is_mac = agt.indexOf('mac') !=-1;
}


/*
Open popup window
*/
function openWindow(uri, name, opts) {
    var options = Object.extend({
      width: 600,
      height: 600,
      scrollbars: 1,
      status: 1,
      personalbar: 0,
      toolbar: 0,
      location: 0,
      menubar: 0,
      resizable: 1,
      closeOnUnload: false
    }, opts || {});

    if (options['closeOnUnload']) {
      Event.observe(window, "unload", (function() {
        if (win && !win.closed) win.close()
      }).bindAsEventListener(this));
    }
    delete options['closeOnUnload'];

    var win = window.open(
        uri,
        name || 'BricolagePopup',
        $H(options).map(function(opt) {
          return opt[0] + "=" + opt[1];
        }).join(",")
    );
    return win;
}
function openAbout() { return openWindow("/help/" + lang_key + "/about.html"); }
function openHelp()  {
    var uri = window.location.pathname.replace(/[\d\/]+$/g, '');
    if (uri.length == 0) uri = "/workflow/profile/workspace";
    else uri = uri.replace(/profile\/[^\/]+\/container/, 'profile/container');
    if (!/^\//.test(uri)) uri = '/' + uri;
    if (!/\.html$/.test(uri)) uri += '.html';
    return openWindow('/help/' + lang_key + uri, "BricolageHelp", { width: 505 });
}


/*
 * findFocus(). called in the onload event. Finds the second form in the page
 * and puts the focus on the first text or textarea or other relevant field
 * that it can find.
 */

function findFocus() {
    if (document.forms.length > 1) {
        // Skip the site context form, which is always 0.
        var elems = document.forms[1].elements;
        for (i = 0; i < elems.length; i++) {
            var elem = elems[i];
            if (elem.type == 'text' || elem.type == 'textarea') {
                selectText(elem, 0, elem.value.length, true);
                break;
            }
        }
    }
}


/*
 * Save scroll position
 */

// <body onload="restoreScrollXY($scrollx, $scrolly)">
function restoreScrollXY(x, y) {
    if (x) window.scrollTo(x);
    var height = document.all ? document.body.scrollTop : window.pageYOffset;
    if (y > height) {
        window.scrollBy(0, 10);
        setTimeout(function () { restoreScrollXY(0, y) }, 3);
    }
}

// <form onSubmit="saveScrollXY('theForm')" ...>
function saveScrollXY(formName) {
    var form = document.forms[formName];
    if (document.all) {
        form.scrollx.value = document.body.scrollLeft;
        form.scrolly.value = document.body.scrollTop;
    } else {
        form.scrollx.value = window.pageXOffset;
        form.scrolly.value = window.pageYOffset;
    }
}

/*
 * Dialog box functions.
 */
function openDialog (dialog, event) {
    dialog = $(dialog);
    // var position = getPosition(event);
    dialog.style.left    = '200px';
    dialog.style.top     = '150px';
    dialog.style.display = "block";
    return false;
}

function closeDialog (dialog, event) {
    dialog = $(dialog);
    dialog.style.display = 'none';
    return false;
}

var dragState = {};

function getPosition (event) {
    var x, y;
    var browser = new Browser();

    // Get the existing position.
    if (browser.is_ie) {
        x = window.event.clientX + document.documentElement.scrollLeft
            + document.body.scrollLeft;
        y = window.event.clientY + document.documentElement.scrollTop
            + document.body.scrollTop;
    }

    else {
        x = event.clientX + window.scrollX;
        y = event.clientY + window.scrollY;
    }
    return {x: x, y: y};
}

function beginDrag(event, elem) {
    dragState.elem = elem;
    var browser    = new Browser();
    var position   = getPosition(event);
    var style      = elem.style;

    // Save starting positions of cursor and element.
    dragState.cursorStartX = position.x;
    dragState.cursorStartY = position.y;
    dragState.elStartLeft  = parseInt(style.left, 10) || 0;
    dragState.elStartTop   = parseInt(style.top,  10) || 0;

    // Capture mousemove and mouseup events on the page.
    if (browser.is_ie) {
        document.attachEvent('onmousemove', dragger);
        document.attachEvent('onmouseup',   endDrag);
        window.event.cancelBubble = true;
        window.event.returnValue = false;
    }
    else {
        document.addEventListener('mousemove', dragger, true);
        document.addEventListener('mouseup',   endDrag, true);
        event.preventDefault();
    }
    dragState.browser = browser;
}

function dragger (event) {
    var position = getPosition(event);
    var style    = dragState.elem.style;

    style.left
        = (dragState.elStartLeft + position.x - dragState.cursorStartX) + 'px';
    style.top
        = (dragState.elStartTop  + position.y - dragState.cursorStartY) + 'px';

    if (dragState.browser.is_ie) {
        window.event.cancelBubble = true;
        window.event.returnValue = false;
    }
    else {
        event.preventDefault();
    }
}

function endDrag(event) {
    if (dragState.browser.is_ie) {
        document.detachEvent('onmousemove', dragger);
        document.detachEvent('onmouseup',   endDrag);
    }

    else {
        document.removeEventListener('mousemove', dragger, true);
        document.removeEventListener('mouseup',   endDrag,  true);
    }
}

/*
 * Search and replace functions.
 */

function openFindDialog(dialog, event) {
    openDialog(dialog, event);
    var find = $('searchfind');
    find.focus();
    find.select();
    return false;
}

function closeFindDialog (dialog, event) {
    closeDialog(dialog, event);
}


function getSearchString () {
    var find = $('searchfind');
    if (!find.value) {
        alert(no_search_string);
        return false;
    }
    return find.value;
}

function searchField (field) {
    var find  = getSearchString();
    if (!find) return false;
    var regex = $('searchregex');
    var found = field.value.match(new RegExp(find, 'g'));
    if (!found || !found.length) {
        alert(none_found);
        return false;
    }
    field.found = found;
    field.lastFoundIndex = 0;
    findNext(field);
    return false;
}

function selectText (field, start, end, noAlert) {
    if (field.setSelectionRange) {
        // Selection in Mozilla.
        field.setSelectionRange(start, end);
    }

    else if (field.createTextRange) {
        // Selection in IE.
        var range = field.createTextRange();
        range.moveStart('character', start);
        range.moveEnd(  'character', end - field.value.length);
        range.select();
    }

    else if (!noAlert) {
        // Everything else.
        alert(found_from + start + found_to + end);
    }

    field.focus();
}

function findNext (field) {
    if (!field.found) {
        searchField(field);
        return false;
    }

    var string = field.found.shift();
    var start = field.value.indexOf(string, field.lastFoundIndex);

    if (start == -1) {
        alert(no_more_instances);
        delete field.lastFoundIndex;
        delete field.found;
        return false;
    }

    field.lastFoundIndex = start + string.length;
    selectText(field, start, start + string.length);
    return false;
}

function replaceAll (field) {
    var find  = getSearchString();
    if (!find) return false;
    var regex = $('searchregex');
    if (regex.checked) find = new RegExp(find);

    var replace = $('searchreplace');
    replace = replace.value == null ? '' : replace.value;

    var chunks = field.value.split(find);
    if (chunks.length == 1) {
        closeDialog($('finddialog'));
        alert(replaced_none);
    }

    else {
        field.value = chunks.join(replace);
        field.focus(); field.blur();
        closeDialog($('finddialog'));
        alert((replaced) + (chunks.length - 1) + (chunks.length > 2 ? occurrences : occurrence));
    }
    return false;
}

/*
 * Menu functions.
 */

function toggleMenu (el, id) {
    // Toggle <li> class: closed <-> open
    var parent = el.parentNode;
    var newclass = parent.className == 'open' ? 'closed' : 'open'
    parent.className = newclass;

    // Update state stored in cookie
    // first make sure to have only the menus cookie
    var name = 'BRICOLAGE_MENUS';
    var regex = new RegExp(name + '=([\\w:|]+);?');
    var val = regex.test(document.cookie) ? RegExp.$1 : '';
    if (val == '') {
        val = id + ':' + newclass;
    } else {
        regex = new RegExp('\\b' + id + ':(?:open|closed)');
        if (regex.test(val)) {
            // if this already contains the menu, replace with the new value
            val = val.replace(regex, id + ':' + newclass);
        } else {
            // otherwise add the new menu
            val += '|' + id + ':' + newclass;
        }
    }
    document.cookie = name + '=' + val + '; path=/';

    // XXX: if I don't do this, the link stays "clicked" (outlined)
    el.blur();

    // Don't follow the link
    return false;
}

function alternateTableRows(element) {
    element = $(element);
    $A(element.getElementsByTagName("tr")).select(function(row) {
      return row.getElementsByTagName("td").length > 0 // Exclude header rows
    }).each(function(row, index) {
        if (index % 2 == 0) {
            Element.addClassName(row, "even");
            Element.removeClassName(row, "odd");
        } else {
            Element.addClassName(row, "odd");
            Element.removeClassName(row, "even");
        }
    })
}

document.getParentByClassName = function(element, className) {
    element = $(element);
    while (element.parentNode && !Element.hasClassName(className)) {
        element = element.parentNode;
    }
    return element;
}
document.getParentByTagName = function(element, tagName) {
    element = $(element);
    while (element.parentNode && (!element.tagName ||
        (element.tagName.toUpperCase() != tagName.toUpperCase()))) {
      element = element.parentNode;
    }
    return element;
}

/*
 * Application-wide stuff.
 */
var Bricolage = {
    _handle: function( req, klass, title ) {
        div = document.createElement('div');
        div.className = klass;
        Element.update(
            div,
            '<h1 class="errorMsg">' + title + '</h1>' +
            req.responseText +
            '<p><a href="#" class="lbAction" rel="deactivate">Close</a></p>'
        );
        document.body.appendChild(div);
        new Lightbox(div).activate();
    },
    handleError: function(req) {
        Bricolage._handle(req, 'lightboxerror', error_msg);
    },
    handleForbidden: function(req) {
        Bricolage._handle(req, 'lightboxforbidden', forbidden_msg);
    },
    handleConflict: function(req) {
        Bricolage._handle(req, 'lightboxconflict', conflict_msg);
    }
};

var Desk = {
    visibleMenu: '',

    update: function(element, opts) {
        element = $(element);
        var options = Object.extend({
            uri: '/widgets/desk/desk_item.html',
            parameters: ''
        }, opts || {});
        Desk.hideMenu();
        new Ajax.Updater( { success: element }, options.uri, {
            insertion: Element.replace,
            asynchronous: true,
            parameters: options.parameters,
            onFailure: Bricolage.handleError,
            on403: Bricolage.handleForbidden,
            on409: Bricolage.handleConflict
        } );
    },

    confirmDelete: function() {
        return confirm(warn_delete_msg);
    },

    request: function(opts, onSuccess) {
        var options = Object.extend({
            uri: window.location.href,
            parameters: ''
        }, opts || {});
        Desk.hideMenu();
        new Ajax.Request( options.uri, {
            asynchronous: true,
            parameters: options.parameters,
            onSuccess: onSuccess,
            onFailure: Bricolage.handleError,
            on403: Bricolage.handleForbidden,
            on409: Bricolage.handleConflict
        } );
    },

    menuHandler: function(button, event) {
        if( Desk.visible == "shown" ) 
          Desk.hideMenu();
        else
          Desk.showMenu(button, event);
    },

    showMenu: function(button, event) {
        Desk.hideMenu();
        Desk.visibleMenu = button.id + "_desks";
        Element.show(Desk.visibleMenu);
        Desk.visible = "shown";
        Event.stop(event);
        Event.observe(document, "click", Desk.hideMenu);
    },

    hideMenu: function() {
        if (Desk.visibleMenu != '') Element.hide(Desk.visibleMenu);
        Desk.visibleMenu = '';
        Desk.visible = "hidden";
        Event.stopObserving(document, "click", Desk.hideMenu);
    }
};

/*
 * Handles the fast_add.mc widget, for adding multiple items such as keywords
 * quickly.
 *
 * Options:
 *  - autocomplete: determines whether an AJAX request will be made to list
 *        existing options for the user to choose from.
 *        (default: true)
 *  - uri: the URI of the page that will return the autocompletion list
 *  - list: the ID or DOM object of the container list to which the new objects
 *        will be added (default: 'fast-add-$type')
 */
var FastAdd = Class.create();
FastAdd.prototype = {
    initialize: function(type, options, autocomplete_options) {
        this.options = Object.extend({
            autocomplete: true,
            uri: '/widgets/profile/fast_add/autocomplete_' + type + '.html',
            list: 'fast-add-' + type
        }, options || {});
        this.type = type;
        this.list = $(this.options.list);

        if (this.options.autocomplete) {
          this.autocompleter = new Ajax.Autocompleter(
            'add_' + this.type,
            'add_' + this.type + '_autocomplete',
            this.options.uri,
            autocomplete_options
          );
        }
    },

    add: function(element) {
        value = $F(element);

        var item = Builder.node("li", { className: 'keyword' }, [
            Builder.node("input", { type: 'hidden', name: 'new_' + this.type, value: value }),
            Builder.node("span", { className: 'value' }, value),
            " (",
            Builder.node("a", { href: "#", onclick: "fastadd" + this.type + ".remove(this.parentNode); return false" }, 'remove'),
            ")"
        ]);

        var placed = false;
        $A(document.getElementsByClassName('value', this.list)).each((function(sibling) {
            if (Element.collectTextNodes(sibling).toLowerCase() > value.toLowerCase()) {
                this.list.insertBefore(item, sibling.parentNode);
                placed = true;
                throw $break;
            }
        }).bind(this));

        if (!placed) {
            this.list.appendChild(item);
        }

        $(element).value = '';
        if (this.options.autocomplete) this.autocompleter.options.defaultParams = Form.serialize(this.list);
    },

    remove: function(element) {
        Element.remove(element);
        if (this.options.autocomplete) this.autocompleter.options.defaultParams = Form.serialize(this.list);
    }
}

var Tabs = Class.create();
Tabs.prototype = {
    initialize: function(tabGroup, pageGroup) {
        this.tabs = document.getElementsByClassName('tab', $(tabGroup));
        this.pages = document.getElementsByClassName('page', $(pageGroup));

        var selected = this.tabs.first();
        this.tabs.each(function(tab) {
          Element.removeClassName(tab, "first");
          if (Element.hasClassName(tab, "selected")) selected = tab;
        })
        Element.addClassName(this.tabs.first(), "first");

        // Select the first tab by default
        this.switchTab(selected);
    },

    switchTab: function(newTab) {
        this.tabs.each(function(tab) {
            if (tab.id == newTab.id) {
                Element.addClassName(tab, "selected");
                Element.show(tab.id + "_page");
            } else {
                Element.removeClassName(tab, "selected");
                Element.hide(tab.id + "_page");
            }
        });
    }
};

Abstract.ListManager = function() {};
Abstract.ListManager.prototype = {
    setOptions: function(options) {
        this.options = {
            extraParameters: []
        };
        Object.extend(this.options, options || {});
    },

    updatePartial: function(uri, callback) {
        var extraParams = this.options.extraParameters.join("&");
        extraParams = extraParams ? "&" + extraParams : '';

        new Ajax.Updater( { success: this.element }, uri, {
            parameters: Form.serialize(this.element) + extraParams,
            asynchronous: true,
            evalScripts: true,
            onSuccess: callback,
            onFailure: Bricolage.handleError,
            on403: Bricolage.handleForbidden,
            on409: Bricolage.handleConflict
        });
    }
};

var AssociationListManager = Class.create();
AssociationListManager.prototype = Object.extend(new Abstract.ListManager(), {
    initialize: function(element, options) {
        this.element = $(element);
        this.setOptions(options);
        this.initializePrimaryRadios();
    },

    initializePrimaryRadios: function() {
        var self = this;
        new Form.EventObserver(this.element, function() { self.updateDeletes(); } );
    },

    updateList: function() {
        this.updatePartial(this.options.uri, function() {
            this.updateDeletes();
        });
    },

    add: function(element) {
        this.options.extraParameters.push($(element).id + "=" + $F(element));
        this.updateList();
        this.options.extraParameters.pop();
    },

    remove: function(element) {
        Element.remove(element);
        this.updateList();
    },

    updateDeletes: function() {
        var deleteButtons = Form.getInputs(this.element, "image", "delete_" + this.options.type);
        var primary = Form.Element.radioValue(this.element, "primary_" + this.options.type + "_id");
        $A(deleteButtons).each(function(button) {
            if (button.value == primary) {
                Element.hide(button);
            } else {
                Element.show(button);
            }
        });
    }
});

/*
Created By: Chris Campbell
Website: http://particletree.com
Date: 2/1/2006

Adapted By: Simon de Haan
Website: http://blog.eight.nl
Date: 21/2/2006

Adapted By: David Wheeler
Website: http://blog.eight.nl
Date: 11/9/2008

Inspired by the lightbox implementation found at
http://www.huddletogether.com/projects/lightbox/
And the lightbox gone wild by ParticleTree at
http://particletree.com/features/lightbox-gone-wild/

*/
var Lightbox = Class.create();
Lightbox.prototype = {
    yPos : 0,
    xPos : 0,
    browser : new Browser(),

    initialize: function(elem) {
        this.content = elem;
    },

    // Turn everything on - mainly the IE fixes
    activate: function(){
        if (this.browser.is_ie) {
            this.getScroll();
            this.prepareIE('100%', 'hidden');
            this.setScroll(0,0);
            this.hideSelects('hidden');
        }
        this.display('block');
    },

    // Ie requires height to 100% and overflow hidden or else you can scroll
    // down past the lightbox
    prepareIE: function(height, overflow){
        bod = document.getElementsByTagName('body')[0];
        bod.style.height = height;
        bod.style.overflow = overflow;

        htm = document.getElementsByTagName('html')[0];
        htm.style.height = height;
        htm.style.overflow = overflow;
    },

    // In IE, select elements hover on top of the lightbox
    hideSelects: function(visibility){
        selects = document.getElementsByTagName('select');
        for(i = 0; i < selects.length; i++) {
            selects[i].style.visibility = visibility;
        }
    },

    // Taken from lightbox implementation found at
    // http://www.huddletogether.com/projects/lightbox/
    getScroll: function(){
        if (self.pageYOffset) {
            this.yPos = self.pageYOffset;
        } else if (document.documentElement && document.documentElement.scrollTop){
            this.yPos = document.documentElement.scrollTop;
        } else if (document.body) {
            this.yPos = document.body.scrollTop;
        }
    },

    setScroll: function(x, y){
        window.scrollTo(x, y);
    },

    display: function(display){
        this.overlay().style.display = display;
        this.content.style.display = display;
        this.content.style.top = window.scrollY + 100 + 'px';
        if (display != 'none') this.actions();
    },

    // Search through new links within the lightbox, and attach click event
    actions: function(){
        lbActions = document.getElementsByClassName('lbAction');

        for(i = 0; i < lbActions.length; i++) {
            Event.observe(
                lbActions[i],
                'click',
                this[lbActions[i].rel].bindAsEventListener(this),
                false
            );
            lbActions[i].onclick = function() { return false };
        }
        return this;
    },

    // Example of creating your own functionality once lightbox is initiated
    deactivate: function() {
        if (this.browser.is_ie){
            this.setScroll(0,this.yPos);
            this.prepareIE('auto', 'auto');
            this.hideSelects('visible');
        }
        this.display('none');
    },

    overlay: function () {
        var overlay = $('overlay');
        if (overlay) return overlay;
        overlay = document.createElement('div');
        overlay.id = 'overlay';
        document.body.appendChild(overlay);
        return overlay;
    }
};

/*
 * Container profile
 */
var Container = {
    refresh: function(container_id, opts) {
        var options = Object.extend({
            extraParameters: ''
        }, opts || {});

        var element = $('element_' + container_id + '_content');
        var form    = $('theForm');

        //We need to disable the buttons on the page before we serialize the form
        //to prevent callback death. MWR 02-23-09 
        var buttons = form.getInputs('image');
        buttons.invoke('disable');

        // Be sure to call onsubmit() so the wysiwyg fields can be updated.
        if (form.onsubmit) form.onsubmit();
        submitting = false; // Reset this so we can submit again!

        // Serialize the form.
        var params = 'container_id=' + container_id + '&' + Form.serialize(form);
        if (options.extraParameters != '') {
            params = params + '&' + options.extraParameters;
        }

        // Now turn the buttons back on.
        buttons.invoke('enable');

        // Only update the element content with the requst results if the request is
        // successful.
        new Ajax.Updater(
            { success: 'element_' + container_id + '_content' },
            '/widgets/container_prof/container.html', {
            parameters: params,
            asynchronous: true,
            evalScripts: true,
            onFailure: Bricolage.handleError,
            on403: Bricolage.handleForbidden,
            on409: Bricolage.handleConflict,
            onSuccess: function(request) {
                Container.updateOrder('element_' + container_id)
            }
        });
    },

    updateOrder: function(list) {
        list = $(list);

        // We must do this so that new elements are sortable
        Sortable.create(list, {
            onUpdate: function(elem) {
                Container.updateOrder(elem);
            },
            handle: 'name',
            scroll: window
        });

        $('container_prof_' + list.id).value = Sortable.sequence(list);

// Sortable changes the z-index on drag and restores it after a drag.  However,
// the call to onUpdate happens before the z-index has been updated, so hack
// around this by updating the z-index after 500ms.
        setTimeout(Container.updatezIndex, 500);
    },

// Update the z-index of containers to keep the popup menu from the previous
// containers from going under the next one.
// Always needed for IE due to its messed up z-index handling, and needed for
// Firefox/etc after elements have been re-ordered.
    updatezIndex: function() {
        var elements = $('containerprof').select('li.container');
        $A(elements).each(function(element, i) {
            element.style.zIndex = elements.length - i;
        });
    },

    confirmDelete: function() {
        return confirm(warn_delete_msg);
    },

    // Used to associate a story or media with an element, from a popup. It
    // returns the updated partial, which is then inserted into the parent
    // window. Takes the container ID to which to add the asset and the ID of
    // the asset to relate
    update_related: function(action, type, widget, container_id, asset_id, sync) {
        new Ajax.Updater(
           { success: window.opener.document.getElementById(
                'element_' + container_id + '_rel_' + type
            ) },
            '/widgets/container_prof/_related.html', {
                parameters: 'type=' + type + '&widget=' + widget +
                    '&container_id=' + container_id + '&container_prof|' +
                     action + '_' + type + '_cb=' + asset_id,
                asynchronous: !sync,
                onSuccess: function(r) { window.close(); },
                onFailure: Bricolage.handleError,
                on403: Bricolage.handleForbidden,
                on409: Bricolage.handleConflict
          }
        )
    },

    relate: function(type, widget, container_id, asset_id, sync) {
        return Container.update_related('relate', type, widget, container_id, asset_id, sync);
    },

    unrelate: function(type, widget, container_id, asset_id, sync) {
        return Container.update_related('unrelate', type, widget, container_id, asset_id, sync);
    },

    // Update the display of an element, but do nothing else. If sync is true,
    // it should *not* be asynchronous.
    update: function( type, widget, container_id, sync ) {
        new Ajax.Updater(
           {
               success: window.opener.document.getElementById(
                    'element_' + container_id + '_rel_' + type
               )
           },
           '/widgets/container_prof/_related.html', {
               parameters: 'type=' + type + '&widget=' + widget +
                   '&container_id=' + container_id,
               asynchronous: !sync,
               onSuccess: function(r) { window.close(); },
               onFailure: Bricolage.handleError,
               on403: Bricolage.handleForbidden,
               on409: Bricolage.handleConflict
           }
        )
    },

    addElement: function(container_id, element_id) {
        Container.refresh(container_id, {
            extraParameters: 'container_prof|add_element_cb=' + container_id + '&container_prof|add_element_to_' + container_id + '=' + element_id
        });
    },

    deleteElement: function(container_id, element_id) {
        if (Container.confirmDelete()) {
            Container.refresh(container_id, {
                extraParameters: 'container_prof|delete_cb=' + element_id
            });
        }
    },

    copyElement: function(container_id, element_id) {
        Container.refresh(container_id, {
            extraParameters: 'container_prof|copy_cb=' + element_id
        });
    },

    /*
    Update the Paste item on all the "Add Element" popup menus.
    input:
        id - the container or field type id (cont_* or data_*) of the element in the buffer
        text - the text to show for the menu item
    */
    updatePaste: function(id, text) {
        $$('.actions .popup-menu ul').each(function (menu) {
            var found = false;
            var links = menu.getElementsByTagName('a');
            for (var i = 0; i < links.length - 1; i++) {
                if (links[i].getAttribute('rel') == id) {
                    found = true;
                    break;
                }
            }

            // The last element of the list is always Paste
            if (found) {
                links[links.length - 1].parentNode.style.display = '';
                links[links.length - 1].innerHTML = text;
            }
            else {
                links[links.length - 1].parentNode.style.display = 'none';
            }
        });
    },

    toggle: function( eid, anchor ) {
        Effect.toggle('element_' + eid, 'blind', {duration: 0.3});
        var hint_element = $('element_' + eid + '_hint');
        if (hint_element) {
            Effect.toggle(hint_element, 'blind', {duration: 0.3});
        }
        var displayed = $('container_' + eid + '_displayed');
        if ( displayed.value == '0' ) {
            // Display it.
            anchor.innerHTML = '&#x25bc;';
            displayed.value = '1';
        } else {
            // Hide it.
            anchor.innerHTML = '&#x25b6;';
            displayed.value = '0';
        }
        return false;
    }
};

Event.observe(window, 'load', function() {
  $A(document.getElementsByClassName('listManager')).each(function(table) {
      alternateTableRows(table);
  })
});
