package Bric::Biz::Keyword::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub test_load : Test(1) {
    use_ok('Bric::Biz::Keyword');
}


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
