#!/usr/bin/perl -w
use Test;
use Bric::Dist::Server;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
	# Do verbose testing here.
	print "Looking up existing server #2\n";
	my $s = Bric::Dist::Server->lookup({ id => 2 });
	print "ID:      ", $s->get_id || '', "\n";
	print "Type:    ", $s->get_server_type_id || '', "\n";
	print "Name:    ", $s->get_host_name || '', "\n";
	print "OS:      ", $s->get_os || '', "\n";
	print "Path:    ", $s->get_doc_root || '', "\n";
	print "Login:   ", $s->get_login || '', "\n";
	print "Pass:    ", $s->get_password || '', "\n";
	print "Cookie:  ", $s->get_cookie || '', "\n\n";

	print "Listing servers with server_type_id 2\n";
	foreach my $s (Bric::Dist::Server->list({server_type_id => 2 })) {
	    print "Name:    ", $s->get_host_name || '', "\n";
	}
	print "\n";

	print "Listing href of servers with doc_root '/home/www'\n";
	my $href = Bric::Dist::Server->href({ doc_root => '/home/www' });
	while (my ($id, $s) = each %$href) {
	    print "ID:      $id\n";
	    print "Name:    ", $s->get_host_name || '', "\n";
	}
	print "\n";

	print "Creating new server.\n";
	$s = Bric::Dist::Server->new;
	$s->set_host_name('www.ce.com');
	$s->set_server_type_id(2);
	$s->set_os('Win32');
	$s->set_doc_root('/here/there/everywhere/');
	$s->set_login('root');
	$s->set_password('toor');
	$s->set_cookie('mmmmmm....cookies!');
	$s->save;
	print "ID:      ", $s->get_id || '', "\n";
	print "Name:    ", $s->get_host_name || '', "\n";
	print "OS:      ", $s->get_os || '', "\n";
	print "Path:    ", $s->get_doc_root || '', "\n";
	print "Login:   ", $s->get_login || '', "\n";
	print "Pass:    ", $s->get_password || '', "\n";
	print "Cookie:  ", $s->get_cookie || '', "\n\n";

	print "Changing and reloading its values.\n";
	$s->set_host_name('www.ick.com');
	$s->set_server_type_id(1);
	$s->set_doc_root('/here/there/');
	$s->set_login('rooter');
	$s->set_password('retoor');
	$s->set_cookie('mmmmmm....cookies are the bomb!');
	$s->save;
	$s =  Bric::Dist::Server->lookup({ id => $s->get_id });
	print "ID:      ", $s->get_id || '', "\n";
	print "Name:    ", $s->get_host_name || '', "\n";
	print "OS:      ", $s->get_os || '', "\n";
	print "Path:    ", $s->get_doc_root || '', "\n";
	print "Login:   ", $s->get_login || '', "\n";
	print "Pass:    ", $s->get_password || '', "\n";
	print "Cookie:  ", $s->get_cookie || '', "\n\n";

	print "Okay, now deleting it.\n";
	$s->del;
	$s->save;
	exit;
    }

    # Do Test::Harness testing here.


    exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}

