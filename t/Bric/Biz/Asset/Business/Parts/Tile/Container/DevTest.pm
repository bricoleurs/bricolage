package Bric::Biz::Asset::Business::Parts::Tile::Container::DevTest;
################################################################################

use strict;
use warnings;

use base qw(Bric::Biz::Asset::Business::Parts::Tile::DevTest);

use Test::More;

use Bric::Biz::Asset::Business::Parts::Tile::Container;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Business::Parts::Tile::Container' }

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;

    (object  => $self->get_story,
     element => $self->get_elem,
    )
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;

    $self->class->new({$self->new_args, @_});
}
################################################################################
# Test the constructors

sub test_new : Test(10) {
    my $self = shift;

    ok (my $cont = $self->construct,    'Construct Container');
    ok (my $at  = $cont->get_element,   'Get Element Object');
    ok (my $atd = ($at->get_data)[0],   'Get Data Element Object');
    ok ($cont->add_data($atd, 'Chomp'), 'Add Data');
    ok ($cont->save,                    'Save Container');
    ok (my $c_id = $cont->get_id,       'Get Container ID');

    $self->add_del_ids([$c_id], $cont->S_TABLE);

    ok (my $lkup = $self->class->lookup({object_type => 'story',
                                         id          => $c_id}),
        'Lookup Container');

    is ($lkup->get_data('deck', 2), 'Chomp',   'Compare Data');

    ok (my $list = $self->class->list({object_type => 'story'}),
        'List Story Containers');
    ok (grep($_->get_id == $cont->get_id, @$list), 'Container is listed');
}

1;

__END__
