package Bric::Util::FTP::FileHandle;

=pod

=head1 NAME

Bric::Util::FTP::FileHandle - Virtual FTP Server FileHandle

=head1 VERSION

$Revision $

=cut

our $VERSION = substr(q$Revision 1.0$, 10, -1);

=pod

=head1 DATE

$Date: 2001-10-09 00:03:02 $

=head1 DESCRIPTION

This module provides a file handle object for use by
Bric::Util::FTP::Server.

=head1 INTERFACE

This module inherits from Net::FTPServer::FileHandle and overrides the
required methods.  This class is used internally by Bric::Util::FTP::Server.

=head2 Constructors

=over 4

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Carp qw(croak confess);
use Bric::Config qw(:ftp);
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::App::Authz qw(:all);
use Bric::Util::Burner;
use Bric::Biz::Asset::Formatting;
use Bric::Util::FTP::DirHandle;
use Net::FTPServer::FileHandle;
use IO::Scalar;

################################################################################
# Inheritance
################################################################################
our @ISA = qw(Net::FTPServer::FileHandle);

=pod

=item new($ftps, $template, $category_id)

Creates a new Bric::Util::FTP::FileHandle object.  Requires three
arguments - the Bric::Util::FTP::Server object, the
Bric::Biz::Asset::Formatting object that this filehandle represents
(aka the template object), and the category_id which this file is in.

=cut

sub new {
  my $class = shift;
  my $ftps = shift;
  my $template = shift;
  my $category_id = shift;
  
  my $filename =  $template->get_file_name;
  $filename = substr($filename, rindex($filename, '/') + 1);

  # Create object.
  my $self = Net::FTPServer::FileHandle->new ($ftps, $filename);
  
  $self->{template} = $template;
  $self->{category_id} = $category_id;
  $self->{filename} = $filename;

  print STDERR __PACKAGE__, "::new() : ", $template->get_file_name, "\n" 
    if FTP_DEBUG;
  
  return bless $self, $class;
}

=back

=head2 Public Instance Methods

=over 4

=item open($mode)

This method opens this template object for access using the provided
mode ('r', 'w' or 'a').  The method returns an IO::Scalar object that
will be used by Net::FTPServer to access the template text.  For
read-only access a plain IO::Scalar object is returned.  For
write-methods an internal tied class -
Bric::Util::FTP::FileHandle::SCALAR - is used with IO::Scalar to
provide write-access to the data in the database.  Returns undef on
failure.

=cut

# Open the file handle.
sub open {
  my $self = shift;
  my $mode = shift;
  my $template = $self->{template};
  
  print STDERR __PACKAGE__, "::open('$mode') : ", $template->get_file_name, "\n" 
    if FTP_DEBUG;

  if ($mode eq "r") {
    # check write access
    return undef unless $self->can_read;

    # reads are easy - just return an IO::Scalar with the template data
    my $data = $template->get_data;
    return new IO::Scalar \$data;
  } elsif ($mode eq "w" or $mode eq "a") {
    # check write access
    return undef unless $self->can_write;

    # first clear the data unless appending
    $template->set_data('') 
      unless $mode eq 'a';

    # create a tied scalar and return an IO::Scalar attached to it
    my $data;
    tie $data, 'Bric::Util::FTP::FileHandle::SCALAR', $template;
    my $handle = new IO::Scalar \$data;

    # seek if appending
    $handle->seek(length($template->get_data))
      if $mode eq 'a';
    
    return $handle;
  }
}

=item dir()

Returns the directory handle for the category that this template is
in.  Calls Bric::Util::FTP::DirHandle->new().

=cut

sub dir {
  my $self = shift;
  return Bric::Util::FTP::DirHandle->new ($self->{ftps},
                                          $self->dirname,
                                          $self->{category_id});
}

=item status()

This method returns information about the object.  The return value is
a list with seven elements - ($mode, $perms, $nlink, $user, $group,
$size, $time).  To quote the good book (Net::FTPServer::Handle):

          $mode     Mode        'd' = directory,
                                'f' = file,
                                and others as with
                                the find(1) -type option.
          $perms    Permissions Permissions in normal octal numeric format.
          $nlink    Link count
          $user     Username    In printable format.
          $group    Group name  In printable format.
          $size     Size        File size in bytes.
          $time     Time        Time (usually mtime) in Unix time_t format.

