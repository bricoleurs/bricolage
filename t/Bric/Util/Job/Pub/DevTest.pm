package Bric::Util::Job::Pub::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Test::Exception;
use Bric::Util::Job::Pub;
use Bric::Util::Job::Dist;
use Bric::Util::Grp::Job;
use Bric::Util::Class;
use Bric::Util::Time qw(:all);
use Bric::Dist::Server;
use Bric::Dist::ServerType;
use Bric::Dist::Resource;
use Bric::Config qw(:time TEMP_DIR QUEUE_PUBLISH_JOBS);
use Bric::Util::Trans::FS;
use Bric::Util::MediaType;
use Bric::Biz::ElementType;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;
use Bric::Util::Burner;
use Bric::Biz::Person::User;
use Bric::Biz::Asset::Template;
use Bric::Util::DBI qw(:junction);
use Test::MockModule;

sub table {'job'}

my $date = '2003-01-22 14:43:23.000000';

my %job = (
            name => 'Test Job',
            user_id => __PACKAGE__->user_id,
            sched_time => $date
          );

sub test_setup : Test(setup) {
    my $self = shift;
    # Turn off event logging.
    $self->{event} = Test::MockModule->new('Bric::Util::Job');
    $self->{event}->mock(commit_events => undef);
}

sub test_teardown : Test(teardown) {
    my $self = shift;
    delete($self->{event})->unmock_all;
    return $self;
}

##############################################################################
# Clean out possible test values from Job.tst. We can delete this if we ever
# delete the .tst files.
##############################################################################
sub _clean_test_vals : Test(startup) {
    my $self = shift;
    $self->add_del_ids([1,2]);
}

##############################################################################
# Deploy the story and autohandler templates. During tests, they won't be
# found because we're using a temporary directory.
##############################################################################
sub _run_me_first : Test(4) {
    ok( my @tmpl = Bric::Biz::Asset::Template->list({
        output_channel__id => 1,
        file_name          => ANY('/story.mc', '/autohandler'),
        Order              => 'file_name',
    }), "Get story template.");

    ok( my $burner = Bric::Util::Burner->new, "Get burner" );
    ok( $burner->deploy($tmpl[0]), "Deploy autohandler template" );
    ok( $burner->deploy($tmpl[1]), "Deploy story template" );
}

##############################################################################
# Test constructors.
##############################################################################
# Test the new() constructor.
sub a_test_const : Test(5) {
    my $self = shift;
    my $sched_time = local_date(undef, undef, 1);
    my $args = { name => 'Test Job',
                 user_id => 0,
                 sched_time => $sched_time
               };

    ok ( my $job = Bric::Util::Job::Pub->new($args), "Test construtor" );
    ok( ! defined $job->get_id, 'Undefined ID' );
    is( $job->get_name, $args->{name}, "Name is '$args->{name}'" );
    is( $job->get_sched_time, $sched_time, "Scheduled time is $sched_time" );
    is( $job->get_user_id, 0, "Check User ID 0" );
}

##############################################################################
# Test the lookup() method.
sub b_test_lookup : Test(7) {
    my $self = shift;
    my %args = %job;
    ok( my $job = Bric::Util::Job::Pub->new(\%args), "Create job" );
    ok( $job->save, "Save the job" );
    ok( my $jid = $job->get_id, "Get the job ID" );
    $self->add_del_ids($jid);
    ok( $job = Bric::Util::Job::Pub->lookup({ id => $jid }),
        "Look up the new job ID '$jid'" );
    is( $job->get_id, $jid, "Check that the ID is the same" );
    # Check a few attributes.
    is( $job->get_sched_time(ISO_8601_FORMAT), $date,
        "Scheduled time is '$date'" );
    my $uid = $self->user_id;
    is( $job->get_user_id, $uid, "Check User ID $uid" );
}

