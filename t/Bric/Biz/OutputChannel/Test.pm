package Bric::Biz::OutputChannel::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Config qw(:oc);
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::OutputChannel');
}

##############################################################################
# Test constructors.
##############################################################################
# Test the new() method.
sub test_new : Test(16) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    isa_ok($oc, 'Bric::Biz::OutputChannel');
    isa_ok($oc, 'Bric');
    isa_ok($oc, 'Exporter');

    # Try new() with parameters.
    my $param = { name        => 'mike\'s test5',
                  description => 'a fun test',
                  primary     => 1,
                  filename    => 'home',
                  protocol    => 'http://',
                  site_id     => 100,
                  uri_format  => '/%{categories}/%Y/%m/',
                  active      => 1
                };

    ok( $oc = Bric::Biz::OutputChannel->new($param),
        "Create new OC with params" );
    is( $oc->get_name, "mike's test5", "Check name" );
    is( $oc->get_description, 'a fun test', "Check description" );
    is( $oc->get_filename, 'home', "Check filename" );
    is( $oc->get_file_ext, 'html', "Check file_ext" );
    is( $oc->get_site_id, 100, "Check site ID" );
    is( $oc->get_protocol, 'http://', "Check protocol" );

    is( $oc->get_uri_format, '/%{categories}/%Y/%m/',
          "Check uri_format" );
    is( $oc->get_fixed_uri_format, '/%{categories}/',
          "Check fixed_uri_format" );
    is( $oc->get_uri_case, Bric::Biz::OutputChannel::MIXEDCASE(),
        "Check uri_case" );
    ok( !$oc->can_use_slug, "Check can_use_slug" );
    ok( $oc->is_active, "Check is_active" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::OutputChannel->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::OutputChannel->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'NewFoo' }),
        "Create OC" );
    ok( my @meths = $oc->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($oc), 'NewFoo', "Check name 'NewFoo'" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test uri_format attribute.
sub test_uri_format : Test(12) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    is( $oc->get_uri_format, '/%{categories}/%Y/%m/%d/%{slug}/',
          "Check uri_format" );
    ok( $oc->set_uri_format('/%{categories}/%d/%m/%{slug}'),
        "Set new category" );
    is( $oc->get_uri_format, '/%{categories}/%d/%m/%{slug}/',
        "Check new category" );
    ok( $oc->set_uri_format('/%{slug}/%{categories}/%Y/'),
        "Set another new category" );
    is( $oc->get_uri_format, '/%{slug}/%{categories}/%Y/',
        "Check another new category" );

    # Try an empty string format.
    eval { $oc->set_uri_format('') };
    ok( my $ex = $@, "Catch empty string exception" );
    isa_ok( $ex, 'Bric::Util::Fault::Exception::DP',
            'Empty string exception is a DP' );
    is( $ex->get_msg, 'No URI Format value specified',
        "Check empty string ex message" );

    # Try a format without %{categories}.
    eval { $oc->set_uri_format('/foo') };
    ok( $ex = $@, "Catch bogus token exception" );
    isa_ok( $ex, 'Bric::Util::Fault::Exception::DP',
            'Bogus token exception is a DP' );
    is( $ex->get_msg, 'Missing the %{categories} token from URI Format',
        "Check bogus token ex message" );
}

##############################################################################
# Test fixed_uri_format attribute.
sub test_fixed_uri_format : Test(12) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    is( $oc->get_fixed_uri_format, '/%{categories}/',
          "Check fixed_uri_format" );
    ok( $oc->set_fixed_uri_format('/%{categories}/%d/%m/%{slug}'),
        "Set new category" );
    is( $oc->get_fixed_uri_format, '/%{categories}/%d/%m/%{slug}/',
        "Check new category" );
    ok( $oc->set_fixed_uri_format('/%{slug}/%{categories}/%Y'),
        "Set another new category" );
    is( $oc->get_fixed_uri_format, '/%{slug}/%{categories}/%Y/',
        "Check another new category" );

    # Try an empty string format.
    eval { $oc->set_fixed_uri_format('') };
    ok( my $ex = $@, "Catch empty string exception" );
    isa_ok( $ex, 'Bric::Util::Fault::Exception::DP',
            'Empty string exception is a DP' );
    is( $ex->get_msg, 'No Fixed URI Format value specified',
        "Check empty string ex message" );

    # Try a format without %{categories}.
    eval { $oc->set_fixed_uri_format('/foo') };
    ok( $ex = $@, "Catch bogus token exception" );
    isa_ok( $ex, 'Bric::Util::Fault::Exception::DP',
            'Bogus token exception is a DP' );
    is( $ex->get_msg, 'Missing the %{categories} token from Fixed URI Format',
        "Check bogus token ex message" );
}

