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

1;
__END__
