package Bric::Util::Burner;
###############################################################################

=head1 NAME

Bric::Util::Burner - A class to manage deploying of formatting assets and publishing of business assets.

=head1 VERSION

$Revision: 1.20 $

=cut

our $VERSION = (qw$Revision: 1.20 $ )[-1];

=head1 DATE

$Date: 2002-05-16 00:04:29 $

=head1 SYNOPSIS

 use Bric::Util::Burner;

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
through deploy() and undeploy().

=item 2

Manages the process of publishing a asset with the burn_one() method.
The actual work of publishing is done by one of Bric::Util::Burner's
sub-classes depending on the burner_type of the asset being published.
See L<Bric::Util::Burner::Mason> and L<Bric::Util::Burner::Template>
for details.

=back

=head1 ADDING A NEW BURNER

It is anticipated that new Burner sub-classes will be added to the system.
Here's a brief guide to adding a new Burner to Bricolage:

=over 4

=item *

Write Bric::Util::Burner::Foo

You'll need to create a new sub-class of Bric::Util::Burner that implements
three methods - new(), chk_syntax(), and burn_one(). You can use an existing
sub-class as a model for the interface and implementation of these methods. Make
sure that when you execute your templates, you do it in the namespace reserved
by the TEMPLATE_BURN_PKG directive -- get this constant by adding

  use Bric::Config qw(:burn);

To your new Burner subclass.

=item *

Modify Bric::Biz::AssetType

To use your Burner you'll need to be able to assign elements to it. To do this
edit Bric::Biz::AssetType and add a constant for your burner. For example,
Bric::Util::Burner::Template's constant is BURNER_TEMPLATE. Next, edit the
my_meths() entry for the "burner" type to include a val entry for your constant.

=item *

Modify Bric::Util::Burner

You'll need to make a modification to Bric::Util::Burner to make it call your
module when it sees an element assigned to your burner. The code you're looking
for is in the _get_subclass() method. Add the approprate C<elsif>s to assigns
the appropriate class name for your burner.

=item *

Modify Bric::Biz::Asset::Formatting

Here you'll make modifications to support the template files needed by your
burner. Do a search for the string "tmpl" and you'll find the appropriate
sections. This is where you'll setup your naming convention and allowed filename
extensions.

=item *

Modify comp/widgets/tmpl_prof/edit_new.html

Add your template filename extensions to the file_type select entry so that
users can create new template files for your burner.

=item *

Done! Now start testing...

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
use Bric::Config qw(:burn :mason PREVIEW_LOCAL ENABLE_DIST);
use Bric::Biz::AssetType qw(:all);
use Bric::App::Util qw(:all);
use Bric::App::Event qw(:all);

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

#==============================================================================#
# Constants                            #
#======================================#

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
    Bric::register_fields({
			 # Public Fields
                         'data_dir'       => Bric::FIELD_RDWR,
			 'comp_dir'       => Bric::FIELD_RDWR,
			 'out_dir'        => Bric::FIELD_RDWR,
			});
}

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $obj = new Bric::Util::Burner($init);

Creates a new burn object.  Keyw to $init are:

=over 4

=item *

data

The directory where the Burner stores temporary files.  Defaults to
BURN_DATA_ROOT set in bricolage.conf.

=item *

comp

The directory templates are deployed to.  Defaults to BURN_COMP_ROOT
set in bricolage.conf.

=item *

out

The staging area directory where the burner places content files upon
publication or preview.  Defaults to BURN_DATA_ROOT set in
bricolage.conf.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>


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

#------------------------------------------------------------------------------#

=item lookup()

Bric::Util::Burner doesn't support lookup().

=cut

sub lookup {
    die $mni->new({msg => __PACKAGE__."::lookup() method not implemented."});
}

#------------------------------------------------------------------------------#

=item list()

Bric::Util::Burner doesn't support list().

=cut

