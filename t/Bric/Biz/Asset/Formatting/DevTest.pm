package Bric::Biz::Asset::Formatting::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::DevTest);
use Test::More;
use Bric::Biz::Asset::Formatting;
use Bric::Biz::AssetType;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }


##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Formatting' }

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    ( output_channel__id => 1,
      user__id   => 1,
    )
}
