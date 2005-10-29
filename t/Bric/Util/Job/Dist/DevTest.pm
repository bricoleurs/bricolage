package Bric::Util::Job::Dist::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Test::Exception;
use Bric::Util::Job::Dist;
use Bric::Util::Grp::Job;
use Bric::Util::Time qw(:all);
use Bric::Dist::Server;
use Bric::Dist::ServerType;
use Bric::Dist::Resource;
use Bric::Config qw(:time TEMP_DIR QUEUE_PUBLISH_JOBS);
use Bric::Util::Trans::FS;
use Bric::Util::MediaType;
use Bric::Dist::Action::Mover;
use Test::MockModule;

sub table {'job '}

my $date = '2003-01-22 14:43:23';

my %job = ( name => 'Test Job',
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
    Bric::Util::DBI::prepare(qq{DELETE FROM job WHERE id > 1023})->execute;
    return $self;
}

##############################################################################
# Clean out possible test values from Job.tst. We can delete this if we ever
# delete the .tst files.
##############################################################################
sub _clean_test_vals : Test(0) {
    my $self = shift;
    $self->add_del_ids([1,2]);
}

##############################################################################
# Test constructors.
##############################################################################
# Test the new() constructor.
sub test_const : Test(12) {
    my $self = shift;
    my $sched_time = local_date(undef, undef, 1);
    my $args = {
                 name => 'Test Job',
                 user_id => 0,
                 sched_time => $sched_time
               };

    ok ( my $job = Bric::Util::Job::Dist->new($args), "Test construtor" );
    ok( ! defined $job->get_id, 'Undefined ID' );
    is( $job->get_name, $args->{name}, "Name is '$args->{name}'" );
    is( $job->get_sched_time, $sched_time, "Scheduled time is $sched_time" );
    is( $job->get_user_id, 0, "Check User ID 0" );
    is( $job->get_priority, 3, "Check default priority");
    $args->{priority} = 1;
    ok( $job = Bric::Util::Job::Dist->new($args), "Test constructor with min priority");
    is( $job->get_priority, 1, "Check priority");
    $args->{priority} = 5;
    ok( $job = Bric::Util::Job::Dist->new($args), "Test constructor with max priority");
    is( $job->get_priority, 5, "Check priority");
    $args->{priority} = 0.9;
    throws_ok {$job = Bric::Util::Job::Dist->new($args)} 'Bric::Util::Fault::Exception::GEN',
      "Test constructor with priority too low";
    $args->{priority} = 0.9;
    throws_ok {$job = Bric::Util::Job::Dist->new($args)} 'Bric::Util::Fault::Exception::GEN',
      "Test constructor with priority too high";
}

##############################################################################
# Test the lookup() method.
sub test_lookup : Test(8) {
    my $self = shift;
    my %args = %job;
    ok( my $job = Bric::Util::Job::Dist->new(\%args), "Create job" );
    ok( $job->save, "Save the job" );
    ok( my $jid = $job->get_id, "Get the job ID" );
    $self->add_del_ids($jid);
    ok( $job = Bric::Util::Job::Dist->lookup({ id => $jid }),
        "Look up the new job ID '$jid'" );
    is( $job->get_id, $jid, "Check that the ID is the same" );
    # Check a few attributes.
    is( $job->get_sched_time(ISO_8601_FORMAT), $date,
        "Scheduled time is '$date'" );
    my $uid = $self->user_id;
    is( $job->get_user_id, $uid, "Check User ID $uid" );
    is( $job->get_priority, 3, "check default priority");
}

