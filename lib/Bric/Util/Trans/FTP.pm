package Bric::Util::Trans::FTP;

=head1 Name

Bric::Util::Trans::FTP - FTP Client interface for distributing resources.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Trans::FTP

=head1 Description

The distribution API uses this class to distribute resources to other servers
via FTP.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Net::FTP;
use Bric::Util::Fault qw(throw_gen);
use Bric::Util::Trans::FS;
use Bric::Config qw(:dist);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $fs = Bric::Util::Trans::FS->new;

################################################################################

################################################################################
# Instance Fields
BEGIN { Bric::register_fields() }

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

NONE.

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

NONE.

=head2 Public Functions

=over

=item my $bool = Bric::Util::Trans::FTP->put_res($resources, $st)

Puts the files specified by the $job object on the servers specified by $st.

B<Throws:>

=over 4

=item *

Unable to connect to remote server.

=item *

Unable to login to remote server.

=item *

Unable to change to binary mode on remote server.

=item *

Unable to create directory on remote server.

=item *

Unable to put resource on remote server.

=item *

Unable to rename resource on remote server.

=item *

Unable to properly close connection to remote server.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Net::FTP internally. Unfortunately, except for connecting to the
remote server, Net::FTP provides no error messages for failures. This will make
debugging more difficult, but there's not much to be done. Hopefully the
generalized error messages will be enough to give system administrators a clue
as to what needs to be changed.

=cut

sub put_res {
    my ($pkg, $resources, $st) = @_;
    foreach my $s ($st->get_servers) {
        # Skip inactive servers.
        next unless $s->is_active;
        (my $hn = $s->get_host_name) =~ s/:\d+$//;
        my $is_win = $s->get_os eq 'Win32';
        # Instantiate an FTP object, login, and change to binary mode.
        my $ftp = Net::FTP->new($hn, Debug => DEBUG)
          or throw_gen error   => "Unable to connect to remote server '$hn'.",
                       payload => $@;
        $ftp->login($s->get_login, $s->get_password)
          or throw_gen error   => "Unable to login to remote server '$hn'.",
                       payload => $ftp->message;
        $ftp->binary
          or throw_gen error   => 'Unable to change to binary mode on' .
                                  " remote server '$hn'.",
                       payload => $ftp->message;

        # Get the FTP and document roots.
        my $ftp_root = $ftp->pwd || '/';
        my $doc_root = $s->get_doc_root;

        # Now, put each file on the remote server.
        my %dirs;
        foreach my $res (@$resources) {
            # Get the source and destination paths for the resource.
            my $src = $res->get_tmp_path || $res->get_path;
            my $dest = $fs->cat_uri($doc_root, $res->get_uri);
            # Create the destination directory if it doesn't exist and we haven't
            # created it already.
            my $dest_dir = $fs->uri_dir_name($dest);
            unless ($dirs{$dest_dir}) {
                unless ($ftp->cwd($dest_dir)) {
                    # The directory doesn't exist.
                    # Get the list of all of the directories.
                    foreach my $dir ($fs->split_uri($dest_dir)) {
                        # Create each one if it doesn't exist.
                        unless ($ftp->cwd($dir)) {
                            $ftp->mkdir($dir);
                            $ftp->cwd($dir) or throw_gen
                              error   => "Unable to create directory '$dir'" .
                                         " in path '$dest_dir' on remote" .
                                         " server '$hn'.",
                              payload => $ftp->message;
                        }
                    }
                }
                # Mark that we've created it, so we don't try to do it again.
                $dirs{$dest_dir} = 1;
                # Go back to root.
                $ftp->cwd($ftp_root);
            }

            # Delete any existing copy of the temp file if the FTP server is
            # Windows or if Bricolage has been explicitly configured to do so.
            my $tmpdest = $dest . '.tmp';
            $ftp->delete($tmpdest) if ($is_win or FTP_UNLINK_BEFORE_MOVE);

            # Now, put the file on the server.
            $ftp->put($src, $tmpdest)
              or throw_gen error => "Unable to put file '$tmpdest' on remote" .
                                  " server '$hn'",
                         payload => $ftp->message;

            # Delete any existing copy of the file if the FTP server is Windows
            # or if Bricolage has been explicitly configured to do so.
            $ftp->delete($dest) if ($is_win or FTP_UNLINK_BEFORE_MOVE);

            # Rename the temporary file.
            $ftp->rename($tmpdest, $dest)
              or throw_gen error => "Unable to rename file '$tmpdest' to" .
                                  " '$dest' on remote server '$hn'.",
                         payload => $ftp->message;
        }
        # Log off.
        $ftp->quit
          or throw_gen error => 'Unable to properly close connection to' .
                              " remote server '$hn'.",
                     payload => $ftp->message;
    }
    return 1;
}

################################################################################

=item my $bool = Bric::Util::Trans::FTP->del_res($resources, $st)

Deletes the files specified by the $job object from the servers specified by
$st.

B<Throws:>

=over 4

=item *

Unable to connect to remote server.

=item *

Unable to login to remote server.

=item *

Unable to delete resource from remote server.

=item *

Unable to properly close connection to remote server.

=back

B<Side Effects:> NONE.

B<Notes:> See put_res(), above.

=cut

sub del_res {
    my ($pkg, $resources, $st) = @_;
    foreach my $s ($st->get_servers) {
        # Skip inactive servers.
        next unless $s->is_active;
        (my $hn = $s->get_host_name) =~ s/:\d+$//;
        # Instantiate an FTP object and login.
        my $ftp = Net::FTP->new($hn, Debug => DEBUG)
          or throw_gen error   => "Unable to connect to remote server '$hn'.",
                       payload => $@;
        $ftp->login($s->get_login, $s->get_password)
          or throw_gen "Unable to login to remote server '$hn'.";

        # Get the document root.
        my $doc_root = $s->get_doc_root;
        foreach my $res (@$resources) {
            # Get the name of the file to be deleted.
            my $file = $fs->cat_uri($doc_root, $res->get_uri);

            # Get the directory to ls, and the file we are looking for
            my $fn   = $fs->base_name($file);
            my $fd   = $fs->dir_name($file);

            # List the target directory.
            my @ftpres  = $ftp->ls($fd);

            # Walk the directory listing looking for the file.
            # The directory listing can include the path.
            foreach my $f (@ftpres) {
                next unless $fs->base_name($f) eq $fn;
                # It exists. Delete it.
                $ftp->delete($file)
                  or throw_gen error => "Unable to delete resource '$file'" .
                                      " from remote server '$hn'.",
                             payload => $ftp->message;
                last;
            }
        }
        $ftp->quit
          or throw_gen error => 'Unable to properly close connection to' .
                                " remote server '$hn'.";
    }
    return 1;
}

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler E<lt>david@justatheory.comE<gt>

=head1 See Also

L<Bric|Bric>,
L<Bric::Dist::Action|Bric::Dist::Action>,
L<Bric::Dist::Action::Mover|Bric::Dist::Action::Mover>,
L<Bric::Util::Trans::FS|Bric::Util::Trans::FS>

=cut