$mode is always 'f'.  $perms is set depending on wether the template
is checked out and whether the user has access to edit the template.
$nlink is always 1.  $user is set to the user that has the template
checked out or "nobody" for checked in templates.  $group is "ci" if
the template is checked out, "ci" if it's checked in.  $size is the
size of the template text in bytes.  $time is set to the deploy_time()
of the template.

=cut

sub status {
  my $self = shift;
  my $template = $self->{template};

  print STDERR __PACKAGE__, "::status() : ", $template->get_file_name, "\n";  
  
  my $size = length($template->get_data);
  my $deploy_date = $template->get_deploy_date;
  my $date = 0;
  if ($deploy_date) {
    $date = local_date($deploy_date, 'epoch');
  }

  my $owner = $template->get_user__id;
  if ($owner) {

    # if checked out, get the username return read-only
    my $user = Bric::Biz::Person::User->lookup({id => $owner});
    my $login = defined $user ? $user->get_login : "unknown";
    return ( 'f', 0444, 1, $login, "co", $size,  $date);

  } else {
    # otherwise check for write privs - can't use chk_authz because it
    # works with the web login caching system.
    my $priv = $self->{ftps}{user_obj}->what_can($template);
    my $mode;
    if ($priv == EDIT or $priv == CREATE) {
      $mode = 0777;
    } else {
      $mode = 0400;
    }
    return ( 'f', $mode, 1, "nobody", "ci", $size,  $date);
  }


}

=item can_*()

Returns permissions information for various activites.  can_read()
always returns 1 since templates can always be read.  can_rename() and
can_delete() return 0 since these operations are not yet supported.
can_write() and can_append() return 1 if the user can write to the
template - if it's checked in and the user has permission.

=cut

# fixed properties
sub can_read   {  1; }
sub can_rename {  0; }
sub can_delete {  0; }

# check to see if template is checked out
sub can_write  { 
  my $self = shift;
  my @stats = $self->status();

  # this should probably be a real bit test for u+w
  if ($stats[1] == 0777) {
    return 1;
  } else {
    return 0;
  }
}
*can_append = \&can_write;

=back

=head1 PRIVATE

=head2 Private Classes

=over 4

=item Bric::Util::FTP::FileHandle::SCALAR

This class provides a tied scalar interface to a template object's
data.  The TIESCALAR constructor takes a template object as a single
argument.  Writes to the tied scalar result in the template object
being altered, saved, checked-in and deployed.

=back

=cut

package Bric::Util::FTP::FileHandle::SCALAR;
use strict;
use warnings;

use Bric::Config qw(FTP_DEBUG);
use Bric::Util::Time qw(:all);

sub TIESCALAR {
  my $pkg = shift;
  my $template = shift;
  my $self = { template => $template };
  print STDERR __PACKAGE__, "::TIESCALAR()\n" if FTP_DEBUG;
  return bless $self, $pkg;
}

sub FETCH {
  my $self = shift;
  print STDERR __PACKAGE__, "::FETCH()\n" if FTP_DEBUG;
  return $self->{template}->get_data();
}

sub STORE {
  my $self = shift;
  my $data = shift;
  my $template = $self->{template};
  print STDERR __PACKAGE__, "::STORE()\n" if FTP_DEBUG;

  # save the new code
  $template->set_data($data);
  $template->save();

  # get a new burner
  my $burner = Bric::Util::Burner->new;

  # deploy and save
  $burner->deploy($template);
  $template->set_deploy_date(strfdate());
  $template->set_deploy_status(1);
  $template->save();

  # get the current desk
  my $desk = $template->get_current_desk;

  # remove from desk
  if ($desk) {
    $desk->remove_asset($template);
    $desk->save;
  } 

  # clear the workflow ID
  $template->set_workflow_id(undef);
  $template->save;

  return $data;
}

1;

__END__

=pod

=head1 AUTHOR

Sam Tregar (stregar@about-inc.com)

=head1 SEE ALSO

Net:FTPServer::FileHandle, Bric::Util::FTP::Server, Bric::Util::FTP::DirHandle

=cut
