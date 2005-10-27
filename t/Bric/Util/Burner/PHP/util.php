<?php
function footer($license = "GPL") {
    global $burner, $story;
    echo "<h4>My URI: ", $burner->best_uri($story)->as_string(), "</h4>\n";
    $perl = Perl::getInstance();
    $version = $perl->getVariable('$PHP::Interpreter::VERSION');
    # Imported functions from PERL_LOADER don't work in 1.0.1 and earlier,
    # so we fake it.
    $any = $version < '1.1.0'
        ? 'Bric::Util::DBI::ANY'
        : preg_replace('=.*$', '', $ANY(1));
    echo "<h3>ANY: $any</h3>\n";
    echo "<div>Licensed under the $license license</div>\n";
}
?>
