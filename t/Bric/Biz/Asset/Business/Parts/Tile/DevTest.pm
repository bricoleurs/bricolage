package Bric::Biz::Asset::Business::Parts::Tile::DevTest;
################################################################################

use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::DevTest);

use Test::More;

use Bric::Biz::Asset::Business::Story;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Business::Parts::Tile' }

################################################################################
# A sample story to use

my $story;
sub get_story {
   my $self = shift;
   my $story_pkg = 'Bric::Biz::Asset::Business::Story';

   unless ($story) {
       $story = $story_pkg->new({name          => 'Fruits',
                                 slug          => 'Cranberry',
                                 element       => $self->get_elem,
                                 user__id      => $self->user_id,
                                 source__id    => 1,
                                 primary_oc_id => 1});
       $story->save;

       $self->add_del_ids([$story->get_id], $story->key_name);
   }

   return $story;
}

sub del_ids : Test(teardown => 0) {
    my $self = shift;
    # Do the main objects, first.
    $self->Bric::Test::DevBase::del_ids(@_);
}

1;

__END__
