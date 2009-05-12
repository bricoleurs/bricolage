package Bric::Util::Burner;

##############################################################################

=head1 Name

Bric::Util::Burner - Publishes stories and deploys templates

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 use Bric::Util::Burner qw(:modes);

 # Create a new publish object.
 $burner = new Bric::Util::Burner;

 # Deploy a template.
 $burner = $burner->deploy($template_asset);

 # Undeploy a template.
 $burner = $burner->undeploy($template_asset);

 # Burn an asset given an output chanels and category
 $burner->burn_one($asset, $output_channel, $category);

 # set list of page extensions
 $burner->set_page_extensions(@page_extensions);

 # get list of page extensions
 @page_extensions = $burner->get_page_extensions();

 # set page numbering start
 $burner->set_page_numb_start($start);

 # retrieve page numbering start
 $page_numb_start = burner->get_page_numb_start;

=head1 Description

This module accomplishes two tasks:

=over 4

=item 1

Manages the process of deploying and undeploying of templates through
C<deploy()> and C<undeploy()>.

=item 2

Manages the process of publishing and previewing business assets via the
C<publish()> and C<preview()> methods, respectively. The actual work of
publishing is done by one of Bric::Util::Burner's subclasses depending on the
C<burner_type> of the asset being published. See L<Bric::Util::Burner::Mason>
and L<Bric::Util::Burner::Template> for details.

=back

=head1 Adding a New Burner

We anticipate that new Burner subclasses will be added to the system. Here's
a brief guide to adding a new Burner to Bricolage:

=over 4

=item *

Modify Bric::Biz::OutputChannel.

To use your Burner you'll need to be able to assign output channels to it. To
do this edit Bric::Biz::OutputChannel and add a constant for your burner. For
example, Bric::Util::Burner::Template's constant is C<BURNER_TEMPLATE>. Next,
edit the C<my_meths()> entry for the "burner" type to include an entry for
your constant.

=item *

Decide on a file naming scheme for your templating architecture. The file name
suffix or suffixes must be unique across Bricolage burners, as must the base
file name of your category templates. See the calls to _register_subclass() in
the other burner classes to ensure that your choices are unique. You must also
decide whether or not your category template file names will have suffixes. We
generally recommend that they don't, so as to prevent possible conflicts with
the names of element templates (see the Mason and PHP burners for an example).

=item *

Write the burner tests by implementing F</t/Bric/Util/Burner/Foo/DevTest.pm>.
See F</t/Bric/Util/Burner/Mason/DevTest.pm> for an example. You will need to
use the constant defined in Bric::Biz::OutputChannel and the file name
standards defined in the last step to have the base class,
F</t/Bric/Util/Burner/DevTest.pm>, properly create and load the test
templates.

You will also have to create the test templates. The templates go into the
same directory as the new F<DevTest.pm> file. For example, if you had elected
to go with the file suffix "foo" and gone with "cat_me" for your category
template name, and the category template does F<not> include the file suffix,
the templates you would need to create would be:

=over

=item F<cat_me>

The root-level category template. Port the Mason test's F<autohandler>
template.

=item F<sub_cat_me>

A subcategory template. This template will wrap the execution of the story
template and be wrapped by the execution of the F<cat_me> template. Port the
Mason test's F<sub_autohandler> template.

=item F<story.foo>

The story element template. Port the Mason test's F<story.mc> template.

=item F<page.foo>

A page subelement template. Port the Mason test's F<pull_quote.mc> template.
This template should be used from paginated content, which will result in the
output of two separate files for the test story.

=item F<pull_quote.foo>

The pull quote subelement template. Port the Mason test's F<pull_quote.mc>
template.

=item F<util.foo>

A utility template. Should be called from some other template, usually
F<cat_me>. Port from the Mason test's F<util.mc> template.

=back

=item *

Write Bric::Util::Burner::Foo.

You'll need to create a new subclass of Bric::Util::Burner that implements
three methods - C<new()>, C<chk_syntax()>, and C<burn_one()>. You can use an
existing subclasses as a model for the interface and implementation of these
methods. Make sure that when you execute your templates, you do it in the
name space reserved by the C<TEMPLATE_BURN_PKG> directive -- get this constant
by adding

  use Bric::Config qw(:burn);

to your new Burner subclass.

Your burner class will also need to call the C<_register_burner()> method when
it loads so as to register itself, its category base file name and its file
name suffix or suffixes. Again, see the existing subclasses for some examples.

=item *

Modify Bric::Util::Burner to load your burner subclass, provided the necessary
prerequisites are installed. For example, the PHP burner is loaded like so:

    require Bric::Util::Burner::PHP if eval { require PHP::Interpreter };

=item *

If all of your tests pass, you're done! You must have a freshly-built
Bricolage database to successfully run the tests. To just run your new
burner's tests, use this command:

  perl inst/runtests.pl -V t/Bric/Util/Burner/Foo/DevTest.pm

When that's working, make sure that I<all> tests pass by running:

  make devtest TEST_VERBOSE=1

=item *

Create a patch using the instructions in L<Bric::Hacker|Bric::Hacker> and send
them to the Bricolage developer's mailing list!

=item *

Profit.

=back

=cut

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric Exporter);

our @EXPORT_OK = qw(PUBLISH_MODE PREVIEW_MODE SYNTAX_MODE);
our %EXPORT_TAGS = (
    all   => \@EXPORT_OK,
    modes => \@EXPORT_OK
);

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;

#--------------------------------------#
# Programatic Dependencies

use Bric::Util::Fault qw(throw_gen throw_burn_error throw_burn_user
                         rethrow_exception);
use Bric::Util::Trans::FS;
use Bric::Config qw(:burn :mason :time PREVIEW_LOCAL ENABLE_DIST :prev :l10n);
use Bric::Biz::OutputChannel qw(:burners);
use Bric::App::Util qw(:all);
use Bric::App::Event qw(:all);
use Bric::App::Session qw(:user);
use Bric::Biz::Site;
require Bric::Util::Job::Pub;
require Bric::Util::Job::Dist;
use Bric::Util::DBI qw(:junction);
use Bric::Util::Pref;
use Bric::Util::Time qw(:all);
use File::Basename qw(fileparse);
use URI;

#=============================================================================#
# Function Prototypes                  #
#======================================#

