package Bric::Biz::Asset::Business::Parts::Tile::DevTest;
################################################################################

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Asset::Business::Story;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Business::Parts::Tile' }

################################################################################
# A sample story to use

sub get_story {
   my $self = shift;
   my $story_pkg = 'Bric::Biz::Asset::Business::Story';

   my $story = $story_pkg->new({ name          => 'Fruits',
                                 slug          => 'Cranberry',
                                 element       => $self->get_elem,
                                 user__id      => $self->user_id,
                                 source__id    => 1,
                                 site_id       => 100,
                               });
   $story->add_categories([1]);
   $story->set_primary_category(1);
   $story->save;
   $self->add_del_ids([$story->get_id], $story->key_name);
   return $story;
}

##############################################################################
# The element object we'll use throughout. Override in subclass if necessary.
my $elem;
sub get_elem {
    $elem ||= Bric::Biz::AssetType->lookup({ id => 1 });
    $elem;
}

1;

__END__
