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
use Bric::Util::ApacheUtil qw(unescape_uri);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

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

    foreach my $server ($st->get_servers) {
        # Skip inactive servers.
        next unless $server->is_active;

        # Connect via SSH2 and establish SFTP channel.
        my $ssh2     = _connect($server);
        my $sftp     = $ssh2->sftp;
        my $doc_root = $server->get_doc_root;
        my $hn       = $server->get_host_name;

        # Now, put each file on the remote server.
        my %dirs;
        foreach my $res (@$resources) {
            # Get the source and destination paths for the resource.
            my $src = $res->get_tmp_path || $res->get_path;
            # Create the destination directory if it doesn't exist and we
            # haven't created it already.
            my $dest_dir = $fs->dir_name(unescape_uri $res->get_uri);
            my ($status, $dirhandle);
            unless ($dirs{$dest_dir}++ or $sftp->opendir($fs->cat_dir(
                $doc_root, substr $dest_dir, 1
            ))) {
                # The directory doesn't exist. So create it.
                my $subdir = $doc_root;
                foreach my $dir ($fs->split_dir($dest_dir)) {
                    # Check for existence of subdirectory.
                    $subdir = $fs->cat_dir($subdir, $dir);
                    $dirs{$subdir} = 1;
                    unless ($sftp->opendir($subdir)) {
                        # Doesn't exist, so create it.
                        $sftp->mkdir($subdir) or throw_gen(
                            error   => "Error creating directory '$subdir' on '$hn'",
                            payload => ($sftp->error)[1],
                        )
                    }
                }
            }

            # Now, put the file on the server.
            my $dest_file = $fs->cat_file(
                $doc_root, unescape_uri substr $res->get_uri, 1
            );
            my $temp_dest = "$dest_file.tmp";

            $sftp->unlink($temp_dest) if FTP_UNLINK_BEFORE_MOVE;
            $ssh2->scp_put($src, $temp_dest) or throw_gen(
                error   => "Error putting file '$dest_file' on '$hn'",
                payload => join ' ', $ssh2->error
            );
            $sftp->unlink($dest_file) if FTP_UNLINK_BEFORE_MOVE;
            $sftp->rename($temp_dest, $dest_file) or throw_gen(
                error   => "Error renaming '$temp_dest' to '$dest_file' on '$hn'",
                payload => join ' ', $sftp->error
            );
        }

        # Disconnect.
        $ssh2->sock->close;
        $ssh2->disconnect;
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

    foreach my $server ($st->get_servers) {
        # Skip inactive servers.
        next unless $server->is_active;

        # Connect via SSH2 and establish SFTP channel.
        my $ssh2     = _connect($server);
        my $sftp     = $ssh2->sftp;
        my $doc_root = $server->get_doc_root;
        my $hn       = $server->get_host_name;

        foreach my $res (@$resources) {
            # Get the name of the file to be deleted.
            my $file = $fs->cat_file(
                $doc_root, unescape_uri substr $res->get_uri, 1
            );
            # Delete the file
            $sftp->unlink($file) or throw_gen(
                error   => "Error deleting '$file' on '$hn'",
                payload => join ' ', $sftp->error,
            );
        }

        # Disconnect.
        $ssh2->sock->close;
        $ssh2->disconnect;
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

=item _connect

Establishes an SSH2 connection.

=cut

sub _connect_to {
    my $server = shift;

    my $hn   = $server->get_host_name;
    my $ssh2 = Net::SSH2->new;

    $ssh2->connect(split /:/ => $hn) or trow_gen(
        error   => "Error connecting to '$hn' via SSH2",
        payload => join ' ', $ssh2->error,
    );

    $ssh2->method('CRYPT_CS', SFTP_MOVER_CIPHER ) or throw_gen(
        error   => "Error setting cipher for '$hn' to " . SFTP_MOVER_CIPHER,
        payload => join ' ', $ssh2->error,
    ) if SFTP_MOVER_CIPHER;

    $ssh2->method('HOSTKEY', SFTP_KEY_TYPE ) or throw_gen(
        error   => "Error setting key type to " . SFTP_KEY_TYPE,
        payload => join ' ', $ssh2->error,
    ) if SFTP_KEY_TYPE;

    my $ret = $ssh2->auth(
        ($server->get_login ? (
            username   => $server->get_login,
            password   => $server->get_password,
        ) : ()),
        (SFTP_PUBLIC_KEY_FILE ? (
            publickey  => SFTP_PUBLIC_KEY_FILE,
            privatekey => SFTP_PRIVATE_KEY_FILE,
        ) : ()),
    );
    throw_gen(
        error => "Error authenticating to '$hn' via SSH2",
        payload => join ' ', $ssh2->error,
    ) unless $ret && $ssh2->auth_ok;

    return $ssh2;
}

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