#==============================================================================#
# Constants                            #
#======================================#
use constant PUBLISH_MODE => 1;
use constant PREVIEW_MODE => 2;
use constant SYNTAX_MODE  => 3;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $fs = Bric::Util::Trans::FS->new;

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
        # Public Fields
        data_dir              => Bric::FIELD_RDWR,
        comp_dir              => Bric::FIELD_RDWR,
        out_dir               => Bric::FIELD_RDWR,
        page_numb_start       => Bric::FIELD_RDWR,
        sandbox_dir           => Bric::FIELD_RDWR,
        user_id               => Bric::FIELD_RDWR,
        mode                  => Bric::FIELD_READ,
        story                 => Bric::FIELD_READ,
        element               => Bric::FIELD_READ,
        oc                    => Bric::FIELD_READ,
        cat                   => Bric::FIELD_READ,
        page                  => Bric::FIELD_READ,
        encoding              => Bric::FIELD_RDWR,
        output_filename       => Bric::FIELD_RDWR,
        output_ext            => Bric::FIELD_RDWR,
        output_path           => Bric::FIELD_READ,
        base_path             => Bric::FIELD_READ,
        base_uri              => Bric::FIELD_READ,
        burn_again            => Bric::FIELD_RDWR,
        resources             => Bric::FIELD_READ,

        # Private Fields
        _page_extensions      => Bric::FIELD_NONE,
        _notes                => Bric::FIELD_NONE,
        _output_preview_msgs  => Bric::FIELD_NONE,
        _republish            => Bric::FIELD_NONE,
    });
}

#==============================================================================#

=head1 Interface

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

=item C<user_id>

ID of the user to get a sandbox to deploy/undeploy templates for previewing.
C<sandbox_dir> is set from this value.

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
    $init->{data_dir}           ||= BURN_DATA_ROOT;
    $init->{comp_dir}           ||= BURN_COMP_ROOT;
    $init->{out_dir}            ||= STAGE_ROOT;
    $init->{page_numb_start}    ||= 1;
    $init->{_page_extensions}   ||= [''];
    $init->{_notes}               = {};
    $init->{resources}            = [];
    $init->{_output_preview_msgs} = 1
        unless defined $init->{_output_preview_msgs};

    $init->{sandbox_dir} = $fs->cat_dir(BURN_SANDBOX_ROOT, 'user_'. $init->{user_id})
       if defined($init->{user_id});

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

=over 4

=item my $burner_class = Bric::Util::Burner->class_for_ext($ext);

Returns the name of the burner class that handles templates with the extension
passed in. The extension must be the full extension name without with the ".",
such as "mc" or "tmpl".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $burner_class = Bric::Util::Burner->class_for_cat_fn($filename);

Returns the name of the burner class that handles category templates with the
base file name passed in. The file name must be the base file name, omitting
any exception, such as "autohandler" or "category".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $burner_class = Bric::Util::Burner->cat_fn_has_ext($filename);

Returns true if the category template with the base file name C<$filename> has
a file extension, and false if it doesn't. For example Mason category templates
have no extension, so this method returns false for the C<$filename>
"autohandler". On the other hand, HTML::Template templates do have extensions,
so this method returns true for the C<$filename> "category".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $file_types = Bric::Util::Burner->list_file_types($burner_id)

Returns an array reference of array references of burner file name extensions
mapped to labels for each. Suitable for use in select widgets. Pass in a
Burner ID (such as C<BURNER_MASON>, as exported by Bric::Biz::OutputChannel)
to get back an array reference of only the burner file name extensions
available for that burner.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

my ($classes, $exts, $cat_fn_class, $cat_ext_fn, $cat_fn_has_ext, $file_types);
sub class_for_ext    { $exts->{$_[1]} }
sub class_for_cat_fn { $cat_fn_class->{$_[1]} }
sub cat_fn_for_ext   { $cat_ext_fn->{$_[1]} }
sub cat_fn_has_ext   { $cat_fn_has_ext->{$_[1]} }
sub list_file_types  {
    shift;
    return $file_types->[shift] if @_;
    return [ map { @$_ } grep { defined } @$file_types ];
}

##############################################################################

=item Bric::Util::Burner->flush_another_queue

Goes through the list of documents queued for publish by C<publish_another()>
and schedules them to be published. This method is called by the cleanup
handler and/or by C<bric_queued>, and therefore not generally of interest to
template developers (unless you want to flush the queue to force a publish
after every call to C<publish_another()>, but be careful! You might force the
publication of documents passed to C<publish_another()> by other templates in
the same request!).

=cut

# XXX We're passing notes here, and Job::Pub will add them to the burner it
# creates, but it does not store them. So if the publish job is in the future
# or if QUEUE_PUBLISH_JOBS is enabled, the notes will not be available to the
# other burner. We might want to add note serialization and deserialization to
# the job class if this becomes a serious problem for anyone.

my @another_queue_uuids;
my %another_queue;

sub flush_another_queue {
    my $class = shift;
    return $class unless @another_queue_uuids;
    while (my $uuid = shift @another_queue_uuids) {
        my ($doc, $pub_time, $notes) = @{ $another_queue{$uuid} };
        my $key = $doc->key_name;
        Bric::Util::Job::Pub->new({
            sched_time          => $pub_time,
            user_id             => get_user_id(),
            name                => 'Publish "' . $doc->get_name . '"',
            "$key\_instance_id" => $doc->get_version_id,
            priority            => $doc->get_priority,
            notes               => $notes,
        })->save;
    }

    # Once we get here all recursive adds to the queue have been cleaned out.
    %another_queue = ();
    return $class;
}

=back

=cut

#--------------------------------------#

=head2 Public Instance Methods

=over 4

=item my $data_dir = $burner->get_data_dir

Returns the data directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $b = $burner->set_data_dir($data_dir)

Sets the data directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $comp_dir = $burner->get_comp_dir

Returns the component directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $b = $burner->set_comp_dir($comp_dir)

Sets the component directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $out_dir = $burner->get_out_dir

Returns the output directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $b = $burner->set_out_dir($out_dir)

Sets the output directory.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $mode = $burner->get_mode

Returns the burn mode. The value is an integer corresponding to one of the
following constants: "PUBLISH_MODE", "PREVIEW_MODE", and "SYNTAX_MODE".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $publishing = $burner->publishing

=item my $previewing = $burner->previewing

=item my $compiling = $burner->compiling

Returns true if the burner is currently in publish, preview, or syntax mode,
respectively. Really it's just sugar for checking the mode directly.

=cut

sub previewing { (shift->get_mode || 0) == PREVIEW_MODE }
sub publishing { (shift->get_mode || 0) == PUBLISH_MODE }
sub compiling  { (shift->get_mode || 0) == SYNTAX_MODE  }

=item my $encoding = $burner->get_encoding

Returns the character set encoding to be used to write out the contents of a
burn to a file. Defaults to "utf8".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $b = $burner->set_encoding($encoding)

Sets the character set encoding to be used to write out the contents of a burn
to a file under Perl 5.8.0 and later. Use this attribute if templates are
converting output data from Bricolage's native UTF-8 encoding to another
encoding. Use "raw" if your templates are outputting binary data. Defaults to
"utf8".

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $story = $burner->get_story

Returns the story currently being burned -- that is, during the execution of
templates by C<burn_one()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $story = $burner->get_element

