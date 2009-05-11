package Bric::Util::Priv::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Priv');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Util::Priv;
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Biz::Person::User;

BEGIN { plan tests => 20 }

eval {

if (@ARGV) {

    print "Getting Priv #1.\n";
    my $p = Bric::Util::Priv->lookup({id => 1});
    print "ID:         ", $p->get_id, "\n";
    print "Usr Grp ID: ", $p->get_usr_grp_id, "\n";
    print "Usr Grp:    ", $p->get_usr_grp->get_name, "\n";
    print "Obj Grp ID: ", $p->get_obj_grp_id, "\n";
    print "Obj Grp:    ", $p->get_obj_grp->get_name, "\n";
    print "MTime:      ", $p->get_mtime, "\n";
    print "Value:      ", $p->get_value, "\n\n";

    print "Changing its value.\n";
    my $val = $p->get_value;
    $p->set_value(EDIT);
    $p->save;
    print "Value:      ", $p->get_value, "\n\n";

    print "Resetting its value.\n";
    $p->set_value($val);
    $p->save;
    print "MTime:      ", $p->get_mtime, "\n";
    print "Value:      ", $p->get_value, "\n\n";

    print "Creating a new Priv.\n";
    $p = Bric::Util::Priv->new({usr_grp => 6, obj_grp => 202, value => DENY});
    print "ID:         ", $p->get_id || '', "\n";
    $p->save;
    print "ID:         ", $p->get_id, "\n";
    print "Usr Grp ID: ", $p->get_usr_grp_id, "\n";
    print "Obj Grp ID: ", $p->get_obj_grp_id, "\n";
    print "Value:      ", $p->get_value, "\n\n";

    print "Looking it up from the database again.\n";
    $p = Bric::Util::Priv->lookup({id => $p->get_id});
    print "ID:         ", $p->get_id, "\n";
    print "Usr Grp ID: ", $p->get_usr_grp_id, "\n";
    print "Obj Grp ID: ", $p->get_obj_grp_id, "\n";
    print "Value:      ", $p->get_value, "\n\n";

    print "Deleting it from the database.\n";
    $p->del;
    $p->save;

    print "Getting all Privs for User Group #21.\n";
    foreach my $p ( Bric::Util::Priv->list({ usr_grp_id => 21 }) ) {
    print "ID:         ", $p->get_id, "\n";
    print "Usr Grp ID: ", $p->get_usr_grp_id, "\n";
    print "Obj Grp ID: ", $p->get_obj_grp_id, "\n";
    print "Value:      ", $p->get_value, "\n\n";
    }

    print "Getting all Privs for User Group #19 via href().\n";
    my $href = Bric::Util::Priv->href({ usr_grp_id => 19 });
    while (my ($id, $p) = each %$href) {
    print "ID:         ", $id, "\n";
    print "Usr Grp ID: ", $p->get_usr_grp_id, "\n";
    print "Obj Grp ID: ", $p->get_obj_grp_id, "\n";
    print "Value:      ", $p->get_value, "\n\n";
    }

    print "Getting MTime for User 1.\n";
    print "MTime: ", Bric::Util::Priv->get_acl_mtime(1), "\n";

    print "Getting privileges for User 1.\n";
    my $acl = Bric::Util::Priv->get_acl(1);
    while (my ($gid, $priv) = each %$acl) {
    print "\t$gid => $priv\n";
    }

    exit;
}

# Get Priv #1. 1-5.
ok my $p = Bric::Util::Priv->lookup({id => 1});
ok $p->get_id;
ok $p->get_usr_grp_id;
ok $p->get_obj_grp_id;
ok $p->get_mtime;
ok $p->get_value;

# Get all privs for user group #3. 6-14.
ok my @ug = Bric::Util::Priv->list({ usr_grp_id => 21 });
ok $ug[0]->get_id;
ok $ug[0]->get_usr_grp_id;
ok $ug[0]->get_obj_grp_id;
ok $ug[0]->get_mtime;
ok $ug[0]->get_value;
ok $ug[1]->get_id;
ok $ug[1]->get_usr_grp_id;
ok $ug[1]->get_obj_grp_id;
ok $ug[1]->get_mtime;
ok $ug[1]->get_value;

# Get the ACL for user #1.
ok my $time = Bric::Util::Priv->get_acl_mtime(1);
ok my $acl = Bric::Util::Priv->get_acl(1);
ok ref $acl eq 'HASH';

};

print "Error: $@\n" if $@;

