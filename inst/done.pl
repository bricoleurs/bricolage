#!/usr/bin/perl -w

=head1 NAME

done.pl - installation script to give the user some final instructions

=head1 VERSION

$Revision: 1.1.6.1 $

=head1 DATE

$Date: 2003/03/23 20:26:14 $

=head1 DESCRIPTION

This script is called at the end of "make install" to give the user some
final instructions.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

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
first action should be changing this password. Navigate into the ADMIN ->
SYSTEM -> Users menu, search for the "admin" user, click the "Edit"
link, and change the password.

=========================================================================
=========================================================================

END

exit 0;