Returns the element currently being burned -- that is, during the execution of
the various element templates by C<burn_one()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $oc = $burner->get_oc

Returns the output channel in which the story returned by C<get_story()> is
currently being burned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $cat = $burner->get_cat

Returns the category to which the story returned by C<get_story()> is
currently being burned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $page = $burner->get_page

Returns the index number of the page that's currently being burned. The index
is 0-based. The first page is "0", the second page is "1" and so on.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $output_filename = $burner->get_output_filename

Returns the base name used to create the file names of all files created by
the current burn. This will have the same value as
C<< $burner->get_oc->get_filename >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $output_ext = $burner->get_output_ext

Returns the filename extension used to create the file names of all files
created by the current burn. This will have the same value as
C<< $burner->get_oc->get_file_ext >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $output_path = $burner->get_base_path

Returns the local file system path to the directory that will be used as the
base path for all files written for documents within a given output channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $output_path = $burner->get_output_path

Returns the local file system path to the directory into which all files
created by the current burn will be written.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $base_uri = $burner->get_base_uri

Returns the base URI to the directory into which all files created by the
current burn will be written.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item  $b = $burner->set_page_extensions(@page_extensions)

Sets page extensions to be used during burning. Will revert to page numbering
once the extensions are all used. Each of the page extensions passed must be
unique or an exception will be thrown.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

Example:

   $burner->set_page_extensions(qw(intro main conc));
   $burner->display_pages('page');

for a 3 page story with a slug of story and a filetype of html will
produce burnt pages with filenames storyintro.html, storymain.html,
and storyconc.html.

=cut

sub set_page_extensions {
    my $self = shift;
    my %seen;
    if (my $dupes = join ', ', grep { $seen{$_}++ } @_) {
        my $oc = $self->get_oc;
        my $cat = $self->get_cat;
        my $elem = $self->get_element;
        throw_burn_error error => "Duplicate page extensions are not allowed, "
                                  . "already seen $dupes",
                         mode  => $self->get_mode,
                         ( $oc   ? (oc    => $oc->get_name)   : ()),
                         ( $cat  ? (cat   => $cat->get_uri)   : ()),
                         ( $elem ? (elem  => $elem->get_name) : ()),
                         ( $elem ? (element => $elem)         : ()),
    }

    $self->_set(['_page_extensions'] => [\@_]);
    return $self;
}

=item  my @page_extensions = $burner->get_page_extensions();

Returns the page extensions to be used during burning.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_page_extensions {
    my $self = shift;
    my $page_extensions = $self->{_page_extensions};
    return @$page_extensions;
}

=item  $b = $burner->set_page_numb_start($start);

Sets the start to be used when numbering pages after array
passed to set_page_extensions has been exhausted.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

Normally after all page extension strings have been used, pages are
numbered using the page number, where the first page after the
explicitly named pages is page 1.

Setting page extensions to qw(en de)
and burning three pages will give:

storyen.html
storyde.html
story1.html

If you want numbering to correspond to the actual story page number,
then you would pass the number of page extensions plus 1.

=item  my $page_numb_start = $burner->get_page_numb_start;

Returns the page extension start.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $success = $burner->deploy($fa);

Deploys a template to the file system. If the burner object
was provided with a user_id, the template is deployed into the user's
sandbox.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub deploy {
    my ($self, $fa) = @_;
    my $oc_dir  = 'oc_' . $fa->get_output_channel->get_id;

    # Grab the file name and directory.
    my $file = $fs->cat_dir($self->get_sandbox_dir || $self->get_comp_dir,
                   $oc_dir, $fa->get_file_name);
    my $dir = $fs->dir_name($file);

    # Create the directory path and write the file.
    $fs->mk_path($dir);
    open (MC, ">$file")
      or throw_gen  error => "Could not open '$file'",
                    payload => $!;
    binmode MC, ':utf8' if ENCODE_OK;
    print MC $fa->get_data;
    close(MC);

    # Just return if we were deploying to a sandbox.
    return if $self->get_sandbox_dir;

    # Delete older versions, if they live elsewhere.
    my $old_version = $fa->get_published_version;
    return $self unless defined $old_version;
    my ($old_fa) = $fa->list({ id      => $fa->get_id,
                               version => $old_version });
    return $self unless $old_fa;
    $self->undeploy($old_fa) if $old_fa->get_file_name ne $fa->get_file_name;
    return $self;
}

#------------------------------------------------------------------------------#

=item $success = $burner->undeploy($fa);

Deletes a template from the file system. If the burner object was provided
with a user_id, the template is undeployed from the user's sandbox.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub undeploy {
    my ($self, $fa) = @_;
    my $oc_dir = 'oc_' . $fa->get_output_channel->get_id;

    # Grab the file name.
    my $file = $fs->cat_dir($self->get_sandbox_dir || $self->get_comp_dir,
                            $oc_dir, $fa->get_file_name);

    # Delete it from the file system.
    $fs->del($file) if -e $file;
}
#------------------------------------------------------------------------------#

=item $url = $burner->preview($ba, $key, $user_id, $oc_id);

Not designed to be called from a template, C<preview()> sends story or media
to preview server and returns URL. The supported arguments are:

=over 4

=item C<$ba>

A business asset object to preview.

=item C<$key>

The string "story" or "media".

=item C<$user_id>

The ID of the user publishing the asset.

=item C<$oc_id>

