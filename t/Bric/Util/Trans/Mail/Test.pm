package Bric::Util::Trans::Mail::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Cwd;
use Bric::Util::Trans::Mail;
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
# Test various recipients.
##############################################################################
# Do a simple send.
sub test_simple_send : Test(2) {
    my $self = shift;
    my $mail = $self->{mail};

    ok( $mail->set_to([$ENV{BRIC_TEST_TO}]), "Set To");

    return $skip_msg unless $ENV{BRIC_TEST_SMTP} && $ENV{BRIC_TEST_TO};

    # Send it.
    ok( $mail->send, "Send message");
}

##############################################################################
# Do a simple send.
sub test_without_from : Test(3) {
    my $self = shift;
    my $mail = $self->{mail};

    ok( $mail->set_to([$ENV{BRIC_TEST_TO}]), "Set To");
    ok( $mail->set_from(undef), "Set from to undef" );
    return $skip_msg unless $ENV{BRIC_TEST_SMTP} && $ENV{BRIC_TEST_TO};

    # Send it.
    ok( $mail->send, "Send message");
}

##############################################################################
# Do a send with a cc.
sub send_with_cc : Test(3) {
    my $self = shift;
    my $mail = $self->{mail};

    ok( $mail->set_to([$ENV{BRIC_TEST_TO}]), "Set To");
    ok( $mail->set_cc([$ENV{BRIC_TEST_CC}]), "Set Cc");

    return $skip_msg unless $ENV{BRIC_TEST_SMTP} && $ENV{BRIC_TEST_TO}
      && $ENV{BRIC_TEST_CC};

    # Send it.
    ok( $mail->send, "Send message");
}

##############################################################################
# Do a send with a bcc.
sub send_with_bcc : Test(2) {
    my $self = shift;
    my $mail = $self->{mail};

    ok( $mail->set_bcc([$ENV{BRIC_TEST_BCC}]), "Set Bcc");

    return $skip_msg unless $ENV{BRIC_TEST_SMTP} && $ENV{BRIC_TEST_BCC};

    # Send it.
    ok( $mail->send, "Send message");
}

##############################################################################
# Do a send with a bcc.
sub send_with_to_and_bcc : Test(3) {
    my $self = shift;
    my $mail = $self->{mail};

    ok( $mail->set_to([$ENV{BRIC_TEST_TO}]), "Set To");
    ok( $mail->set_bcc([$ENV{BRIC_TEST_BCC}]), "Set BCc");

    return $skip_msg unless $ENV{BRIC_TEST_SMTP} && $ENV{BRIC_TEST_TO}
      && $ENV{BRIC_TEST_BCC};

    # Send it.
    ok( $mail->send, "Send message");
}

##############################################################################
# Do a send with a bcc.
sub send_with_all : Test(4) {
    my $self = shift;
    my $mail = $self->{mail};

    ok( $mail->set_to([$ENV{BRIC_TEST_TO}]), "Set To");
    ok( $mail->set_cc([$ENV{BRIC_TEST_CC}]), "Set Cc");
    ok( $mail->set_bcc([$ENV{BRIC_TEST_BCC}]), "Set Bcc");

    return $skip_msg unless $ENV{BRIC_TEST_SMTP} && $ENV{BRIC_TEST_TO}
      && $ENV{BRIC_TEST_CC} && $ENV{BRIC_TEST_BCC};

    # Send it.
    ok( $mail->send, "Send message");
}

##############################################################################
# Test content type and attaching files.
##############################################################################
# Send an HTML email.
sub test_send_html : Test(4) {
    my $self = shift;
    my $mail = $self->{mail};

    ok( $mail->set_to([$ENV{BRIC_TEST_TO}]), "Set To");
    ok( $mail->set_message('<h3>' . $mail->get_message . '</h3>'),
        "Set HTML message" );
    ok( $mail->set_content_type('text/html'), "Set content type" );

    return $skip_msg unless $ENV{BRIC_TEST_SMTP} && $ENV{BRIC_TEST_TO};

    # Send it.
    ok( $mail->send, "Send message");
}

1;
__END__
