package Bric::Util::EventType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::EventType;
use Bric::Util::DBI qw(:junction);

my %addr = (
    type    => 'Shipping',
    city    => 'Sacramento',
    state   => 'CA',
    code    => '95821',
    country => 'U.S.A.',
    lines   => ['4171 17th Street'],
);

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(12) {
    my $self = shift;

    # Key name is unique.
    ok my $et = Bric::Util::EventType->lookup({ key_name => 'site_new' }),
        'Look up by key_name';
    is $et->get_key_name, 'site_new',        'Check key name';
    is $et->get_name,     'Site Created',    'Check name';
    is $et->get_class,    'Bric::Biz::Site', 'Check class id';

    # And of course so is ID.
    my $et_id = $et->get_id;
    ok $et = Bric::Util::EventType->lookup({ id => $et_id }),
        'Look up by id';
    isa_ok $et, 'Bric::Util::EventType';
    isa_ok $et, 'Bric';
    is $et->get_id,       $et_id,             'Check id';
    is $et->get_key_name, 'site_new',        'Check key name';

    # And so is name.
    ok $et = Bric::Util::EventType->lookup({ name => 'Site Created' }),
        'Look up by name';
    is $et->get_id,       1171,              'Check id';
    is $et->get_key_name, 'site_new',        'Check key name';
}

##############################################################################
# Test the list() method.
sub test_list : Test(35) {
    my $self = shift;

    # Try key_name.
    ok my @ets = Bric::Util::EventType->list({ key_name => 'site_new' }),
        'Search by key_name';
    is scalar @ets, 1, "Should have one event type";
    ok @ets = Bric::Util::EventType->list({ key_name => 'site_%' }),
        'Search by wildcard key_name';
    is scalar @ets, 3, "Should have three event typees";
    isa_ok $_, 'Bric::Util::EventType' for @ets;
    my @et_ids = map { $_->get_id } @ets;
    ok @ets = Bric::Util::EventType->list({
        key_name => ANY('site_new', 'site_save' )
    }), "Look up by ANY(key_name)";
    is scalar @ets, 2, "Should have two event typees";

    # Try ID.
    ok @ets = Bric::Util::EventType->list({ id => $et_ids[0] }),
        'Search by id';
    is scalar @ets, 1, "Should have one event type";
    ok @ets = Bric::Util::EventType->list({ id => ANY(@et_ids)}),
        "Look up by ANY(key_name)";
    is scalar @ets, 3, "Should have three event typees";

    # Try name.
    ok @ets = Bric::Util::EventType->list({ name => 'Site Created' }),
        'Search by name';
    is scalar @ets, 1, "Should have one event type";
    ok @ets = Bric::Util::EventType->list({ name => 'Site%' }),
        'Search by wildcard name';
    is scalar @ets, 3, "Should have three event typees";
    ok @ets = Bric::Util::EventType->list({
        name => ANY('Site Created', 'Site Saved' )
    }), "Look up by ANY(name)";
    is scalar @ets, 2, "Should have two event typees";

    # Try description.
    ok @ets = Bric::Util::EventType->list({
        description => 'Site was created.',
    }), 'Search by description';
    is scalar @ets, 1, "Should have one event type";
    ok @ets = Bric::Util::EventType->list({ description => 'Site%' }),
        'Search by wildcard description';
    is scalar @ets, 3, "Should have three event typees";
    ok @ets = Bric::Util::EventType->list({
        description => ANY('Site was created.', 'Site was deactivated.' )
    }), "Look up by ANY(description)";
    is scalar @ets, 2, "Should have two event typees";

    # Try class.
    ok @ets = Bric::Util::EventType->list({ class => 'Bric::Biz::Site' }),
        'Search by class';
    is scalar @ets, 3, "Should have three event types";
    ok @ets = Bric::Util::EventType->list({ class => 'Bric::Biz::%' }),
        'Search by wildcard class';
    is scalar @ets, 106, "Should have 106 event types";
    ok @ets = Bric::Util::EventType->list({
        class => ANY('Bric::Biz::Site', 'Bric::Biz::Keyword' )
    }), "Look up by ANY(class)";
    is scalar @ets, 6, "Should have six event typees";

    # Try class_id.
    ok @ets = Bric::Util::EventType->list({ class_id => 75 }),
        'Search by class_id';
    is scalar @ets, 3, "Should have three event types";
    ok @ets = Bric::Util::EventType->list({ class_id => ANY(75, 41)}),
        "Look up by ANY(key_name)";
    is scalar @ets, 6, "Should have six event typees";
}

