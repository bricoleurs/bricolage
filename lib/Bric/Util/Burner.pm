package Bric::Util::Burner;
##############################################################################

=head1 NAME

Bric::Util::Burner - Publishes Business Assets and Deploys Templates

=head1 VERSION

$Revision: 1.31 $

=cut

our $VERSION = (qw$Revision: 1.31 $ )[-1];

=head1 DATE

$Date: 2002-11-06 20:31:57 $

=head1 SYNOPSIS

 use Bric::Util::Burner qw(:modes);

 # Create a new publish object.
 $burner = new Bric::Util::Burner;

 # Deploy a formatting asset.
 $burner = $burner->deploy($formatting_asset);

 # Undeploy a formatting asset.
 $burner = $burner->undeploy($formatting_asset);

 # Burn an asset given an output chanels and category
 $burner->burn_one($asset, $output_channel, $category);

=head1 DESCRIPTION

This module accomplishes two tasks:

=over 4

=item 1

Manages the process of deploying and undeploying of formatting assets
through C<deploy()> and C<undeploy()>.

=item 2

Manages the process of publishing and previewing business assets via the
C<publish()> and C<preview()> methods, respectively. The actual work of
publishing is done by one of Bric::Util::Burner's sub-classes depending on the
C<burner_type> of the asset being published. See L<Bric::Util::Burner::Mason>
and L<Bric::Util::Burner::Template> for details.

=back

=head1 ADDING A NEW BURNER

We anticipate that new Burner sub-classes will be added to the system. Here's
a brief guide to adding a new Burner to Bricolage:

=over 4

=item *

Write Bric::Util::Burner::Foo

You'll need to create a new sub-class of Bric::Util::Burner that implements
three methods - C<new()>, C<chk_syntax()>, and C<burn_one()>. You can use an
existing sub-class as a model for the interface and implementation of these
methods. Make sure that when you execute your templates, you do it in the
namespace reserved by the C<TEMPLATE_BURN_PKG> directive -- get this constant
by adding

  use Bric::Config qw(:burn);

To your new Burner subclass.

=item *

Modify Bric::Biz::AssetType

To use your Burner you'll need to be able to assign elements to it. To do this
edit Bric::Biz::AssetType and add a constant for your burner. For example,
Bric::Util::Burner::Template's constant is C<BURNER_TEMPLATE>. Next, edit the
C<my_meths()> entry for the "burner" type to include an entry for your
constant.

=item *

Modify Bric::Util::Burner

You'll need to make a modification to Bric::Util::Burner to make it call your
module when it sees an element assigned to your burner. The code you're
looking for is in the C<_get_subclass()> method. Add the approprate C<elsif>s
to assign the appropriate class name for your burner.

=item *

Modify Bric::Biz::Asset::Formatting

Here you'll make modifications to support the template files needed by your
burner. Do a search for the string "tmpl" and you'll find the appropriate
sections. This is where you'll setup your naming convention and allowed filename
extensions.

=item *

Modify F<comp/widgets/tmpl_prof/edit_new.html>.

Add your template filename extensions to the C<file_type> select entry so that
users can create new template files for your burner.

=item *

Done! Now start testing...

=back

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;

#--------------------------------------#
# Programatic Dependencies

use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::AP;
use Bric::Util::Fault::Exception::MNI;
use Bric::Util::Trans::FS;
use Bric::Config qw(:burn :mason :time PREVIEW_LOCAL ENABLE_DIST);
use Bric::Biz::AssetType qw(:all);
use Bric::App::Util qw(:all);
use Bric::App::Event qw(:all);

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric Exporter);

our @EXPORT_OK = qw(PUBLISH_MODE PREVIEW_MODE SYNTAX_MODE);
our %EXPORT_TAGS = ( all => \@EXPORT_OK,
                     modes => \@EXPORT_OK);

#=============================================================================#
# Function Prototypes                  #
#======================================#

