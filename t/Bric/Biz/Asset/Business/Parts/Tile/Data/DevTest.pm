package Bric::Biz::Asset::Business::Parts::Tile::Data::DevTest;
################################################################################

use strict;
use warnings;

use base qw(Bric::Biz::Asset::Business::Parts::Tile::DevTest);
use Test::More;

use Bric::Biz::Asset::Business::Parts::Tile::Container;
use Bric::Biz::Asset::Business::Parts::Tile::Data;

##############################################################################
# Utility methods
##############################################################################
# The class we're testing. Override this method in subclasses.
sub class { 'Bric::Biz::Asset::Business::Parts::Tile::Data' }

my $cont_pkg = 'Bric::Biz::Asset::Business::Parts::Tile::Container';

################################################################################

my $cont;
sub get_container {
    my $self = shift;

    unless ($cont) {
        my $story = $self->get_story;
        $cont = $cont_pkg->new({object       => $story,
                                element_type => $self->get_elem});
        $cont->save;
    }

    return $cont;
}

##############################################################################
# Arguments to the new() constructor. Used by construct(). Override as
# necessary in subclasses.
sub new_args {
    my $self = shift;
    my $story = $self->get_story;
    my $cont  = $story->get_tile; #$self->get_container;
    my $atd   = ($cont->get_element_type->get_data)[0];

    (active             => 1,
     object_type        => 'story',
     object_instance_id => $story->get_version_id,
     parent_id          => $cont->get_id,
     element_data       => $atd,
     object_order       => 0)
}

##############################################################################
# Constructs a new object.
sub construct {
    my $self = shift;
    $self->class->new({$self->new_args, @_});
}
################################################################################
# Test the constructors

sub test_new : Test(9) {
    my $self = shift;

    ok (my $dtile = $self->construct, 'Construct Data Tile');
    ok ($dtile->set_data('Macaroon'), 'Add Data to Data Tile');
    ok ($dtile->save,                 'Save Data Tile');
    ok (my $d_id = $dtile->get_id,    'Get Data Tile ID');

    $self->add_del_ids([$d_id], $dtile->S_TABLE);

    ok (my $lkup = $self->class->lookup({id          => $d_id,
                                         object_type => 'story'}),
        'Lookup Data Tile');
    is ($lkup->get_data, 'Macaroon',                    'Compare Data');

    ok (my $atd = $dtile->get_element_data_obj, 'Get Element Data Object');

    ok (my $list = $self->class->list({object_type => 'story'}),
       'List Data Tiles');
    ok (grep($_->get_id == $dtile->get_id, @$list), 'Data Tile is Listed');
}

1;

__END__
