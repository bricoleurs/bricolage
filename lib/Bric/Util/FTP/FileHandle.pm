package Bric::Util::FTP::FileHandle;

=pod

=head1 NAME

Bric::Util::FTP::FileHandle - Virtual FTP Server FileHandle

=head1 VERSION

1.0

=cut

our $VERSION = "1.0";

=pod

=head1 DATE

$Date: 2001-10-02 16:23:59 $

=head1 DESCRIPTION

This module provides a file handle object for use by
Bric::Util::FTP::Server.

=head1 AUTHOR

Sam Tregar (stregar@about-inc.com

=head1 SEE ALSO

Bric::Util::FTP::Server

=head1 REVISION HISTORY

$Log: FileHandle.pm,v $
Revision 1.1  2001-10-02 16:23:59  samtregar
Added FTP interface to templates


=cut

use strict;
use warnings;

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

our @ISA = qw(Net::FTPServer::FileHandle);

# return a new file handle.
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

# the directory handle for this file.
sub dir {
  my $self = shift;
  return Bric::Util::FTP::DirHandle->new ($self->{ftps},
                                          $self->dirname,
                                          $self->{category_id});
}

# get stat for this file
sub status {
  my $self = shift;
  my $template = $self->{template};

  print STDERR __PACKAGE__, "::status() : ", $template->get_file_name, "\n";  
  
  my $size = length($template->get_data);
  my $date = local_date($template->get_deploy_date, 'epoch');

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
