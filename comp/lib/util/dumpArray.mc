<%perl>

# porting this bad boy to perl sure could be helpful

function dumpArray($var) {


#	if ((isset($var)) || ($var != ""))  {
	
		switch (gettype($var)) {
			case 'integer':				// Integer, double and strings are simply displayed.
			case 'double':
			case 'string':
				echo $var;
				break;
			case 'array':				// Arrays need to be handled special. Oooo recusrions
				if (! count($var)) {	// Check to see if the array is empty.
					echo 'Empty Array.<BR>';
				} 
				else {				// Llllllet's get ready to rumble.	
					print "\n<!-- ARRAY DUMP - START -->\n";
					echo '<table border="1" width="100%"><tr><th>Key</th><th>Value</th></tr>';
					// echo '<table border="1" width="100%"><tr><th>Key</th><th>DataType</th><th>Value</th></tr>';
					do {				// Loop through the array.
						echo '<tr><td align="left" valign="top">';
						echo key($var);
						//	echo '</td><td align="left" valign="top">';
						//	echo gettype(key($var));
						echo '</td><td align="left" valign="top">';
						dumpArray($var[key($var)]);
						echo '</td></tr>';
					} while (next($var));
					echo '</table>';
					print "\n<!-- ARRAY DUMP - END -->\n";
				}
				break;
	case 'boolean':
	    settype($var, "integer");
	    if ($var == 0) {
		echo "<i>false</i>";
	    } else {
		echo "<i>true</i>";
	    }
	    break;
	default:
	    $pooh = gettype($var);
	    echo "\nUnknown data type($pooh): $var\n";
				
	    settype($var, "integer");
	    print "-- $var";
				
	    break;
	}
#    }
		
}

</%perl>