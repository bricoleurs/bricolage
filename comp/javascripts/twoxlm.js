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
