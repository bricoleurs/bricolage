package Bric::Biz::Workflow::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Workflow');
}

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(5) {
    my $self = shift;
    my $args = { name => 'Bogus',
                 description => 'Bogus Workflow' };

    ok ( my $wf = Bric::Biz::Workflow->new($args), "Test construtor" );
    ok( ! defined $wf->get_id, 'Undefined ID' );
    is( $wf->get_name, $args->{name}, "Name is '$args->{name}'" );
    is( $wf->get_description, $args->{description},
        "Description is '$args->{description}'" );
    ok( $wf->is_active, "Check that it's activated" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(6) {
    ok( my $meths = Bric::Biz::Workflow->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::Workflow->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Disabled because this isn't an identifier anymore
    # Try the identifier methods.
#    ok( my $wf = Bric::Biz::Workflow->new({ name => 'NewFoo' }),
#        "Create workflow" );
#    ok( my @meths = $wf->my_meths(0, 1), "Get ident meths" );
#    is( scalar @meths, 1, "Check for 1 meth" );
#    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
#    is( $meths[0]->{get_meth}->($wf), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__
