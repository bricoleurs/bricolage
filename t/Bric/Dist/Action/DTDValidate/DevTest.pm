package Bric::Dist::Action::DTDValidate::DevTest;
use strict;
use warnings;
use base qw(Bric::Dist::Action::DevTest);
use Test::More;
use File::Spec::Functions qw(catfile);
use File::Basename qw(dirname);
use Bric::Dist::Action::DTDValidate;

sub class { 'Bric::Dist::Action::DTDValidate' }

##############################################################################
# Test the do_it method.
##############################################################################
sub test_do_it : Test(31) {
    return "XML::LibXML not installed"
      unless Bric::Dist::Action::DTDValidate->HAVE_LIB_XML;

    my $self = shift;
    my $class = $self->class;

    ok( my $act = $class->new({ type => 'DTD Validation',
                                server_type_id => $self->{dest}->get_id }),
        "Create validation action" );
    isa_ok( $act, $class );

    # We have to save and look up the action so that the media types are
    # properly loaded from the database.
    ok( $act->save, "Save act" );
    $self->add_del_ids($act->get_id);
    ok( $act = $class->lookup({ id => $act->get_id }), "Reload action" );
    isa_ok( $act, $class );

    my $html_type    = 'text/html';

    # Create the resources.
    ok( my $bad = Bric::Dist::Resource->new
        ({ path       => catfile(dirname(__FILE__), 'bad.html'),
           uri        => '/foo/bad.html',
           media_type => $html_type }),
        "Create bad HTML resource" );

    ok( my $invalid = Bric::Dist::Resource->new
        ({ path       => catfile(dirname(__FILE__), 'invalid.html'),
           uri        => '/foo/invalid.html',
           media_type => $html_type }),
        "Create invalid HTML resource" );

    ok( my $valid = Bric::Dist::Resource->new
        ({ path       => catfile(dirname(__FILE__), 'valid.html'),
           uri        => '/foo/valid.html',
           media_type => $html_type }),
        "Create valid HTML resource" );

    # Make sure there's a localization handle to translate the error message.
    ok( Bric::Util::Language->get_handle('en_us'), "Create lang handle" );

    # Start trapping the output to STDERR.
    $self->trap_stderr;

    # Make sure that we get a parse failure for bad.html.
    eval { $act->do_it([$bad]) };
    ok( my $err = $@, "Catch parse exception" );
    is( $self->read_stderr, 'Validating /foo/bad.html',
        "Check for status message" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    is( $err->error, 'Error parsing XML', "Check bad parse error message" );
    like( $err->payload,
          qr|^/foo/bad\.html:11: (parser )?error ?: Opening and ending tag mismatch: br line 10 and p|,
          "Check parse error payload" );

    # Make sure that we get a validation failure for invalid.html.
    eval { $act->do_it([$invalid]) };
    ok( $err = $@, "Catch invalid exception" );
    is( $self->read_stderr, 'Validating /foo/invalid.html',
        "Check for status message" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    is( $err->error, 'Error parsing XML', "Check invalid XML message" );
    like( $err->payload,
          qr|/foo/invalid\.html:0: validity error ?:|,
         "Check validation payload");

    # Make sure that a valid file, um, validates.
    ok( $act->do_it([$valid]), "Validate valid XHTML" );
    is( $self->read_stderr, 'Validating /foo/valid.html',
        "Check for status message" );

    # Make sure that multiple files are validated.
    eval { $act->do_it([$valid, $bad]) };
    ok( $err = $@, "Catch parse exception" );
    is( $self->read_stderr,
        "Validating /foo/valid.htmlValidating /foo/bad.html",
        "Check for status message" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    is( $err->error, 'Error parsing XML', "Check bad parse error message" );
    like( $err->payload,
          qr|^/foo/bad\.html:11: (parser )?error ?: Opening and ending tag mismatch: br line 10 and p|,
          "Check parse error payload" );

    # Make sure that multiple files are validated.
    eval { $act->do_it([$valid, $invalid]) };
    ok( $err = $@, "Catch parse exception" );
    is( $self->read_stderr,
        "Validating /foo/valid.htmlValidating /foo/invalid.html",
        "Check for status message" );
    isa_ok($err, 'Bric::Util::Fault::Exception::DP');
    is( $err->error, 'Error parsing XML', "Check invalid XML message" );
    like( $err->payload,
          qr|/foo/invalid\.html:0: validity error ?:|,
         "Check validation payload");
}

1;
__END__
