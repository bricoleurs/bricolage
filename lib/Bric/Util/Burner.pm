package Bric::Util::Burner;
###############################################################################

=head1 NAME

Bric::Util::Burner - A class to manage deploying of formatting assets and publishing of business assets.

=head1 VERSION

$Revision: 1.14 $

=cut

our $VERSION = (qw$Revision: 1.14 $ )[-1];

=head1 DATE

$Date: 2002-03-09 00:43:02 $

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

You'll need to create a new sub-class of Bric::Util::Burner that implements two
methods - new() and burn_one(). You can use an existing sub-class as a model for
the interface and implementation of these methods. Make sure that when you
execute your templates, you do it in the namespace reserved by the
TEMPLATE_BURN_PKG directive -- get this constant by adding

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
for is in the burn_one() method. Add an "elsif" that assigns the appropriate
class name for your burner.

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
use Bric::Config qw(:burn);
use Bric::Biz::AssetType;


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
my $xml_fh = INCLUDE_XML_WRITER ? Bric::Util::Burner::XMLWriterHandle->new
  : undef;

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
    my $burner = $self->_get_subclass($_[0]);
    $burner->burn_one(@_);
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
    my $burner = $self->_get_subclass($_[0]);
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
    my ($self, $ba) = @_;
    my $at = Bric::Biz::AssetType->lookup({'id' => $ba->get_element__id});
    my $which_burner = $at->get_burner() || Bric::Biz::AssetType::BURNER_MASON;

    my $burner_class = "Bric::Util::Burner::";
    if ($which_burner == Bric::Biz::AssetType::BURNER_MASON) {
      $burner_class .= "Mason";
    } elsif ($which_burner == Bric::Biz::AssetType::BURNER_TEMPLATE) {
      $burner_class .= "Template";
    }

    # instantiate the proper subclass and call burn_one()
    return $burner_class->new($self);
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
