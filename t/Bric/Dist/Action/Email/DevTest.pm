package Bric::Dist::Action::Email::DevTest;
use strict;
use warnings;
use base qw(Bric::Dist::Action::DevTest);
use Cwd;
use File::Spec::Functions qw(catfile);
use Bric::Dist::Action::Email;
use Test::More;

sub class { 'Bric::Dist::Action::Email' }

##############################################################################
# Test the attribute methods.
##############################################################################
sub test_attrs : Test(26) {
    my $self = shift;
    my $class = $self->class;
    ok( my $act = $class->new({ type => 'Email',
                                server_type_id => $self->{dest}->get_id }),
        "Create email action" );

    my $addrs = 'you@example.com, Them <them@example.net>';
    ok( $act->set_to($addrs), "Set To" );
    is( $act->get_to, $addrs, "Check To" );

    ok( $act->set_cc($addrs), "Set Cc" );
    is( $act->get_cc, $addrs, "Check Cc" );

    ok( $act->set_bcc($addrs), "Set Bcc" );
    is( $act->get_bcc, $addrs, "Check Bcc" );

    ok( $act->set_subject('subject'), "Set Subject" );
    is( $act->get_subject, 'subject', "Check Subject" );

    ok( $act->set_content_type('text/html'), "Set Content type" );
    is( $act->get_content_type, 'text/html', "Check Content type" );

    is( $act->get_handle_text, $class->INLINE,
        "Check handle_text is INLINE" );
    ok( $act->set_handle_text($class->ATTACH),
        "Set handle_text" );
    is( $act->get_handle_text, $class->ATTACH,
        "Check handle_text is ATTACH" );

    is( $act->get_handle_other, $class->IGNORE,
        "Check handle_other is IGNORE" );
    ok( $act->set_handle_other($class->ATTACH),
        "Set handle_other" );
    is( $act->get_handle_other, $class->ATTACH,
        "Check handle_other is ATTACH" );

    # Save it and look it up again.
    ok( $act->save, "Save the action" );
    $self->add_del_ids($act->get_id);
    ok( $act = $act->lookup({ id => $act->get_id }), "Look up action" );

    # Now check all the attributes.
    is( $act->get_to, $addrs, "Check To" );
    is( $act->get_cc, $addrs, "Check Cc" );
    is( $act->get_bcc, $addrs, "Check Bcc" );
    is( $act->get_subject, 'subject', "Check Subject" );
    is( $act->get_content_type, 'text/html', "Check Content type" );
    is( $act->get_handle_text, $class->ATTACH,
        "Check handle_text is ATTACH" );
    is( $act->get_handle_other, $class->ATTACH,
        "Check handle_other is ATTACH" );
}

##############################################################################
# Test the do_it method.
##############################################################################
sub test_do_it : Test(28) {
    my $self = shift;
    my $class = $self->class;

    ok( my $act = $class->new({ type => 'Email',
                                server_type_id => $self->{dest}->get_id }),
        "Create email action" );

    ok( $act->set_from('bric_test@example.com'), "Set From" );
    ok( $act->set_to($ENV{BRIC_TEST_TO}), "Set To" );
    ok( $act->set_cc($ENV{BRIC_TEST_CC}), "Set Cc" );
    ok( $act->set_bcc($ENV{BRIC_TEST_BCC}), "Set Bcc" );

    my $text_file = catfile cwd, 'README';
    my $text_type = 'text/plain';
    my $html_file = catfile cwd, qw(comp help en_us admin profile user.html);
    my $html_type = 'text/html';
    my $gif_file = catfile cwd, qw(comp media images note.gif);
    my $gif_type = 'image/gif';

    # Just bail if we ain't got no files to send.
    return "$text_file does not exist" unless -f $text_file;
    return "$html_file does not exist" unless -f $html_file;
    return "$gif_file does not exist" unless -f $gif_file;

    # Create the resources.
    ok( my $text = Bric::Dist::Resource->new({ path       => $text_file,
                                               media_type => $text_type }),
        "Create text resource" );

    ok( my $html = Bric::Dist::Resource->new({ path       => $html_file,
                                               media_type => $html_type }),
        "Create html resource" );

    ok( my $gif = Bric::Dist::Resource->new({ path       => $gif_file,
                                              media_type => $gif_type }),
        "Create gif resource" );

    # Bail if there are no email addresses and such to test.
    return "Set BRIC_TEST_SMTP, BRIC_TEST_TO, BRIC_TEST_CC, and " .
      "BRIC_TEST_BCC fully test Bric::Dist::Action::Email by having it " .
      "send messages"
      unless $ENV{BRIC_TEST_SMTP} &&
        ($ENV{BRIC_TEST_TO} || $ENV{BRIC_TEST_CC} || $ENV{BRIC_TEST_BCC});

    # Leave the default settings for handling text and other files and send
    # it with the text file.
    ok( $act->set_subject('Action::Email Plain Text Test'),
        "Set text subject" );
    ok( $act->do_it([$text, $gif]), "Send the text inline" );

    # Make sure that the text will be concatenated.
    ok( $act->set_subject('Action::Email Double Text Test'),
        "Set double text subject" );
    ok( $act->do_it([$text, $text]), "Send the text inline" );

    # Try sending an HTML file.
    ok( $act->set_subject('Action::Email HTML Test'), "Set HTML subject" );
    ok( $act->do_it([$html, $gif]), "Send the html inline" );

    # Make sure that the HTML will be concatenated.
    ok( $act->set_subject('Action::Email Double HTML Test'),
        "Set double HTML subject" );
    ok( $act->do_it([$html, $html]), "Send the double HTML inline" );

    # Now send the text with the GIF attached.
    ok( $act->set_subject('Action::Email Text+GIF Test'),
        "Set Text + GIF subject" );
    ok( $act->set_handle_other($class->ATTACH), "Set others to attach" );
    ok( $act->do_it([$text, $gif]), "Send the text + gif" );

    # And finally send the HTML with the GIF attached.
    ok( $act->set_subject('Action::Email HTML+GIF Test'),
        "Set HTML+GIF subject" );
    ok( $act->do_it([$html, $gif]), "Send the text + gif" );

    # Now send the text and HTML files only as attachments.
    ok( $act->set_subject('Action::Email Attach Text Test'),
        "Set attach text subject" );
    ok( $act->set_handle_text($class->ATTACH), "Set text to attach" );
    ok( $act->do_it([$text, $html]), "Send the text + html" );

    # Set the content type to force the HTML message to be sent as plain text.
    ok( $act->set_content_type('text/plain'), "Set content type" );
    ok( $act->set_subject('Action::Email plain text HTML Test'),
        "Set plain text HTML subject" );
    ok( $act->set_handle_text($class->INLINE), "Set text to inline" );
    ok( $act->do_it([$html]), "Send the plain text html inline" );
}

1;
__END__
