package Bric::Util::Trans::S3;

=head1 Name

Bric::Util::Trans::S3 - AWS S3 Client interface for distributing resources.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

    use Bric::Util::Trans::S3

=head1 Description

The distribution API uses this class to distribute resources to AWS S3 buckets.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;
use Net::Amazon::S3;
use File::MimeInfo;

################################################################################
# Programmatic Dependences
use Bric::Util::Fault qw(throw_gen);
use Bric::Util::Trans::FS;
use Bric::Config qw(:dist);
use Bric::Util::ApacheUtil qw(unescape_uri escape_uri);

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

=item my $bool = Bric::Util::Trans::S3->put_res($resources, $st)

Puts the files specified by the $job object into the S3 bucket specified by $st.

B<Throws:>

=over 4

=item *

Unable to connect to AWS API.

=item *

Unable to login to AWS account.

=item *

Unable to set permissions on bucket.

=item *

Unable to put resources into bucket.

=back

B<Side Effects:> NONE.

B<Notes:> 

=cut

sub put_res {
    my ($pkg, $resources, $st) = @_;
    foreach my $s ($st->get_servers) {
        # Skip inactive servers.
        next unless $s->is_active;
        my $s3 = Net::Amazon::S3->new({   
          aws_access_key_id     => $s->get_login,
          aws_secret_access_key => $s->get_password,
          retry                 => 1,
        }) or
	throw_gen 
                error => 'fail',  
                payload => 'login: ' . $s->get_login . "\n" . 'password: ' . $s->get_password;
        # Instantiate the S3 bucket
        my $bucket = $s3->bucket($s->get_host_name);
        foreach my $res (@$resources) {
            # Get the source and destination paths for the resource.
            my $src = $res->get_tmp_path || $res->get_path;
            my $dest = $s->get_doc_root . substr $res->get_uri, 1;
            my $mime = mimetype($src);
            #throw_gen error => 'fail', payload => "src: $src\ndest: $dest\nmime: $mime";
            # store a file in the bucket
            $bucket->add_key_filename( $dest, $src,
                { content_type => $mime, })
            or 
	    throw_gen 
                error => $s3->err,  
                payload => 'src: ' . $src . "\ndest: " . $dest . ' * ' . $s3->errstr;
            # set the ACL so everyone can see the file
            $bucket->set_acl({'acl_short' => 'public-read', 'key' => $dest}) 
            or throw_gen
                error => $s3->err,
                payload => $s3->errstr;

        }
        return 1;
    }
}

################################################################################

=item my $bool = Bric::Util::Trans::S3->del_res($resources, $st)

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
        my $s3 = Net::Amazon::S3->new({
            aws_access_key_id     => $s->get_login,
            aws_secret_access_key => $s->get_password,
            retry                 => 1,
        });
        # Instantiate the S3 bucket
        my $bucket = $s3->bucket($s->get_host_name);
        foreach my $res (@$resources) {
            # Get the name of the file to be deleted.
            my $target = $s->get_doc_root . $res->get_uri;
            $bucket->delete_key($target)
            or throw_gen
                error => $s3->err,
                payload => $s3->errstr;
        
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

David Wheeler E<lt>david@justatheory.comE<gt>

=head1 See Also

L<Bric|Bric>,
L<Bric::Dist::Action|Bric::Dist::Action>,
L<Bric::Dist::Action::Mover|Bric::Dist::Action::Mover>,
L<Bric::Util::Trans::FS|Bric::Util::Trans::FS>

=cut
