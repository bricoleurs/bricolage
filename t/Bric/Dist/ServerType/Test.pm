package Bric::Dist::ServerType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Dist::ServerType');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Dist::ServerType;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
	# Do verbose testing here.
	print "Fetching ServerType #2\n";
	my $st = Bric::Dist::ServerType->lookup({ id => 2 });
	print "ID:      ", $st->get_id || '', "\n";
	print "Name:    ", $st->get_name || '', "\n";
	print "Desc:    ", $st->get_description || '', "\n";
	print "Mover:   ", $st->get_move_method || '', "\n";
	print "Copy:    ", $st->can_copy ? 'Yes' : 'No', "\n";
	print "Publish: ", $st->can_publish ? 'Yes' : 'No', "\n";
	print "Preview: ", $st->can_preview ? 'Yes' : 'No', "\n";
	print "Copy:    ", $st->can_copy ? 'Yes' : 'No', "\n";
	print "Active:  ", $st->is_active ? 'Yes' : 'No', "\n\n";

	print "Getting a list of its associated outpust channels.\n";
	print $_->get_name, "\n" for $st->get_output_channels;
	print "\n";

	print "Adding a new output channel.\n";
	$st->add_output_channels(Bric::Biz::OutputChannel->lookup({id => 4}));
	$st->save;
	$st = Bric::Dist::ServerType->lookup({ id => 2 });
	print $_->get_name, "\n" for $st->get_output_channels;
	print "\n";

	print "Okay, now removing it again.\n";
	$st->del_output_channels(4);
	$st->save;
	$st = Bric::Dist::ServerType->lookup({ id => 2 });
	print $_->get_name, "\n" for $st->get_output_channels;
	print "\n";

	print "Getting a list of its servers.\n";
	print $_->get_host_name, "\n" for $st->get_servers;
	print "\n";

	print "Adding a new server.\n";
	my $s = $st->new_server({ host_name => 'www.foo.com',
				  os => 'Win32',
				  doc_root => '/usr/src' });
	$st->save;
	$st = Bric::Dist::ServerType->lookup({ id => 2 });
	print $_->get_host_name, "\n" for $st->get_servers;
	print "\n";

	print "Now deleting that new server.\n";
	$st->del_servers($s->get_id);
	$st->save;
	$st = Bric::Dist::ServerType->lookup({ id => 2 });
	print $_->get_host_name, "\n" for $st->get_servers;
	print "\n";

	print "Getting a list of its actions.\n";
	print $_->get_type, "\n" for $st->get_actions;
	print "\n";

	print "Getting a list of server types.\n";
	foreach my $st (Bric::Dist::ServerType->list({move_method => 'F%' })) {
	    print "ID:      ", $st->get_id || '', "\n";
	    print "Name:    ", $st->get_name || '', "\n";
	    print "Desc:    ", $st->get_description || '', "\n";
	    print "Mover:   ", $st->get_move_method || '', "\n";
	    print "Copy:    ", $st->can_copy ? 'Yes' : 'No', "\n";
	    print "Publish: ", $st->can_publish ? 'Yes' : 'No', "\n";
	    print "Preview: ", $st->can_preview ? 'Yes' : 'No', "\n";
	    print "Active:  ", $st->is_active ? 'Yes' : 'No', "\n\n";
	}

	print "Getting an href of server types for Job ID #2.\n";
	my $href = Bric::Dist::ServerType->href({ job_id => 2 });
	while (my ($id, $st) = each %$href) {
	    print "ID:      ", $st->get_id || '', "\n";
	    print "Name:    ", $st->get_name || '', "\n";
	    print "Desc:    ", $st->get_description || '', "\n";
	    print "Mover:   ", $st->get_move_method || '', "\n";
	    print "Copy:    ", $st->can_copy ? 'Yes' : 'No', "\n";
	    print "Publish: ", $st->can_publish ? 'Yes' : 'No', "\n";
	    print "Preview: ", $st->can_preview ? 'Yes' : 'No', "\n";
	    print "Active:  ", $st->is_active ? 'Yes' : 'No', "\n\n";
	}

	print "Getting a list of publishable server types.\n";
	foreach my $st (Bric::Dist::ServerType->list({ can_publish => 1 })) {
	    print "ID:      ", $st->get_id || '', "\n";
	    print "Name:    ", $st->get_name || '', "\n";
	    print "Desc:    ", $st->get_description || '', "\n";
	    print "Mover:   ", $st->get_move_method || '', "\n";
	    print "Copy:    ", $st->can_copy ? 'Yes' : 'No', "\n";
	    print "Publish: ", $st->can_publish ? 'Yes' : 'No', "\n";
	    print "Preview: ", $st->can_preview ? 'Yes' : 'No', "\n";
	    print "Active:  ", $st->is_active ? 'Yes' : 'No', "\n\n";
	}

	print "Getting a list of server type ids.\n";
	print "IDS: @{ Bric::Dist::ServerType->list_ids({ name => 'P%' }) }\n";

	print "Getting a list of Mover classes.\n";
	{
	    local $" = "\n";
	    print "@{ Bric::Dist::ServerType->list_move_methods }\n\n";
	}

	print "Creating a new ServerType.\n";
	$st = Bric::Dist::ServerType->new;
	$st->set_name('Bogus Servers');
	$st->set_description('These servers really suck. Obvioiusly they run NT.');
	$st->set_move_method('File System');
	$st->save;
	print "ID:      ", $st->get_id || '', "\n";
	print "Name:    ", $st->get_name || '', "\n";
	print "Desc:    ", $st->get_description || '', "\n";
	print "Mover:   ", $st->get_move_method || '', "\n";
	print "Copy:    ", $st->can_copy ? 'Yes' : 'No', "\n";
	print "Publish: ", $st->can_publish ? 'Yes' : 'No', "\n";
	print "Preview: ", $st->can_preview ? 'Yes' : 'No', "\n";
	print "Active:  ", $st->is_active ? 'Yes' : 'No', "\n\n";

	print "Now changing its values and reloading it.\n";
	$st->set_name('Bogus NT Servers');
	$st->set_description('These servers really suck.');
	$st->set_move_method('FTP');
	$st->no_publish;
	$st->on_preview;
	$st->deactivate;
	$st->save;
	$st = Bric::Dist::ServerType->lookup({ id => $st->get_id });
	print "ID:      ", $st->get_id || '', "\n";
	print "Name:    ", $st->get_name || '', "\n";
	print "Desc:    ", $st->get_description || '', "\n";
	print "Mover:   ", $st->get_move_method || '', "\n";
	print "Copy:    ", $st->can_copy ? 'Yes' : 'No', "\n";
	print "Publish: ", $st->can_publish ? 'Yes' : 'No', "\n";
	print "Preview: ", $st->can_preview ? 'Yes' : 'No', "\n";
	print "Active:  ", $st->is_active ? 'Yes' : 'No', "\n\n";

	print "Cleaning up bogus records.\n";
        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM server_type
            WHERE  id > 1023
        })->execute;
	print "Done!\n";
	exit;
    }

    # Do Test::Harness testing here.


    exit;
    Bric::Util::DBI::prepare_c(qq{
        DELETE FROM server_type
        WHERE  id > 1023
    })->execute;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}

