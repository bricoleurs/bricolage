package Bric::Util::Job::Dist;

=head1 Name

Bric::Util::Job::Dist - Manages Bricolage distribution jobs.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Job::Dist;

  my $id = 1;
  my $format = "%D %T";

  # Constructors.
  my $job = Bric::Util::Job::Dist->new($init);
  $job = Bric::Util::Job::Dist->lookup({ id => $id });
  my @jobs = Bric::Util::Job::Dist->list($params);

  # Class Methods.
  my @job_ids = Bric::Util::Job::Dist->list_ids($params);

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

This class manages distribution jobs. A job is a list of things to be
transformed by actions and moved out, all at a scheduled time. The idea is that
Bricolage will schedule a job and then it will be executed at its scheduled
times. There are two types of jobs, "Deliver" and "Expire".

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:dist :temp STAGE_ROOT);
use File::Spec::Functions qw(catdir);
use Bric::Util::Time qw(:all);
use Bric::Util::Class;
use Bric::App::Event qw(log_event);
use Bric::Dist::Action::Mover;

################################################################################
# Constants
################################################################################
use constant KEY_NAME => 'dist_job';
use constant CLASS_ID => 79;

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

=head3 my (@jobs || $jobs_aref) = Bric::Util::Job::Dist->list($params)

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

For each of the server types associated with this job, the list of actions
will be performed on each file, hopefully culminating in the distribution of
the resources to the servers associated with the server type. At the end of
the process, a completion time will be saved to the database. Attempting to
execute a job before its scheduled time will throw an exception.

B<Throws:> Quite a few exceptions can be thrown here. Check the do_it() methods
on all Bric::Dist::Action subclasses, as well as the put_res() methods of the
mover classes (e.g., Bric::Util::Trans::FS). Here are the exceptions thrown from
withing this method itself.

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
    # Grab all of the resources.
    my $resources = $self->get_resources;
    # Figure out what we're doing here.
    if ($self->get_type) {
        # This is an expiration job.
        foreach my $st ($self->get_server_types) {
            # Go through the actions in reverse order.
            foreach my $a (reverse $st->get_actions) {
                # Undo the action.
                my $ret = $a->undo_it($resources, $st);
                if ($ret) {
                    my $type = $a->get_type;
                    next if $type eq 'Move';
                    log_event('resource_undo_action', $_, { Action => $type })
                      for @$resources;
                }
            }
        }

        # Always log that the document was expired.
        if (my $vid = $self->get_story_instance_id) {
            my $doc = Bric::Biz::Asset::Business::Story->lookup({
                version_id => $vid,
            });
            log_event(story_expire => $doc);
        }

        elsif ($vid = $self->get_media_instance_id) {
            my $doc = Bric::Biz::Asset::Business::Media->lookup({
                version_id => $vid,
            });
            log_event(media_expire => $doc);
        }

    } else {
        # A Delivery job. Go through the server types one at a time.
        foreach my $st ($self->get_server_types) {
            if ($st->can_copy) {
                # The resources should be copied to a temporary directory.
                my $fs = Bric::Util::Trans::FS->new;
                foreach my $res (@$resources) {
                    # Create the temporary resource path.
                    my $path = $res->get_path;
                    my $tmp_path = catdir TEMP_DIR, $path;
                    # Copy the resources to the tmp location.
                    $fs->copy($path, $tmp_path);
                    # Add the temporary path to the resource.
                    $res->set_tmp_path($tmp_path);
                }
            }
            # Okay, we know where the resources are on disk. Let's
            # perform each of the actions in turn.
            foreach my $a ($st->get_actions) {
                # Execute the action.
                $a->do_it($resources, $st);
                # Grab the action type and log the action for each resource.
                my $type = $a->get_type;
                next if $type eq 'Move';
                log_event('resource_action', $_, { Action => $type })
                  for @$resources;
            }
        }
    }
    return $self;
}

__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@kineticode.com>

Mark Jaroski <jaroskim@who.int>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::Job>

=cut