Output channel ID (optional).

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub preview {
    my $self = shift;
    my ($ats, $oc_sts) = ({}, {});
    my ($ba, $key, $user_id, $oc_id) = @_;
    my $comp_root = MASON_COMP_ROOT->[0][1];
    my $site_id = $ba->get_site_id;

    my $do_status_msg = $self->_get('_output_preview_msgs');

    # Get a list of the relevant categories, put primary category first
    my @cats = $key eq 'story'
      ? ($ba->get_primary_category, $ba->get_secondary_categories)
      : ();

    # Grab the asset type and output channel.
    my $at = $ats->{$ba->get_element_type_id} ||= $ba->get_element_type;
    my $oc = Bric::Biz::OutputChannel->lookup
                ({ id => $oc_id ? $oc_id : $ba->get_primary_oc_id($site_id) });

    # Setup.
    $self->_set(['mode'], [PREVIEW_MODE]);

    # Burn to each output channel.
    my $ret = eval {
        status_msg('Writing files to "[_1]" Output Channel.', $oc->get_name)
          if $do_status_msg;
        my $ocid = $oc->get_id;
        $self->_set(['base_path'], [$fs->cat_dir($self->get_out_dir,
                                                 'oc_'. $ocid)]);

        # Get a list of server types this categroy applies to.
        my $bat = $oc_sts->{$ocid} ||= Bric::Dist::ServerType->list({
            can_preview       => 1,
            active            => 1,
            output_channel_id => $ocid
        });

        # Make sure we have some destinations.
        unless (@$bat) {
            unless (PREVIEW_LOCAL) {
                Bric::Util::Fault::Error->throw(
                  error => 'Cannot preview asset "' . $ba->get_name . '" because '
                           . 'there are no Preview Destinations associated with '
                           . 'its output channels.',
                   maketext => ['Cannot preview asset "[_1]" because there ' .
                                'are no Preview Destinations associated with ' .
                                'its output channels.', $ba->get_name])
                   unless $do_status_msg;
                severe_status_msg('Cannot preview asset "[_1]" because there ' .
                                  'are no Preview Destinations associated with ' .
                                  'its output channels.', $ba->get_name);
                next;
            }
        }

        # Create a job for moving this asset in this output Channel.
        my $name = 'Preview "' . $ba->get_name . '" in "' .
          $oc->get_name . '"';

        my $job = Bric::Util::Job::Dist->new({
            sched_time          => '',
            user_id             => $user_id,
            name                => $name,
            server_types        => $bat,
            "$key\_instance_id" => $ba->get_version_id,
            priority            => $ba->get_priority,
        });
        my $resources = [];
        # Burn, baby, burn!
        if ($key eq 'story') {
            foreach my $cat (@cats) {
                push @$resources, $self->burn_one($ba, $oc, $cat);
            }
        } else {
            my $path = $ba->get_path;
            my $uri = $ba->get_uri($oc);
            if ($path && $uri) {
                my $res = _get_resource( $path, $uri);
                $res->add_media_ids($ba->get_id);
                $res->save;
                push @$resources, $res;
            }
        }
        # Save the delivery job.
        $job->add_resources(@$resources);
        $job->save;
        log_event('job_new', $job);

        # Execute the job and redirect.
        status_msg("Distributing files.") if $do_status_msg;

        # We don't need to execute the job if it has already been executed.
        $job->execute_me unless $job->get_comp_time;

        # Make sure there are some files to redirect to.
        unless (@$resources) {
            status_msg("No output to preview.") if $do_status_msg;
            return;
        }

        if (PREVIEW_LOCAL) {
            # Copy the files for previewing locally.
            foreach my $rsrc (@$resources) {
                $fs->copy($rsrc->get_path,
                          $fs->cat_dir($comp_root, PREVIEW_LOCAL,
                                       $rsrc->get_uri));
            }
            # Return the redirection URL.
            return $fs->cat_uri('/', PREVIEW_LOCAL, $resources->[0]->get_uri);
        } else {
            # Return the redirection URL, if we have one
            if (@$bat) {
                return ($oc->get_protocol || 'http://')
                  . ($bat->[0]->get_servers)[0]->get_host_name
                  . $resources->[0]->get_uri;
            }
        }
    };

    my $err = $@;

    # Reset and bail.
    $self->_set(['mode'], [undef]);
    return $ret unless $err;
    rethrow_exception $err;
}
#------------------------------------------------------------------------------#

=item $url = $b->preview_another($ba, $oc_id);

Burns a story or media document, distributes it to the preview server and
returns the URL. It is designed to be the complement of C<publish_another()>,
to be used in templates during previews to burn and distribute related
documents so that they'll be readily available on the preview server within
the context of previewing another document. Like C<publish_another()>, it will
not bother to preview the document if it's the same story as the currently
burning story. The supported arguments are:

=over 4

=item C<$ba>

A business asset object to burn and send to the preview server.

=item C<$oc_id>

The ID of the output channel to use to burn a story. Defaults to the primary
output channel of the story.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub preview_another {
    my $self = shift;
    my ($ba, $oc_id) = @_;

    # return unless we are in preview mode
    return unless $self->_get('mode') == PREVIEW_MODE;

    # Figure out what we're previewing.
    my $key = ref $ba eq 'Bric::Biz::Asset::Business::Story'
      ? 'story'
      : 'media';

    # Don't bother if it's the same as the current story.
    if ($key eq 'story' and my $story = $self->get_story) {
        return if $ba->get_id == $story->get_id;
    }

    # Create a new burner, copy the notes, and do the preview.
    my $b2 = __PACKAGE__->new({ user_id => $self->get_user_id,
                                out_dir => PREVIEW_ROOT,
                              });
    $b2->_set([qw(_output_preview_msgs _notes)] => [0, $self->_get('_notes')]);
    return $b2->preview($ba, $key, get_user_id(), $oc_id);
}

#------------------------------------------------------------------------------#

=item $url = $b->preview_another_all_ocs($ba);

Designed to be called from a template, C<preview_another_all_ocs()>
complements C<preview_another()> and previews a story or media document in all
of the the output channels it is associated with. The supported arguments are:

=over 4

=item C<$ba>

A business asset object to burn and send to the preview servers.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub preview_another_all_ocs {
    my ($self, $ba) = @_;

    # return unless we are in preview mode
    return unless $self->_get('mode') == PREVIEW_MODE;

    # Iterate over all the Ouput Channels for this story and preview each one.
    $self->preview_another($ba, $_->get_id ) for $ba->get_output_channels;
}

#------------------------------------------------------------------------------#

=item $url = $b->blaze_another($ba);

Designed to be called from a template, C<blaze_another()> is a high level
method that wraps around the entire publish/preview process. It takes a story
or media document as an argument, and in publish mode, it publishes it, and in
preview mode, it previews it with C<preview_another_all_ocs()>. The supported
arguments are:

=over 4

=item C<$ba>

A business asset object to publish or to burn and preview, based on the burn
context.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub blaze_another {
    my $self = shift;

    if ($self->get_mode == PUBLISH_MODE) {
        $self->publish_another(@_);
    } else {
        $self->preview_another_all_ocs(@_);
    }
}

#------------------------------------------------------------------------------#

=item $published = $burner->publish($ba, $key, $user_id, $publish_date);

