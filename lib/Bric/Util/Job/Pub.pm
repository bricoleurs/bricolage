package Bric::Util::Job::Pub;

=head1 Name

Bric::Util::Job::Pub - Manages Bricolage publishing jobs.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Job::Pub;

  my $id = 1;
  my $format = "%D %T";

  # Constructors.
  my $job = Bric::Util::Job::Pub->new($init);
  $job = Bric::Util::Job::Pub->lookup({ id => $id });
  my @jobs = Bric::Util::Job::Pub->list($params);

  # Class Methods.
  my @job_ids = Bric::Util::Job::Pub->list_ids($params);

  # Instance Methods
  my $id = $job->get_id;

  my $type = $job->get_type;
  $job = $job->set_type($type);

  my $sched_time = $job->get_sched_time($format);
  $job = $job->set_sched_time($sched_time);
  my $comp_time = $job->get_comp_time($format);

  my @resources = $job->get_resources;
  my @resource_ids = $job->get_resource_ids;
  $job = $job->set_resource_ids(@resource_ids);

  my @server_types = $job->get_server_types;
  my @server_type_ids = $job->get_server_type_ids;
  $job = $job->set_server_type_ids(@server_type_ids);

  # Save the job.
  $job = $job->save;

  # Cancel the job.
  $job = $job->cancel;

  # Execute the job.
  $job = $job->execute_me;

=head1 Description

This class manages publishing jobs. A publishing job designates that a given
Story or Media object will be published by a Burner at a given time. Publishing
jobs create distribution jobs as they are run. Jobs which fail in execution are
tried again, and eventually if the failure continues marked as 'failed'.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:dist :temp :time STAGE_ROOT);
use File::Spec::Functions qw(catdir);
use Bric::Util::Time qw(:all);
use Bric::Util::Burner;
use Bric::Util::Burner::Mason;
use Bric::Biz::Asset::Business::Media;
use Bric::Biz::Asset::Business::Media::Audio;
use Bric::Biz::Asset::Business::Media::Image;
use Bric::Biz::Asset::Business::Media::Video;
use Bric::Biz::Asset::Business::Story;

################################################################################
# Constants
################################################################################
use constant KEY_NAME => 'pub_job';
use constant CLASS_ID => 80;

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Util::Job);

################################################################################
# Private Class Fields
my $dp = 'Bric::Util::Fault::Exception::DP';
my $gen = 'Bric::Util::Fault::Exception::GEN';

################################################################################

=head2 Constructors

=head3 my (@jobs || $jobs_aref) = Bric::Util::Job::Pub->list($params)

Inherited from L<Bric::Util::Job|Bric::Util::Job>

=head3 my (@job_ids || $job_ids_aref) = Bric::Util::Job->list_ids($params)

Inherited from L<Bric::Util::Job|Bric::Util::Job>

=head2 Private Instance Methods

=cut

################################################################################

=head3 $self = $job->_do_it

Carries out the actions that constitute the job. This method is called by
C<execute_me()> in Bric::Dist::Job and should therefore never be called
directly.

Sends the Story or Media object contained by the job to the burner. In case of
a template error the job is released to be executed again. Three such errors
are considered a failure, in which case the job is marked as such. The most
recent error message is stored in the error_message field. At the end of the
process, a completion time will be saved to the database. Attempting to
execute a job before its scheduled time will throw an exception.

B<Throws:> Quite a few exceptions can be thrown here. Check the do_it()
methods on all Bric::Publish::Action subclasses, as well as the put_res()
methods of the mover classes (e.g., Bric::Util::Trans::FS). Here are the
exceptions thrown from withing this method itself.

=over 4

=item *

Cannot execute job before its scheduled time.

=item *

Cannot execute job that has already been executed.

=item *

Can't get a lock on job.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_it {
    my $self = shift;
    my $burner = Bric::Util::Burner->new({ out_dir => STAGE_ROOT });
    $burner->_set(['_notes'] => $self->{notes}) if $self->{notes};

    # Check to see if we have story or media id
    if (my $sid = $self->get_story_instance_id) {
        # Instantiate the story.
        my $s = Bric::Biz::Asset::Business::Story->lookup({
            version_id => $sid,
        });
        $burner->publish($s, 'story', $self->get_user_id,
                         $self->get_sched_time(ISO_8601_FORMAT), 1);
    } elsif (my $mid = $self->get_media_instance_id) {
        # Instantiate the media.
        my $m = Bric::Biz::Asset::Business::Media->lookup({
            version_id => $mid,
        });
        $burner->publish($m, 'media', $self->get_user_id,
                         $self->get_sched_time(ISO_8601_FORMAT), 1);
    }

    return $self;
}

__END__

=head1 Notes

NONE.

=head1 Author

Mark Jaroski <jaroskim@who.int>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::Job>

=cut

