<%args>
$widget
$field
$param
</%args>

<%init>;
if ($field eq "$widget|login_cb") {
    my $un = $param->{$widget. '|username'};
    my $pw = $param->{$widget. '|password'};
    my ($res, $msg) = login($r, $un, $pw);
    if ($res) {
	if ($param->{$widget. '|ssl'}) {
	    # They want to use SSL. Do a simple redirect.
	    set_state_name($widget, 'ssl');
	    do_queued_redirect();
	} else {
	    # Redirect them back to port 80 if not using SSL.
	    set_state_name($widget, 'nossl');
	    redirect_onload('http://' . $r->hostname . (del_redirect() || ''));
	}
    } else {
	add_msg($msg);
	$r->log_reason($msg);
    }
}

elsif ($field eq $widget.'|masquerade_cb') {
    my $un = $param->{$field};

    my ($res, $msg) = Bric::App::Auth::masquerade($r, $un);

    if ($res) {
	set_redirect('/');
    } else {
	add_msg($msg);
	$r->log_reason($msg);
    }
}
</%init>
