package Bric::Dist::Job::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::Time qw(local_date);

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Dist::Job');
}

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(5) {
    my $self = shift;
    my $sched_time = local_date(undef, undef, 1);
    my $args = { name => 'Test Job',
                 user_id => 0,
                 sched_time => $sched_time
               };

    ok ( my $job = Bric::Dist::Job->new($args), "Test construtor" );
    ok( ! defined $job->get_id, 'Undefined ID' );
    is( $job->get_name, $args->{name}, "Name is '$args->{name}'" );
    is( $job->get_sched_time, $sched_time, "Scheduled time is $sched_time" );
    is( $job->get_user_id, 0, "Check User ID 0" );
}

1;
__END__
