package Bric::Biz::Org::Source::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Org::DevTest);
use Bric::Biz::Org::Source;
use Test::More;

sub class { 'Bric::Biz::Org::Source' };
sub grp_class { 'Bric::Util::Grp::Source' }

sub new_args {
    my $self = shift;
    ( $self->SUPER::new_args,
      source_name => 'Kineticode 10-day',
      description => '10 day Kineticode lease',
      expire      => 10
    )
}

sub add_del_obj {
    my ($self, $org) = @_;
    $self->add_del_ids($org->get_org_id);
}

sub modify_args {
    my ($self, $n) = @_;
    my $args = $self->SUPER::modify_args($n);
    $args->{source_name} .= $n;
    if ($n % 2) {
        $args->{description} .= $n;
    } else {
        $args->{expire} = 30;
    }
    return $args;
}

sub test_list : Test(+10) {
    my $self = shift;
    $self->SUPER::test_list(@_);

    my %org = $self->new_args;
    my $class = $self->class;

    # Try source_name + wildcard.
    ok( my @orgs = $class->list({ source_name => "$org{source_name}%" }),
        "Look up source_name '$org{source_name}%'" );
    is( scalar @orgs, 5, "Check for 5 orgs" );

    # Try description.
    ok( @orgs = $class->list({ description => $org{description} }),
        "Look up description '$org{description}'" );
    is( scalar @orgs, 2, "Check for 2 orgs" );

    # Try description + wildcard.
    ok( @orgs = $class->list({ description => "$org{description}%" }),
        "Look up description '$org{description}%'" );
    is( scalar @orgs, 5, "Check for 5 orgs" );

    # Try expire
    ok( @orgs = $class->list({ expire => $org{expire} }),
        "Look up expire '$org{expire}'" );
    is( scalar @orgs, 3, "Check for 3 orgs" );

    ok( @orgs = $class->list({ expire => 30 }),
        "Look up expire '30'" );
    is( scalar @orgs, 2, "Check for 2 orgs" );
}

1;
__END__