Not designed to be called from a template, C<publish()> publishes an asset,
then remove it from workflow. Returns 1 if publish was successful, else 0. The
supported arguments are:

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
    my ($ats, $oc_sts) = ({}, {});
    my ($ba, $key, $user_id, $publish_date, $die_err) = @_;

    $publish_date ||= strfdate;
    my $published   = 0;
    my $baid        = $ba->get_id;
    my $repub       = $ba->get_publish_status;

    # Mark the story as published, so that other stories published by
    # burn_another() can find it as published in the database.
    $ba->set_publish_date($publish_date);
    $ba->set_publish_status(1) unless $repub;
    $ba->save;
    $self->_set([qw(mode _republish)], [PUBLISH_MODE, $repub]);

    # Determine if we've published before. Set the expire date if we haven't.
    my $exp_date = $ba->get_expire_date(ISO_8601_FORMAT);

    # Get a list of the relevant categories.
    my @cats = $key eq 'story' ? $ba->get_categories : ();
    # Grab the asset type.
    my $at = $ats->{$ba->get_element_type_id} ||= $ba->get_element_type;
    my $ocs = $ba->get_output_channels;

    my (@job_ids, %uris);
    foreach my $oc (@$ocs) {
        my $ocid = $oc->get_id;
        my $base_path = $fs->cat_dir($self->get_out_dir, 'oc_'. $ocid);
        $self->_set(['base_path'], [$base_path]);

        # Get a list of server types this category applies to.
        my $bat = $oc_sts->{$ocid} ||= Bric::Dist::ServerType->list({
            can_publish       => 1,
            active            => 1,
            output_channel_id => $ocid,
        });

        # Make sure we have some destinations.
        unless (@$bat) {
            my $errstr = q{Cannot publish asset "} . $ba->get_name
              . q{" to "} . $oc->get_name . q{" because there }
               . "are no Destinations associated with this output channel.";
            throw_burn_error error   => $errstr,
                             mode    => $self->get_mode,
                             oc      => $oc->get_name,
                             elem    => $at->get_name,
                             element => $at
                if $die_err;
            add_msg($errstr);
            next;
        }

        if ($exp_date && $exp_date lt $publish_date) {
            # Don't really publish it, just expire it.
            return 1 unless $ba->get_publish_status;
            (my $search_path = $base_path) =~ s/([_%])/\\$1/g;
            my @stale = Bric::Dist::Resource->list({
                "$key\_id" => $baid,
                $key eq 'story'
                    ? (path  => "$search_path/%")
                    : (oc_id => $oc->get_id),
            }) or next;
            my $expname = 'Expire "' . $ba->get_name .
              '" from "' . $oc->get_name . '"';
            $self->_expire($exp_date, $ba, $bat, $expname, $user_id, \@stale);
        } else {
            # Create a job for moving this asset in this output Channel.
            my $name = 'Distribute "' . $ba->get_name . '" to "' .
              $oc->get_name . '"';
            my $job = Bric::Util::Job::Dist->new({
                sched_time          => $publish_date,
                user_id             => $user_id,
                name                => $name,
                server_types        => $bat,
                "$key\_instance_id" => $ba->get_version_id,
                priority            => $ba->get_priority,
            });

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
                    my $res = _get_resource( $path, $uri);
                    $res->add_media_ids($baid);
                    $res->save;
                    $job->add_resources($res);
                    $published = 1;
                } else {
                    $published = 1;
                    add_msg('No media file is associated with asset "[_1]", ' .
                            'so none will be distributed.', $ba->get_name);
                }
            }

            # Save the job.
            $job->save;
            log_event('job_new', $job);

            # Stash away its ID and the SQL LIKE-escaped URI.
            push @job_ids, $job->get_id;
            $uris{$_} = undef for map {
                (my $u = $_->get_uri) =~ s/([_%])/\\$1/g;
                $u;
            } $job->get_resources;

            # Set up an expire job, if necessary.
            if ($exp_date and my @res = $job->get_resources) {
                my $expname = 'Expire "' . $ba->get_name .
                  '" from "' . $oc->get_name . '"';
                $self->_expire($exp_date, $ba, $bat, $expname, $user_id, \@res);
            }
        }
    }

    # Expire stale resources, if necessary.
    if (@job_ids and my @stale = Bric::Dist::Resource->list({
        "$key\_id" => $baid,
        (%uris ? ( not_uri => ANY(keys %uris) ) : ()),
        not_job_id => ANY(@job_ids),
    })) {
        # Yep, there are old resources to expire. Map them to destinations.
        my %resources_for;
        my %dest_for;
        for my $res (@stale) {
            for my $dest (Bric::Dist::ServerType->list({
                resource_id => $res->get_id,
                active      => 1,
            })) {
                $dest_for{$dest->get_id} ||= $dest;
                push @{ $resources_for{$dest->get_id} ||= [] }, $res;
            }
        }

        # Expire all resources from each destination.
        while (my ($did, $res) = each %resources_for) {
            my $dest = $dest_for{$did};
            $self->_expire(
                $publish_date,
                $ba,
                [$dest],
                'Expire stale "' . $ba->get_name . '" from "'
                    . $dest->get_name . '"',
                $user_id,
                $res,
            );
        }

        # Dissociate the stale resources from this asset.
        my $meth = $key eq 'story' ? 'del_story_ids' : 'del_media_ids';
        $_->$meth($baid)->save for @stale;
    }

    if ($published) {
        # Set published version if we've reverted
        # (i.e. unless we're republishing published_version)
        my $pubversion = $ba->get_published_version;
        unless (defined $pubversion && $ba->get_version <= $pubversion) {
            $ba->set_published_version($ba->get_version);
        }
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

    $self->_set([qw(mode _republish)], [undef, undef]);
    return $published;
}

##############################################################################

=item $burner->publish_another($ba);

  $burner->publish_another($ba);
  $burner->publish_another($ba, $publish_time);
  $burner->publish_another($ba, $publish_time, $anytime);

Designed to be called from within a template, this method schedules the
publication of a document other than the one currently being published. This
is useful when a template for one document type needs to trigger the
publication of another document. Look up that document via the Bricolage API
and then pass it to this method to have it scheduled for publication at the
same time as the story currently being published.

If the mode isn't C<PUBLISH_MODE> or if the document passed in is the same
story as the currently burning story, the publish will not actually be
executed. Pass in an ISO-8601 datetime string to specify a date and time
different than the current story to publish the document at a different time.
Pass in a true value as the third argument to trigger the publish in any mode,
including C<PREVIEW_MODE> (not recommended).

If the document to be published has been published before, then the
previously-published version will be published instead of the current version.
This will help prevent removing stories from workflow while users are working
on them.

Note that any values stored in the C<notes> attribute of the current burner
will be copied to the publish job, and will therefore be available in
templates when the other document is published, but B<only> if the publish
date and time is before I<now> and if the C<QUEUE_PUBLISH_JOBS>
F<bricolage.conf> directive is not enabled.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

All documents passed to C<publish_another()> are stored in a publish queue
internal to Bric::Util::Burner; they will B<not> be published immediately. The
queue may be cleared and all documents in it published by calling the
C<flush_another_queue()> class method.

You do not need to flush the publish queue from your templates, however,
unless you want to always force an immediate republish. The reason for this is
so that, if the bulk publication of a lot of stories at once causes the same
document to be repeatedly passed to C<publish_another>, it will only be
published once per Apache request or per poll time by C<bric_queued>. So in
principal, you don't need to worry about this at all.

=cut

