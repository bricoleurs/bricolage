package Bric::Util::FTP::Server;

=pod

=head1 NAME

Bric::Util::FTP::Server - Virtual FTP Server

=head1 VERSION

$Revision $

=cut

our $VERSION = (qw$Revision: 1.8 $ )[-1];

=pod

=head1 DATE

$Date $

=head1 SYNOPSIS

  use Bric::Util::FTP::Server;
  Bric::Util::FTP::Server->run;

=head1 DESCRIPTION

This module provides an FTP interface to Bricolage templates.  The
directory tree is the category tree created in Bricolage.  The first
directory level selects the output channel.  The files are the
template files in the output channels and categories.  When a user
downloads a template file they recieve the most recent checked-in
version of the template.  When a file is uploaded it is automatically
checked-in and deployed.

For installation and configuration instructions see L<Bric::Admin>.

=head1 LIMITATIONS

Only GET, PUT and DELETE are implemented for templates.  No
modification of categories is supported.

The system doesn't deal with the possibility of having more than one
active template for a given filename.  This probably won't be fixed
here - rather, Bricolage will soon prevent this situation.

=head1 INTERFACE

This module inherits from Net::FTPServer and doesn't override any
public methods.  See L<Net::FTPServer> for details.

=head1 PRIVATE

=head2 Private Instance Methods

=over 4

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Config qw(:ftp);
use Bric::Biz::Person::User;
use Net::FTPServer;
use Bric::Util::FTP::FileHandle;
use Bric::Util::FTP::DirHandle;

################################################################################
# Inheritance
################################################################################
our @ISA = qw(Net::FTPServer);

=item pre_configuration_hook()

This is called by Net:FTPServer before configuration begins.  It's
used in this class to add our name and version to the version string
displayed by the server.

=cut

sub pre_configuration_hook {
  my $self = shift;

  # add to version info
  $self->{version_string} .= " Bric::Util::FTP::Server/$VERSION";

  print STDERR "Bricolage FTP Server Started\n" if FTP_DEBUG;
}

=item authenticaton_hook($user, $pass, $user_is_anon)

When a user logs in authentication_hook() is called to check their
username and password.  This method calls
Bric::Biz::Person::User->lookup() using the given username and then
checks the password.  Returns -1 on login failure or 0 on success.  As
a side-effect this method stashes the Bric::Biz::Person::User object
into $self->{user_obj}.

=cut

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

=item root_directory_hook()

Net::FTPServer calls this method to get a DirHandle for the root
directory.  This method just calls Bric::Util::FTP::DirHandle->new().

=cut

sub root_directory_hook {
  my $self = shift;
  return Bric::Util::FTP::DirHandle->new($self);
}

=item system_error_hook()

This method is called when an error is signaled elsewhere in the
server.  It looks for a key called "error" in $self and returns that
if it's available.  This allows for an OO version of the ever-popular
$! mechanism.  (Or, at least, that's the idea.  As far as I can tell
it never really gets called!)

=cut

sub system_error_hook {
  my $self = shift;
  print STDERR __PACKAGE__, "::system_error_hook()\n" if FTP_DEBUG;
  return delete $self->{error}
    if exists $self->{error};
  return "Unknown error occurred.";
}

1;

__END__

=back

=head1 AUTHOR

Sam Tregar (stregar@about-inc.com

=head1 SEE ALSO

Net::FTPServer

L<Bric::Util::FTP::DirHandler>

L<Bric::Util::FTP::FileHandle>

=cut

