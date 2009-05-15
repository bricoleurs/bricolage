package Bric::Util::FTP::FileHandle;

=pod

=head1 Name

Bric::Util::FTP::FileHandle - Virtual FTP Server FileHandle

=cut

require Bric; our $VERSION = Bric->VERSION;

=pod

=head1 Description

This module provides a file handle object for use by
Bric::Util::FTP::Server.

=head1 Interface

This module inherits from Net::FTPServer::FileHandle and overrides the
required methods.  This class is used internally by Bric::Util::FTP::Server.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:ftp);
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::App::Authz qw(:all);
use Bric::Util::Burner;
use Bric::Biz::Asset::Template;
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::FTP::DirHandle;
use Net::FTPServer::FileHandle;
use IO::Scalar;
use Bric::Util::Event;

################################################################################
# Inheritance
################################################################################
our @ISA = qw(Net::FTPServer::FileHandle);

=head2 Constructors

=over 4

=cut

=item new($ftps, $template, $site_id, $oc_id, $category_id)

Creates a new Bric::Util::FTP::FileHandle object. Requires three arguments:
the Bric::Util::FTP::Server object, the Bric::Biz::Asset::Template object
that this filehandle represents (aka the template object), and the category_id
for the category that thetemplate is in.

=cut

sub new {
  my $class       = shift;
  my $ftps        = shift;
  my $template    = shift;
  my $site_id     = shift;
  my $oc_id       = shift;
  my $category_id = shift;
  my $deploy      = shift;

  my $filename =  $template->get_file_name;
  $filename = substr($filename, rindex($filename, '/') + 1);

  # Create object.
  my $self = Net::FTPServer::FileHandle->new($ftps, $filename);

  $self->{template}    = $template;
  $self->{category_id} = $category_id;
  $self->{oc_id}       = $oc_id;
  $self->{site_id}     = $site_id;
  $self->{filename}    = $filename;
  $self->{deploy}      = $deploy || FTP_DEPLOY_ON_UPLOAD;

  print STDERR __PACKAGE__, "::new() : ", $template->get_file_name, "\n"
    if FTP_DEBUG;

  return bless $self, $class;
}

=back

=head2 Public Instance Methods

=over 4

=item open($mode)

This method opens this template object for access using the provided mode
('r', 'w' or 'a'). The method returns an IO::Scalar object that will be used
by Net::FTPServer to access the template text. For read-only access a plain
IO::Scalar object is returned. For write-methods an instance of an internal
subclass of IO::Scalar--Bric::Util::FTP::FileHandle::IO--is used to provide
write access to the data in the database. Returns C<undef> on failure.

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

    # Create and return an instance of our subclassed IO::Scalar class.
    my $data = $template->get_data;
    my $handle = Bric::Util::FTP::FileHandle::IO->new(
        \$data,
        template => $template,
        user     => $self->{ftps}{user_obj},
        ftps     => $self->{ftps},
        deploy   => $self->{deploy},
        ftpfh    => $self,
    );

    # seek if appending
    $handle->seek(length $data) if $mode eq 'a';

    return $handle;
  }
}

=item dir()

Returns the directory handle for the category that this template is
in.  Calls Bric::Util::FTP::DirHandle->new().

=cut