sub publish_another {
    my ($self, $ba, $pub_time, $anytime) = @_;
    # Just return if we're in publish mode or the user wants to trigger
    # the publish in preview mode, too (totally whacked).
    return $self unless $anytime || $self->_get('mode') == PUBLISH_MODE;

    # Figure out what we're publishing. (Why can't it figure that out for
    # itself??
    my $key = ref $ba eq 'Bric::Biz::Asset::Business::Story'
      ? 'story'
      : 'media';

    # Publishing checked-out stories is a really bad idea.
    if ($ba->get_checked_out) {
        my $uri = $ba->get_uri;
        throw_burn_error(
            error => qq{Cannot publish $key "$uri" because it is checked out. }
                   . 'Your best bet is to pass `published_version => 1` when '
                   . 'looking up documents to pass to burn_another()',
            mode  => $self->get_mode,
        );
    }

    # Don't bother if it's the same as the current story.
    if ($key eq 'story' and my $story = $self->get_story) {
        return $self if $ba->get_id == $story->get_id;
    }

    # Figure out the publish time. Default to the same time as the story
    # that's currently being burned.
    $pub_time ||= $self->get_story->get_publish_date(ISO_8601_FORMAT)
        || strfdate;

    # Make sure that, if it has been published before, that we republish
    # the published version, not the current version.
    $ba = ref($ba)->lookup({ version_id => $ba->get_version_id })
        if $ba->get_publish_status
        && $ba->get_version > $ba->get_published_version;

    my $uuid = $ba->get_uuid;
    if (my $queue = $another_queue{$uuid}) {
        # Set up the earliest publish time.
        if ($pub_time lt $queue->[1]) {
            @{ $queue }[1,2] = ($pub_time, [ $self->_get('_notes') ] );
        }
    } else {
        # Add it to the publish_another queue.
        push @another_queue_uuids, $uuid;
        $another_queue{$uuid} = [ $ba, $pub_time, [ $self->_get('_notes') ] ];
    }
    return $self;
}

#------------------------------------------------------------------------------#

=item @resources = $burner->burn_one($ba, $oc, $cat);

Burn an asset in a given output channel and category, this is usually called
by the preview or publish method. Returns a list of resources burned.

Parameters are:

=over 4

=item C<$ba>

A business asset object to burn.

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
    my ($story, $oc, $cat) = @_;

    # Figure out the base URI and output path.
    my $base_uri = $story->get_uri($cat, $oc, 1);
    my $path = $fs->cat_dir($self->get_base_path, $fs->uri_to_dir($base_uri));

    # Create the output directory.
    $fs->mk_path($path);

    # Set up properties needed by the subclasses.
    $self->_set([qw(story oc cat output_filename output_ext output_path
                    base_uri page encoding)],
                [@_, $oc->get_filename($story), $oc->get_file_ext, $path,
                 $base_uri, 0, 'utf8']);

    # Construct the burner and do it!
    my $burner = $self->_get_subclass($story, $oc);

    # Never use the local user's preferences during a burn.
    my $use_user = Bric::Util::Pref->use_user_prefs;
    Bric::Util::Pref->use_user_prefs(0) if $use_user;
    my $ret = $burner->burn_one(@_);
    Bric::Util::Pref->use_user_prefs(1) if $use_user;

    # Return a list of the resources we just burned.
    $self->_set(['resources', 'page'], [[], 0]);
    return wantarray ? @$ret : $ret;
}

=item my $bool = $burner->chk_syntax($template, \$err)

Compiles the template. If the compile succeeds with no errors, chk_syntax()
returns true. Otherwise, it returns false, and the error will be in the $err
varible passed by reference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub chk_syntax {
    my $self = shift;
    my ($burner) = $self->_get_subclass($_[0]);
    $burner->_set(['mode'], [SYNTAX_MODE]);
    my $ret = $burner->chk_syntax(@_);
    return $ret;
}

##############################################################################

=item $success = $b->set_burn_again(1)

=item my $again = $b->get_burn_again

This method is designed to be called from within a template. When passed a
true value, it causes the burner to burn the current story and page again,
creating another file. This is useful for creating multi-file output without
extra paginated subelements. For example, if you need to create an index of
stories, and you only want to list 10 on a page over multiple pages, you can
use this method to force the burner to burn as many pages as you need to get
the job done.

When the burner prepares to burn the page again, it resets the C<burn_again>
attribute. So you'll need to set it for every page for which another page
burned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

##############################################################################

=item my $repub = $b->is_republish

Returns true if the document being published has been published before.
Returns false if it has not. Only relevant during a call to C<publish()>, so
in templates, that's when C<publish_mode> is set to C<PUBLISH>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $repub = $b->is_first_publish

Returns true if the document is being published for the first time. Returns
false if it has not. Only relevant during a call to C<publish()>, so in
templates, that's when C<publish_mode> is set to C<PUBLISH>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_republish { shift->_get('_republish') }
sub is_first_publish { !shift->_get('_republish') }

##############################################################################

=item my $page_file = $burner->page_file($number)

  % # Mason syntax.
  % my $page_file = $burner->page_file($number);
  <a href="<% $page_file %>">Page Number <% $number %></a>

Returns the file name for a page in a story as the story is being burned. The
page number must be greater than 0.

B<Throws:>

=over 4

=item *

Page number not greater than zero.

=back

B<Side Effects:> NONE.

B<Notes:> This method does not check to see if the page number passed in is
actually a page in the story. Caveat templator.

=cut

sub page_file {
    my ($self, $number) = @_;
    return unless defined $number;
    throw_burn_error error => "Page number '$number' not greater than zero",
                     oc    => $self->get_oc->get_name,
                     mode  => $self->get_mode,
                     cat   => $self->get_cat->get_uri
      unless $number > 0;
    my ($fn, $ext) = $self->_get(qw(output_filename output_ext));
    my @page_extensions = $self->get_page_extensions;
    my $start = $self->get_page_numb_start;

    if ($number <= @page_extensions) {
        $number = $page_extensions[--$number];
    } else {
        $number += $start - @page_extensions - 1;
    }

    $ext = ".$ext" if $ext ne '';
    return "$fn$number$ext";
}

##############################################################################

=item my $page_uri = $burner->page_uri($number)

  % # Mason syntax.
  % my $page_uri = $burner->page_uri($number);
  <a href="<% $page_uri %>">Page Number <% $number %></a>

Returns the URI for a page in a story as the story is being burned. The
page number must be greater than 0.

B<Throws:>

=over 4

=item *

Page number not greater than zero.

=back

B<Side Effects:> NONE.

B<Notes:> This method does not check to see if the page number passed in is
actually a page in the story. Caveat templator.

=cut

sub page_uri {
    my $self = shift;
    my $filename = $self->page_file(@_) or return;
    my $base_uri = $self->_get('base_uri');
    return $fs->cat_uri($base_uri, $filename);
}

##############################################################################

=item my $page_filepath = $burner->page_filepath($number)

Returns the complete local file system file name for a page in a story as the
story is being burned. The page number must be greater than 0.

B<Throws:>

=over 4

=item *

Page number not greater than zero.

=back

B<Side Effects:> NONE.

B<Notes:> This method does not check to see if the page number passed in is
actually a page in the story. Caveat templator.

