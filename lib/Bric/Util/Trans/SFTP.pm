package Bric::Util::Trans::SFTP;

=head1 Name

Bric::Util::Trans::SFTP - SFTP Client interface for distributing resources.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Trans::SFTP

=head1 Description

The distribution API uses this class to distribute resources to other servers
via SFTP.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependencies
use Net::SSH2;
use Net::SSH2::File;
use Net::SSH2::SFTP;
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
my ($no_warn);

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

=item my $bool = Bric::Util::Trans::SFTP->put_res($resources, $st)

Puts the files specified by the $resources object on the servers
specified by $st.

B<Throws:>

=over 4

=item *

Unable to login to remote server.

=item *

Unable to create directory on remote server.

=item *

Unable to put resource on remote server.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Net::SFTP internally.

=cut

sub put_res {
    my ($pkg, $resources, $st) = @_;

    # Set HOME environment variable for SSH client
    local $ENV{HOME} = SFTP_HOME if SFTP_HOME;

    foreach my $s ($st->get_servers) {
        # Skip inactive servers.
        next unless $s->is_active;

        # Instantiate a Net::SSH2 object and login.

        (my $hn = $s->get_host_name) =~ s/:\d+$//;
        my $user = $s->get_login;
        my $password = $s->get_password;

        my $ssh2 = Net::SSH2->new();
        my $connect = eval {
            $ssh2->connect($hn);
            $ssh2->method('CRYPT_CS', SFTP_MOVER_CYPHER ) if SFTP_MOVER_CIPHER;
            $ssh2->auth( username => $user, password => $password );
        };
        throw_gen error   => "Unable to login to remote server '$hn'.",
                  payload => $@
          if $@;

        # Get the document root.
        my $doc_root = $s->get_doc_root;

        # Create a Net::SSH2::SFTP object to use later
        my $sftp = $ssh2->sftp;

        # Now, put each file on the remote server.
        my %dirs;
        foreach my $res (@$resources) {
            # Get the source and destination paths for the resource.
            my $src = $res->get_tmp_path || $res->get_path;
            # Create the destination directory if it doesn't exist and we
            # haven't created it already.
            my $dest_dir = $fs->uri_dir_name($res->get_uri);
            my ($status, $dirhandle);
            unless ($dirs{$dest_dir}) {
                $dirhandle = eval {
                    local $SIG{__WARN__} = $no_warn;
                    $sftp->opendir($fs->cat_dir($doc_root, $dest_dir));
                };
                unless (defined $dirhandle) {
                    # The directory doesn't exist.
                    # Get the list of all of the directories.
                    my $subdir = $doc_root;
                    foreach my $dir ($fs->split_uri($dest_dir)) {
                        # Create each one if it doesn't exist.
                        $subdir = $fs->cat_dir($subdir, $dir);
                        # Mark that we've created it, so we don't try to do it
                        # again.
                        $dirs{$subdir} = 1;
                        $dirhandle = eval{
                            local $SIG{__WARN__} = $no_warn;
                            $sftp->opendir($subdir);
                        };
                        unless (defined $dirhandle) {
                            $status = eval {
                                local $SIG{__WARN__} = $no_warn;
                                $sftp->mkdir($subdir);
                            };
                            unless (defined $status) {
                                my $msg = "Unable to create directory '$subdir'"
                                  . " on remote server '$hn'";
                                throw_gen(error => $msg);
                            }
                        }
                    }
                }
            }
            # Now, put the file on the server.
            my $dest_file = $fs->cat_dir($doc_root, $res->get_uri);
            # Strip the filename off end of uri and escape it
            my $orig_base = $fs->base_name($dest_file);
            my $escaped_base;
            ($escaped_base = $orig_base) =~ s/(.)/\\$1/g;
            # Strip off directory destination and
              # re-name file with escapes included
            my $base_dir = $fs->dir_name($dest_file);
            my $dest_file_esc = $fs->cat_dir($base_dir, $escaped_base);
            # Create temporary destination and put file on server
            my $tmp_dest = $dest_file . '.tmp';
            my $tmp_dest_esc = $dest_file_esc . '.tmp';
            $status = eval{
                local $SIG{__WARN__} = $no_warn;
                $sftp->unlink($tmp_dest) if FTP_UNLINK_BEFORE_MOVE;
                my $f = $ssh2->scp_put($src, $tmp_dest_esc);
                $sftp->unlink($dest_file) if FTP_UNLINK_BEFORE_MOVE;
                $sftp->rename($tmp_dest, $dest_file);
            };
            unless (defined $status) {
                my $msg = "Unable to put file '$dest_file' on remote host"
                  . " '$hn', status '" . $sftp->error. "'";
                throw_gen(error => $msg);
            }
        }
        # Disconnect and free memory
        $ssh2->disconnect;
        undef $sftp;
    }
    return 1;
}

################################################################################

=item my $bool = Bric::Util::Trans::SFTP->del_res($resources, $st)

Deletes the files specified by the $resources object from the servers
specified by $st.

B<Throws:>

=over 4

=item *

Unable to login to remote server.

=item *

Unable to delete resource from remote server.

=back

B<Side Effects:> NONE.

B<Notes:> See put_res(), above.

=cut

sub del_res {
    my ($pkg, $resources, $st) = @_;

    # Set HOME environment variable for SSH client
    local $ENV{HOME} = SFTP_HOME if SFTP_HOME;

    foreach my $s ($st->get_servers) {
        # Skip inactive servers.
        next unless $s->is_active;

        # Instantiate a Net::SSH2 object and login.
        (my $hn = $s->get_host_name) =~ s/:\d+$//;
        my $user = $s->get_login;
        my $password = $s->get_password;

        my $ssh2 = Net::SSH2->new();
        my $connect = eval {
            $ssh2->connect($hn);
            $ssh2->method('CRYPT_CS', SFTP_MOVER_CYPHER ) if SFTP_MOVER_CIPHER;
            $ssh2->auth( username => $user, password => $password );
        };
        throw_gen error   => "Unable to login to remote server '$hn'.",
                  payload => $@
          if $@;

        # Create a Net::SSH2::SFTP object to use later
        my $sftp = $ssh2->sftp;

        # Get the document root.
        my $doc_root = $s->get_doc_root;
        foreach my $res (@$resources) {
            # Get the name of the file to be deleted.
            my $file = $fs->cat_dir($doc_root, $res->get_uri);
            # Delete the file
            $sftp->unlink($file);
        }

        # Disconnect and free memory
        $ssh2->disconnect;
        undef $sftp;
        undef $ssh2;
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

=over 4

=item local $SIG{__WARN__} = $no_warn;

Anonymous subroutine to prevent warning messages.

B<Throws:> NONE.

B<Notes:> NONE.

=cut

$no_warn = sub { };

=back

=head1 Notes

NONE.

=head1 Author

Scott Lanning E<lt>slanning@theworld.comE<gt>
Sarah Mercier E<lt>mercie_s@denison.eduE<gt>
Charlie Reitsma E<lt>reitsma@denison.eduE<gt>
Matt Rolf E<lt>rolfm@denison.eduE<gt>

=head1 See Also

L<Bric|Bric>,
L<Bric::Dist::Action|Bric::Dist::Action>,
L<Bric::Dist::Action::Mover|Bric::Dist::Action::Mover>,
L<Bric::Util::Trans::FS|Bric::Util::Trans::FS>,
L<Net::SSH2|Net::SSH2>,
L<Net::SSH::Perl|Net::SSH::Perl>

=cut