sub dir {
  my $self = shift;
  print STDERR __PACKAGE__, "::dir() : ", $self->{template}->get_file_name, "\n"
    if FTP_DEBUG;
  return Bric::Util::FTP::DirHandle->new($self->{ftps},
                                         $self->dirname,
                                         $self->{site_id},
                                         $self->{oc_id},
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
checked out or "nobody" for checked in templates.  $group is "co" if
the template is checked out, "ci" if it's checked in.  $size is the
size of the template text in bytes.  $time is set to the deploy_time()
of the template.

=cut

sub status {
  my $self = shift;
  my $template = $self->{template};

  print STDERR __PACKAGE__, "::status() : ", $template->get_file_name, "\n"
    if FTP_DEBUG;

  my $data = $template->get_data || "";
  my $size = length($data);
  my $date = $template->get_deploy_date('epoch') || 0;

  my $owner = $template->get_user__id;
  if (defined $owner) {

    # if checked out, get the username return read-only
    my $login = 'nobody';
    my $mode = 0444;
    if (my $user = Bric::Biz::Person::User->lookup({id => $owner})) {
        $login = $user->get_login;
        $mode = 0777 if $user->get_id == $self->{ftps}{user_obj}->get_id;
    }

    return ( 'f', $mode, 1, $login, "co", $size,  $date);

  } else {
    # otherwise check for write privs - can't use chk_authz because it
    # works with the web login caching system.
    my $priv = $self->{ftps}{user_obj}->what_can($template);
    my $mode;
    my $twid = $template->get_workflow_id;
    if (!$priv or $priv == DENY) {
        # They can't touch it.
        $mode = 0000;
    } elsif ($priv >= RECALL) {
        # They have full access.
        $mode = 0777;
    } elsif ($twid and my $d = $template->get_current_desk) {
        # See if they have access to the desk.
        if (chk_authz(undef, READ, $d->get_asset_grp, $d->get_grp_ids)
            && $priv >= EDIT) {
            # They have full access.
            $mode = 0777;
        } else {
            # They can read it.
            $mode = 0444;
        }
    } else {
        # They can read it.
        $mode = 0444;
    }
    return ( 'f', $mode, 1, "nobody", "ci", $size,  $date);
  }
}

=item move()

Deploys the template if the new name is the same as the template name followed by
'.deploy'. Otherwise it's a no-op.

=cut
sub move {
    my $self = shift;
    my $dirh = shift;
    my $filename  = shift;
    my $template = $self->{template};
    return 0 unless $filename =~ /\.deploy$/;
    print STDERR __PACKAGE__, "\n\n::move(", $template->get_file_name,
      ",$filename)\n"
      if FTP_DEBUG;

    $self->{deploy} = 1;
    $self->_deploy($template, $self->{ftps}{user_obj});
    return 1;
}

=item delete()

Deletes the current template.  This has the same effect as deleting
the template through the UI - it undeploys the template if it's
deployed and marks it inactive.

=cut

sub delete {
  my $self = shift;
  my $template = $self->{template};

  print STDERR __PACKAGE__, "::delete() : ", $template->get_file_name, "\n"
    if FTP_DEBUG;

  # delete code equivalent to delete callback in
  # comp/widgets/tmpl_prof

  # remove from current desk
  my $desk = $template->get_current_desk;
  if ($desk) {
      $desk->checkin($template);
      $desk->remove_asset($template);
      $desk->save;
  }

  # log the removal
  Bric::Util::Event->new({ key_name  => 'template_rem_workflow',
                           obj       => $template,
                           user      => $self->{ftps}{user_obj},
                         });

  # undeploy and deactivate
  my $burn = Bric::Util::Burner->new;
  $burn->undeploy($template);
  $template->deactivate;
  $template->save;

  # log the deactivation
  Bric::Util::Event->new({ key_name  => 'template_deact',
                           obj       => $template,
                           user      => $self->{ftps}{user_obj},
                         });

  return 1;
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
sub can_rename {  1; }
sub can_delete {  1; }

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


sub _deploy {
    my ($self, $template, $user) = @_;

    # checkin the template
    $template->checkin;

    # remove from desk
    my $cur_desk = $template->get_current_desk;
    unless ($cur_desk && $cur_desk->can_publish) {
        # Find a desk to deploy from.
        my $wf = Bric::Biz::Workflow->lookup({
            id => $template->get_workflow_id
        });
        my $pub_desk;
        foreach my $d ($wf->allowed_desks) {
            $pub_desk = $d and last if $d->can_publish
              && $user->can_do($d, READ);
        }

        unless ($pub_desk) {
            warn "Cannot deploy ", $template->get_name,
              ": no deploy desk\n";
            return;
        }

        # Transfer the template to the publish desk.
        if ($cur_desk) {
            $cur_desk->transfer({ to    => $pub_desk,
                                  asset => $template });
            $cur_desk->save;
        } else {
            $pub_desk->accept({ asset => $template });
        }
        $cur_desk = $pub_desk;

        # Save the deploy desk and log it.
        $pub_desk->save;
        Bric::Util::Event->new({
            key_name  => "template_moved",
            obj       => $template,
            user      => $user,
            attr      => { Desk => $pub_desk->get_name },
        });
    }

    # Make sure they have permission to deploy (publish).
    unless ($user->can_do($template, PUBLISH)) {
        warn "Cannot deploy ", $template->get_name, ": permission denied\n";
        return;
    }

    # Now remove it!
    $cur_desk->remove_asset($template);
    $cur_desk->save;

    # clear the workflow ID
    if ($template->get_workflow_id) {
        $template->set_workflow_id(undef);
        Bric::Util::Event->new({
            key_name  => "template_rem_workflow",
            obj       => $template,
            user      => $user,
        });
    }

    $template->save;
    # get a new burner
    my $burner = Bric::Util::Burner->new;

    # deploy and save
    $burner->deploy($template);
    $template->set_deploy_date(strfdate());
    $template->set_deploy_status(1);
    $template->set_published_version($template->get_current_version);
    $template->save;

    # Be sure to undeploy it from the user's sandbox.
    my $sb = Bric::Util::Burner->new({user_id => $user->get_id });
    $sb->undeploy($template);

    # log the deploy
    Bric::Util::Event->new({
        key_name  => $template->get_deploy_status
          ? 'template_redeploy'
          : 'template_deploy',
        obj       => $template,
        user      => $user,
    });
}

=back

=head1 Private

=head2 Private Classes

=over 4

=item Bric::Util::FTP::FileHandle::IO

This class subclasses IO::Scalar to encapsulate the interface to a template
object's data. The C<new()> constructor takes a scalar variable as a first
argument, followed by a parameter list. The supported parameters are:

=over

=item template

=item user

=item deploy

=item ftps

An instance of the Bric::Util::FTP::Server class.

=item ftpfh

An instance of the Bric::Util::FTP::FileHandle class.

=back

Bric::Util::FTP::FileHandle::IO objects track when data has been written to
the underlying scalar, and, if so, write the data to the underlying template
object when the file handle is closed. It also properly handles deploying the
template to the user's sandbox, and deploying the template to production if
the name of the file ends in ".deploy".

=back

=cut

package Bric::Util::FTP::FileHandle::IO;
use Bric::Config qw(FTP_DEBUG);
use Bric::Util::Time qw(:all);
use Bric::Util::Event;
use Bric::Util::Priv::Parts::Const qw(:all);
use base 'IO::Scalar';

{
    my %data;
    sub new {
        my $self = shift->SUPER::new(shift);
        $data{$self->sref} = { @_ };
        print STDERR __PACKAGE__, "::new()\n" if FTP_DEBUG;
        return $self;
    }

    sub DESTROY { delete $data{\shift()}}

    sub print {
        my $self = shift;
        $data{$self->sref}->{mod} = 1;
        $self->SUPER::print(@_);
    }

    sub syswrite {
        my $self = shift;
        $data{$self->sref}->{mod} = 1;
        $self->SUPER::syswrite(@_);
    }

    sub close {
        my $self = shift;
        my $sref = $self->sref;
        print STDERR __PACKAGE__, "::close()\n" if FTP_DEBUG;

        my ($mod, $template, $user, $ftps) =
          @{$data{$sref}}{qw(mod template user ftps)};

        # Just return if the template has not been modified.
        return 1 unless $mod;

        # Put the template into workflow.
        if (not $template->get_workflow_id) {
            # Recall it into workflow, move it to a desk, and check it out.
            $ftps->move_into_workflow($template)
        } elsif (not $template->get_desk_id) {
            # Move it to the start desk and check it out.
            $ftps->move_onto_desk($template)
        } elsif (not $template->get_checked_out) {
            # Check it out.
            $ftps->check_out($template)
        }

        # save the new code
        $template->set_data($$sref);
        $template->save;

        # log the save
        Bric::Util::Event->new({
            key_name  => 'template_save',
            obj       => $template,
            user      => $user,
        });

        if ($data{$sref}->{deploy}) {
            $data{$sref}->{ftpfh}->_deploy($template, $user);
        } else {
            # Simply deploy it to the user's sandbox.
            my $burner = Bric::Util::Burner->new({user_id => $user->get_id });
            $burner->deploy($template);
        }
        return 1;
    }
}

1;

__END__

=pod

=head1 Author

Sam Tregar <stregar@about-inc.com>

David Wheeler <david@kineticode.com>

=head1 See Also

L<Net:FTPServer::FileHandle|Net:FTPServer::FileHandle>

L<Bric::Util::FTP::Server|Bric::Util::FTP::Server>

L<Bric::Util::FTP::DirHandle|Bric::Util::FTP::DirHandle>

=cut