#==============================================================================#
# Constants                            #
#======================================#
use constant PUBLISH_MODE => 1;
use constant PREVIEW_MODE => 2;
use constant SYNTAX_MODE => 3;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $mni = 'Bric::Util::Fault::Exception::MNI';
my $ap = 'Bric::Util::Fault::Exception::AP';
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $fs = Bric::Util::Trans::FS->new;

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields
        ({
          # Public Fields
          data_dir => Bric::FIELD_RDWR,
          comp_dir => Bric::FIELD_RDWR,
          out_dir  => Bric::FIELD_RDWR,
          mode     => Bric::FIELD_READ,
      });
}

#==============================================================================#

=head1 INTERFACE

In addition to the class and object methods documented below,
Bric::Util::Burner can export a number of constants. These constants are used
for comparing the values stored in the C<mode> property of a burner
object. They can be imported individually, or by using the C<:modes> or
C<:all> export tags. The supported constants are:

=over

=item C<PUBLISH_MODE>

The burner object is in the process of publishing an asset.

=item C<PREVIEW_MODE>

The burner object is in the process of previewing an asset.

=item C<SYNTAX_MODE>

The burner object is in the process of checking the syntax of a template.

=back

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $obj = new Bric::Util::Burner($init);

Creates a new burner object. The parameters that can be passed via the
C<$init> hash reference are:

=over 4

=item C<data_dir>

The directory where the Burner stores compiled template files. Defaults to the
value stored in the C<BURN_DATA_ROOT> directive set in F<bricolage.conf>.

=item C<comp_dir>

The directory to which the burner deploys and can find templates for
burning. Defaults to the value stored in the C<BURN_COMP_ROOT> directive set
in F<bricolage.conf>.

=item C<out_dir>

The directory in which the burner writes burned content files upon publication
or preview. Defaults to the value stored in the C<BURN_DATA_ROOT> directive
set in F<bricolage.conf>.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($class, $init) = @_;

    # setup defaults
    $init->{data_dir} ||= BURN_DATA_ROOT;
    $init->{comp_dir} ||= BURN_COMP_ROOT;
    $init->{out_dir}  ||= STAGE_ROOT;

    # create the object using mother's constructor and return it
    return $class->SUPER::new($init);
}

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {}

#--------------------------------------#

=back

=head2 Public Class Methods

NONE.

=cut

#--------------------------------------#

=head2 Public Instance Methods

=over 4

=item my $data_dir = $b->get_data_dir

Returns the data directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $b = $b->set_data_dir($data_dir)

Sets the component directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $comp_dir = $b->get_comp_dir

Returns the component directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $b = $b->set_comp_dir($comp_dir)

Sets the data directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $out_dir = $b->get_out_dir

Returns the output directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $b = $b->set_out_dir($out_dir)

Sets the output directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $mode = $b->get_mode

Returns the burn mode. The value is an integer corresponding to one of the
following constants: "PUBLISH_MODE", "PREVIEW_MODE", and "SYNTAX_MODE".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $success = $b->deploy($fa);

Deploys a template to the file system.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub deploy {
    my ($self, $fa) = @_;
    my $oc_dir  = 'oc_' . $fa->get_output_channel->get_id;

    # Grab the file name and directory.
    my $file = $fs->cat_dir($self->get_comp_dir, $oc_dir, $fa->get_file_name);
    my $dir = $fs->dir_name($file);

    # Create the directory path and write the file.
    $fs->mk_path($dir);
    open (MC, ">$file")
      or die $ap->new({ msg => "Could not open '$file'", payload => $! });
    print MC $fa->get_data;
    close(MC);
}

#------------------------------------------------------------------------------#

=item $success = $b->undeploy($fa);

