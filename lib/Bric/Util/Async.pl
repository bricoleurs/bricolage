#!/usr/bin/perl

use strict;

use Bric::Util::Async;

use Bric::Util::Async::Parts::Event;

my $name = shift @ARGV;
my $f_name = shift @ARGV;

eval {

my $as = Bric::Util::Async->new( {
					name => $name,
					description => 'A test of mine',
					file_name => $f_name,
					active => 1 });

my @ases;

for (1024 .. 1034) {
	my $event = Bric::Util::Async::Parts::Event->new({
								name => 'A test',
                                description => 'A test',
                                minutes => 1,
                                hours => '',
                                days => '',
                                month => '',
                                days_of_week => '',
                                obj_id => $_,
                                obj_type => 'Bric::Biz::Asset::Business::Story',
                                active => 1 });
	$event->save();

	push @ases, $event;
}

$as->add_events(\@ases);

$as->save();

print $as->get_id() . "\n";

};

if ($@) {
	die $@->get_msg()
}

