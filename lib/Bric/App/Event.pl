#!/usr/bin/perl -w
use Bric::BL::Event qw(:all);
use Bric::BL::Default qw(:all);
use Bric::BC::Person;
use Bric::BC::Person::User;
use Test;


BEGIN { plan tests => 5 }

eval {
    if (@ARGV) {
	print "Creating a new event.\n";
	my $p = Bric::BC::Person->lookup({ id => 1 });
	my $trig = Bric::BC::Person::User->lookup({ id => 4 });
	set_def('User', $trig);
	log_event('Last Name Changed', $p, { new_lname => 'Dickerson' });
	commit_events();
	exit;
    }

    # Do the Test::Harness stuff here.
    ok my $p = Bric::BC::Person->lookup({ id => 1 });
    ok my $trig = Bric::BC::Person::User->lookup({ id => 4 });
    ok set_def('User', $trig);
    ok log_event('Last Name Changed', $p, { new_lname => 'Dickerson' });
    ok commit_events();

};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