##############################################################################
# Test filename attribute.
sub test_filename : Test(20) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    is( $oc->get_filename, DEFAULT_FILENAME, "Check filename default" );
    ok( $oc->set_filename('foo'), "Set filename to 'foo'" );
    is( $oc->get_filename, 'foo', "Check for 'foo'" );

    # Create a mock story object.
    ok( my $s = Bric::Biz::Asset::Business::Story->newish('bar'),
        "Create story" );

    # Test it with the story object.
    is( $oc->get_filename($s), 'foo', "Check for 'foo' again" );

    # Now set use_slug.
    ok( $oc->use_slug_on, "Turn on use_slug" );
    is( $oc->get_filename($s), 'bar', "Check for 'bar'" );
    # Now try it with a mock story object that has no slug.
    ok( $s = Bric::Biz::Asset::Business::Story->newish,
        "Create slugless story" );
    is( $oc->get_filename($s), 'foo', "Check for 'foo' again" );

    # Now try with the case changed.
    ok( $oc->set_uri_case(Bric::Biz::OutputChannel::UPPERCASE()),
        "Set for uppercase" );
    is( $oc->get_filename, 'FOO', "Check for 'FOO'" );
    ok( $s = Bric::Biz::Asset::Business::Story->newish('bar'),
        "Create story" );
    is( $oc->get_filename($s), 'BAR', "Check for 'BAR'" );

    # Now try it with a media object.
    ok( my $m = Bric::Biz::Asset::Business::Media->newish('Foo.gif'),
        "Create media" );
    is( $oc->get_filename($m), 'FOO.GIF', "Check for 'FOO.GIF'" );

    # And try it without the case changed.
    ok( $oc->set_uri_case(Bric::Biz::OutputChannel::MIXEDCASE()),
        "Set for mixed case" );
    is( $oc->get_filename($m), 'Foo.gif', "Check for 'Foo.gif'" );

    # And finally, with the case all lowercase.
    ok( $oc->set_uri_case(Bric::Biz::OutputChannel::LOWERCASE()),
        "Set for lower case" );
    is( $oc->get_filename($m), 'foo.gif', "Check for 'foo.gif'" );
}

##############################################################################
# Test file_ext attribute.
sub test_file_ext : Test(6) {
    ok( my $oc = Bric::Biz::OutputChannel->new, "Create new OC" );
    is( $oc->get_file_ext, DEFAULT_FILE_EXT, "Check filename default" );
    ok( $oc->set_file_ext('foo'), "Set filename to 'foo'" );
    is( $oc->get_file_ext, 'foo', "Check for 'foo'" );

    # Try it with the case changed.
    ok( $oc->set_uri_case(Bric::Biz::OutputChannel::UPPERCASE()),
        "Set for uppercase" );
    is( $oc->get_file_ext, 'FOO', "Check for 'FOO'" );
}


##############################################################################
# Create bogus story constructor used by test_filename(). This is a bit fishy,
# so we may want to change it to use a real Story object constructed by new(),
# later.
package Bric::Biz::Asset::Business::Story;
sub newish { bless { slug => $_[1] } }

##############################################################################
# Create bogus media constructor used by test_filename(). This is a bit fishy,
# so we may want to change it to use a real Media object constructed by new(),
# later.
package Bric::Biz::Asset::Business::Media;
sub newish { bless { file_name => $_[1] } }

1;
__END__
