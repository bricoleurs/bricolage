package Bric::Biz::AssetType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(2) {
    use_ok('Bric::Biz::AssetType::Parts::Data');
    use_ok('Bric::Biz::AssetType');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl

use lib '/usr/local/bricolage/lib';

use strict;

use Bric::BC::AssetType;
use Bric::BC::AssetType::Parts::Data;

# Read or write information.
my $READ = 0;

my ($at, $in, @all, $one, @con);

if ($READ) {
    $at = Bric::BC::AssetType->lookup({'id' => 1});

    # my @ids = $at->get_grp_ids;

    @all = $at->get_data;
    $one = $at->get_data('image');

    @con = $at->get_containers;
} else {
    print "Creating new assettypes\n";

    print "Creating 'Book Review'\n";
    $at = Bric::BC::AssetType->new({ type__id => 1 });

    $at->set_name('Book Review 3');
    $at->add_output_channels([1]);
    $at->set_primary_oc_id(1);
    $at->set_description('A weekly column asset type');

    my $atd = $at->new_data({'name'        => 'paragraph',
		   'description' => 'A paragraph',
			'required'	=> 1,
			'quantifier'	=> 1,
			'sql_type' => 'short'
		  });
	$atd->set_attr('html_info', '');
	$atd->set_meta('html_info', 'type', 'textarea');
	$atd->set_meta('html_info', 'cols', 30);
	$atd->set_meta('html_info', 'rows', 6);

    $atd = $at->new_data({'name'         => 'author',
		   'description'  => 'The person who wrote this story.',
			'sql_type'	=> 'short'
		  });
	$atd->set_attr('html_info', '');
	$atd->set_meta('html_info', 'type', 'text');
	$atd->set_meta('html_info', 'length', 30);
	$atd->set_meta('html_info', 'maxlength', 80);

    $atd = $at->new_data({'name'        => 'url',
		   'description' => 'An HTML link',
			'sql_type'	=> 'short'
		  });
	$atd->set_attr('html_info', '');
	$atd->set_meta('html_info', 'type', 'text');
	$atd->set_meta('html_info', 'length', 30);
	$atd->set_meta('html_info', 'maxlength', 50);

    $atd = $at->new_data({'name'        => 'quote',
		   'description' => 'A quotation',
			'sql_type' => 'short'
		  });
	$atd->set_attr('html_info', '');
	$atd->set_meta('html_info', 'type', 'text');
	$atd->set_meta('html_info', 'length', 30);
	$atd->set_meta('html_info', 'maxlength', 150);
    
    print "Creating 'Book Profile'\n";
    $in = Bric::BC::AssetType->new( { type__id => 2 });
    
    $in->set_name('Book Profile 3');
    
    $in->set_description('A book Profile');
    
    $atd = $in->new_data({'name'        => 'Author',
		   'description' => 'A link to something else',
			'quantifer'	=> 1,
			'sql_type' => 'short'
		  }); 
	$atd->set_attr('html_info', '');
	$atd->set_meta('html_info', 'type', 'text');
	$atd->set_meta('html_info', 'length', 30);
	$atd->set_meta('html_info', 'maxlength', 150);
    
    $atd = $in->new_data({'name'        => 'title',
		   'description' => 'An image',
			'required'	=> 1,
			'sql_type' => 'short'
		  });
	$atd->set_attr('html_info', '');
	$atd->set_meta('html_info', 'type', 'text');
	$atd->set_meta('html_info', 'length', 30);
	$atd->set_meta('html_info', 'maxlength', 150);
 

	$atd = $in->new_data({ 'name'        => 'fav_food',
			       'description' => 'The Authors Favorite Foods',
			       'quantifier'  => 1,
			       'sql_type'    => 'short'
			});
	$atd->set_attr('html_info', '');
	$atd->set_meta('html_info', 'type', 'text');
	$atd->set_meta('html_info', 'length', 30);
	$atd->set_meta('html_info', 'maxlength', 150);


    print "Saving 'Book Profile'\n";
    $in->save;
    
    print "Adding 'Book Profile' to 'Book Review'\n";
    $at->add_containers([$in]);
    
    print "Saving 'Book Review'\n";
    $at->save();
}    

print "Done\n";
