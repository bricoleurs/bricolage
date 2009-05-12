#!/usr/bin/perl -w

=head1 Name

done.pl - installation script to give the user some final instructions

=head1 Description

This script is called at the end of "make install" to give the user some
final instructions.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use File::Spec::Functions qw(:ALL);

# read in user config settings
our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";
our $AP;
do "./apache.db" or die "Failed to read apache.db : $!";

my $url = "http://$AP->{server_name}" .
    ($AP->{port} == 80 ? "" : ":$AP->{port}");

my $ctl = "bric_apachectl";
$ctl = catfile($CONFIG->{BIN_DIR}, $ctl)
    unless grep { $_ eq $CONFIG->{BIN_DIR} } path();
$ctl = "BRICOLAGE_ROOT=$CONFIG->{BRICOLAGE_ROOT} $ctl"
    unless $CONFIG->{BRICOLAGE_ROOT} eq '/usr/local/bricolage';

my $error_log = catfile($CONFIG->{LOG_DIR}, "error_log");

print <<END;








=========================================================================
=========================================================================

           Bricolage Installation Complete

You may now start your Bricolage server with the command (as root):

  $ctl start

If this command fails, look in your error log for more information:

  $error_log

Once your server is started, open a web browser and enter the URL for
your server:

  $url

Login in as "admin" with the default password "change me now!". Your
first action should be changing this password. Click "Logged in as
Bricolage Administrator" in the top right corner of the browser window
and change the password.

Pointers for documentation and lots of getting started advice are in
the main README file in the unpacked distribution directory.

=== IMPORTANT NOTE ===

For 1.10.3 the way the login page redirects was changed. Please send
a message to the bricolage users list if you cannot login. You should
also consider joining the list anyway since there is a lot of useful
information and help available :  users\@lists.bricolage.cc

=========================================================================
=========================================================================

END

exit 0;