##############################################################################
# Test the list() method.
sub test_list : Test(48) {
    my $self = shift;

    # Create a new job group.
    ok( my $grp = Bric::Util::Grp::Job->new({ name => 'Test JobGrp' }),
        "Create group" );

    # Create a destination.
    ok( my $dest = Bric::Dist::ServerType->new({ name => 'Bogus',
                                                 move_method => 'File System',
                                                 site_id     => 100,
                                               }),
        "Create destination." );
    ok( $dest->save, "Save destination" );
    ok( my $did = $dest->get_id, "Get destination ID" );
    $self->add_del_ids($did, 'server_type');

    # Create a resource.
    ok( my $res = Bric::Dist::Resource->new({ path => TEMP_DIR,
                                              uri => TEMP_DIR,
                                              media_type => 'none'
                                            }),
        "Create resource." );
    ok( $res->save, "Save resource" );
    ok( my $rid = $res->get_id, "Get resource ID" );
    $self->add_del_ids($rid, 'resource');

    # Create some test records.
    for my $n (1..5) {
        my %args = %job;
        if ($n % 2) {
            # Tweak name and add destination ID. Will be 3 of these.
            $args{name} .= $n if $n % 2;
            $args{server_types} = [$dest];
        } else {
            # Add resource ID. Will be two of these.
            $args{resources} = [$res];
        }

        ok( my $job = Bric::Util::Job::Dist->new(\%args), "Create $args{name}" );
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
    ok( my @jobs = Bric::Util::Job::Dist->list({ name => $job{name} }),
        "Look up name $job{name}" );
    is( scalar @jobs, 2, "Check for 2 jobs" );

    # Try name + wildcard.
    ok( @jobs = Bric::Util::Job::Dist->list({ name => "$job{name}%" }),
        "Look up name $job{name}%" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    # Try grp_id.
    ok( @jobs = Bric::Util::Job::Dist->list({ grp_id => $grp_id }),
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
    ok( @jobs = Bric::Util::Job::Dist->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @jobs, 2, "Check for 2 jobs" );

    # Try user_id.
    my $uid = $self->user_id;
    ok( @jobs = Bric::Util::Job::Dist->list({ user_id => $uid }),
        "Look up user_id $uid" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    # Try sched_time.
    ok( @jobs = Bric::Util::Job::Dist->list({ sched_time => $job{sched_time} }),
        "Look up sched_time '$job{sched_time}'" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    # Try sched_time BETWEEN.
    my $before = '2003-01-01 00:00:00';
    my $after  = '2003-02-01 00:00:00';
    ok( @jobs = Bric::Util::Job::Dist->list({ sched_time => [$before, $after] }),
        "Look up sched_time BETWEEN" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    # Try after a date.
    ok( @jobs = Bric::Util::Job::Dist->list({ sched_time => [$before] }),
        "Look up sched_time after 1" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    @jobs = Bric::Util::Job::Dist->list({ sched_time => [$after] });
    is( scalar @jobs, 0, "Check for 0 jobs" );

    # Try before a date.
    ok( @jobs = Bric::Util::Job::Dist->list({ sched_time => [undef, $after] }),
        "Look up sched_time before 1" );
    is( scalar @jobs, 5, "Check for 5 jobs" );

    @jobs = Bric::Util::Job::Dist->list({ sched_time => [undef, $before] });
    is( scalar @jobs, 0, "Check for 0 jobs" );

    # Try server_type_id.
    ok( @jobs = Bric::Util::Job::Dist->list({ server_type_id => $did }),
        "Look up server_type_id '$did'" );
    is( scalar @jobs, 3, "Check for 3 jobs" );

    # Try resource_id.
    ok( @jobs = Bric::Util::Job::Dist->list({ resource_id => $rid }),
        "Look up resource_id '$rid'" );
    is( scalar @jobs, 2, "Check for 2 jobs" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(21) {
    my $self = shift;

    # Create a new job group.
    ok( my $grp = Bric::Util::Grp::Job->new({ name => 'Test JobGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %job;
        # Make sure the name is unique.
        $args{name} .= $n if $n % 2;
        ok( my $job = Bric::Util::Job::Dist->new(\%args), "Create $args{name}" );
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
    ok( my @job_ids = Bric::Util::Job::Dist->list_ids({ name => $job{name} }),
        "Look up name $job{name}" );
    is( scalar @job_ids, 2, "Check for 2 job ids" );

    # Try name + wildcard.
    ok( @job_ids = Bric::Util::Job::Dist->list_ids({ name => "$job{name}%" }),
        "Look up name $job{name}%" );
    is( scalar @job_ids, 5, "Check for 5 job ids" );

    # Try grp_id.
    ok( @job_ids = Bric::Util::Job::Dist->list_ids({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @job_ids, 3, "Check for 3 job ids" );

    # Try user_id.
    my $uid = $self->user_id;
    ok( @job_ids = Bric::Util::Job::Dist->list_ids({ user_id => $uid }),
        "Look up user_id $uid" );
    is( scalar @job_ids, 5, "Check for 5 job ids" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save()
sub test_save : Test(9) {
    my $self = shift;
    my %args = %job;
    ok( my $job = Bric::Util::Job::Dist->new(\%args), "Create job" );
    ok( $job->save, "Save the job" );
    ok( my $jid = $job->get_id, "Get the job ID" );
    $self->add_del_ids($jid);
    ok( $job = Bric::Util::Job::Dist->lookup({ id => $jid }),
        "Look up the new job" );
    ok( my $old_name = $job->get_name, "Get its name" );
    my $new_name = $old_name . ' Foo';
    ok( $job->set_name($new_name), "Set its name to '$new_name'" );
    ok( $job->save, "Save it" );
    ok( Bric::Util::Job::Dist->lookup({ id => $jid }),
        "Look it up again" );
    is( $job->get_name, $new_name, "Check name is '$new_name'" );
}

##############################################################################
# Test execute_me(). This is the big one.
sub test_execute_me : Test(48) {
    my $self = shift;
    my @fns = qw(index.html index1.html email.html print.html story.gif);

    my $fs = Bric::Util::Trans::FS->new;
    # Create a directory for the files.
    my $doc_root = $fs->cat_dir(TEMP_DIR, 'dist');
    my @uri_parts = qw(tech feature);
    my $dir = $fs->cat_dir(TEMP_DIR, 'content',@uri_parts);
    my $uri_dir = $fs->cat_uri(@uri_parts);
    my $dest_dir = $fs->cat_dir($doc_root, @uri_parts);
    $fs->mk_path($dir);

    # Create the resources (files).
    my (@res, @dest_files);
    foreach my $fn (@fns) {
        my $file = $fs->cat_file($dir, $fn);
        my $uri = $fs->cat_uri($uri_dir, $fn);
        $self->greek_file($file);
        my $mt = Bric::Util::MediaType->get_name_by_ext($uri);
        ok( my $res = Bric::Dist::Resource->lookup({ path => $file,
                                                     uri => $uri })
            || Bric::Dist::Resource->new({ path => $file,
                                           uri => $uri,
                                           media_type => $mt }),
            "Create resource for '$fn'" );
        ok($res->save, "Save resource '$fn'" );
        $self->add_del_ids($res->get_id, 'resource');
        push @res, $res;
        push @dest_files, $fs->cat_file($dest_dir, $fn);
    }

    # Create the ServerType and server.
    ok( my $dest = Bric::Dist::ServerType->new({ name => 'Big Test',
                                                 move_method => 'File System',
                                                 site_id     => 100,
                                               }),
        "Create destination" );
    ok( $dest->save, "Save destination" );
    ok( my $did = $dest->get_id, "Get destination ID" );
    $self->add_del_ids($did, 'server_type');

    # Add a move action.
    ok( $dest->new_action({ type => 'Move' }), "Create new action" );
    ok( $dest->save, "Save new action" );

    # Look the destination up again. This is so that it knows what the mover
    # class is.
    ok( $dest = Bric::Dist::ServerType->lookup({ id => $did }),
        "Look up destination '$did'" );

    # Create server.
    ok( my $server = Bric::Dist::Server->new({ host_name => 'localhost',
                                               server_type_id => $did,
                                               os => 'Unix',
                                               doc_root => $doc_root
                                             }),
        "Create server" );
    ok( $server->save, "Save server" );
    ok( my $sid = $server->get_id, "Get server ID" );
    $self->add_del_ids($sid, 'server');

    # Create and execute the job.
    my %args = %job;
    ok( my $job = Bric::Util::Job::Dist->new(\%args), "Create new job" );
    ok( $job->add_resources(@res), "Add resources" );
    ok( $job->add_server_types($dest), "Add destination" );
    # Set the job to execute now.
    ok( $job->set_sched_time(local_date(0, ISO_8601_FORMAT, 1)),
        "Set time for now" );
    if (QUEUE_PUBLISH_JOBS) {
        $job->save;
        ok( $job->execute_me, "Execute job" );
    } else {
        ok( $job->save, "Save job" );
    }
    $self->add_del_ids($job->get_id);

    # check for error message
    is($job->get_error_message, undef, "... should not have an error message.");

    # Now check for the existence of the files.
    foreach (@dest_files) {
        ok(-f, "Check for '$_'");
    }

    # Create a new ServerType and server.
    ok( my $bad_dest = Bric::Dist::ServerType->new({ name => 'Big Bad Test',
                                                 move_method => 'FTP',
                                                 site_id     => 100,
                                               }),
        "Create destination" );
    ok( $bad_dest->save, "Save destination" );
    ok( $did = $bad_dest->get_id, "Get destination ID" );
    $self->add_del_ids($did, 'server_type');

    # Add a move action.
    ok( $bad_dest->new_action({ type => 'Move' }), "Create new action" );
    ok( $bad_dest->save, "Save new action" );

    # Look the destination up again. This is so that it knows what the mover
    # class is.
    ok( $bad_dest = Bric::Dist::ServerType->lookup({ id => $did }),
        "Look up destination '$did'" );

    # Create server.
    ok( my $bad_server = Bric::Dist::Server->new({ host_name => 'ftp.example.com',
                                               server_type_id => $did,
                                               os => 'Unix',
                                               doc_root => 'does_not_exist', 
                                             }),
        "Create server" );
    ok( $bad_server->save, "Save server" );
    ok( $sid = $server->get_id, "Get server ID" );
    $self->add_del_ids($sid, 'server');


    # create a new job, same files etc.
    $job = Bric::Util::Job::Dist->new(\%args);
    $job->add_resources(@res);
    $job->add_server_types($bad_dest);
    $job->set_sched_time(local_date(0, ISO_8601_FORMAT, 1));
    # check return on execution for a bad destination
    if (QUEUE_PUBLISH_JOBS) {
        $job->save;
        dies_ok {$job->execute_me} "Try another job, this time with a bad destination.";
    } else {
        dies_ok {$job->save} "Try another job, this time with a bad destination.";
    }
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
}

##############################################################################
# Utility methods.
##############################################################################
# Writes stuff to a file.
sub greek_file {
    my ($self, $file) = @_;
    open F, '>', $file or die "Cannot open '$file': $!\n";
    local $/;
    print F <DATA>;
    close $file;
}

1;
__DATA__
Taken from http://www.lemurzone.com/notes/greeking.htm.

Perhaps a re-engineering of your current world view will re-energize your
online nomenclature to enable a new holistic interactive enterprise internet
communication solution.

Upscaling the resurgent networking exchange solutions, achieving a breakaway
systemic electronic data interchange system synchronization, thereby
exploiting technical environments for mission critical broad based capacity
constrained systems.

Fundamentally transforming well designed actionable information whose semantic
content is virtually null.

To more fully clarify the current exchange, a few aggregate issues will
require addressing to facilitate this distributed communication venue.

In integrating non-aligned structures into existing legacy systems, a holistic
gateway blueprint is a backward compatible packaging tangible of immeasurable
strategic value in right-sizing conceptual frameworks when thinking outside
the box.
