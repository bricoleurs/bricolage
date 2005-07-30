<?php
function footer($license = "GPL") {
    global $BRIC;
    echo "<h4>My URI: ", $BRIC['burner']->best_uri($BRIC['story'])->as_string(), "</h4>\n";
    echo "<div>Licensed under the $license license</div>\n";
}
?>