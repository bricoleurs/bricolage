package Bric::Util::FTP::Server;

=pod

=head1 NAME

Bric::Util::FTP::Server - Virtual FTP Server

=head1 VERSION

1.0

=cut

our $VERSION = "1.0";

=pod

=head1 DATE

$Date: 2001-10-02 16:23:59 $

=head1 DESCRIPTION

This module provides an FTP interface to Bricolage templates.  The
directory tree is the category tree created in Bricolage.  The files
are the template files in those categories.  When a user downloads a
template file they recieve the most recent checked-in version of the
template.  When a file is uploaded it is automatically checked-in and
deployed.

B<WARNING:> The FTP server component is an experimental feature and
has not been fully tested of completely implemented!

For installation instructions see L<Bric::Admin>.

=head1 NOTES

Currently only GET and PUT are implemented.  Also, you cannot create a
new template file using the FTP interface.  You must create a template
through the web interface and check it in before you can access it
using FTP.

=head1 AUTHOR

Sam Tregar (stregar@about-inc.com

=head1 SEE ALSO

Net::FTPServer

=head1 REVISION HISTORY

$Log: Server.pm,v $
Revision 1.1  2001-10-02 16:23:59  samtregar
Added FTP interface to templates


=cut



use strict;
use warnings;

use Bric::Util::DBI qw(:all);
use Bric::Config qw(:ftp);
use Bric::Biz::Person::User;

use Net::FTPServer;
use Bric::Util::FTP::FileHandle;
use Bric::Util::FTP::DirHandle;

our @ISA = qw(Net::FTPServer);

sub pre_configuration_hook {
  my $self = shift;

  # add to version info
  $self->{version_string} .= " Bric::Util::FTP::Server/$VERSION";
}

sub post_accept_hook {
  my $self = shift;
  
  # start a transaction
  # begin();
}

# This is called after executing every command. It commits the transaction
# into the database.
sub post_command_hook {
  my $self = shift;
  
  # commit transaction and start a new one
  #commit();
  #begin();
}


# perform login against the database.
sub authentication_hook {
  my $self = shift;
  my $user = shift;
  my $pass = shift;
  my $user_is_anon = shift;
  
  # disallow anonymous access.
  return -1 if $user_is_anon;
  
  # lookup user and store in object
  my $u = Bric::Biz::Person::User->lookup({ login => $user });
  $self->{user_obj} = $u;

  # return failure if authentication fails.
  return -1 unless $u && $u->chk_password($pass);
  
  # successful login.
  return 0;
}

# Return an instance of Bric::Util::FTP::DirHandle for the root
# directory.
sub root_directory_hook {
  my $self = shift;
  return new Bric::Util::FTP::DirHandle ($self);
}

# called when an error occured
sub system_error_hook {
  my $self = shift;
  print STDERR __PACKAGE__, "::system_error_hook()\n" if FTP_DEBUG;
  return delete $self->{error}
    if exists $self->{error};
  return "Unknown error occurred.";
}

1;
