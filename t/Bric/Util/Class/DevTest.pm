package Bric::Util::Class::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Class;

sub class { 'Bric::Util::Class' }

##############################################################################
# Test constructors.
##############################################################################
# Test lookup().

sub test_lookup : Test(8) {
    my $self = shift;
    my $test_class = $self->class;
    # Lookup by ID.
    ok( my $c = $test_class->lookup({ id => 3 }), "Lookup org class by ID." );
    is( $c->get_key_name, 'org', "Key name is 'org'" );

    # Lookup by package name.
    my $pkg = 'Bric::Biz::Asset::Template';
    ok( $c = $test_class->lookup({ pkg_name => $pkg}),
        "Lookup template by pkg_name" );
    is( $c->get_key_name, 'template', "Key name is 'template'" );

    # Lookup by key name.
    ok( $c = $test_class->lookup({ key_name => 'Bric::Biz::Person'}),
        "Lookup person by key_name" );
    is( $c->get_key_name, 'person', "Key name is 'person'" );

    # Lookup by all three, defaulting to package name.
    ok( $c = $test_class->lookup({ id => $pkg, key_name => $pkg,
                                   pkg_name => $pkg }),
        "Looup by all three" );
    is( $c->get_key_name, 'template', "Key name is 'template'" );
}

1;
__END__
