package Bric::Dist::Job::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Dist::Job');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Dist::Job;
use Bric::Dist::ServerType;
use Bric::Dist::Resource;
use Bric::Util::MediaType;
use Bric::Util::Time qw(local_date);

BEGIN { plan tests => 10 }

eval {


    if (lc $ARGV[0] eq 'bigtest') {
	# Do the big test here.
	my @tech = qw( /tmp/content/tech/feature/index.html
		       /tmp/content/tech/feature/index1.html
		       /tmp/content/tech/feature/email.html
		       /tmp/content/tech/feature/print.html
		       /tmp/content/tech/feature/story.gif
		     );
	my @ent = qw( /tmp/content/ent/col/rose/email.html
		      /tmp/content/ent/col/rose/index.html
		      /tmp/content/ent/col/rose/print.html
		      /tmp/content/ent/col/rose/story.jpg
		    );

	my @res;
	# Create the tech resources.
	print "Instantiating the tech resources...\n";
	foreach my $file (@tech) {
	    (my $uri = $file) =~ s/^\/tmp\/content//g;
	    my $mt = Bric::Util::MediaType->get_name_by_ext($uri);
	    my $res = Bric::Dist::Resource->lookup({ path => $file, uri => $uri })
	      || Bric::Dist::Resource->new({ path => $file , uri => $uri, media_type => $mt });
	    $res->save;
	    push @res, $res;
	}
	# Intantiate the server type.
	print "Instantiating the preview server type...\n";
	my $st = Bric::Dist::ServerType->lookup({ name => 'Preview Server' });

	# Instantiate the Job.
	print "Instantiating the job...\n";
	my $job = Bric::Dist::Job->new;
	$job->set_name('Test Job One');
	$job->set_user_id(3);
	$job->add_resources(@res);
	$job->add_server_types($st);
	$job->set_type(1);
	$job->set_sched_time(local_date(0, 0, 1));
	$job->save;

	print "Executing the job.\n";
	$job->execute_me;


	print "Cleaning up bogus records.\n";
        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM resource
            WHERE  id > 1023
        })->execute;
        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM job
            WHERE  id > 1023
        })->execute;
	print "Done!\n";
	exit;

    } elsif (@ARGV) {
	# Do verbose testing here.
	my $job;
	print "Fetching Job #1\n";
	$job = Bric::Dist::Job->lookup({ id => 1 });
	print "ID:             ", $job->get_id || '', "\n";
	print "Scheduled Time: ", $job->get_sched_time("%D %T") || '', "\n";
	print "Complete Time:  ", $job->get_comp_time("%D %T") || '', "\n";
	print "Exp Time:       ", $job->get_exp_time("%D %T") || '', "\n";
	print "Exp Comp Time:  ", $job->get_exp_comp_time("%D %T") || '', "\n";
	    print "Exec Tries:     ", $job->get_exec_tries, "\n";
	    print "Exp Tries:      ", $job->get_exp_tries, "\n";
	print "Pending:        ", $job->is_pending ? 'Yes' : 'No', "\n";
	print "Resources:";
	if (my @res = $job->get_resources) {
	    print "\n  ", $_->get_path for @res;
	} else {
	    print " None.";
	}
	print "\nServer Types:";
	if (my @sts = $job->get_server_types) {
	    print "\n  ", $_->get_name for @sts;
	} else {
	    print " None.";
	}
	print "\n\n";

#	$job->set_sched_time('2001-01-01 12:34:56');
#	$job->set_exp_time('2001-12-01 23:59:59');


	print "Fetching jobs scheduled between 1/1/01 and 1/3/01\n";
	foreach my $job (Bric::Dist::Job->list({ sched_time =>
					       ['2001-01-01 00:00:00',
						'2001-03-01 00:00:00'] } ) ) {
	    print "ID:             ", $job->get_id || '', "\n";
	    print "Scheduled Time: ", $job->get_sched_time("%D %T") || '', "\n";
	    print "Complete Time:  ", $job->get_comp_time("%D %T") || '', "\n";
	    print "Exp Time:       ", $job->get_exp_time("%D %T") || '', "\n";
	    print "Exp Comp Time:  ", $job->get_exp_comp_time("%D %T") || '', "\n";
	    print "Exec Tries:     ", $job->get_exec_tries, "\n";
	    print "Exp Tries:      ", $job->get_exp_tries, "\n";
	    print "Pending:        ", $job->is_pending ? 'Yes' : 'No', "\n\n";
	}


	print "Creating a new job.\n";
	my @sts = Bric::Dist::ServerType->list({ mover_class => 'Bric::Util%' });
	my @res = Bric::Dist::Resource->list({ size => [0, 500] });
	$job = Bric::Dist::Job->new({ server_types => \@sts,
				    resources => \@res,
				    sched_time => local_date(0, 0, 1)
				  });
#	$job = Bric::Dist::Job->new({ sched_time => local_date(0, 0, 1) });
	print "ID:             ", $job->get_id || '', "\n";
	print "Scheduled Time: ", $job->get_sched_time("%D %T") || '', "\n";
	print "Complete Time:  ", $job->get_comp_time("%D %T") || '', "\n";
	print "Exp Time:       ", $job->get_exp_time("%D %T") || '', "\n";
	print "Exp Comp Time:  ", $job->get_exp_comp_time("%D %T") || '', "\n";
	print "Exec Tries:     ", $job->get_exec_tries, "\n";
	print "Exp Tries:      ", $job->get_exp_tries, "\n";
	print "Pending:        ", $job->is_pending ? 'Yes' : 'No', "\n";

	print "Resources:";
	if (my @res = $job->get_resources) {
	    print "\n  ", $_->get_path for @res;
	} else {
	    print " None.";
	}
	print "\nServer Types:";
	if (my @sts = $job->get_server_types) {
	    print "\n  ", $_->get_name for @sts;
	} else {
	    print " None.";
	}
	print "\n\n";

	$job->save;
	print "ID:             ", $job->get_id || '', "\n";

	print "Deleting some resources and server types.\n";
	$job->del_resources($res[0]);
	$job->del_server_types($sts[0]);
	$job->save;
	$job = $job->lookup({ id => $job->get_id });
	print "Resources:";
	if (my @res = $job->get_resources) {
	    print "\n  ", $_->get_path for @res;
	} else {
	    print " None.";
	}
	print "\nServer Types:";
	if (my @sts = $job->get_server_types) {
	    print "\n  ", $_->get_name for @sts;
	} else {
	    print " None.";
	}
	print "\n\n";

	print "Canceling that job.\n";
	$job->cancel;
	$job->save;

	exit;
    }

    # Do Test::Harness testing here.


    exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->error_info . "\n" .
      ($err->get_payload || '') . "\n" : "$err\n";
}

