package Bric::Util::Attribute::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Attribute');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl56 -w

use strict;

use Bric::Util::Attribute::Person;

# Set the schema to look at.
$Bric::Cust = 'sharky';

my $attr_obj = new Bric::Util::Attribute::Person({'subsys' => 'test',
                        'id'     => 1024});



 # Return specific settings about the attribute object
 my $short    = $attr_obj->short_object_type();
 my $id       = $attr_obj->get_object_id();

print "Object type: $short\n";
print "Object ID: $id\n";

 # Get and set the current subsys.
 my $subsys = $attr_obj->get_subsys();

print "Subsystem: $subsys\n";

 my $success  = $attr_obj->set_subsys('physical');
 $subsys   = $attr_obj->get_subsys();

print "Subsystem (updated): $subsys\n";

 # Return a list of subsystem names.
 my @names    = $attr_obj->subsys_names($subsys);

print "Subsysem names = ".join(', ', @names), "\n";

 # The ID of the object to which these attributes apply.
 $id       = $attr_obj->get_object_id();

print "Object ID = $id\n";

 # Get and set attributes for the target object.
 my $sqltype  = $attr_obj->get_sqltype({'name' => 'hair_color'});

print "SQL type: $sqltype\n";

 my $value = $attr_obj->get_attr({'name' => 'eye color'});

print "Attribute 'eye color' has value '$value'\n";


 $value = $attr_obj->get_attr_hash({'name' => ['age', 'weight', 'sex']});


 $value = $attr_obj->set_attr({'name' => 'eye color', 'value' => 'blue-grey'});

 $value = $attr_obj->get_attr({'name' => 'eye color'});

print "Attribute 'eye color' NOW has value '$value'\n";

 # Add a new metadata point.
 $attr_obj->add_meta({'name'  => 'age', 
              'field' => 'required', 
              'value' => 'yes'});

 $value = $attr_obj->get_meta({'name'  => 'age', 
                   'field' => 'required'});

print "Metadata value 'required' for attribute 'age' is '$value'\n";

 ##-- Other methods --##

 $success  = $attr_obj->save();

print "Success after save = '$success'\n";

#my $obj = $a->get_attr_obj({'new' => 1, 
#                'name' => 'cheese_puffs',
#                'sql_type' => 'short'});

#my $val;

#$val = $a->get_attr({'name' => 'hair_color'});

#print "Got val '$val'\n";

#$val = $a->get_attr({'name'    => 'weight',
#             'sql_type' => 'short'});

#$val = $a->get_meta({'name'  => 'weight',
#             'field' => 'description'});

#$a->add_meta({'name'  => 'weight',
#          'field' => 'description',
#          'value' => 'moo cow how?'});

#$a->add_meta({'name'  => 'weight',
#          'field' => 'blue moon',
#          'value' => 'I saw you standing alone'});

#$a->save();

#print "Got val '$val'\n";
