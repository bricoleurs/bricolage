package Bric::Util::AlertType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::AlertType');
}

my %test_vals = ( event_type_id => 1028,
                  owner_id      => 0,
                  name          => 'Testing!',
                  subject       => 'Test Subject',
                  message       => 'Test Message'
                );

##############################################################################
# Test constructor.
##############################################################################
sub test_new : Test(9) {
    my $self = shift;
    ok( my $at = Bric::Util::AlertType->new, "Create new AT" );
    isa_ok($at, 'Bric::Util::AlertType');
    ok( $at->is_active, "Make sure it's active" );
    ok( $at = Bric::Util::AlertType->new(\%test_vals), "New AT with vals" );
    is( $at->get_event_type_id, $test_vals{event_type_id},
        "Check event_type_id = $test_vals{event_type_id}" );
    is( $at->get_owner_id, $test_vals{owner_id},
        "Check owner_id = $test_vals{owner_id}" );
    is( $at->get_name, $test_vals{name},
        "Check name = $test_vals{name}" );
    is( $at->get_subject, $test_vals{subject},
        "Check subject = $test_vals{subject}" );
    is( $at->get_message, $test_vals{message},
        "Check message = $test_vals{message}" );
}

1;
__END__
