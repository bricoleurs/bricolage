package Bric::Util::Grp::User::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Grp::User');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;

BEGIN { plan tests => 20 }

require Bric;
use Bric::Util::Grp::User;
use Bric::Util::Grp::Person;
use Bric::Util::Priv::Parts::Const qw(:all);

$Bric::Cust = 'sharky';

eval {

    if (@ARGV) {
    print "Getting User Group #3\n";
    my $grp = Bric::Util::Grp::User->lookup({id => 3});
    foreach my $p ($grp->get_privs) {
        print "ID:         ", $p->get_id, "\n";
        print "Usr Grp ID: ", $p->get_usr_grp_id, "\n";
        print "Obj Grp ID: ", $p->get_obj_grp_id, "\n";
        print "Value:      ", $p->get_value, "\n\n";
    }

    print "Adding a privilege to Group #3 and reloading it.\n";
    my $pgrp = Bric::Util::Grp::Person->lookup({id => 1});
    my $priv = $grp->new_priv($pgrp, CREATE);
    $grp->save;

    $grp = Bric::Util::Grp::User->lookup({id => 3});
    foreach my $p ($grp->get_privs) {
        print "ID:         ", $p->get_id, "\n";
        print "Usr Grp ID: ", $p->get_usr_grp_id, "\n";
        print "Obj Grp ID: ", $p->get_obj_grp_id, "\n";
        print "Value:      ", $p->get_value, "\n\n";
    }

    print "Now deleting the new priv and reloading Group #3\n";
    $grp->del_privs($priv->get_id);
    $grp->save;

    $grp = Bric::Util::Grp::User->lookup({id => 3});
    foreach my $p ($grp->get_privs) {
        print "ID:         ", $p->get_id, "\n";
        print "Usr Grp ID: ", $p->get_usr_grp_id, "\n";
        print "Obj Grp ID: ", $p->get_obj_grp_id, "\n";
        print "Value:      ", $p->get_value, "\n\n";
    }
    exit;
    }

    # Run the Test::Harness code here.

};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
