package Bric::Biz::Workflow::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Workflow');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w

use strict;

use Bric::BC::Workflow qw(:wf_const);
use Bric::BC::Workflow::Parts::Desk;


my @desk_names     = qw(Copy Art Legal Template Publish);
my @workflow_names = qw(Media Story Template);
my (@d, @w);

# Create some desks.
if (@ARGV) {
print "Creating some desks\n";
eval {
    foreach my $dn (@desk_names) {
	print "\tLooking up exising '$dn' desks\n";
	my @all = Bric::BC::Workflow::Parts::Desk->list({'name' => $dn});
	
	print "\tDeleting conflicting desks ";
	foreach my $o (@all) {
	    print '.';
	    $o->remove;
	    $o->save;
	}
	print " done\n";

	print "\tCreating new '$dn' desk\n";
	my $init = {'name'        => $dn,
		    'description' => "$dn Desk"};
	my $d_obj = Bric::BC::Workflow::Parts::Desk->new($init);

        # If this is the publish desk, set the publish flag.
        $d_obj->make_publish_desk if $dn eq 'Publish';
	
	print "\tSaving desk\n";
	$d_obj->save;

	push @d, $d_obj if $d_obj;
  }
};

print "Got Error: $@" if $@;

# Create some workflows
print "Creating some workflows\n";
eval {
    foreach my $wn (@workflow_names) {
	print "\tLooking up exising '$wn' workflows\n";
	my @all = Bric::BC::Workflow->list({'name' => $wn});
	
	print "\tDeleting conflicting workflows ";
	foreach my $o (@all) {
	    print '.';
	    $o->remove;
	    $o->save;
	}
	print " done\n";
    }
    
    print "Creating new workflow Media\n";
    $w[0] = Bric::BC::Workflow->new({'name'        => 'Media',
				   'description' => 'Media Workflow',
				   'type'        => MEDIA_WORKFLOW,
				   'start_desk'  => $d[1]});
    print "Creating new workflow Story\n";
    $w[1] = Bric::BC::Workflow->new({'name'        => 'Story',
				   'description' => 'Story Workflow',
				   'type'        => STORY_WORKFLOW,
				   'start_desk'  => $d[0]});
    print "Creating new workflow Template\n";
    $w[2] = Bric::BC::Workflow->new({'name'        => 'Template',
				   'description' => 'Template Workflow',
				   'type'        => TEMPLATE_WORKFLOW,
				   'start_desk'  => $d[3]});
};

print "Got Error: $@" if $@;

eval {
    $w[0]->add_desk({'required'   => [ $d[4] ],
		     'allowed'    => [ $d[2] ]});
    $w[1]->add_desk({'required'   => [ @d[4,2] ],
		     'allowed'    => [ $d[1] ]});
    $w[2]->add_desk({'required'   => [ $d[4] ]});
    
};

print "Got Error: $@" if $@;

print "Saving workflows\n";
eval {
    $w[0]->save;
    $w[1]->save;
    $w[2]->save;
};

print "Got Error: $@" if $@;

print "Done\n";
}
