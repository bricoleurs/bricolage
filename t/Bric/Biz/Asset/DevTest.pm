package Bric::Biz::Asset::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Biz::Asset;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

sub class { 'Bric::Biz::Asset' }

1;
__END__
