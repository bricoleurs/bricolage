#!/usr/bin/perl -w

use Bric::BC::Asset::Business::Story;
use Bric::BC::AssetType;

my $story;

eval {
my $at = Bric::BC::AssetType->lookup( { id => 1 });

my $s = Bric::BC::Asset::Business::Story->new({'element'   => $at,
					     'user__id'     => 11,
					     'source__id'   => 3});

generate_part_list($at,$s);

$s->checkin();

$s->save();

print $s->get_id() . "\n";

my $id = $s->get_id;

$story = Bric::BC::Asset::Business::Story->lookup( { id => $id });

my $title = $story->get_data('title',0);

my $url = $story->get_data('url',0);

print "These were returned by name and object index\n";
print "$title  $url \n";

print "here is everythingin order \n";
parse_container($story->get_tile, 0);

$story->checkout({user__id => 11});

$story->save();
};

die $@ if $@;

print "Checked out story is " . $story->get_id() . "\n";

sub parse_container {
	my $container = shift;
	my $index = shift;

	my $tabs = "\t" x $index;
	print "Container " . $container->get_name . "\n";

	my @tiles = $container->get_tiles();

	foreach my $tile (@tiles) {
		if ($tile->is_container) {
			parse_container($tile, $index++);
		} else {
			print $tabs . $tile->get_data() . "\n";
		}
	}
}

sub generate_part_list {
    my ($atc,$container) = @_;

    my $parts = $atc->get_data();
    my $sub_containers = $atc->get_containers();

    my $i = 0;

    my $add = {};
    foreach (@$parts) {
	$add->{$i}->{'id'} = $_->get_id();
	$add->{$i}->{'name'} = $_->get_name();
	$add->{$i}->{'obj'} = $_;
	$add->{$i}->{'data'} = 1;
	$i++;
    }

    foreach (@$sub_containers) {
	$add->{$i}->{'id'} = $_->get_id();
	$add->{$i}->{'name'} = $_->get_name();
	$add->{$i}->{'obj'} = $_;
	$add->{$i}->{'data'} = 0;
	$i++;
    }

    $add->{$i}->{'name'} = 'finish';
    $add->{$i}->{'end'} = 1;

    my $end = 0;
    while ($end != 1) {
	print "Choose From this list\n";
	
	foreach (sort { $a <=> $b} keys %$add) {
	    if (exists $add->{$_}->{'data'}) {
		print $add->{$_}->{'data'} ? 'D:  ' : 'C:  ';
	    } else {
		print '    ';
	    }

	    my $id   = $add->{$_}->{'id'} || '';
	    my $name = $add->{$_}->{'name'};

	    print "$_\t$id\t$name\n";
	}
	
	print "Enter your Choice\n";
	my $ii = <STDIN>;
	chomp $ii;
	
	my $string;
	unless (exists $add->{$ii}->{'end'}) {
	    print "Enter a value\n";
	    $string = <STDIN>;
	    chomp $string;
	}
	
	unless (exists $add->{$ii}->{'end'}) {
	    if ($add->{$ii}->{'data'}) {
		my $atd = $add->{$ii}->{'obj'};
		$container->add_data($atd, $string);
		
	    } else {
		my $nc = $container->add_container($add->{$ii}->{'obj'});
		# add the container bit here
		generate_part_list( $add->{$ii}->{'obj'}, $nc);
	    }
	} else {	
	    $end = 1;
	}
    }
}