=cut

sub page_filepath {
    my $self = shift;
    my $filename = $self->page_file(@_) or return;
    my $base_dir = $self->_get('output_path');
    return $fs->cat_file($base_dir, $filename);
}

##############################################################################

=item my $prev_page_file = $burner->prev_page_file

  % if (my $prev = $burner->prev_page_file) {
      <a href="<% $prev %>">Previous Page</a>
  % }

Returns the file name for the previous file in a story as the story is being
burned. If there is no previous file, C<prev_page_file()> returns undef.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub prev_page_file {
    my $self = shift;
    my $page = $self->_get(qw(page)) or return;
    return $self->page_file($page);
}

##############################################################################

=item my $prev_page_uri = $burner->prev_page_uri

  % if (my $prev = $burner->prev_page_uri) {
      <a href="<% $prev %>">Previous Page</a>
  % }

Returns the URI for the previous file in a story as the story is being
burned. If there is no previous URI, C<prev_page_uri()> returns undef.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub prev_page_uri {
    my $self = shift;
    my $filename = $self->prev_page_file or return;
    my $base_uri = $self->_get('base_uri');
    return $fs->cat_uri($base_uri, $filename);
}

##############################################################################

=item my $next_page_file = $burner->next_page_file

  % if (my $next = $burner->next_page_file) {
      <a href="<% $next %>">Next Page</a>
  % }

Returns the file name for the next file in a story as the story is being
burned. If there is no next file, C<next_page_file()> returns undef.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub next_page_file {
    my $self = shift;
    my ($page, $isnext, $again) = $self->_get(qw(page more_pages burn_again));
    return unless $isnext || $again;
    return $self->page_file($page + 2);
}

##############################################################################

=item my $next_page_uri = $burner->next_page_uri

  % if (my $next = $burner->next_page_uri) {
      <a href="<% $next %>">Next Page</a>
  % }

Returns the URI for the next file in a story as the story is being
burned. If there is no next URI, C<next_page_uri()> returns undef.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub next_page_uri {
    my $self = shift;
    my $filename = $self->next_page_file or return;
    my $base_uri = $self->_get('base_uri');
    return $fs->cat_uri($base_uri, $filename);
}

##############################################################################

=item my $uri = $burner->best_uri($story)

  % if (my $rel_story = $element->get_related_story) {
      <a href="<% $burner->best_uri($rel_story)->as_string %>">
        <% $rel_story->get_title %>
      </a>
  % }

Returns a URI object representing Bricolage's best guess as to the appropriate
URI to use to link to the story or media object passed as an argument. See the
L<URI|URI> docs for information on its interface. The semantics that
C<best_uri()> uses to create the URI are as follows:

First, it checks to see if the asset's Site ID is the same as the the Site ID
for the current output channel. If it is, then the URI is returned without the
protocol or server name, but formatted for either the current output channel
or for the document's primary output channel.

If the document isn't in the current output channel's site, C<best_uri()>
looks for an alias to the document in the current output channel's site. If
there is one the alias is used to create the URI, and the URI is returned
without the protocol or server name, but formatted for either the current
output channel or for the alias' primary output channel.

And finally, if the document is in another site and there is no alias in the
current site, C<best_uri()> will return a full URI with the prtocol and the
document's site's domain name, formatted according to the settings of the
document's primary output channel.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub best_uri {
    my ($self, $ba) = @_;
    my $oc = $self->get_oc;
    my $site_id = $oc->get_site_id;
    my $uri = '';

    if ($ba->get_site_id == $site_id) {
        # Make sure we have an output channel that works with this asset.
        # Try the current one, and fallback on the default if that fails.
        $oc = ($ba->get_output_channels($oc->get_id))[0] ||
          $ba->get_primary_oc;
    } else {
        # The asset's not in this site. Try to lookup an alias in this site.
        if (my $rel = $ba->lookup({ alias_id => $ba->get_id,
                                    site_id  => $site_id })) {
            # Use the alias, instead.
            $ba = $rel;
            # Make sure we have an output channel that works with this asset.
            # Try the current one, and fallback on the default if that fails.
            $oc = ($ba->get_output_channels($oc->get_id))[0] ||
              $ba->get_primary_oc;
        } else {
            # No alias. Prepend the protocol and site domain name to
            # the URI.
            $oc = $ba->get_primary_oc;
            my $site = Bric::Biz::Site->lookup({ id => $ba->get_site_id });
            $uri = $oc->get_protocol . $site->get_domain_name;
        }
    }

    # Who's idea was it to have the OC passed as the first argument to Media
    # and the second to Story??? (Oh yeah, mine -- legacy reasons.) -- David
    return URI->new($uri . $ba->get_uri((UNIVERSAL::isa($ba, 'Bric::Biz::Asset::Business::Story') ? undef : ()), $oc));
}

##############################################################################

=item $burner->notes

  my $notes = $burner->notes;
  while (my ($k, $v) = each %$notes) {
      print "$k => $v\n";
  }

  my $last = 10;
  $burner->notes( last_story => $last );
  $last = $burner->notes('last_story');

The C<notes()> method provides a place to store burn data data, giving
template developers a way to share data among multiple burns over the course
of publishing a single story in a single category to a single output
channel. Any data stored here persists for the lifetime of the burner object,
as well as to any burners generated by calls to C<publish_another()> or
C<preview_another()>. Use C<clear_notes()> to manually clear the notes.

Conceptually, C<notes()> contains a hash of key-value pairs. C<notes($key,
$value)> stores a new entry in this hash. C<notes($key)> returns a previously
stored value. C<notes()> without any arguments returns a reference to the
entire hash of key-value pairs.

C<notes()> is similar to the mod_perl method C<< $r->pnotes() >>. The main
differences are that this C<notes()> can be used in a non-mod_perl environment
(such as when a story is published by F<bric_queued>), and that its lifetime is
tied to the lifetime of the burner object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub notes {
    my $self = shift;
    my $notes = $self->_get('_notes');
    return $notes unless @_;
    my $key = shift;
    return @_
      ? $notes->{$key} = shift
      : $notes->{$key};
}

##############################################################################

=item $burner->clear_notes

  $cb_request->clear_notes;

Use this method to clear out the notes hash.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub clear_notes {
    my $self = shift;
    my $notes = $self->_get('_notes');
    %$notes = ();
    return $self;
}

##############################################################################

=item $burner->display_pages(\@element_key_names);

  $burner->display_pages($element_key_name)
  $burner->display_pages($element_key_name, %ARGS)
  $burner->display_pages(\@element_key_names, %ARGS)

A method to be called from template space. Use this method to display
paginated elements. If this method is used, the burn system will run once for
every page element listed in C<\@paginated_element_key_names> (or just
C<$paginated_element_key_name>) in the story; this is so that category
templates and story element type templates will be executed when appropriate.
All arguments after the first argument will be passed to the template executed
as its C<%ARGS> hash.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> This method requires that the burner subclass has implemented a
C<display_element()> method.

