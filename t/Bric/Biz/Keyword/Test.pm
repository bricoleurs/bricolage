package Bric::Biz::Keyword::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Keyword');
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::Keyword->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::Keyword->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $kw = Bric::Biz::Keyword->new({ name => 'NewFoo' }),
        "Create Keyword" );
    ok( my @meths = $kw->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($kw), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use strict;

use Carp::Heavy; # I'd love to know why I have to do this...
use Test::More 'no_plan';
use Bric::Biz::Keyword;
use Bric::Biz::Asset::Business::Story;

# create a new keyword for testing
srand(time);
my $name = 'test keyword ' . rand();
my $key = Bric::Biz::Keyword->new({ name => $name});
isa_ok($key, "Bric::Biz::Keyword");
is($key->get_name, $name, 'name test');
$key->save();
ok($key->get_id, "id test");

# find a new story for testing
my ($story) = Bric::Biz::Asset::Business::Story->list({Limit => 1});

# add keyword to story
ok($key->associate($story), 'associate story');

# test has_keyword
ok($story->has_keyword($key), 'has_keyword');

# dissociate keyword from story
ok($key->dissociate($story), 'dissociate story');

# add keyword to story using add_keywords
ok($story->add_keywords([$key]), 'add_keywords');

# test has_keyword
ok($story->has_keyword($key), 'has_keyword');

# do a search based on keyword
my @stories = Bric::Biz::Asset::Business::Story->list({ keyword => $name });
ok(@stories == 1, 'story search');
ok((grep { $_->get_id == $story->get_id } @stories), 'story search');

# test simple search
@stories = Bric::Biz::Asset::Business::Story->list({ simple => $name });
ok(@stories == 1, 'simple search');
ok((grep { $_->get_id == $story->get_id } @stories), 'simple search');

# add keyword to story using delete_keywords
ok($story->delete_keywords([$key]), 'delete_keywords');

# all done - invalidate this keyword
$key->remove();
$key->save();
