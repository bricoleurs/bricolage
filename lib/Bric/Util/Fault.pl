use constant DEBUG => 1;

use Bric::Util::Fault;
use Bric::Util::Fault::Error;
use Bric::Util::Fault::Exception;
use Bric::Util::Fault::Exception::DA;



eval { die Bric::Util::Fault->new ({msg => 'Fault!' }) };

 if ($@) {

	# do this because $@ get over-written for every eval
	my $s = $@; 
	print "uhho.  something faulted.  lets look at it...";
	print "the fault was of type " . ref ($s) . "\n";

	print "timestamp -- " . $s->get_timestamp . "\n";
	print "pkg -- " . $s->get_pkg . "\n";
	print "filename-- " . $s->get_filename. "\n";
	print "line -- " . $s->get_line . "\n";
	print "env -- " . $s->get_env . "\n";
	print "msg -- " . $s->get_msg . "\n";
	print "payload -- " . $s->get_payload . "\n";
 }



eval { die Bric::Util::Fault::Error->new ({msg => 'Error!' }) };

if ($@) {
	my $r = ref $@;
	my $s = $@;
	print "ref of $@ is $r \n and content is " . $@ . "\n\n";
	print "short error string is " . $s->error_info . "\n";
}

eval { die Bric::Util::Fault::Exception->new ({msg => 'Exception!' }) };

if ($@) {
	my $r = ref $@;
	print "ref of $@ is $r \n and content is " . $@ . "\n\n";
}


eval { die Bric::Util::Fault::Exception::DA->new ({msg => 'DA!' }) };

if ($@) {
	my $r = ref $@;
	print "ref of $@ is $r \n and content is " . $@ . "\n\n";
}

