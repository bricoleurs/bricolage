package Bric::Util::Trans::Mail::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Cwd;
use Bric::Util::Trans::Mail;
use Bric::Dist::Resource;
use File::Spec::Functions qw(catfile);

my $skip_msg = "Set BRIC_TEST_SMTP, BRIC_TEST_TO, BRIC_TEST_CC, and " .
  "BRIC_TEST_BCC fully test Bric::Util::Trans::Mail by having it send " .
  "messages";

my $test_file = catfile cwd, qw(comp media images note.gif);
my $media_type = 'image/gif';

sub setup : Test(setup => 6) {
    my $self = shift;

    # Create a mail object.
    my $mail = Bric::Util::Trans::Mail->new;
    isa_ok($mail, 'Bric::Util::Trans::Mail');
    isa_ok($mail, 'Bric');
    my $meth = $self->current_method;

    # Do a simple send.
    ok( $mail->set_smtp($ENV{BRIC_TEST_SMTP}), "Set SMTP");
    ok( $mail->set_from('Bric Test <bric_test@example.com>'), "Set from");
    ok( $mail->set_subject("Bricolage Mail Test $meth"),
        "Set subject");
    ok( $mail->set_message('This is a test message from ' .
                           "Bric::Util::Trans::Mail::Test. The test\n" .
                           "method that sent it was $meth\n"),
        "Set message");
    $self->{mail} = $mail;

}

##############################################################################
# Attach a file.
sub test_attach_file : Test(4) {
    my $self = shift;
    my $mail = $self->{mail};

    return "$test_file does not exist" unless -f $test_file;

    ok( $mail->set_to([$ENV{BRIC_TEST_TO}]), "Set To");
    ok( my $res = Bric::Dist::Resource->new({ path       => $test_file,
                                              media_type => $media_type }),
        "Create resource" );
    ok( $mail->set_resources([$res]), "Add resource to mail" );

    return $skip_msg unless $ENV{BRIC_TEST_SMTP} && $ENV{BRIC_TEST_TO};

    # Send it.
    ok( $mail->send, "Send message");
}

