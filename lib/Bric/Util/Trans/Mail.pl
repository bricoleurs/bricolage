#!/usr/bin/perl -w
use Bric::Util::Trans::Mail;
use Test;

BEGIN { plan tests => 1 }

eval {
    if (@ARGV) {
	print "Creating a new mail object.\n";
	my $mail = Bric::Util::Trans::Mail->new;
	$mail->set_smtp('mail.about.com');
	$mail->set_from('David@Wheeler.net');
	$mail->set_to(['david@wheeler.net', 'david@about.com']);
	$mail->set_cc(['david@wheeler.net']);
	$mail->set_bcc(['dw@dnai.com']);
	$mail->set_subject('Test message from Bric::Util::Trans::Mail');
	$mail->set_message('This is a test message from Bric::Util::Trans::Mail. Check it out!');

	print "SMTP:    ${ \$mail->get_smtp}\n";
	print "From:    ${ \$mail->get_from}\n";
	local $" = ', ';
	print "To:      @{ $mail->get_to}\n";
	print "Cc:      @{ $mail->get_cc}\n";
	print "Bcc:     @{ $mail->get_bcc}\n";
	print "Subject: ${ \$mail->get_subject}\n";
	print "Message: ${ \$mail->get_message}\n";

	print "Sending the message.\n";
	$mail->send;
	exit;


    }

    # Now, the Test::Harness code.
    exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
