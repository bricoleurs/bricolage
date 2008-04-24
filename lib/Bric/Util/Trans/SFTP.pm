package Bric::Util::Trans::SFTP;

=head1 NAME

Bric::Util::Trans::SFTP - SFTP Client interface for distributing resources.

=head1 VERSION

$LastChangedRevision$

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 SYNOPSIS

  use Bric::Util::Trans::SFTP

=head1 DESCRIPTION

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
use Net::SFTP;
use Net::SFTP::Attributes;
use Net::SFTP::Constants qw(:flags :status);
use Net::SFTP::Util qw(fx2txt);
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
my ($no_warn, $sftp_args);

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

=head1 INTERFACE

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

        # Instantiate a Net::SFTP object and login.

        (my $hn = $s->get_host_name) =~ s/:\d+$//;
        my $sftp = eval {
            local $^W; # Silence Net::SFTP warnings.
            Net::SFTP->new($sftp_args->($s));
        };

        throw_gen error   => "Unable to login to remote server '$hn'.",
                  payload => $@
          if $@;

        # Get the document root.
        my $doc_root = $s->get_doc_root;

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
                    $sftp->do_opendir($fs->cat_dir($doc_root, $dest_dir));
                };
                unless (defined $dirhandle) {
                    # The directory doesn't exist.
                    # Get the list of all of the directories.
                    my $attrs = Net::SFTP::Attributes->new();
                    my $subdir = $doc_root;
                    foreach my $dir ($fs->split_uri($dest_dir)) {
                        # Create each one if it doesn't exist.
                        $subdir = $fs->cat_dir($subdir, $dir);
                        # Mark that we've created it, so we don't try to do it
                        # again.
                        $dirs{$subdir} = 1;
                        $dirhandle = eval{
                            local $SIG{__WARN__} = $no_warn;
                            $sftp->do_opendir($subdir);
                        };
                        unless (defined $dirhandle) {
                            $status = eval {
                                local $SIG{__WARN__} = $no_warn;
                                $sftp->do_mkdir($subdir, $attrs);
                            };
                            unless (defined $status && $status == SSH2_FX_OK) {
                                my $msg = "Unable to create directory '$subdir'"
                                  . " on remote server '$hn'";
                                throw_gen(error => $msg);
                            }
                        } else {
                            $sftp->do_close($dirhandle);
                        }
                    }
                } else {
                    $sftp->do_close($dirhandle);
                }
            }
            # Now, put the file on the server.
            my $dest_file = $fs->cat_dir($doc_root, $res->get_uri);
            my $tmp_dest = $dest_file . '.tmp';
            $status = eval{
                local $SIG{__WARN__} = $no_warn;
                $sftp->do_remove($tmp_dest) if FTP_UNLINK_BEFORE_MOVE;
                $sftp->put($src, $tmp_dest);
                $sftp->do_remove($dest_file) if FTP_UNLINK_BEFORE_MOVE;
                $sftp->do_rename($tmp_dest, $dest_file);
            };
            unless (defined $status && $status == SSH2_FX_OK) {
                my $msg = "Unable to put file '$dest_file' on remote host"
                  . " '$hn', status '" . fx2txt($status) . "'";
                throw_gen(error => $msg);
            }
        }
        # how do you logout???
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

        # Instantiate a Net::SFTP object and login.
        (my $hn = $s->get_host_name) =~ s/:\d+$//;
        my $sftp = eval {
            local $^W; # Silence Net::SFTP warnings.
            Net::SFTP->new($sftp_args->($s));
        };

        throw_gen error   => "Unable to login to remote server '$hn'.",
                  payload => $@
          if $@;

        # Get the document root.
        my $doc_root = $s->get_doc_root;
        foreach my $res (@$resources) {
            # Get the name of the file to be deleted.
            my $file = $fs->cat_uri($doc_root, $res->get_uri);
            my $status = eval{
                local $SIG{__WARN__} = $no_warn;
                $sftp->do_stat($file);
            };
            if (defined $status) {
                # It exists. Delete it.
                $status = eval{
                    local $SIG{__WARN__} = $no_warn;
                    $sftp->do_remove($file);
                };
                unless (defined $status && $status == SSH2_FX_OK) {
                    my $msg = "Unable to delete resource '$file' from"
                      . "remote host '$hn', status '" . fx2txt($status) . "'.";
                    throw_gen(error => $msg);
                }
            }
        }
        # how do you logout???
        undef $sftp;
    }
    return 1;
}

=back

=head1 PRIVATE

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

=item my @args = $sftp_args->($server);

Pass in a Bric::Dist::Server object to get back a list of arguments suitable
for passing to C<< Net::SFTP->new() >>.

=cut

$sftp_args = sub {
    my $server = shift;

    # Set up the SSH arguments. Make sure we're never mistaken for root.
    # by setting privileged => 0. This comes up with bric_queued.
    my @ssh_args = (privileged => 0);
    if (ENABLE_SFTP_V2 || SFTP_MOVER_CIPHER) {
        push @ssh_args, protocol => '2,1' if ENABLE_SFTP_V2;
        push @ssh_args, cipher   => SFTP_MOVER_CIPHER if SFTP_MOVER_CIPHER;
    }

    (my $hn = $server->get_host_name) =~ s/:\d+$//;
    return (
        $hn,
        debug    => DEBUG,
        ssh_args => \@ssh_args,
        user     => $server->get_login,
        password => $server->get_password
    );
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

Scott Lanning E<lt>slanning@theworld.comE<gt>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric::Dist::Action|Bric::Dist::Action>,
L<Bric::Dist::Action::Mover|Bric::Dist::Action::Mover>,
L<Bric::Util::Trans::FS|Bric::Util::Trans::FS>,
L<Net::SFTP|Net::SFTP>,
L<Net::SSH::Perl|Net::SSH::Perl>

=cut
