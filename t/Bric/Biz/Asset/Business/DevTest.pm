package Bric::Biz::Asset::Business::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::DevTest);
use Test::More;
use Bric::Biz::Asset::Business;
use Bric::Biz::AssetType;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Overrid this method in subclasses.
sub class { 'Bric::Biz::Asset::Business' }

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    ( element       => $self->get_elem,
      user__id      => $self->user_id,
      source__id    => 1,
      primary_oc_id => 1,
    )
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({ $self->new_args, @_ });
}


1;
__END__
