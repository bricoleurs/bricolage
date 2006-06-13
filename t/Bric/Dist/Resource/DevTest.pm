package Bric::Dist::Resource::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Config qw(:temp);
use Bric::Dist::Resource;
use Bric::Util::Job::Dist;
use Bric::Util::Time qw(strfdate);
use Bric::Util::Trans::FS;
use Bric::Biz::Asset::Business::Story::DevTest;
use Bric::Biz::Asset::Business::Media::DevTest;
use File::Spec::Functions qw(catfile);
use Cwd;

sub table {'resource'}

my $contents = '% $m->print("Hello world!\n");';

sub write_file {
    my ($self, $fn, $data) = @_;
    my $file = Bric::Util::Trans::FS->cat_dir(TEMP_DIR, $fn);
    open F, ">$file" or die "Cannot open '$file': $!\n";
    print F $contents;
    print F $data if $data;
    close F;
    return $file;
}

##############################################################################
# Setup.
sub test_setup : Test(setup => 50) {
    my $self = shift;
    my $name = 'test';
    $self->{basename} = $name;

    # Construct a story.
    ok( my $story = Bric::Biz::Asset::Business::Story::DevTest->construct,
        "Construct story" );
    ok( $story->save, "Save story" );
    ok( my $sid = $story->get_id, "Get story ID" );
    $self->add_del_ids($sid, 'story' );
    $self->{sid} = $sid;

    # Construct a media document.
    ok( my $media = Bric::Biz::Asset::Business::Media::DevTest->construct,
        "Construct media" );
    ok( $media->save, "Save media" );
    ok( my $mid = $media->get_id, "Get media ID" );
    $self->add_del_ids($mid, 'media' );
    $self->{mid} = $mid;

    # Construct a couple of jobs.
    my $date = '2030-01-22 14:43:23';
    my @jobs;
    for my $i (1, 2) {
        ok( my $j = Bric::Util::Job::Dist->new({ name => "Test Job $i",
                                           user_id => __PACKAGE__->user_id,
                                           sched_time => $date }),
            "Create job $i" );
        push @jobs, $j;
    }

    # Create a resource for the directory.
    ok( my $dir = Bric::Dist::Resource->new({ path       => TEMP_DIR,
                                              uri        => '/',
                                              media_type => 'none' }),
        "Create directory resource" );
    isa_ok( $dir, 'Bric::Dist::Resource' );
    isa_ok( $dir, 'Bric' );
    ok( $dir->save, "Save directory resource" );
    ok( my $did = $dir->get_id, "Get directory ID" );
    $self->add_del_ids($did);
    $self->{did} = $did;

    my (@res, @rids, @paths);
    # Create some test records.
    for my $n (1..5) {
        my (%args, $res);
        my $fn = "$name\_$n.";
        if ($n % 2) {
            $fn .= 'txt';
            $args{uri} = "/$fn";
            $args{media_type} = 'text/plain';
            $args{parent_id} = $did;
            ok( $args{path} = $self->write_file($fn), "Write $fn" );
            ok( $res = Bric::Dist::Resource->new({ %args }),
                "Create $args{uri}" );
            ok( $res->add_story_ids($sid), "Add story ID to $args{uri}" );
            ok( $jobs[1]->add_resources($res), "Add $args{uri} to job 2" );
        } else {
            $fn .= 'html';
            $args{uri} = "/$fn";
            $args{media_type} = 'text/html';
            delete $args{parent_id};
            ok( $args{path} = $self->write_file($fn, $n), "Write $fn" );
            ok( $res = Bric::Dist::Resource->new({ %args }),
                "Create $args{uri}" );
            ok( $res->add_media_ids($mid), "Add media ID to $args{uri}" );
        }

        ok( $jobs[0]->add_resources($res), "Add $args{uri} to job 1" );
        push @paths, $args{path};

        ok( $res->save, "Save $args{uri}" );
        ok( my $rid = $res->get_id, "Get resource $args{uri} ID" );
        # Save the ID for deleting.
        $self->add_del_ids($rid);
        push @rids, $rid;
        push @res, $res;
    }

    # Save the jobs.
    my @jids;
    for my $i (0, 1) {
        ok( $jobs[$i]->save, "Save job $i" );
        ok( $jids[$i] = $jobs[$i]->get_id, "Get job $i ID" );
    }
    $self->add_del_ids(\@jids, 'job');
    $self->{jids}  = \@jids;
    $self->{jobs}  = \@jobs;
    $self->{paths} = \@paths;
    $self->{rids}  = \@rids;
    $self->{res}   = \@res;
}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(9) {
    my $self = shift;
    ok( my $res = Bric::Dist::Resource->lookup({ id => $self->{rids}[0] }),
        "Look up the new resource" );
    isa_ok( $res, 'Bric::Dist::Resource' );
    isa_ok( $res, 'Bric' );
    is( $res->get_id, $self->{rids}[0], "Check that the ID is the same" );
    # Check a few attributes.
    is( $res->get_path, $self->{res}[0]->get_path, "Check path" );
    is( $res->get_uri, $self->{res}[0]->get_uri, "Check uri" );
    is( $res->get_size, $self->{res}[0]->get_size, "Check size" );
    is( $res->get_mod_time, strfdate((stat $self->{res}[0]->get_path)[9]),
        "Check mod time" );
    ok( !$res->is_dir, "Check it's not a directory" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(48) {
    my $self = shift;
    # Try uri.
    ok( my @ress = Bric::Dist::Resource->list
        ({ uri => "/$self->{basename}\_1.txt" }),
        "Look up uri '/$self->{basename}\_1.txt'" );
    is( scalar @ress, 1, "Check for 1 resources" );

    # Try uri + wild card.
    ok( @ress = Bric::Dist::Resource->list({ uri => "/$self->{basename}%" }),
        "Look up uri '/$self->{basename}%'" );
    is( scalar @ress, 5, "Check for 5 resources" );

    # Try path.
    ok( @ress = Bric::Dist::Resource->list({ path => $self->{paths}[0] }),
        "Look up path '$self->{paths}[0]'" );
    is( scalar @ress, 1, "Check for 1 resources" );

    # Try path + wild card.
    (my $trunc_file = $self->{paths}[0]) =~ s/_\d\.[^\.]*$//;
    ok( @ress = Bric::Dist::Resource->list({ path => "$trunc_file%" }),
        "Look up path '$trunc_file%'" );
    is( scalar @ress, 5, "Check for 5 resources" );

    # Try media_type.
    ok( @ress = Bric::Dist::Resource->list({ media_type => 'text/plain' }),
        "Look up media_type 'text/plain'" );
    is( scalar @ress, 3, "Check for 3 resources" );
    ok( @ress = Bric::Dist::Resource->list({ media_type => 'text/html' }),
        "Look up media_type 'text/html'" );
    is( scalar @ress, 2, "Check for 2 resources" );

    # Try media_type + wild card.
    ok( @ress = Bric::Dist::Resource->list({ media_type => 'text/%' }),
        "Look up media_type 'text/%'" );
    is( scalar @ress, 5, "Check for 5 resources" );

    # Try mod_time.
    my $mod_epoch = (stat $self->{paths}[0])[9];
    my $mod = strfdate($mod_epoch);
    ok( @ress = Bric::Dist::Resource->list({ mod_time => $mod }),
        "Look up mod_time '$mod'" );
    ok( scalar @ress >= 1, "Check for 1 or more resources" );

    # Try a range of mod_times.
    my $early = strfdate($mod_epoch - 60 * 60);
    my $late = strfdate($mod_epoch + 5);
    ok( @ress = Bric::Dist::Resource->list({ mod_time => [$early, $late] }),
        "Look up mod_time between '$early' and '$late'" );
    # Includes the directory of course!
    is( scalar @ress, 6, "Check for 6 resources" );

    # Try size.
    my $size = length $contents;
    ok( @ress = Bric::Dist::Resource->list({ size => $size }),
        "Look up size '$size'" );
    is( scalar @ress, 3, "Check for 3 resources" );
    $size++;
    ok( @ress = Bric::Dist::Resource->list({ size => $size }),
        "Look up size '$size'" );
    is( scalar @ress, 2, "Check for 2 resources" );

    # Try a range of sizes.
    ok( @ress = Bric::Dist::Resource->list({ size => [$size - 1, $size] }),
        "Look up size between " . ($size - 1) . "and '$size'" );
    is( scalar @ress, 5, "Check for 5 resources" );

    # Try is_dir.
    ok( @ress = Bric::Dist::Resource->list({ is_dir => 0 }),
        "Look up is_dir false" );
    is( scalar @ress, 5, "Check for 5 resources" );
    ok( @ress = Bric::Dist::Resource->list({ is_dir => 1 }),
        "Look up is_dir true" );
    is( scalar @ress, 1, "Check for 1 resource" );

    # Try story_id.
    ok( @ress = Bric::Dist::Resource->list({ story_id => $self->{sid} }),
        "Look up story_id '$self->{sid}'" );
    is( scalar @ress, 3, "Check for 3 resources" );

    # Try media_id.
    ok( @ress = Bric::Dist::Resource->list({ media_id => $self->{mid} }),
        "Look up media_id '$self->{mid}'" );
    is( scalar @ress, 2, "Check for 2 resources" );

    # Try dir_id.
    ok( @ress = Bric::Dist::Resource->list({ dir_id => $self->{did} }),
        "Look up dir_id '$self->{did}'" );
    is( scalar @ress, 3, "Check for 3 resources" );

    # Try job_id.
    ok( @ress = Bric::Dist::Resource->list({ job_id => $self->{jids}[0] }),
        "Look up job_id '$self->{jids}[0]'" );
    is( scalar @ress, 5, "Check for 5 resources" );
    ok( @ress = Bric::Dist::Resource->list({ job_id => $self->{jids}[1] }),
        "Look up job_id '$self->{jids}[1]'" );
    is( scalar @ress, 3, "Check for 3 resources" );

    # Try not_job_id.
    ok( @ress = Bric::Dist::Resource->list({ not_job_id => $self->{jids}[0] }),
        "Look up not_job_id '$self->{jids}[0]'" );
    is( scalar @ress, 1, "Check for 1 resources" );
    ok( @ress = Bric::Dist::Resource->list({ not_job_id => $self->{jids}[1] }),
        "Look up not_job_id '$self->{jids}[1]'" );
    is( scalar @ress, 3, "Check for 2 resources" );

    # Try oc_id.
    ok( my $oc = Bric::Biz::OutputChannel->lookup({ id => 1 }),
        'Lookup Web OC' );
    ok( my $dest = Bric::Dist::ServerType->new({
        name        => 'tester',
        site_id     => 100,
        move_method => 'File System'
    }), 'Create destination');
    ok $dest->add_output_channels($oc), 'Add the Web OC to it';
    ok $dest->save, 'Save the destination';
    $self->add_del_ids($dest->get_id, 'server_type');

    # Associate one of the jobs with the server type.
    $self->{jobs}[0]->add_server_types($dest)->save;

    ok( @ress = Bric::Dist::Resource->list({ oc_id => 1 }),
        "Look up oc_id '5'" );
    is( scalar @ress, 5, "Check for 5 resources" );
}

##############################################################################
# Test the href() method.
sub test_href : Test(47) {
    my $self = shift;
    # Try uri.
    ok( my $ress = Bric::Dist::Resource->href
        ({ uri => "/$self->{basename}\_1.txt" }),
        "Look up uri '/$self->{basename}\_1.txt'" );
    is( scalar keys %$ress, 1, "Check for 1 resources" );

    # Try uri + wild card.
    ok( $ress = Bric::Dist::Resource->href({ uri => "/$self->{basename}%" }),
        "Look up uri '/$self->{basename}%'" );
    is( scalar keys %$ress, 5, "Check for 5 resources" );

    # Check the keys and values.
    while (my ($k, $v) = each %$ress) {
        is( $k, $v->get_id, "Check ID $k" );
    }

    # Try path.
    ok( $ress = Bric::Dist::Resource->href({ path => $self->{paths}[0] }),
        "Look up path '$self->{paths}[0]'" );
    is( scalar keys %$ress, 1, "Check for 1 resources" );

    # Try path + wild card.
    (my $trunc_file = $self->{paths}[0]) =~ s/_\d\.[^\.]*$//;
    ok( $ress = Bric::Dist::Resource->href({ path => "$trunc_file%" }),
        "Look up path '$trunc_file%'" );
    is( scalar keys %$ress, 5, "Check for 5 resources" );

    # Try media_type.
    ok( $ress = Bric::Dist::Resource->href({ media_type => 'text/plain' }),
        "Look up media_type 'text/plain'" );
    is( scalar keys %$ress, 3, "Check for 3 resources" );
    ok( $ress = Bric::Dist::Resource->href({ media_type => 'text/html' }),
        "Look up media_type 'text/html'" );
    is( scalar keys %$ress, 2, "Check for 2 resources" );

    # Try media_type + wild card.
    ok( $ress = Bric::Dist::Resource->href({ media_type => 'text/%' }),
        "Look up media_type 'text/%'" );
    is( scalar keys %$ress, 5, "Check for 5 resources" );

    # Try mod_time.
    my $mod_epoch = (stat $self->{paths}[0])[9];
    my $mod = strfdate($mod_epoch);
    ok( $ress = Bric::Dist::Resource->href({ mod_time => $mod }),
        "Look up mod_time '$mod'" );
    ok( scalar keys %$ress >= 1, "Check for 1 or more resources" );

    # Try a range of mod_times.
    my $early = strfdate($mod_epoch - 60 * 60);
    my $late = strfdate($mod_epoch + 5);
    ok( $ress = Bric::Dist::Resource->href({ mod_time => [$early, $late] }),
        "Look up mod_time between '$early' and '$late'" );
    # Includes the directory of course!
    is( scalar keys %$ress, 6, "Check for 6 resources" );

    # Try size.
    my $size = length $contents;
    ok( $ress = Bric::Dist::Resource->href({ size => $size }),
        "Look up size '$size'" );
    is( scalar keys %$ress, 3, "Check for 3 resources" );
    $size++;
    ok( $ress = Bric::Dist::Resource->href({ size => $size }),
        "Look up size '$size'" );
    is( scalar keys %$ress, 2, "Check for 2 resources" );

    # Try a range of sizes.
    ok( $ress = Bric::Dist::Resource->href({ size => [$size - 1, $size] }),
        "Look up size between " . ($size - 1) . "and '$size'" );
    is( scalar keys %$ress, 5, "Check for 5 resources" );

    # Try is_dir.
    ok( $ress = Bric::Dist::Resource->href({ is_dir => 0 }),
        "Look up is_dir false" );
    is( scalar keys %$ress, 5, "Check for 5 resources" );
    ok( $ress = Bric::Dist::Resource->href({ is_dir => 1 }),
        "Look up is_dir true" );
    is( scalar keys %$ress, 1, "Check for 1 resource" );

    # Try story_id.
    ok( $ress = Bric::Dist::Resource->href({ story_id => $self->{sid} }),
        "Look up story_id '$self->{sid}'" );
    is( scalar keys %$ress, 3, "Check for 3 resources" );

    # Try media_id.
    ok( $ress = Bric::Dist::Resource->href({ media_id => $self->{mid} }),
        "Look up media_id '$self->{mid}'" );
    is( scalar keys %$ress, 2, "Check for 2 resources" );

    # Try dir_id.
    ok( $ress = Bric::Dist::Resource->href({ dir_id => $self->{did} }),
        "Look up dir_id '$self->{did}'" );
    is( scalar keys %$ress, 3, "Check for 3 resources" );

    # Try job_id.
    ok( $ress = Bric::Dist::Resource->href({ job_id => $self->{jids}[0] }),
        "Look up job_id '$self->{jids}[0]'" );
    is( scalar keys %$ress, 5, "Check for 5 resources" );
    ok( $ress = Bric::Dist::Resource->href({ job_id => $self->{jids}[1] }),
        "Look up job_id '$self->{jids}[1]'" );
    is( scalar keys %$ress, 3, "Check for 3 resources" );

    # Try not_job_id.
    ok( $ress = Bric::Dist::Resource->href({ not_job_id => $self->{jids}[0] }),
        "Look up not_job_id '$self->{jids}[0]'" );
    is( scalar keys %$ress, 1, "Check for 1 resources" );
    ok( $ress = Bric::Dist::Resource->href({ not_job_id => $self->{jids}[1] }),
        "Look up not_job_id '$self->{jids}[1]'" );
    is( scalar keys %$ress, 3, "Check for 2 resources" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test the list() method.
sub test_list_ids : Test(42) {
    my $self = shift;
    # Try uri.
    ok( my @res_ids = Bric::Dist::Resource->list_ids
        ({ uri => "/$self->{basename}\_1.txt" }),
        "Look up uri '/$self->{basename}\_1.txt'" );
    is( scalar @res_ids, 1, "Check for 1 resource IDs" );

    # Try uri + wild card.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ uri => "/$self->{basename}%" }),
        "Look up uri '/$self->{basename}%'" );
    is( scalar @res_ids, 5, "Check for 5 resource IDs" );

    # Try path.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ path => $self->{paths}[0] }),
        "Look up path '$self->{paths}[0]'" );
    is( scalar @res_ids, 1, "Check for 1 resource IDs" );

    # Try path + wild card.
    (my $trunc_file = $self->{paths}[0]) =~ s/_\d\.[^\.]*$//;
    ok( @res_ids = Bric::Dist::Resource->list_ids({ path => "$trunc_file%" }),
        "Look up path '$trunc_file%'" );
    is( scalar @res_ids, 5, "Check for 5 resource IDs" );

    # Try media_type.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ media_type => 'text/plain' }),
        "Look up media_type 'text/plain'" );
    is( scalar @res_ids, 3, "Check for 3 resource IDs" );
    ok( @res_ids = Bric::Dist::Resource->list_ids({ media_type => 'text/html' }),
        "Look up media_type 'text/html'" );
    is( scalar @res_ids, 2, "Check for 2 resource IDs" );

    # Try media_type + wild card.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ media_type => 'text/%' }),
        "Look up media_type 'text/%'" );
    is( scalar @res_ids, 5, "Check for 5 resource IDs" );

    # Try mod_time.
    my $mod_epoch = (stat $self->{paths}[0])[9];
    my $mod = strfdate($mod_epoch);
    ok( @res_ids = Bric::Dist::Resource->list_ids({ mod_time => $mod }),
        "Look up mod_time '$mod'" );
    ok( scalar @res_ids >= 1, "Check for 1 or more resource IDs" );

    # Try a range of mod_times.
    my $early = strfdate($mod_epoch - 60 * 60);
    my $late = strfdate($mod_epoch + 5);
    ok( @res_ids = Bric::Dist::Resource->list_ids({ mod_time => [$early, $late] }),
        "Look up mod_time between '$early' and '$late'" );
    # Includes the directory of course!
    is( scalar @res_ids, 6, "Check for 6 resource IDs" );

    # Try size.
    my $size = length $contents;
    ok( @res_ids = Bric::Dist::Resource->list_ids({ size => $size }),
        "Look up size '$size'" );
    is( scalar @res_ids, 3, "Check for 3 resource IDs" );
    $size++;
    ok( @res_ids = Bric::Dist::Resource->list_ids({ size => $size }),
        "Look up size '$size'" );
    is( scalar @res_ids, 2, "Check for 2 resource IDs" );

    # Try a range of sizes.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ size => [$size - 1, $size] }),
        "Look up size between " . ($size - 1) . "and '$size'" );
    is( scalar @res_ids, 5, "Check for 5 resource IDs" );

    # Try is_dir.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ is_dir => 0 }),
        "Look up is_dir false" );
    is( scalar @res_ids, 5, "Check for 5 resource IDs" );
    ok( @res_ids = Bric::Dist::Resource->list_ids({ is_dir => 1 }),
        "Look up is_dir true" );
    is( scalar @res_ids, 1, "Check for 1 resource" );

    # Try story_id.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ story_id => $self->{sid} }),
        "Look up story_id '$self->{sid}'" );
    is( scalar @res_ids, 3, "Check for 3 resource IDs" );

    # Try media_id.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ media_id => $self->{mid} }),
        "Look up media_id '$self->{mid}'" );
    is( scalar @res_ids, 2, "Check for 2 resource IDs" );

    # Try dir_id.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ dir_id => $self->{did} }),
        "Look up dir_id '$self->{did}'" );
    is( scalar @res_ids, 3, "Check for 3 resource IDs" );

    # Try job_id.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ job_id => $self->{jids}[0] }),
        "Look up job_id '$self->{jids}[0]'" );
    is( scalar @res_ids, 5, "Check for 5 resource IDs" );
    ok( @res_ids = Bric::Dist::Resource->list_ids({ job_id => $self->{jids}[1] }),
        "Look up job_id '$self->{jids}[1]'" );
    is( scalar @res_ids, 3, "Check for 3 resource IDs" );

    # Try not_job_id.
    ok( @res_ids = Bric::Dist::Resource->list_ids({ not_job_id => $self->{jids}[0] }),
        "Look up not_job_id '$self->{jids}[0]'" );
    is( scalar @res_ids, 1, "Check for 1 resource IDs" );
    ok( @res_ids = Bric::Dist::Resource->list_ids({ not_job_id => $self->{jids}[1] }),
        "Look up not_job_id '$self->{jids}[1]'" );
    is( scalar @res_ids, 3, "Check for 2 resource IDs" );
}

##############################################################################
# Test getting resource contents.
##############################################################################
sub test_content : Test(4) {
    my $file = catfile cwd, 'Makefile.PL';
    return "$file does not exist" unless -f $file;
    ok( my $res = Bric::Dist::Resource->new({ path => $file }),
        "Create resource" );
    isa_ok($res, 'Bric::Dist::Resource');
    isa_ok($res, 'Bric');

    # Read in the contents of the file.
    open F, $file or die "Cannot open '$file': $!\n";
    my $contents = join '', <F>;
    close F;

    # Compare 'em.
    is($res->get_contents, $contents, "Check the contents");
}


1;
__END__
