package Bric::App::Event::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::App::Event');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

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