##############################################################################
# Test the list() method.
sub c_test_list : Test(47) {
    my $self = shift;

    # Create a new job group.
    ok( my $grp = Bric::Util::Grp::Job->new({ name => 'Test JobGrp' }),
        "Create group" );

    my ($element) = Bric::Biz::ElementType->list({ name => 'Story' });
    # And the default OutputChannel.
    my ($oc) = Bric::Biz::OutputChannel->list();

    # Create a destination.
    ok( my $dest = Bric::Dist::ServerType->new({ name        => 'Bogus',
                                                 move_method => 'File System',
                                                 site_id     => 100,
                                               }),
        "Create destination." );

    $dest->add_output_channels($oc);
    ok( $dest->save, "Save destination" );
    ok( my $did = $dest->get_id, "Get destination ID" );
    $self->add_del_ids($did, 'server_type');

    # look up a story element
    my $time = time;
    my $story = Bric::Biz::Asset::Business::Story->new({
            name        => "_test_$time",
            description => 'this is a test',
            priority    => 1,
            source__id  => 1,
            slug        => 'test',
            user__id    => $self->user_id(),
            element     => $element,
            site_id     => 100,
        });
    my $cat = Bric::Biz::Category->lookup({ id => 1 });
    $story->add_categories([$cat]);
    $story->set_primary_category($cat);
    $story->set_cover_date('2005-03-22 21:07:56');
    $story->save();
    my $svid = $story->get_version_id;
    my $sid  = $story->get_id;
    $self->add_del_ids($sid, 'story');

    # XXX Check media too !!!

    # Create some test records.
    for my $n (1..5) {
        my %args = %job;
        if ($n % 2) {
            # Tweak name and add destination ID. Will be 3 of these.
            $args{name} .= $n if $n % 2;
            $args{server_types} = [$dest];
        } else {
            # Add story ID. Will be two of these.
            $args{story_instance_id} = $svid;
        }

        ok( my $job = Bric::Util::Job::Pub->new(\%args), "Create $args{name}" );
        ok( $job->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($job->get_id);
        $grp->add_member({ obj => $job }) if $n % 2;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name.
    ok( my @jobs = Bric::Util::Job::Pub->list({ name => $job{name} }),
        "Look up name $job{name}" );
    is( scalar @jobs, 2, "Check for 2 jobs" );

    # Try name + wildcard.
    ok( @jobs = Bric::Util::Job::Pub->list({ name => "$job{name}%" }),
        "Look up name $job{name}%" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    # Try grp_id.
    ok( @jobs = Bric::Util::Job::Pub->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @jobs, 3, "Check for 3 jobs" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Util::Job::INSTANCE_GROUP_ID;
    foreach my $job (@jobs) {
        my %grp_ids = map { $_ => 1 } $job->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $jobs[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @jobs = Bric::Util::Job::Pub->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @jobs, 2, "Check for 2 jobs" );

    # Try user_id.
    my $uid = $self->user_id;
    ok( @jobs = Bric::Util::Job::Pub->list({ user_id => $uid }),
        "Look up user_id $uid" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    # Try sched_time.
    ok( @jobs = Bric::Util::Job::Pub->list({ sched_time => $job{sched_time} }),
        "Look up sched_time '$job{sched_time}'" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    # Try sched_time BETWEEN.
    my $before = '2003-01-01 00:00:00';
    my $after  = '2003-02-01 00:00:00';
    ok( @jobs = Bric::Util::Job::Pub->list({ sched_time => [$before, $after] }),
        "Look up sched_time BETWEEN" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    # Try after a date.
    ok( @jobs = Bric::Util::Job::Pub->list({ sched_time => [$before] }),
        "Look up sched_time after 1" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    @jobs = Bric::Util::Job::Pub->list({ sched_time => [$after] });
    is( scalar @jobs, 0, "Check for 0 jobs" );

    # Try before a date.
    ok( @jobs = Bric::Util::Job::Pub->list({ sched_time => [undef, $after] }),
        "Look up sched_time before 1" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    @jobs = Bric::Util::Job::Pub->list({ sched_time => [undef, $before] });
    is( scalar @jobs, 0, "Check for 0 jobs" );

    # Try server_type_id.
    ok( @jobs = Bric::Util::Job::Pub->list({ server_type_id => $did }),
        "Look up server_type_id '$did'" );
    is( scalar @jobs, 3, "Check for 3 jobs" );

    # Try story_id.
    ok( @jobs = Bric::Util::Job::Pub->list({ story_id => $sid }),
        "Look up story_id '$sid'" );
    is( scalar @jobs, 2, "Check for 2 jobs" );

    # Try story_instance_id.
    ok( @jobs = Bric::Util::Job::Pub->list({ story_instance_id => $svid }),
        "Look up story_instance_id '$svid'" );
    is( scalar @jobs, 2, "Check for 2 jobs" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test the list_ids() method.
sub d_test_list_ids : Test(21) {
    my $self = shift;

    # Create a new job group.
    ok( my $grp = Bric::Util::Grp::Job->new({ name => 'Test JobGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %job;
        # Make sure the name is unique.
        $args{name} .= $n if $n % 2;
        ok( my $job = Bric::Util::Job::Pub->new(\%args), "Create $args{name}" );
        ok( $job->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($job->get_id);
        $grp->add_member({ obj => $job }) if $n % 2;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name.
    ok( my @job_ids = Bric::Util::Job::Pub->list_ids({ name => $job{name} }),
        "Look up name $job{name}" );
    is( scalar @job_ids, 2, "Check for 2 job ids" );

    # Try name + wildcard.
    ok( @job_ids = Bric::Util::Job::Pub->list_ids({ name => "$job{name}%" }),
        "Look up name $job{name}%" );
    is( scalar @job_ids, 5, "Check for 5 job ids" );

    # Try grp_id.
    ok( @job_ids = Bric::Util::Job::Pub->list_ids({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @job_ids, 3, "Check for 3 job ids" );

    # Try user_id.
    my $uid = $self->user_id;
    ok( @job_ids = Bric::Util::Job::Pub->list_ids({ user_id => $uid }),
        "Look up user_id $uid" );
    is( scalar @job_ids, 5, "Check for 5 job ids" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save()
sub f_test_save : Test(9) {
    my $self = shift;
    my %args = %job;
    ok( my $job = Bric::Util::Job::Pub->new(\%args), "Create job" );
    ok( $job->save, "Save the job" );
    ok( my $jid = $job->get_id, "Get the job ID" );
    $self->add_del_ids($jid);
    ok( $job = Bric::Util::Job::Pub->lookup({ id => $jid }),
        "Look up the new job" );
    ok( my $old_name = $job->get_name, "Get its name" );
    my $new_name = $old_name . ' Foo';
    ok( $job->set_name($new_name), "Set its name to '$new_name'" );
    ok( $job->save, "Save it" );
    ok( Bric::Util::Job::Pub->lookup({ id => $jid }),
        "Look it up again" );
    is( $job->get_name, $new_name, "Check name is '$new_name'" );

}

##############################################################################
# Test execute_me(). This is the big one.
sub g_test_execute_me : Test(10) {
    my $self = shift;
    my %args = %job;
    # Get the story element
    my ($element) = Bric::Biz::ElementType->list({ name => 'Story' });
    # And the default OutputChannel.
    my ($oc) = Bric::Biz::OutputChannel->list();
    # and a user
    # We'll need a destination, since there are none by default
    my $dest = Bric::Dist::ServerType->new({ 
                                             name => 'Big Test',
                                             move_method => 'File System',
                                             site_id     => 100,
                                          });
    $dest->add_output_channels($oc); # this is crucial for publishing
    $dest->save;
    my $did = $dest->get_id;
    $self->add_del_ids($did, 'server_type');
    # Create a story
    my $time = time;
    my $story = Bric::Biz::Asset::Business::Story->new({
            name        => "_test_$time",
            description => 'this is a test',
            priority    => 1,
            source__id  => 1,
            slug        => 'test',
            user__id    => $self->user_id(),
            element     => $element, 
            site_id     => 100,
        });
    my $cat = Bric::Biz::Category->lookup({ id => 1 });
    $story->add_categories([$cat]);
    $story->set_primary_category($cat);
    $story->set_cover_date('2005-03-22 21:07:56');
    $story->save();
    my $sid = $story->get_id;
    $self->add_del_ids($sid, 'story');
    # create a job
    my $job = Bric::Util::Job::Pub->new(\%args);
    # add the story to the job
    $job->set_story_instance_id($story->get_version_id);
    # set the job execution time to now
    $job->set_sched_time(local_date(0, ISO_8601_FORMAT, 1));
    # test: Save the job.  With the default config file this will have the
    # side effect of executing the job. OK?
    if (QUEUE_PUBLISH_JOBS) {
        $job->save;
        ok( $job->execute_me, 'Execute the job');
    } else {
        ok( $job->save, 'Save (and execute) the job');
    }
    is( $job->get_error_message, undef, "There was no error running job.");
    $self->add_del_ids($job->get_id);
    # test: Check that our job is now complete
    ok( $job = Bric::Util::Job->lookup({ id => $job->get_id }), 
      'lookup the job we just executed' );
    isnt( $job->get_comp_time(), undef, 
      'check that the job has a completion time');
    # test: Check for a matching Dist job
    my $story_name = $story->get_name();
    my $job_name = "Distribute \"$story_name\" to \"Web\"";
    ok( my @dist_jobs = Bric::Util::Job::Dist->list({ name => $job_name }), 
      'list the dist jobs' );
    is( scalar @dist_jobs, 1, '... there should be just one' );
    # test: Get it's resources and ...
    my ($dist_job) = @dist_jobs;
    ok( my @resources = $dist_job->get_resources(),
      'get the resources of from the new dist job');
    is( scalar @resources, 1, '... there should be just one' );
    my ($resource) = @resources;
    $self->add_del_ids($resource->get_id,'resource');
    # test: get the resource path
    ok( my $path = $resource->get_path, 'get the path to the resource');
    open IN, $path;
    local $/;
    my $got = <IN>;
    close IN;
    my $expect = qq{<!-- Start "autohandler" -->
<html>
    <head>
        <title>$story_name</title>
    </head>
    <body>
<!-- Start "Story" -->

<h1>$story_name</h1>

<hr />


<br>
Page 1
<!-- End "Story" -->
    </body>
</html>
<!-- End "autohandler" -->
};
    is( $got, $expect, 'Check that the resource came out all right');
    # Save any dist job ids for deleting too
    $self->add_del_ids( [ Bric::Util::Job::Dist->list_ids ] );
}

##############################################################################
# Test execute_me error_handling.
sub h_test_execute_me : Test(16) {
    my $self = shift;

    my $elem = Bric::Biz::ElementType->new({
        name          => 'Test Element',
        key_name      => 'test_element',
        description   => 'Testing Publish Job error handling',
        top_level     => 1,
        reference     => 0,
        primary_oc_id => 1
    });
    $elem->save;
    $self->add_del_ids($elem->get_id, 'element_type');

    my $tmpl = Bric::Biz::Asset::Template->new({
        output_channel__id => 1,
        user__id           => $self->user_id,
        category_id        => 1,
        site_id            => 100,
        element            => $elem,
        data               => '% die "Goodbye cruel world !";',
    });
    $tmpl->save;
    $self->add_del_ids($tmpl->get_id, 'template');

    # Create a burner.
    my $fs = Bric::Util::Trans::FS->new;
    ok( my $burner = Bric::Util::Burner->new
        ({ comp_dir => $fs->cat_dir(TEMP_DIR, 'comp') }),
        "Create burner" );

    # Check in an deploy the template
    $tmpl->checkin;
    $tmpl->save;
    $burner->deploy($tmpl);

    # We'll need a destination, since there are none by default
    my $dest = Bric::Dist::ServerType->new({
        name => 'Big Test',
        move_method => 'File System',
        site_id     => 100,
    });

    # the default OutputChannel.
    my $oc = Bric::Biz::OutputChannel->lookup({ id => 1 });
    $dest->add_output_channels($oc); # this is crucial for publishing
    $dest->save;
    my $did = $dest->get_id;
    $self->add_del_ids($did, 'server_type');

    # Create a story
    my $story = Bric::Biz::Asset::Business::Story->new({
        name        => 'bad test story',
        description => 'this is a test',
        priority    => 1,
        source__id  => 1,
        slug        => 'badtest',
        user__id    => $self->user_id(),
        element     => $elem,
        site_id     => 100,
    });

    my $cat = Bric::Biz::Category->lookup({ id => 1 });
    $story->add_categories([$cat]);
    $story->set_primary_category($cat);
    $story->add_output_channels($oc);;
    $story->set_primary_oc_id(1);
    $story->set_cover_date('2005-03-22 21:07:56');
    $story->save;
    $self->add_del_ids($story->get_id, 'story');

    # Make sure that the old story_id parameter still works.
    my $job = Bric::Util::Job::Pub->new({
        name        => 'Test Job',
        user_id     => $self->user_id,
        sched_time  => $date,
        story_id    => $story->get_id,
    });

    if (QUEUE_PUBLISH_JOBS) {
        $job->save;
        dies_ok {$job->execute_me} 'Publish with a template error';
    } else {
        dies_ok {$job->save} 'Publish with a template error';
    }
    # Save the ID for deleting.
    $self->add_del_ids($job->get_id);

    # check for error message
    isnt($job->get_error_message, undef, "... should have an error message now.");
    # check that tries goes up
    is($job->get_tries, 1, "... should have one try now.");
    is($job->has_failed, 0, "... has_failed should still return false.");
    # check that tries goes up on another error
    dies_ok {$job->execute_me} "Try again.";
    is($job->get_tries, 2, "... should have two tries now.");
    # check that tries goes up on another error
    dies_ok {$job->execute_me} "Try again.";
    is($job->get_tries, 3, "... should have three tries now.");
    is($job->has_failed, 1, "... has_failed should now return true.");

    # Try resetting the job.
    ok($job->reset, 'Reset the job');
    ok($job->save, 'Save the reset job');
    ok($job = Bric::Util::Job::Pub->lookup({ id => $job->get_id}),
       'Look up the job again for good measure');
    is($job->get_error_message, undef,
       'The error message should be undefined again');
    is($job->get_tries, 0, 'Tries should be reset');
    is($job->has_failed, 0, 'The job should no loner be marked as failed');
}

1;
__END__