=cut

sub display_pages {
    my ($self, $key_names) = @_;
    $key_names = [$key_names] unless ref $key_names;

    # Get the current element
    my $elem = $self->_current_element;
    my $page_place = $self->_get('_page_place') || 0;

    # Get the page and the next page.
    my $pages = $elem->get_containers(@$key_names);
    my $page_elem = $pages->[$page_place];
    my $next_page = $pages->[$page_place + 1];

    # Set the 'more_pages' and '_page_place' properties.
    $self->_set([ qw(more_pages _page_place) ],
                [ $next_page, ++$page_place ]);

    # Display it!
    $self->display_element($page_elem, @_);
}

##############################################################################

=item $burner->throw_error(@message);

  my $media = $element->get_related_media or $burner->throw_error(
      'Hey, you forgot to associate a media document! ',
      'What were you thinking?',
  );

Throws a Bric::Util::Fault::Exception::Burner::User exception. The arguments
passed to the method will be joined into a single erroor message that will be
displayed in the UI so that your user can see any mistakes you caught and fix
them.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub throw_error {
    my $self = shift;
    my ($oc, $cat, $elem) = $self->_get(qw(oc cat element));
    throw_burn_user
        error => join('', @_),
        mode  => $self->get_mode,
        oc    => ($oc   ? $oc->get_name   : ''),
        cat   => ($cat  ? $cat->get_uri   : ''),
        elem  => ($elem ? $elem->get_name : ''),
        ($elem ? (element => $elem) : ()),
    ;
}

##############################################################################

=item $success = $b->add_resource();

  $burner->add_resource($filename, $uri);

Adds a Bric::Dist::Resource object to a burn. Pass in the file name and URI of
the resource. Called by the burner subclasess after they've written files to
disk.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_resource {
    my ($self, $file, $uri) = @_;
    my ($story, $ext, $ress) = $self->_get(qw(story output_ext resources));

    # Create a resource for the distribution stuff.
    my $res = _get_resource( $file, $uri);
    # Add our story ID.
    $res->add_story_ids($story->get_id);
    $res->save;
    push @$ress, $res;
    return $self;
}

##############################################################################

=back

=head2 Protected Class Methods

=over 4

=item __PACKAGE__->_register_burner(@args)

  __PACKAGE__->_register_burner( Bric::Biz::OutputChannel::BURNER_TEMPLATE,
                                 category_fn => 'category',
                                 exts        =>
                                   { 'pl'   => 'HTML::Template Script (.pl)',
                                     'tmpl' => 'HTML::Template Template (.tmpl)'
                                   }
                               );

Protected method only called by Burner subclasses when they're loaded. This
method registers the subclasses, along with their Bric::Biz::OutputChannel
constants, file names, and file extenstions. Note that the C<category_fn> and
must be unique among all burners, as must the file extensions passed via the
C<exts> directive.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _register_burner {
    my $class = shift;
    my $burner = shift;

    # Register the class with the constant.a
    $classes->{$burner} = $class;

    # Save the file name specs.
    my %p = @_;
    $cat_fn_class->{$p{category_fn}} = $class;
    $cat_fn_has_ext->{$p{category_fn}} = $p{cat_fn_has_ext};
    while (my ($e, $label) = each %{$p{exts}}) {
        $exts->{$e} = $class;
        push @{ $file_types->[$burner] }, [ $e => $label ];
        $cat_ext_fn->{$e} = $p{category_fn};
    }
}


##############################################################################

=back

=head2 Private Instance Methods

=over 4

=item $burner->_get_subclass($ba, $oc)

Returns the subclass of Bric::Util::Burner appropriate for handling the $ba
template object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_subclass {
    my ($self, $asset, $oc) = @_;
    $oc ||= $asset->get_primary_oc;
    my $b = $oc->get_burner || BURNER_MASON;
    my $burner_class = $classes->{$b}
        or throw_gen 'Cannot determine template burner subclass.';
    # Instantiate the proper subclass.
    return $burner_class->new($self);
}

=item $burner->_expire($expire_date, $ba, $server_types, $exp_name, $user_id, $resources)

Sets up an expiration job for resources.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _expire {
    my ($self, $exp_date, $ba, $bat, $expname, $user_id, $res) = @_;
    # Make sure we haven't expired this asset on that date already.
    # XXX There could potentially be some files missed because of
    # changes between versions, but that should be extremely uncommon.
    return if Bric::Util::Job::Dist->list_ids({
        sched_time  => $exp_date,
        resource_id => $res->[0]->get_id,
        type        => 1,
    })->[0];

    # We'll need to expire it.
    my $exp_job = Bric::Util::Job::Dist->new({
        sched_time   => $exp_date,
        user_id      => $user_id,
        server_types => $bat,
        name         => $expname,
        resources    => $res,
        type         => 1,
        priority     => $ba->get_priority,
        $ba->key_name . '_instance_id' => $ba->get_version_id,
    });
    $exp_job->save;
    log_event('job_new', $exp_job);
}

=item $burner->_get_resource( $path, $uri )

Looks up or creates a resource objct for the given path/URI combination. SQL
LIKE wildcard characters are escaped so as to avoid bogus lookups.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_resource {
    my ($path, $uri) = @_;
    ( my $lpath = $path) =~ s/([_%])/\\$1/g;
    ( my $luri  = $uri)  =~ s/([_%])/\\$1/g;
    return Bric::Dist::Resource->lookup({
        path => $lpath,
        uri  => $luri,
    }) || Bric::Dist::Resource->new({
        path       => $path,
        uri        => $uri,
        media_type => Bric::Util::MediaType->get_name_by_ext($uri),
    });
}

#------------------------------------------------------------------------------#

# XXX Grab the PERL_LOADER code from Bric::Config, where it has been sneakily
# stached in its %INC hash, and execute it.
if (my $code = delete $Bric::Config::INC{PERL_LOADER}) {
    my $pkg = TEMPLATE_BURN_PKG;
    eval qq{
        package $pkg;
        use Bric::Util::DBI qw(:junction);
        $code;
    };
    # Just die if there was an error.
    die $@ if $@;
}

# These *must* come after the above code to ensure that all the symbols
# are available to be loaded.
require Bric::Util::Burner::Template if eval { require HTML::Template::Expr };
require Bric::Util::Burner::TemplateToolkit
    if eval { require Template && $Template::VERSION >= 2.14 };
require Bric::Util::Burner::PHP if eval { require PHP::Interpreter };

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

Garth Webb <garth@perijove.com>

Sam Tregar <stregar@about-inc.com>

Matt Vella <mvella@about-inc.com>

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric>, L<Bric::Util::Burner::Mason>, L<Bric::Util::Burner::Template>.

=cut