Deletes a template from the file system.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub undeploy {
    my ($self, $fa) = @_;
    my $oc_dir = 'oc_' . $fa->get_output_channel->get_id;

    # Grab the file name.
    my $file = $fs->cat_dir($self->get_comp_dir, $oc_dir, $fa->get_file_name);

    # Delete it from the file system.
    $fs->del($file) if -e $file;
}
#------------------------------------------------------------------------------#

=item $url = $b->preview($ba, $key, $user_id, $m);

Sends story or media to preview server and returns URL. Params:

=over 4

=item C<$ba>

A business asset object to preview.

=item C<$key>

The string "story" or "media".

=item C<$user_id>

The ID of the user publishing the asset.

=item C<$m>

A Mason request object (optional).

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub preview {
    my $self = shift;
    $self->_set(['mode'], [PREVIEW_MODE]);
    my ($ats, $oc_sts) = ({}, {});
    my ($ba, $key, $user_id, $m, $oc_id) = @_;
    my $send_msg = $m ? sub { $m->comp('/lib/util/status_msg.mc', @_) } :
                        sub { 0; };
    my $comp_root = MASON_COMP_ROOT->[0][1];

    # Get a list of the relevant categories, put primary category first
    my @cats = ($key eq 'story') ?
      ($ba->get_primary_category, $ba->get_secondary_categories) :
      ();

    # Grab the asset type and output channel.
    my $at = $ats->{$ba->get_element__id} ||= $ba->_get_element_object;
    my $oc = Bric::Biz::OutputChannel->lookup
                ({ id => $oc_id ? $oc_id : $at->get_primary_oc_id });

    # Burn to each output channel.
    &$send_msg("Writing files to &quot;" . $oc->get_name
               . '&quot; Output Channel.');
    my $ocid = $oc->get_id;
    # Get a list of server types this categroy applies to.
    my $bat = $oc_sts->{$ocid} ||=
      Bric::Dist::ServerType->list({ can_preview => 1,
                                     output_channel_id => $ocid });
    # Make sure we have some destinations.
    unless (@$bat) {
        if (not PREVIEW_LOCAL) {
            # can't use add_msg here because we're already in a new window
            &$send_msg("<font color=red><b>Cannot preview asset &quot;" .
                       $ba->get_name . "&quot; because there are no " .
                       "Preview Destinations associated with its " .
                       "output channels.</b></font>");
            next;
        }
    }

    # Create a job for moving this asset in this output Channel.
    my $name = 'Preview &quot;' . $ba->get_name . "&quot; in &quot;" .
      $oc->get_name . "&quot;";

    my $job = Bric::Dist::Job->new({ sched_time => '',
                                     user_id => $user_id,
                                     name => $name,
                                     server_types => $bat});

    my $res = [];
    # Burn, baby, burn!
    if ($key eq 'story') {
        foreach my $cat (@cats) {
            push @$res, $self->burn_one($ba, $oc, $cat);
        }
    } else {
        my $path = $ba->get_path;
        my $uri = $ba->get_uri($oc);
        if ($path && $uri) {
            my $r = Bric::Dist::Resource->lookup({ path => $path,
                                                   uri  => $uri })
              || Bric::Dist::Resource->new
                ({ path => $path,
                   media_type => Bric::Util::MediaType->get_name_by_ext($uri),
                   uri => $uri
                 });

            $r->add_media_ids($ba->get_id);
            $r->save;
            push @$res, $r;
        }
    }
    # Save the delivery job.
    $job->add_resources(@$res);
    $job->save;
    log_event('job_new', $job);

    # Execute the job and redirect.
    &$send_msg("Distributing files.");
    # We don't need to exeucte the job if it has already been executed.
    $job->execute_me unless ENABLE_DIST;
    if (PREVIEW_LOCAL) {
        # Copy the files for previewing locally.
        foreach my $rsrc (@$res) {
            $fs->copy($rsrc->get_path,
                      $fs->cat_dir($comp_root, PREVIEW_LOCAL,
                                   $rsrc->get_uri));
        }
        $self->_set(['mode'], [undef]);
        # Return the redirection URL.
        return $fs->cat_uri('/', PREVIEW_LOCAL, $res->[0]->get_uri);
    } else {
        # Return the redirection URL, if we have one
        $self->_set(['mode'], [undef]);
        if (@$bat) {
            return 'http://' . ($bat->[0]->get_servers)[0]->get_host_name
                . $res->[0]->get_uri;
        }
    }
}
#------------------------------------------------------------------------------#

