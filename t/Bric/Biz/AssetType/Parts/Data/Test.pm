package Bric::Biz::AssetType::Parts::Data::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::AssetType::Parts::Data');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl

use strict;

use Bric::BC::AssetType::Parts::Data;

$Bric::Cust = 'mike';

my $data = Bric::BC::AssetType::Parts::Data->new();
$data->set_element_id(1026);
$data->set_name('ike2');
$data->set_place(0);
$data->set_description('A test');
$data->set_container_id(1024);
$data->set_publishable(1);
$data->set_max_length(35);
$data->set_repeatable(undef);
$data->set_required(1);
$data->set_sql_type(1);
$data->save();
my $id = $data->get_id();
print "Record of $id Created\n";

my $meta = Bric::BC::AssetType::Parts::Meta->lookup({ id=> 1035 });

my $data3 = Bric::BC::AssetType::Parts::Data->new( { meta_object => $meta});
$data3->set_element_id(1026);
$data3->set_container_id(1024);
$data3->set_place(0);
$data3->save();
print $data3->get_name() . "\n";




my $data2 = Bric::BC::AssetType::Parts::Data->lookup({ id => $id } );

print $data2->get_name() . "\n";;

my $datas = Bric::BC::AssetType::Parts::Data->list({ active => 1 } );

foreach ( @{ $datas } ) {
	print "NAME: " . $_->get_name() . "\n";
}