##############################################################################
# Class methods.
##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(35) {
    my $self = shift;

    # Try key_name.
    ok my @et_ids = Bric::Util::EventType->list_ids({
        key_name => 'site_new'
    }), 'Search by key_name';
    is scalar @et_ids, 1, "Should have one event type id";
    ok @et_ids = Bric::Util::EventType->list_ids({ key_name => 'site_%' }),
        'Search by wildcard key_name';
    is scalar @et_ids, 3, "Should have three event type ides";
    like $_, qr/^\d+$/ for @et_ids;
    my @test_et_ids = @et_ids;
    ok @et_ids = Bric::Util::EventType->list_ids({
        key_name => ANY('site_new', 'site_save' )
    }), "Look up by ANY(key_name)";
    is scalar @et_ids, 2, "Should have two event type ides";

    # Try ID.
    ok @et_ids = Bric::Util::EventType->list_ids({ id => $test_et_ids[0] }),
        'Search by id';
    is scalar @et_ids, 1, "Should have one event type id";
    ok @et_ids = Bric::Util::EventType->list_ids({ id => ANY(@test_et_ids)}),
        "Look up by ANY(key_name)";
    is scalar @et_ids, 3, "Should have three event type ides";

    # Try name.
    ok @et_ids = Bric::Util::EventType->list_ids({ name => 'Site Created' }),
        'Search by name';
    is scalar @et_ids, 1, "Should have one event type id";
    ok @et_ids = Bric::Util::EventType->list_ids({ name => 'Site%' }),
        'Search by wildcard name';
    is scalar @et_ids, 3, "Should have three event type ides";
    ok @et_ids = Bric::Util::EventType->list_ids({
        name => ANY('Site Created', 'Site Saved' )
    }), "Look up by ANY(name)";
    is scalar @et_ids, 2, "Should have two event type ides";

    # Try description.
    ok @et_ids = Bric::Util::EventType->list_ids({
        description => 'Site was created.',
    }), 'Search by description';
    is scalar @et_ids, 1, "Should have one event type id";
    ok @et_ids = Bric::Util::EventType->list_ids({ description => 'Site%' }),
        'Search by wildcard description';
    is scalar @et_ids, 3, "Should have three event type ides";
    ok @et_ids = Bric::Util::EventType->list_ids({
        description => ANY('Site was created.', 'Site was deactivated.' )
    }), "Look up by ANY(description)";
    is scalar @et_ids, 2, "Should have two event type ides";

    # Try class.
    ok @et_ids = Bric::Util::EventType->list_ids({ class => 'Bric::Biz::Site' }),
        'Search by class';
    is scalar @et_ids, 3, "Should have three event type ids";
    ok @et_ids = Bric::Util::EventType->list_ids({ class => 'Bric::Biz::%' }),
        'Search by wildcard class';
    is scalar @et_ids, 106, "Should have 106 event type ids";
    ok @et_ids = Bric::Util::EventType->list_ids({
        class => ANY('Bric::Biz::Site', 'Bric::Biz::Keyword' )
    }), "Look up by ANY(class)";
    is scalar @et_ids, 6, "Should have six event type ides";

    # Try class_id.
    ok @et_ids = Bric::Util::EventType->list_ids({ class_id => 75 }),
        'Search by class_id';
    is scalar @et_ids, 3, "Should have three event type ids";
    ok @et_ids = Bric::Util::EventType->list_ids({ class_id => ANY(75, 41)}),
        "Look up by ANY(key_name)";
    is scalar @et_ids, 6, "Should have six event type ides";
}

1;
__END__