=item $published = $b->publish($ba, $key, $user_id, $publish_date);

Publishes an asset, then remove from workflow. Returns 1 if publish was
successful, else 0. Parameters are:

=over 4

=item C<$ba>

A business asset object to publish.

=item C<$key>

The string "story" or "media".

=item C<$user_id>

The ID of the user publishing the asset.

=item C<$publish_date>

The date to set to schedule publishing job. If not defined it will default set
up the asset to be published immediately.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub publish {
    my $self = shift;
    $self->_set(['mode'], [PUBLISH_MODE]);
    my ($ats, $oc_sts) = ({}, {});
    my ($ba, $key, $user_id, $publish_date, $die_err) = @_;
    my $published=0;
    $ba->set_publish_date($publish_date);

    # Determine if we've published before. Set the expire date if we haven't.
    my ($repub, $exp_date) = $ba->get_publish_status ?
      (1, undef) : (undef, $ba->get_expire_date(ISO_8601_FORMAT));

    # Get a list of the relevant categories.
    my @cats = $key eq 'story' ? $ba->get_categories : ();
    # Grab the asset type.
    my $at = $ats->{$ba->get_element__id} ||= $ba->_get_element_object;
    my $ocs = $ba->get_output_channels;

    foreach my $oc (@$ocs) {
        my $ocid = $oc->get_id;
        # Get a list of server types this categroy applies to.
        my $bat = $oc_sts->{$ocid} ||=
            Bric::Dist::ServerType->list({ can_publish => 1,
                                           output_channel_id => $ocid });

        # Make sure we have some destinations.
        unless (@$bat) {
            $die_err
              ? die "Cannot publish asset &quot;" . $ba->get_name
              . "&quot; because there are no Destinations associated with "
              . "its output channels."
              : add_msg("Cannot publish asset &quot;" . $ba->get_name
                        . "&quot; because there are no Destinations associated "
                        . "with its output channels.");
            next;
        }

        # Create a job for moving this asset in this output Channel.
        my $name = 'Publish &quot;' . $ba->get_name . "&quot; to &quot;" .
          $oc->get_name . "&quot;";
        my $job = Bric::Dist::Job->new({ sched_time => $publish_date,
                                         user_id => $user_id,
                                         name => $name,
                                         server_types => $bat});

        # Burn, baby, burn!
        if ($key eq 'story') {
            foreach my $cat (@cats) {
                $job->add_resources($self->burn_one($ba, $oc, $cat));
            }
            $published = 1;
        } else {
            my $path = $ba->get_path;
            my $uri = $ba->get_uri($oc);
            if ($path && $uri) {
                my $r = Bric::Dist::Resource->lookup({ path => $path,
                                                       uri  => $uri })
                    || Bric::Dist::Resource->new
                      ({ path => $path,
                         media_type => Bric::Util::MediaType->get_name_by_ext($uri),
                         uri => $uri
                       });

                $r->add_media_ids($ba->get_id);
                $r->save;
                $job->add_resources($r);
                $published = 1;
            } else {
                $published = 1;
                add_msg('No media file is associated with asset &quot;' .
                        $ba->get_name . '&quot;, so none will be distributed.');
            }
        }

        # Save the job.
        $job->save;
        log_event('job_new', $job);

        # Set up an expire job, if necessary.
        if ($exp_date) {
            # We'll need to expire it.
            my $expname = "Expire &quot;" . $ba->get_name .
              "&quot; from &quot" . $oc->get_name . "&quot;";
            my $exp_job = Bric::Dist::Job->new
              ({ sched_time   => $exp_date,
                 user_id      => $user_id,
                 server_types => $bat,
                 name         => $expname,
                 resources    => [$job->get_resources],
                 type => 1
               });
            $exp_job->save;
            log_event('job_new', $exp_job);
        }
    }

    if ($published) {
        $ba->set_publish_status(1);
        # Set published version
        $ba->set_published_version($ba->get_current_version);
        # Now log that we've published and get it out of workflow.
        log_event($key . ($repub ? '_republish' : '_publish'), $ba);

        # Remove it from the desk it's on.
        if (my $d = $ba->get_current_desk) {
            $d->remove_asset($ba);
            $d->save;
        }
        # Remove it from the workflow by setting is workflow ID to undef
        if ($ba->get_workflow_id) {
            $ba->set_workflow_id(undef);
            log_event("${key}_rem_workflow", $ba);
        }

        # Save it!
        $ba->save;
    }

    $self->_set(['mode'], [undef]);
    return $published;
}

