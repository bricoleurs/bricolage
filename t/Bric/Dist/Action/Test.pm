package Bric::Dist::Action::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Dist::Action;
use Bric::Dist::Action::Mover;
use Bric::Dist::Action::Email;
use Bric::Dist::Action::DTDValidate;

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(11) {
    my $self = shift;
    my $args = { ord            => 1,
                 server_type_id => 20,
                 type           => 'Move',
                 description    => 'Test action',
               };

    ok ( my $act = Bric::Dist::Action->new($args), "Test construtor" );
    isa_ok($act, 'Bric::Dist::Action');
    isa_ok($act, 'Bric');
    ok( ! defined $act->get_id, 'Undefined ID' );
    is( $act->get_server_type_id, $args->{server_type_id},
        "Server type ID is '$args->{server_type_id}'");
    is( $act->get_type, $args->{type}, "Action type is '$args->{type}'");
    is( $act->get_name, $args->{type}, "Name is '$args->{type}'");
    is( $act->get_ord, $args->{ord}, "Order is '$args->{ord}'");
    is( $act->get_description, $args->{description},
        "Description is '$args->{description}'" );
    ok( ! $act->has_more, "It has no more" );
    ok( $act->is_active, "Check that it's activated" );
}

1;
__END__
