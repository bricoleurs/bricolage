package Bric::Util::Trans::WebDAV;

=head1 Name

Bric::Util::Trans::WebDAV - WebDAV Client interface for distributing resources.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Trans::WebDAV

=head1 Description

The distribution API uses this class to distribute resources to other servers
via WebDAV

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use HTTP::DAV;
use Bric::Util::Fault qw(throw_gen);
use Bric::Util::Trans::FS;

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

=item my $bool = Bric::Util::Trans::WebDAV->put_res($resources, $st)

Puts the files specified by the $job object on the servers specified by $st.

B<Throws:>

=over 4

=item *

Unable to create DAV object

=item *

Unable to connect to remote server.

=item *

Unable to login to remote server.

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

B<Notes:> Uses HTTP::DAV internally.

=cut

sub put_res {
    my ($pkg, $resources, $st) = @_;
    foreach my $s ($st->get_servers) {
        # Skip inactive servers.
        next unless $s->is_active;
        (my $hn = $s->get_host_name) =~ s/:\d+$//;

        # Unless specified, hostname is prefixed by http://
        # this should allow a user to user DAV over SSL
        # by using https://hostname/ in Server Profile.

        unless($hn =~ m#^https?://#) {
            $hn = 'http://' . $hn;
        }

        # Get the document root.
        my $doc_root = $s->get_doc_root;

        # Convert it into an url.
        my $base_url = $hn . '/';

        # Instantiate an HTTP::DAV object, define credentials and login.
        my $d = HTTP::DAV->new()
          || throw_gen(error => "Unable to create DAV object.",
                       payload => $@);

        $d->credentials( -user => $s->get_login, 
                         -pass => $s->get_password,
                         -url  => $base_url);

        $d->open( -url => $base_url )
          || throw_gen(error => "Unable to login to remote server '$hn'.",
                       payload => $d->message);

        # Now, put each file on the remote server.
        my %dirs;
        foreach my $res (@$resources) {
            # Get the source and destination paths for the resource.
            my $src = $res->get_tmp_path || $res->get_path;
            my $dest = $fs->cat_uri($doc_root, $res->get_uri);
            # Create the destination directory if it doesn't exist and we haven't
            # created it already.
            my $dest_dir = $fs->uri_dir_name($dest);

            unless ($dirs{$dest_dir} || $d->cwd( -url => $dest_dir )) {
                # The directory doesn't exist.
                # Get the list of all of the directories.
                foreach my $dir ($fs->split_uri($dest_dir)) {
                    # Create each one if it doesn't exist.
                    unless ($d->cwd( -url => $dir)) {

                        if(length($dir)) {
                            $d->mkcol( -url => $dir)
                              || throw_gen(error => "Unable to create directory '$dir' " .
                                             "in path '$dest_dir' on remote server " .
                                             "'$hn'.", payload => $d->message);

                            $d->cwd($dir)
                              || throw_gen(error => "Unable to change to directory '$dir' " .
                                             "in path '$dest_dir' on remote server " .
                                             "'$hn'.",
                                           payload => $d->message );
                        }
                    }
                }
            }

            # Mark that we've created it, so we don't try to do it again.
            $dirs{$dest_dir} = 1;
            # Go back to root.
            $d->cwd( -url => $doc_root);

            # Now, put the file on the server, using a temporary name.
            my $tmpdest =  $dest . '.tmp';
            $d->put( -local => $src, -url => $tmpdest)
              || throw_gen(error => "Unable to put $src as file '$tmpdest' on remote server '$hn'.",
                           payload => $d->message);

            # Rename the temporary file
            $d->move(-url => $tmpdest, -dest => $dest)
              || throw_gen(error => "Unable to rename file '$tmpdest' " .
                             "to '$dest' on remote server '$hn'.",
                           payload => $d->message);

        }
    }

    return 1;
}

################################################################################

=item my $bool = Bric::Util::Trans::WebDAV->del_res($resources, $st)

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

        # Unless specified, hostname is prefixed by http://
        # this should allow a user to user DAV over SSL
        # by using https://hostname/ in Server Profile.

        unless($hn =~ m#^http(s)?://#) {
            $hn = 'http://' . $hn;
        }

        # Get the document root.
        my $doc_root = $s->get_doc_root;

        # Convert it into an url.
        $doc_root = $hn . '/'. $doc_root;

        # Instantiate an HTTP::DAV object, define credentials and login.
        my $d = HTTP::DAV->new()
          || throw_gen(error => "Unable to create DAV object.",
                       payload => $@);

        $d->credentials( -user => $s->get_login, 
                         -pass => $s->get_password,
                         -url  => $doc_root);

        $d->open( -url => $doc_root )
          || throw_gen(error => "Unable to login to remote server '$hn'.",
                       payload => $d->message);

        foreach my $res (@$resources) {
            # Get the name of the file to be deleted.
            my $file = $fs->cat_uri($doc_root, $res->get_uri);

            my $resource = $d->propfind( -url => $file);
            if ($resource && $resource->get_property("getcontentlength") > -1) {
                # It exists. Delete it.
                $d->delete(-url => $file)
                  || throw_gen(error => "Unable to delete resource '$file' "
                                 . "from remote server '$hn'.",
                               payload => $d->message);
            }
        }
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

Joao Pedro Goncalves E<lt>joaop@co.sapo.pt<gt>

=head1 See Also

L<Bric|Bric>,
L<Bric::Dist::Action|Bric::Dist::Action>,
L<Bric::Dist::Action::Mover|Bric::Dist::Action::Mover>,
L<Bric::Util::Trans::FS|Bric::Util::Trans::FS>

=cut
