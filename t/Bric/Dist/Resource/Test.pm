package Bric::Dist::Resource::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

sub _test_load : Test(1) {
    use_ok('Bric::Dist::Resource');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Dist::Resource;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
    # Do verbose testing here.
    my $res;
    print "Fetching Resource #1\n";
    $res = Bric::Dist::Resource->lookup({ id => 1 });
    print "ID:       ", $res->get_id || '', "\n";
    print "Path:     ", $res->get_path || '', "\n";
    print "URL:      ", $res->get_url || '', "\n";
    print "Size:     ", $res->get_size || '0', "\n";
    print "ModTime:  ", $res->get_mod_time || '', "\n";
    print "MEDIAType: ", $res->get_media_type || '', "\n";
    print "Is Dir?:  ", $res->is_dir ? 'Yes' : 'No', "\n\n";

    print "Getting its asset associations.\n";
    print "Story IDS: @{ $res->get_story_ids }\n";
    print "Media IDS: @{ $res->get_media_ids }\n\n";

    print "Adding story IDs.\n";
    $res->add_story_ids(12, 89, 345);
    print "Story IDS: @{ $res->get_story_ids }\n\n";

    print "Deleting story IDs.\n";
    $res->del_story_ids(12, 89, 345);
    print "Story IDS: @{ $res->get_story_ids }\n\n";

    print "Getting associated File IDs.\n";
    print "File IDS: @{ $res->get_file_ids }\n\n";

    print "Fetching Path /data/content/tech/feature/index.html\n";
    $res = Bric::Dist::Resource->lookup({ path => '/data/content/tech/feature/index.html' });
    print "ID:       ", $res->get_id || '', "\n";
    print "Path:     ", $res->get_path || '', "\n";
    print "URL:      ", $res->get_url || '', "\n";
    print "Size:     ", $res->get_size || '0', "\n";
    print "ModTime:  ", $res->get_mod_time || '', "\n";
    print "MEDIAType: ", $res->get_media_type || '', "\n";
    print "Is Dir?:  ", $res->is_dir ? 'Yes' : 'No', "\n\n";

    print "Fetching Resources with sizes between 0 and 500.\n";
    foreach my $res (Bric::Dist::Resource->list({ size => [0, 500]})) {
        print "ID:       ", $res->get_id || '', "\n";
        print "Path:     ", $res->get_path || '', "\n";
        print "URL:      ", $res->get_url || '', "\n";
        print "Size:     ", $res->get_size || '0', "\n";
        print "ModTime:  ", $res->get_mod_time || '', "\n";
        print "MEDIAType: ", $res->get_media_type || '', "\n";
        print "Is Dir?:  ", $res->is_dir ? 'Yes' : 'No', "\n\n";
    }

    print "Fetching resources associated with Job #1.\n";
    my $href = Bric::Dist::Resource->href({ job_id => 1 });
    while (my ($id, $res) = each %$href) {
        print "ID:       ", $id || '', "\n";
        print "Path:     ", $res->get_path || '', "\n";
        print "URL:      ", $res->get_url || '', "\n";
        print "Size:     ", $res->get_size || '0', "\n";
        print "ModTime:  ", $res->get_mod_time || '', "\n";
        print "MEDIAType: ", $res->get_media_type || '', "\n";
        print "Is Dir?:  ", $res->is_dir ? 'Yes' : 'No', "\n\n";
    }

    print "Creating a new directory resource.\n";
    $res = Bric::Dist::Resource->new({ path => '/usr/bin', url => '/bin' });
    print "ID:       ", $res->get_id || '', "\n";
    print "Path:     ", $res->get_path || '', "\n";
    print "URL:      ", $res->get_url || '', "\n";
    print "Size:     ", $res->get_size || '0', "\n";
    print "ModTime:  ", $res->get_mod_time || '', "\n";
    print "MEDIAType: ", $res->get_media_type || '', "\n";
    print "Is Dir?:  ", $res->is_dir ? 'Yes' : 'No', "\n\n";


    print "Creating a new file resource.\n";
    $res = Bric::Dist::Resource->new({ path => '/usr/share/sounds/error.wav',
                         url => 'sounds/error.wav' });
    print "ID:       ", $res->get_id || '', "\n";
    print "Path:     ", $res->get_path || '', "\n";
    print "URL:      ", $res->get_url || '', "\n";
    print "Size:     ", $res->get_size || '0', "\n";
    print "ModTime:  ", $res->get_mod_time || '', "\n";
    print "MEDIAType: ", $res->get_media_type || '', "\n";
    print "Is Dir?:  ", $res->is_dir ? 'Yes' : 'No', "\n\n";

    print "Testing set_path() and saving the resource.\n";
    $res->set_path('/usr/share/gimp/1.2/scripts');
    $res->save;
    print "ID:       ", $res->get_id || '', "\n";
    print "Path:     ", $res->get_path || '', "\n";
    print "Size:     ", $res->get_size || '0', "\n";
    print "ModTime:  ", $res->get_mod_time || '', "\n";
    print "MEDIAType: ", $res->get_media_type || '', "\n";
    print "Is Dir?:  ", $res->is_dir ? 'Yes' : 'No', "\n\n";

    print "Creating another resource and associating it with the last one.\n";
    my $res2 = Bric::Dist::Resource->new({ path => '/usr/share/gimp/1.2/scripts/beavis.jpg',
                         url => '/gimp/1.2/scripts/beavis.jpg' });
    $res2->save;
    $res->add_file_ids($res2->get_id);
    $res->save;
    $res = $res->lookup({ id => $res->get_id });
    print "File IDS: @{ $res->get_file_ids }\n\n";

    print "Okay, now deleting that resource association.\n";
    $res->del_file_ids($res2->get_id);
    $res->save;
    $res = $res->lookup({ id => $res->get_id });
    print "File IDS: @{ $res->get_file_ids }\n\n";

    print "Associating story and media IDs now.\n";
    $res->add_story_ids(1,2,3);
    $res->add_media_ids(21,22,23);
    $res->save;
    $res = $res->lookup({ id => $res->get_id });
    print "Story IDS: @{ $res->get_story_ids }\n";
    print "Media IDS: @{ $res->get_media_ids }\n\n";

    print "Now deleting them.\n";
    $res->del_story_ids(1,2,3);
    $res->del_media_ids(21,22,23);
    $res->save;
    $res = $res->lookup({ id => $res->get_id });
    print "Story IDS: @{ $res->get_story_ids }\n";
    print "Media IDS: @{ $res->get_media_ids }\n\n";

    print "Testing other set methods.\n";
    $res->set_size(2222);
    $res->set_url('/my/url/rulez');
    $res->set_mod_time('1999-12-19 21:42:34');
    $res->set_media_type('text/html');
    print "Path:     ", $res->get_path || '', "\n";
    print "URL:      ", $res->get_url || '', "\n";
    print "Size:     ", $res->get_size || '0', "\n";
    print "ModTime:  ", $res->get_mod_time || '', "\n";
    print "MEDIAType: ", $res->get_media_type || '', "\n";
    print "Is Dir?:  ", $res->is_dir ? 'Yes' : 'No', "\n\n";

    print "Cleaning up bogus records.\n";
        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM resource
            WHERE  id > 1023
        })->execute;
    print "Done!\n";
    exit;
    }

    # Do Test::Harness testing here.



    exit;
    Bric::Util::DBI::prepare_c(qq{
        DELETE FROM resource
        WHERE  id > 1023
    })->execute;

};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->error_info . "\n" . $err->get_payload
      . "\n" : "$err\n";
}

1;
