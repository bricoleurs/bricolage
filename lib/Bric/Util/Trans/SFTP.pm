package Bric::Util::Trans::SFTP;

=head1 NAME

Bric::Util::Trans::SFTP - SFTP Client interface for distributing resources.

=head1 VERSION

$Revision: 1.4 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.4 $ )[-1];

=head1 DATE

$Date: 2003-07-06 19:20:15 $

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
use Bric::Util::Fault::Exception::GEN;
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
my $gen = 'Bric::Util::Fault::Exception::DP';
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
    my ($pkg, $res, $st) = @_;
    foreach my $s ($st->get_servers) {
	# Skip inactive servers.
	next unless $s->is_active;
	my $hn = $s->get_host_name;
	# Instantiate a Net::SFTP object and login.
	my $sftp = Net::SFTP->new($hn, debug => DEBUG,
                                  ENABLE_SFTP_V2 ? (ssh_args => [ protocol => '2,1' ]) : (),
				  user => $s->get_login,
				  password => $s->get_password)
	  || die $gen->new({msg => "Unable to login to remote server '$hn'." });
	# Get the document root.
	my $doc_root = $s->get_doc_root;

	# Now, put each file on the remote server.
	my %dirs;
	foreach my $r (@$res) {
	    # Get the source and destination paths for the resource.
	    my $src = $r->get_tmp_path || $r->get_path;
	    # Create the destination directory if it doesn't exist and we haven't
	    # created it already.
	    my $dest_dir = $fs->uri_dir_name($r->get_uri);
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
			# Mark that we've created it, so we don't try to do it again.
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
				my $msg = "Unable to create directory '$subdir' on"
				  . " remote server '$hn'";
				die $gen->new({ msg => $msg });
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
	    my $dest_file = $fs->cat_dir($doc_root, $r->get_uri);
	    $status = eval{
		local $SIG{__WARN__} = $no_warn;
		$sftp->put($src, $dest_file);
	    };
	    unless (defined $status && $status == SSH2_FX_OK) {
		my $msg = "Unable to put file '$dest_file' on remote host '$hn',"
		  . " status '" . fx2txt($status) . "'";
		die $gen->new({ msg => $msg });
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
    my ($pkg, $res, $st) = @_;
    foreach my $s ($st->get_servers) {
	# Skip inactive servers.
	next unless $s->is_active;
	my $hn = $s->get_host_name;
	# Instantiate a Net::SFTP object and login.
	my $sftp = Net::SFTP->new($hn, debug => DEBUG,
                                  ENABLE_SFTP_V2 ? (ssh_args => [ protocol => '2,1' ]) : (),
				  user => $s->get_login,
				  password => $s->get_password)
	  || die $gen->new({ msg => "Unable to login to remote server '$hn'." });
	# Get the document root.
	my $doc_root = $s->get_doc_root;
	foreach my $r (@$res) {
	    # Get the name of the file to be deleted.
	    my $file = $fs->cat_uri($doc_root, $r->get_uri);
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
		    die $gen->new({ msg =>  $msg});
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