sub list {
    die $mni->new({msg => __PACKAGE__."::list() method not implemented."});
}


#--------------------------------------#

=head2 Destructors

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {}

#--------------------------------------#

=head2 Public Class Methods

=cut

#--------------------------------------#

=head2 Public Instance Methods

=cut

#------------------------------------------------------------------------------#

=item $success = $b->deploy($fa);

Deploys a template to the file system.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

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

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

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

=item *

$ba

A business asset object to publish.

=item *

$key

story or media

=item *

$user_id

user_id to publish as.

=item *

$m

mason object (optional).

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub preview {
    my $self = shift;
    my ($ats, $oc_sts) = ({}, {});
    my ($ba, $key, $user_id, $m) = @_;
    my $send_msg = $m ? sub { $m->comp('/lib/util/status_msg.mc', @_) } :
	                sub { 0; };
    my $comp_root = MASON_COMP_ROOT->[0][1];

    $ba->set_publish_date();
    # Create a job for moving this asset.
    my $job = Bric::Dist::Job->new( { sched_time => '',
				      user_id => $user_id,
				      name => 'Preview' . " &quot;" .
				      $ba->get_name . "&quot;" });
    # Get a list of the relevant categories.
    my @cats = $key eq 'story' ? $ba->get_categories : ();
    # Grab the asset type.
    my $at = $ats->{$ba->get_element__id} ||= $ba->_get_element_object;
    my $bats = {};
    my $res = [];
    my $ocs = [ Bric::Biz::OutputChannel->lookup({ id => $at->get_primary_oc_id }) ];
	
    # Iterate through each output channel.
    foreach my $oc (@$ocs) {
    	&$send_msg("Writing files to &quot;" . $oc->get_name
		   . '&quot; Output Channel.');
    	my $ocid = $oc->get_id;
    	# Get a list of server types this categroy applies to.
    	my $bat = $oc_sts->{$ocid} ||=
	    Bric::Dist::ServerType->list({ "can_preview" => 1,
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
	# Force the list of server types into a hash so that they're unique
	# (they can repeat between asset channels).
	grep { $bats->{ $_->get_id } = $_ } @$bat;

	# Burn, baby, burn!
	if ($key eq 'story') {
	    foreach my $cat (@cats) {
		push @$res, $self->burn_one($ba, $oc, $cat);
	    }
    	} else {
	    my $path = $ba->get_path;
	    my $uri = $ba->get_uri;
	    if ($path && $uri) {
		my $r = Bric::Dist::Resource->lookup({ path => $path })
		    || Bric::Dist::Resource->new({ path => $path,
						   media_type => Bric::Util::MediaType->get_name_by_ext($uri)
						 });
		$r->set_uri($uri);
		$r->add_media_ids($ba->get_id);
		$r->save;
		push @$res, $r;
	    }
    	}
    }
    # Turn the hash of server types into an array.
    $bats = [ values %$bats ];

    # Save the delivery job.
    $job->add_server_types(@$bats);
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
	# Return the redirection URL.
        return $fs->cat_uri('/', PREVIEW_LOCAL, $res->[0]->get_uri);
    } else {
        # Return the redirection URL, if we have one
        if (@$bats) {
	    return 'http://' . ($bats->[0]->get_servers)[0]->get_host_name
		. $ba->get_uri;
	}
    }
}
#------------------------------------------------------------------------------#

=item $published = $b->publish($ba, $key, $user_id, $publish_date);

Publishes an asset, then remove from workflow.  Returns 1 if publish was successful, else 0.  Parameters are:

=over 4

=item *

$ba

A business asset object to publish.

=item *

$key

story or media

=item *

$user_id

user_id to publish as.

=item *

$publish_date

Date to set up publishing job for - if left blank, the present.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub publish {
    my $self = shift;
    my ($ats, $oc_sts) = ({}, {});
    my ($ba, $key, $user_id, $publish_date, $die_err) = @_;
    my $published=0;
    $ba->set_publish_date($publish_date);
    # Create a job for moving this asset.
    my $job = Bric::Dist::Job->new( { sched_time => $publish_date,
                                      user_id => $user_id,
                                      name => ucfirst('publish') . " &quot;" .                                            $ba->get_name . "&quot;" });

    my $exp_job;
    my $repub;

    if (!$ba->get_publish_status) {
        # This puppy hasn't been published before. Mark it.
        $ba->set_publish_status(1);
        if (my $exp_date = $ba->get_expire_date) {
            # We'll need to expire it.
            $exp_job = Bric::Dist::Job->new( { sched_time => $exp_date,
					       user_id => $user_id,
					       type => 1 });
            $exp_job->set_name("Expire &quot;" . $ba->get_name . "&quot;");
        }
    } else {
	$repub = 1;
    }

    # Get a list of the relevant categories.
    my @cats = $key eq 'story' ? $ba->get_categories : ();
    # Grab the asset type.
    my $at = $ats->{$ba->get_element__id} ||= $ba->_get_element_object;
    my $bats = {};
    my $res = [];
    my $ocs = $at->get_output_channels;

    foreach my $oc (@$ocs) {
        my $ocid = $oc->get_id;
        # Get a list of server types this categroy applies to.
        my $bat = $oc_sts->{$ocid} ||=
	    Bric::Dist::ServerType->list({ "can_publish" => 1,
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
	# Force the list of server types into a hash so that they're unique
	# (they can repeat between asset channels).
	grep { $bats->{ $_->get_id } = $_ } @$bat;

	# Burn, baby, burn!
	if ($key eq 'story') {
	    foreach my $cat (@cats) {
		push @$res, $self->burn_one($ba, $oc, $cat);
	    }
	    $published=1;
	} else {
	    my $path = $ba->get_path;
	    my $uri = $ba->get_uri;
	    if ($path && $uri) {
		my $r = Bric::Dist::Resource->lookup({ path => $path })
                    || Bric::Dist::Resource->new({ path => $path,
						   media_type => Bric::Util::MediaType->get_name_by_ext($uri)
						 });
		$r->set_uri($uri);
		$r->add_media_ids($ba->get_id);
		$r->save;
		push @$res, $r;
		$published=1;
	    }
	}
    }

    # Turn the hash of server types into an array.
    $bats = [ values %$bats ];

    # Save the delivery job.
    $job->add_server_types(@$bats);
    $job->add_resources(@$res);
    $job->save;
    log_event('job_new', $job);

    # Save the expiration job, if there is one.
    if ($exp_job) {
        # Add the server types to the job.
        $exp_job->add_server_types(@$bats);
        $exp_job->add_resources(@$res);
        $exp_job->save;
        log_event('job_new', $exp_job);
    }

    if ($published) {
	# Set published version
	$ba->set_published_version($ba->get_current_version());
        # Now log that we've published and get it out of workflow.
        log_event($key . ($repub ? '_republish' : '_publish'), $ba);
        my $d = $ba->get_current_desk;
        $d->remove_asset($ba);
        $d->save;
	# Remove this asset from the workflow by setting is workflow ID to undef
        $ba->set_workflow_id(undef);
        $ba->save;

        log_event("${key}_rem_workflow", $ba);
    }

    return $published;
}

#------------------------------------------------------------------------------#

=item @resources = $b->burn_one($ba, $oc, $cat);

Publishes an asset.  Returns a list of resources burned.  Parameters are:

=over 4

=item *

$ba

A business asset object to publish.

=item *

$oc

An output channel object to use for the publish

=item *

cat

A category in which to publish.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

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
    $burner->chk_syntax(@_);
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


=head1 AUTHOR

"Garth Webb" <garth@perijove.com>

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric>, L<Bric::Util::Burner::Mason>, L<Bric::Util::Burner::Template>.

=cut