#------------------------------------------------------------------------------#

=item @resources = $b->burn_one($ba, $oc, $cat);

Publishes an asset. Returns a list of resources burned. Parameters are:

=over 4

=item C<$ba>

A business asset object to publish.

=item C<$oc>

The output channel to which to burn the asset.

=item C<$cat>

A category in which to burn the asset.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub burn_one {
    my $self = shift;
    my ($burner, $at) = $self->_get_subclass($_[0]);
    $burner->burn_one(@_, $at);
}

=item my $bool = $burner->chk_syntax($ba, \$err)

Compiles the template found in $ba. If the compile succeeds with no errors,
chk_syntax() returns true. Otherwise, it returns false, and the error will be in
the $err varible passed by reference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub chk_syntax {
    my $self = shift;
    my ($burner) = $self->_get_subclass($_[0]);
    $self->_set(['mode'], [SYNTAX_MODE]);
    my $ret = $burner->chk_syntax(@_);
    $self->_set(['mode'], [undef]);
    return $ret;
}

=back

=head2 Private Instance Methods

=over 4

=item $burner->_get_subclass($ba)

Returns the subclass of Bric::Util::Burner appropriate for handling the $ba
template object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_subclass {
    my ($self, $asset) = @_;
    my $burner_class = 'Bric::Util::Burner::';
    if (my $at = Bric::Biz::AssetType->lookup({id => $asset->get_element__id})) {
        # Easy to get it
        my $b = $at->get_burner || BURNER_MASON;
        $burner_class .=
            $b == BURNER_MASON ? 'Mason' :
                $b == BURNER_TEMPLATE ? 'Template' :
                    die $gen->new({ msg => 'Cannot determine template burner subclass.'});

        # Instantiate the proper subclass.
        return ($burner_class->new($self), $at);

    } else {
        # There is no asset type. It could be a template. Find out.
        $asset->key_name eq 'formatting'
            || die $gen->new({msg => 'No element associated with asset.'});
        # Okay, it's a template. Figure out the proper burner from the file name.
        my $file_name = $asset->get_file_name;
        if ($file_name =~ /autohandler$/ || $file_name =~ /\.mc$/) {
            # It's a mason component.
            $burner_class .= 'Mason';
        } elsif ($file_name =~ /\.tmpl$/ || $file_name =~ /\.pl$/) {
            # It's an HTML::Template template.
            $burner_class .= 'Template';
        } else {
            die $gen->new({msg => 'Cannot determine template burner subclass.'});
        }

        # Instantiate the proper subclass.
        return ($burner_class->new($self));
    }
}


1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

Garth Webb <garth@perijove.com>

Sam Tregar <stregar@about-inc.com>

Matt Vella <mvella@about-inc.com>

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric>, L<Bric::Util::Burner::Mason>, L<Bric::Util::Burner::Template>.

=cut
